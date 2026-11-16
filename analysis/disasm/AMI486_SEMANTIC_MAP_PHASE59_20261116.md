# AMI486 semantic map — phase 59 (2026-11-16)

## Scope

Trace the reset/protected-mode return path upstream of D604h and check whether it can be proven to initialize BP before the POST path that later reaches the BP bitmap consumer.

## 1. Reset vector and first startup trampoline

The ROM begins with:
    E000  ljmp F000:E005
    E005  jmp F73B

At F73Bh:
    F73B  cli
    F73C  mov bp,sp
    F73E  mov ax,cs
    F740  cmp ax,[bp+2]
    F743  jne F752
    F745  mov ax,F7AF
    F748  cmp ax,[bp]
    F74B  jne F752
    F74D  add sp,6
    F750  jmp F7B2
    F752  mov si,7B15
    F755  jmp F509

The matching-return path removes six bytes from the stack and continues at F7B2. The alternate path goes to the error/message routine F509. F73Ch sets BP to SP, but this is a stack-frame pointer, not a status-bitmap initializer. The subsequent return path and callers must be traced before treating that BP value as the BP consumed at 1662h.

## 2. Protected-mode exit reaches D604h

The relevant code at F090h–F096h:
    F090  lidt cs:[E2B8]
    F096  jmp E05B

At E05Bh the actual instruction is a near jump:
    E05B  jmp D604

The linear listing displays the raw bytes around E05Bh as data because the code stream is not aligned with the linear decode there. This is a confirmed alternate entry into D604h, in addition to the already documented 5D04h entry.

## 3. D604h dispatches on the 8042 SYS bit

    D604  cli
    D605  cld
    D606  in al,64h
    D608  test al,04h
    D60A  jne D612
    D60C  jmp 88CE
    D612  jmp 8A04

Thus reset/protected-mode return enters the same D604h dispatcher already analyzed in earlier phases. The SYS-clear branch goes to 88CEh; SYS-set goes to 8A04h.

On the 8A04h/CMOS8F path, BIOS reads CMOS8F, clears it, and dispatches the saved selector. The known table includes:
- selector 7 → 1B5Bh → D724h
- selector 8 → 8A1Dh → D724h
- selector 9 → 9206h
- selector 10 → F737h (indirect far jump through [0067h])

## 4. BP writes on the D724h path

The D724h branch has:
    D724  test byte ptr cs:[8281],40h
    ...
    D73B  mov al,3
    D73D  out 80h,al
    D73F  mov ax,cs
    D741  mov ss,ax
    D743  xor bp,bp
    D745  mov ds,bp
    D747  mov es,bp
    D749  jmp 8A75

This is a real explicit BP initializer, but only for the D724h path. The following D74Ch code may OR BP.12 and BP.15 according to the 8042 SYS bit and BDA warm-boot signature. It does not set BP.13.

Therefore, for selector 7/8 (and any other path proven to pass through D724h), BP is cleared before the D74Ch status accumulation. This is not yet evidence that the path reaches 10E0h/1662h; no direct control-flow edge from D74Ch to E3xx/10E0h has been established.

## 5. Relationship to the 10E0h → 1662h bitmap path

The previously established local chain remains valid:
- E380h → E394h (stack-crafted return from FA4Eh)
- E3ACh → 10E0h
- 10E0h–120Dh modifies BP bits 8–11, clears bit15 at 11FDh, and calls 1656h
- 1656h falls through into the 1662h–1675h 16-bit BP bitmap walker.

However, the upstream connection between D604h's reset dispatch and E380h/E3ACh is still not proven. The reset entry at E000h leads to F73Bh, while the protected-mode return at F096h leads to E05Bh→D604h. Do not merge these separate branches into a single linear startup path without identifying the missing indirect/far/stack transfer.

## 6. Confirmed vs unresolved

### Confirmed
- Reset vector E000h far-jumps to F000:E005; E005h jumps to F73Bh.
- F73Ch copies SP into BP as a stack-frame pointer; it is not a bitmap constant.
- F096h jumps to E05Bh; E05Bh jumps to D604h.
- D604h branches on port64 bit2 to 88CEh or 8A04h.
- D724h explicitly clears BP at D743h; D74Ch can subsequently set BP.12 and BP.15, but not BP.13.
- The local E3ACh→10E0h→120Dh→1656h→1662h chain remains verified.

### Unresolved
- Which D604h selector/branch, if any, eventually transfers control to E380h/E3ACh.
- Whether the BP bitmap consumed at 1662h comes from the D724h path, an alternate selector, or a separate stack-restored context.
- The actual upstream producer of BP.13. The D724h path clears BP and therefore cannot itself supply a pre-set bit13 unless a later unlocated operation sets it.
