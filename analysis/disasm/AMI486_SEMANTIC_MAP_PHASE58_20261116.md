# AMI486 semantic map — phase 58 (2026-11-16)

## Scope

Trace the BP bitmap consumer at 1662h backwards through its actual caller, identify the POST entry path, and establish exactly where the bit-13 value is preserved and discarded.

## 1. 1662h is reached by ordinary fall-through inside helper 1656h

The caller at 120Dh executes `CALL 1656h`. Routine 1656h is not a tiny wrapper ending at 165Fh; after its two helper calls it falls directly into the BP bitmap loop:

```asm
120D  call 1656
...
1656  call F571
1659  mov cx,2000h
165C  call E93C
165F  call F571
1662  push bp
1663  mov cx,10h
1666  lodsw
1668  ror bp,1
166A  jae 1673
166C  push si
166D  mov si,ax
166F  call 16C0
1672  pop si
1673  loop 1666
1675  pop bp
1676  test bx,bp
...
16B6  ret
```

The 16-iteration ROR loop consumes the incoming BP bitmap. BP is restored at 1675h, then tested against BX at 1676h. The helper eventually returns at 16B6h.

## 2. The actual producer window is the early POST sequence 10E0h–120Dh

The entry into this POST sequence is a real near jump at E3ACh:
- E394h disables interrupts and sets BX=0870h.
- E398h calls EEE7h, which programs PIC ports using AL/BL/BH and does not write BP.
- E39Bh–E3ABh sets the PIC masks and reenables interrupts.
- E3ACh executes `JMP 10E0h` (the linear decoder prints the wrapped target as 110E0h).

The entry bytes at 10E0h are not aligned with the linear disassembler's prior instruction boundary; the first instructions from the true entry are:
- 10E0h MOV AL,F4h
- 10E2h OUT 80h,AL
- 10E4h CALL 90B3h (RET stub)
- 10E7h onward selects the keyboard-controller initialization branch and continues into the 1100h–120Dh POST code.

The E343h helper F419h executes PUSHAW and checks a fixed byte sequence; it does not assign BP. The EEE7h PIC helper also does not assign BP. No BP initializer has been identified in the E300h–10E0h setup sequence. Thus BP enters the early POST path as inherited state from code preceding E3ACh.

## 3. Early POST modifies only selected low/mid bits before bitmap processing

The BP updates between the POST entry and the bitmap walk are:
- 113Bh OR BP,0200h (bit 9)
- 1141h OR BP,0400h (bit 10)
- 117Fh OR BP,0100h (bit 8)
- 11A1h / 11BCh OR BP,0800h (bit 11)
- 145Eh is outside the immediate path and sets bit 6 in the separate RTC failure branch.

At 11FDh the active path executes `AND BP,7FFFh`. This clears bit 15 only. It does not clear bit 13. At 1201h the code tests whether BP is zero; if nonzero, it reaches 120Dh and calls 1656h, which consumes all 16 BP bits.

Therefore BP.13 at 1668h is inherited from the state present at the POST entry (or a prior unlocated mutation before the entry), unless some unrecognized alternate path modifies it. The known early POST OR operations do not create bit 13.

## 4. The later POP BP / AND C000h is cleanup after the bitmap consumer, not evidence that BP.13 was cleared before it

The normal continuation after 120Dh returns through 1210h–12B7h. If the wait/helper path reaches the zero-CX branch at 12B7h, control goes to 12D3h:
- 12D3h POP BP restores the BP saved at 11DFh.
- 12D4h AND BP,C000h keeps only bits 14 and 15.

This occurs after the 1662h bitmap consumer on the path through 120Dh. The earlier Phase 56 interpretation must therefore be scoped carefully: 12D3h–12D4h clears bits 0–13 only in the restored outer BP value at this later cleanup point. It does not explain or preclude BP.13 being consumed at 1668h earlier in the same POST flow.

The push at 11DFh brackets the POST diagnostic processing; 12D3h restores the saved incoming status word after the diagnostic handling.

## 5. Consequence for BP.13

The source has now been narrowed from “somewhere before 5CF9h” to:

1. BP already contains bit 13 when execution enters the early POST block at 10E0h, or
2. an unrecognized alternate entry/preceding path modifies BP before 10E0h.

The known 10E0h–120Dh path does not set bit 13. It preserves it through `AND BP,7FFFh`, processes it in the 1662h–1675h bitmap loop, then eventually restores the outer saved BP and masks that restored value with C000h at 12D3h–12D4h.

This also establishes that the 1662h bitmap walker belongs to the early POST flow, not an unrelated disconnected routine.

## 6. Confirmed vs unresolved

### Confirmed
- 120Dh directly calls 1656h; 1656h falls through into 1662h.
- 1662h–1675h consumes the 16-bit BP bitmap and restores BP before the BX mask test.
- E3ACh jumps to the true POST entry at 10E0h; the apparent 110E0h target is 16-bit IP wrap.
- EEE7h programs the PIC and does not write BP.
- F419h preserves registers with PUSHAW and does not assign BP.
- The known early POST operations set only BP bits 8–11; 11FDh clears bit 15 but preserves bit 13.
- 12D3h–12D4h is later cleanup after the bitmap consumer on the 120Dh path.

### Unresolved
- The upstream code that supplies BP before the E3ACh → 10E0h transition.
- Whether BP.13 is deliberately preloaded by an earlier POST stage or is inherited from an even earlier caller/stack frame.
- The precise relationship between this early POST bitmap and the later DAxx/5Cxx test path; no direct edge is yet proven.
