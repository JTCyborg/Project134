# AMI486 semantic map — phase 60 (2026-11-16)

## Scope

Correct the reset-vector mistake in phase 59, reconstruct the actual incoming edge to the E3xx POST sequence, and trace the BP value saved before the 1662h bitmap consumer.

## 1. Correct hardware reset vector

The raw `ami486.bin` image is 65,534 bytes in the repository. Its final bytes at file offset FFF0h are:

```
FF F0: EA 5B E0 00 F0
```

This is the x86 reset-vector instruction:

```asm
FFFF0  EA 5B E0 00 F0    ljmp F000:E05B
F000:E05B                jmp D604
```

Therefore the hardware reset path is `FFFF0h -> F000:E05Bh -> D604h`.

The bytes at file offset E000h (`EA 05 E0 00 F0`) form a separate far-jump entry to F000:E005h, and E005h jumps to F73Bh. This is not the reset vector. No static direct branch to E000h was found in the linear listing. The F73Bh routine begins with `MOV BP,SP`, but it is not established as the source of the BP value later consumed at 1662h.

The phase-59 statement that E000h is the reset vector is withdrawn. The D604h protected-mode-return analysis remains valid: F096h also jumps to E05Bh, whose actual instruction jumps to D604h.

## 2. The real incoming edge to the E3xx sequence

A direct reference search found:

```asm
52C1  jmp E2C6
E2C6  out 0Dh,al
...
E2F4  jmp E382       ; only on the timeout/error condition
...
E2F7  mov al,60h     ; normal continuation
...
E380  jmp E394
E394  cli
...
E3AC  jmp 10E0h
```

Important correction: `E2F4 -> E382` is an error/message route, not the successful path into E394h. On the normal path E2F4's conditional branch is not taken; execution continues through E2F7h and the E2F7–E380 hardware setup sequence. The successful path then reaches E394h and E3ACh.

The 52C1h edge is statically confirmed. The earlier E3ACh→10E0h→120Dh→1656h→1662h chain remains valid.

## 3. BP provenance narrowed to the register frame at 525Fh

The relevant code is:

```asm
5194  or bp,bp
5196  jns 51F3
...
51F3  push bp
51F4  mov bp,1
...
5239  pop bp
...
525F  pushaw
5260  mov ax,sp
5262  mov [0067],ax
...
5280  mov ax,[0067]
5283  mov sp,ax
5289  popaw
...
52C1  jmp E2C6
```

On the nonnegative path, BP is temporarily changed to 1 at 51F4h, but the original BP is restored by POP BP at 5239h before the PUSHAW at 525Fh. On the negative path from 5198h, the examined instructions do not modify BP before the paths converge at 523Eh and reach the same saved frame.

Thus the PUSHAW at 525Fh saves the BP value that was already present at 5194h. The frame is restored at 5289h before the jump to E2C6h. The E2C6–E3ACh path contains no identified BP assignment. The early POST sequence then sets bits 8–11, clears bit15 at 11FDh, and preserves bit13 until the 1662h bitmap walk.

Consequently, BP.13 consumed at 1668h is carried in the incoming BP value at 5194h, saved at 525Fh, restored at 5289h, and preserved along the successful E2xx/E3xx route.

## 4. What is still not established

- No direct CALL/JMP to 5189h, 5190h, 50A0h, or 50E1h appears in the linear listing. The upstream entry into this POST/memory-test block may be indirect, table-driven, or stack-crafted.
- The code before 5194h does not locally initialize BP in the inspected 50A0h–5194h range. The caller/context supplying BP to 5194h is not yet identified.
- The separate E000h→E005h→F73Bh entry has not been connected to the 52C1h→E2C6h path. Do not infer that F73Ch's `MOV BP,SP` supplies the bitmap.
- The D604h reset/protected-mode dispatcher and the E3xx route must remain separate until an actual transfer edge is identified.

## 5. Confirmed vs unresolved

### Confirmed
- Hardware reset vector is at file offset FFF0h and encodes `LJMP F000:E05B`.
- E05Bh jumps to D604h. F096h also jumps to E05Bh.
- E000h is a separate code entry, not the hardware reset vector.
- 52C1h jumps to E2C6h; normal execution proceeds through E2F7h–E380h, E394h, E3ACh and enters POST at 10E0h.
- E2F4h→E382h is a conditional error path, not the normal route to E394h.
- PUSHAW at 525Fh saves the original BP after the temporary BP=1 at 51F4h has been undone by POP BP at 5239h.
- POPAW at 5289h restores that BP before E2C6h. The intervening E2xx/E3xx route does not assign BP.
- BP.13 at 1662h therefore originates no later than the incoming BP at 5194h.

### Unresolved
- The actual caller or indirect entry supplying BP at 5194h.
- Whether that caller is reached from the hardware reset path through an indirect dispatch, or through a separate firmware entry.
- The producer of BP.13 itself.
