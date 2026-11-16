# AMI486 semantic map — phase 64 (2026-11-16)

## Scope

Accelerated audit of all plausible BP producers before the 5Cxx/DAxx path. The pass isolates actual BP destination writes from ordinary [BP+disp] frame accesses and scans the early POST blocks that had been suspected as possible flag initializers.

## 1. Early POST flags at 1100h–12D4h

The 1100h block accumulates hardware/status flags in BP:

~~~asm
112F  mov al,81h
1133  mov ax,00ABh
1136  call F5BCh
1139  jne 1141
113B  or bp,0200h
1141  or bp,0400h
...
1179  in al,64h
117B  test al,10h
117D  jne 1183
117F  or bp,0100h
...
119B  cmp ax,[0013h]
119F  je 11A9
11A1  or bp,0800h
...
11B7  cmp ax,cx
11B9  pop ax
11BA  je 11C2
11BC  or bp,0800h
~~~

These set bits 9, 10, 8, and 11 only. No BP.13 producer appears in this block.

At 11DFh the current BP is saved. The subsequent mask operations clear selected status bits, then restore the saved value at 12D3h and immediately apply:

~~~asm
12D3  pop bp
12D4  and bp,0C000h
~~~

This explicitly clears BP.0–BP.13 on that path, retaining only bits14 and15. Therefore this particular POST path cannot carry BP.13 past 12D4h.

This is a path-specific conclusion, not a global statement about all callers of the later 5Cxx/DAxx code.

## 2. Other early BP writers

The complete decoded destination-write scan in the early executable region found:

- 145Eh: OR BP,0040h (bit6), on RTC validation failure.
- 157Ch: AND BP,FCFEh, clearing bits0 and8; 1580h AND BP,7FFFh, clearing bit15. The surrounding 1576h PUSH BP / 158Fh POP BP restores the original caller BP after the diagnostic check.
- 23DEh: MOV BP,3, on a separate failure/helper path; caller linkage to the DAxx route is not established.
- 27D0h: OR BP,4000h (bit14), on a memory-test failure branch.
- 2913h: XOR BP,BP, then BP counts successfully scanned 16-KiB memory segments. At 2937h it is copied to BX and BP is replaced with SP. This is a memory-size calculation, not a source of BP.13.

The 11xx and 1576h blocks therefore do not explain BP.13.

## 3. D6C4h is a stack/register self-test, not the DAxx caller

The unusual sequence at D6C4h is:

~~~asm
D6C4  mov bx,ax
D6C6  mov cx,bx
D6C8  mov dx,cx
D6CA  mov si,dx
D6CC  mov di,si
D6CE  mov bp,di
D6D0  mov es,bp
D6D2  mov ax,es
D6D4  mov ds,ax
D6D6  mov ax,ds
D6D8  mov ss,ax
D6DA  mov ax,ss
D6DC  jmp sp
~~~

Its only direct entries are the deliberately constructed stack-test continuations at D6FAh and D707h. It copies the test value from AX through the general registers into BP and then into segment registers, finally jumping through SP. This is a register/stack integrity test, not evidence of an incoming edge to DAxx or 509Eh.

Although this instruction can place arbitrary bits into BP, no control-flow edge from this test to the DAxx timing path has been established.

## 4. Important negative result: no simple immediate BP.13 producer

Across the inspected early POST and memory-sizing paths, there is no immediate operation equivalent to OR BP,2000h or MOV BP,2000h on the normal route. The known bit accumulators stop at bit11; bit14 is set by the memory test; bit15 is separately tested/cleared.

The remaining realistic possibilities are:
1. BP.13 is inherited from a caller that supplies a composite status word.
2. A non-immediate load such as MOV BP,DI / POP BP / XCHG BP,AX carries the bit in from a runtime value.
3. The DAxx/5Cxx path is entered from a path not represented by the assumed early-POST linear fall-through.

## 5. Confirmed vs unresolved

### Confirmed
- 1100h–11C2h accumulates BP bits9,10,8,11 only.
- 12D3h–12D4h clears BP bits0–13 on that specific path.
- 145Eh sets bit6 only.
- 157Ch/1580h clear bits0,8,15 inside a saved-BP diagnostic frame; the caller's BP is restored.
- 27D0h sets bit14 only on its failure branch.
- 2913h resets BP and uses it as a memory-segment counter.
- D6CEh copies the register-test value into BP inside a stack self-test; no link to DAxx is proven.

### Unresolved
- Which runtime entry reaches DAxx.
- Whether BP.13 is supplied as a caller status bit or loaded from a dynamic register/memory value.
- The first executed instruction that creates BP.13 on the path ending at 5CF9h/509Eh.
