# AMI486 semantic map — phase 65 (2026-11-16)

## Scope
Reconstructed the known reset/POST path from the D9D9 branch through the stack-crafted helper chain, and checked the ROM bytes for static pointers into the DAxx timing routine.

## 1. D9D9 is a hard branch around D9DCh

~~~asm
D9D5  mov al,13h
D9D7  out 80h,al
D9D9  jmp 1AFBh
D9DC  mov al,14h       ; linear next bytes, not fall-through
~~~

The unconditional near jump makes D9DCh unreachable by fall-through from D9D9. The destination calculation wraps 16-bit IP and lands at 1AFBh.

## 2. Actual continuation after the jump is stack-crafted

~~~asm
1AFB  mov al,B3h
1AFE  mov sp,1B04h
1B01  jmp EE94h
1B04  db 06h,1Bh       ; return IP = 1B06h
1B06  ...              ; CMOS/POST setup
1B58  jmp 208Dh
208D  mov ax,C503h
2090  mov sp,2096h
2093  jmp 8DDCh
2096  db 98h,20h       ; return IP = 2098h
2098  ...              ; extended-memory probing
~~~

The apparent instruction at 1B05h is the high byte of the crafted return address and must not be decoded as executable SBB BP,[...].

The same mechanism appears again at 20C6h/20D2h:
- 20C6h sets SP=20CCh and jumps to F66Ah; the helper returns to 20CCh.
- 20D2h sets SP=20D8h and jumps to EEEFh; the helper returns to 20D8h, whose word 20DAh is the next instruction address.

## 3. This path enters a temporary protected-mode memory probe

The executed sequence starts at 20DAh (not 20D8h):

~~~asm
20DA  mov eax,cr0
20DD  or al,1
20DF  mov cr0,eax
20E3  lgdt cs:[2068h]
...
23BD  mov eax,cr0
23C0  and al,0FEh
23C2  mov cr0,eax
23C5  jmp 23C7h
~~~

The code performs 32-bit memory tests at low and extended addresses, records the tested memory boundary in registers, and clears CR0.PE again at 23BDh. This is a temporary protected-mode memory probe embedded in the reset/POST path.

The later 23DEh MOV BP,3 is on the memory-probe error branch and transfers to the fatal handler F4A5h. It is not evidence of BP.13 on the normal path.

## 4. DAxx entry search: static references

A full decoded-instruction scan found no direct near CALL/JMP into DA00h–DA9Fh. A raw 64-KiB ROM scan also found no literal pointer words for the plausible entry addresses D9DCh, D9E0h, DA46h, DA56h, DA5Eh, or DA61h. The one raw occurrence of 9FDAh is the displacement bytes of an unrelated near JMP at B3DFh, not a pointer to DA9Fh.

The DAxx routine itself contains its own stack continuation:
- DA5Eh sets SP=DA64h and jumps to F598h.
- F598h returns into DA66h, after which the PIT/port-61 timing sample runs.
- DA95h sets BP=1 only on the configured fatal timing-error branch.
- DA9Fh jumps to 5BF8h on the normal continuation.

No proven in-ROM static edge to DA5Eh/DA61h was found in this pass. Possible runtime vector/table setup or an alternate entry outside the reset path remains open.

## 5. Consequence for BP.13

The main reset/POST path D9D9 → 1AFB → 1B06 → 1B58 → 208D → 2098 → 20DA → 23BD does not provide a normal-path BP.13 set. The only BP assignment seen in the later memory probe is MOV BP,3 at 23DEh, an error-only branch.

Thus the BP.13 producer sought on the 5Cxx/509Eh route remains outside this established reset-path chain, or is supplied dynamically through a path not represented by direct static references.

## Confirmed vs unresolved

### Confirmed
- D9D9 unconditionally branches to 1AFBh; D9DCh is not fall-through.
- 1AFBh returns to 1B06h via the crafted stack word at 1B04h.
- 1B58h transfers to 208Dh; crafted returns resume at 2098h, 20CCh, and 20DAh.
- 20DAh starts a temporary CR0.PE memory probe; CR0.PE is cleared at 23BDh.
- 23DEh MOV BP,3 is an error-only branch.
- No direct decoded CALL/JMP or static pointer word to the plausible DAxx entries was found in the scanned ROM.

### Unresolved
- The runtime entry that activates DA5Eh/DA61h.
- Whether DAxx is an alternate/legacy POST path, entered through runtime vector setup or another dynamic transfer.
- The source of inherited BP.13 before the 5Cxx/509Eh flow.
