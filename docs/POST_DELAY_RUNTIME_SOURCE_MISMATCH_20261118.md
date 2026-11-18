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

## Required next verification

1. Inspect the exact 64-KiB ROM file configured for PCem, not just the Visual Studio build output.
2. Read byte offset 8284h from that exact file. It must match the runtime observation (52h) if the current log is from that file.
3. Compare the file's SHA-256 and bytes at 8284h, D709h..D73Dh against the latest build output.
4. Only after the loaded image is proven to be the intended build should the delay loop or missing ROM data be changed.

No BIOS instruction or delay logic is changed by this investigation.
