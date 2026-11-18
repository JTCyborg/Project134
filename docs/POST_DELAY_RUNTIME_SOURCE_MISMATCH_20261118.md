# Project134 — POST delay runtime/source mismatch (2026-11-18)

## Finding

The current Project134 PCem log ends at:

```
EAX=00000052 ECX=000067CB ESP=0000D709
PC=D71E CS=F000
[POST80] 01
[POST80] 02
12 × onesec
11355552 ins
```

The reconstructed source at `bios/src/reset.asm` executes this sequence at F000:D709:

```asm
mov al, [cs:0x8284]
or  al, al
jz  bios_post_delay_complete
bios_post_delay_loop:
    loop bios_post_delay_loop
    dec al
    jnz bios_post_delay_loop
```

At F000:D71E, `AL=52h` means the byte read from `CS:8284` was 52h. The final `CX=67CBh`, starting from AAAAh, means 17,119 LOOP iterations have completed. The CPU is progressing through the first delay pass; this is not evidence of a frozen LOOP instruction.

## Critical inconsistency

In the current NASM source, the last defined content before offset 8400h ends at 20FCh. The directive

```asm
times 0x8400 - ($ - rom_start) db 0xFF
```

fills the entire interval 20FCh..83FFh with FFh. Therefore the current source image defines byte 8284h as FFh, not 52h.

Consequently, the observed runtime value AL=52h is inconsistent with the current source image. The most likely explanation is that PCem loaded a different/stale BIOS image, or the tested ROM file is not the output of the current NASM source. This must be resolved before changing the delay algorithm.

## Reference run

Project133's original-BIOS log reaches POST checkpoints 03h and onward through 67h, then 80h, 82h, 83h and 85h. Its final state is F000:B3C5 with CR0=60000010 and 37,826,874 instructions.

## Verification of the published Visual Studio output

The user identified the intended build artifact as `out/Debug/Project134.bin`. I fetched that exact file from `main` and decoded it:

- Git blob SHA: `6ee43a5d23bf21213b2a7c642e0d23a8629155f1`
- Decoded size: `65536` bytes (exactly 64 KiB)
- SHA-256: `unavailable`
- ROM byte at offset `8284h`: `FF`
- ROM bytes at `D709h..D73Dh`:

```
35 AA AA 75 B0 B0 8D E6 70 B0 02 E6 80 2E A0 84 82 08 C0 74 06 E2 FE FE C8 75 FA 2E F6 06 81 82 40 75 0F 0F 01 E0 08 E4 74 08 0F 20 C0 0C 10 0F 22 C0 B0 03 E6
```

The published build therefore agrees with the current NASM source at `8284h` (FFh), and contains the expected delay-loop machine code at `D709h`. But the published `pcem.log` still records `AL=52h` at `F000:D71E`. This is now a confirmed artifact/runtime mismatch: the log was not produced by this exact published binary, or PCem loaded another ROM image. It is no longer necessary to ask whether the Visual Studio output itself has stale contents; the mismatch is between this verified artifact and the recorded runtime.

## Next verification required

Identify the ROM path selected by PCem's AMI486 machine configuration and compare that file byte-for-byte with this artifact. The repository log records the machine and runtime state but does not expose the loaded BIOS file path. Until that path is known, changing the delay loop would be an unsupported workaround.

No BIOS instruction or delay logic is changed by this investigation.
