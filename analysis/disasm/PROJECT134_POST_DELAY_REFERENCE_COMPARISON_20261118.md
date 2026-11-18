# Project134 — reconstructed POST delay checkpoint comparison

Date: 2026-11-18  
Branch: `main`  
Reference run: `JTCyborg/Project133/pcem.log` (original AMI486 ROM)  
Reconstruction run: `JTCyborg/Project134/pcem.log` (NASM-built ROM)

## Observed result

Both logs identify the same PCem machine configuration: AMI486, 486 CPU, 10 MHz, builtin FPU, and 16 MiB RAM. The original-ROM run progresses through POST checkpoints `01`, `02`, `03` and later reaches `85`. Its final CPU location is `F000:B3C5`, with `CR0=60000010` and 37,826,874 instructions.

The reconstructed-ROM run emits only `01` and `02`. At the captured pause it is at `F000:D71E`, with `AL=52h`, `CX=67CBh`, `SP=D709h`, and `CR0=40000000`, after 11,355,552 instructions.

## Interpretation of F000:D71E

The original disassembly at this address is:

```asm
F000:D716  mov al,[cs:8284]
F000:D71A  or  al,al
F000:D71C  jz  D724
F000:D71E  loop D71E
F000:D720  dec al
F000:D722  jnz D71E
F000:D724  test byte [cs:8281],40h
```

The register-test trampoline at `D6C4-D6DA` copies the `AAAAh` test value through BX, CX, DX, SI, DI, BP, ES, DS and SS. Therefore the delay loop starts with `CX=AAAAh`; the captured `CX=67CBh` is a decremented value, not the initial value. The loop is executing rather than sitting at an unchanging instruction pointer.

For the captured state:
- `AAAAh - 67CBh = 42DFh = 17,119` LOOP iterations have elapsed in the current AL pass.
- `AL=52h` remains unchanged because the current 16-bit LOOP pass has not yet reached zero.
- A completed outer-loop pass consumes 43,690 iterations on the initial pass, then 65,536 iterations on each subsequent pass because LOOP wraps CX from zero to FFFFh before the next DEC AL.
- With `AL=52h`, the full delay is 5,352,106 LOOP iterations before control reaches `D724h`.

## Source comparison and decision

The NASM source in `bios/src/reset.asm` contains the same register-test trampoline, CMOS read, `LOOP`, `DEC AL`, and `JNZ` sequence at the corresponding fixed addresses. The source also pins the continuation at `D724h`. The existing structural validator checks the surrounding reconstructed instruction stream.

No BIOS instruction was changed in this investigation: the delay sequence is present in the original disassembly and the captured CPU state demonstrates forward progress through it. Changing or bypassing this loop now would alter original BIOS behavior without evidence of an instruction-encoding defect.

## Next diagnostic target

The current logs do not establish why the reconstructed run has not yet emitted POST `03`. The next useful comparison is the runtime value read from `CS:8284` and the effective execution rate/elapsed emulated time for this loop in both runs. Keep the original ROM immutable and do not treat the reconstructed BIOS as functionally validated until it reaches the later POST checkpoints.
