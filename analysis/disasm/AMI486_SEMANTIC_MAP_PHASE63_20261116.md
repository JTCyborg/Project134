# AMI486 semantic map — phase 63 (2026-11-16)

## Scope

Batch control-flow pass over the full linear disassembly: find direct references to 509Eh, reconstruct its actual incoming POST path, and validate the suspicious BP write at 1B05h caused by the wrapped jump from D9D9h.

## 1. Exact direct entry into 509Eh found

The full ROM scan found one direct near transfer to 509Eh:

~~~asm
5F58  call 5FD6
5F5B  call 54E5
5F5E  mov al,3Bh
5F60  out 80h,al
5F62  jmp 509Eh
~~~

This resolves the earlier missing static reference. The 509Eh block is reached from the main POST path after the display/memory configuration and cursor positioning steps.

The target block begins:

~~~asm
509E  mov ax,028Fh
50A1  call EE9D
50A4  mov al,40h
50A6  out 80h,al
50A8  call F3DB
...
50CD  mov ah,89h
50D3  int 15h
~~~

## 2. Reconstructed predecessor chain

The earlier memory/timing branch reaches the memory-test body through a deliberately crafted stack return:

~~~asm
DA9B  mov al,1Bh
DA9D  out 80h,al
DA9F  jmp 5BF8

5BF8  mov al,20h
5BFA  out 80h,al
5BFC  mov sp,5C02h
5BFF  jmp F5A9

5C02  db 04h,5Ch
5C04  xor di,di
...
5F58  call 5FD6
5F5B  call 54E5
5F62  jmp 509Eh
~~~

F5A9h is used as a stack/port helper; its RET consumes the word at 5C02h and resumes at 5C04h. This is not a normal CALL edge, which explains why a conventional direct-xref scan did not reveal the start of this chain.

Within the 5C04h–5F62h successful path, no instruction sets BP.13:
- 5C37h sets BP=3 only on the fatal memory-test error path.
- 5CF9h tests BP.13; it does not set it.
- 5D07h clears BP.12, not BP.13.
- 5ECC and 5F7Dh set BP.7 and BP.6 respectively.
- 5DC1h restores the BP saved at 5DBDh.
- 5FD6h and 54E5h do not modify BP.

Thus BP.13 must be present before the entry into the DAxx timing branch (or be inherited from an earlier caller/initialization context).

## 3. Wrapped jump D9D9h does not execute the apparent BP write at 1B05h

The jump at D9D9h has a 16-bit relative target of 1AFBh (IP wraparound):

~~~asm
D9D9  jmp 1AFBh
1AFB  mov al,0B3h
1AFD  nop
1AFE  mov sp,1B04h
1B01  jmp EE94h
~~~

EE94h is a CMOS-index/read helper: OUT 70h,AL; short delays; IN AL,71h; RET.

Because SP is explicitly set to 1B04h before entering EE94h, its RET consumes the word stored at 1B04h (06 1B) and resumes at 1B06h. Bytes at 1B05h are therefore stack/inline data on this path, not executed instructions. The linear disassembler's apparent instruction 1B05 SBB BP,[...] is a false code interpretation and is not a BP.13 producer.

This is an important example of why the linear listing cannot be treated as a complete CFG or as proof that every decoded instruction executes.

## 4. Global candidate scan

The batch scan found 21 decoded indirect CALL/JMP instructions across the image. None was proven to dispatch directly to 509Eh. The direct incoming edge is now known at 5F62h.

No decoded immediate BP operation in the verified DAxx→5BF8h→5C04h→5F62h path sets bit 13. The DAxx timing path has only:
- DA29h: OR BP,0001h on a timer-check failure with the diagnostic option enabled.
- DA95h: BP=1 on a fatal timeout/error path, then jump to F4A5h.
- DA9Fh: normal continuation into 5BF8h.

The normal path's BP.13 source is therefore upstream of DA00h.

## 5. Confirmed vs unresolved

### Confirmed
- Unique direct near JMP into 509Eh: 5F62h.
- 509Eh is reached through 5C04h memory tests and 5F58h/5F5Bh setup calls.
- 5C04h is entered by the stack-crafted continuation at 5BF8h, reached from DA9Fh.
- No BP.13 producer exists on the audited successful path from DA9Fh through 5F62h.
- D9D9h wraps to 1AFBh; 1B05h is skipped stack data after the RET at EE94h and is not executable BP code.
- BP.13 must be inherited into the DAxx branch from an earlier context.

### Unresolved
- Runtime entry into the DAxx timing block and the BP value at that entry.
- First real producer of BP.13, or whether it is a preserved caller-supplied status bit.
- Whether the 21 linear indirect transfers include any runtime path into DAxx; no such target has yet been established.
