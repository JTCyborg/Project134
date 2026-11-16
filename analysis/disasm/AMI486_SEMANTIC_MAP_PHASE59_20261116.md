# AMI486 semantic map — phase 59 (2026-11-16)

## Scope

Trace the protected-mode return path upstream of D604h and determine whether it can be connected to the E3xx POST route and the BP bitmap consumer.

## 1. Correction to the previous reset-vector interpretation

The hardware reset vector is **not** at file offset E000h. The raw image bytes at offset FFF0h are:

```
EA 5B E0 00 F0
```

They encode `LJMP F000:E05B`. The actual reset path is:

```asm
FFFF0  ljmp F000:E05B
F000:E05B  jmp D604
```

The separate code at E000h begins with `LJMP F000:E005`; E005h jumps to F73Bh. This is an alternate ROM entry, not the hardware reset vector. F73Ch copies SP into BP as a stack-frame pointer, but no edge has been established from this entry to the later BP bitmap route.

## 2. Protected-mode exit reaches D604h

At F090h–F096h, the BIOS loads the IDT and executes a near jump to E05Bh. E05Bh is an alternate instruction boundary in the linear listing; its actual bytes decode as `JMP D604h`.

## 3. D604h dispatches on the 8042 SYS bit

```asm
D604  cli
D605  cld
D606  in al,64h
D608  test al,04h
D60A  jne D612
D60C  jmp 88CE
D612  jmp 8A04
```

The SYS-clear branch goes to 88CEh; SYS-set goes to 8A04h. The latter reads and clears CMOS8Fh before dispatching the saved selector.

## 4. BP writes on the D724h path

The D724h branch includes:

```asm
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
```

This explicitly clears BP on that branch. The subsequent D74Ch path can set BP.12 and BP.15 according to port64 and the warm-boot signature, but does not set BP.13.

This path is not proven to connect to E2C6h/E3xx or the BP frame at 525Fh.

## 5. Relationship to the E3xx → early POST bitmap path

The local E3ACh→10E0h→120Dh→1656h→1662h chain is confirmed. Phase 60 identifies the upstream edge into the E3xx route as 52C1h→E2C6h and traces the BP value to the frame saved at 525Fh and restored at 5289h.

The hardware reset/protected-mode path through D604h remains a separate branch unless a concrete selector, indirect jump, far transfer, or stack-crafted continuation is found connecting it to the 52C1h route.

## 6. Confirmed vs unresolved

### Confirmed
- Hardware reset vector at FFF0h is `LJMP F000:E05B`; E05Bh jumps to D604h.
- F096h also jumps to E05Bh.
- E000h→E005h→F73Bh is a separate code entry, not the hardware reset vector.
- D604h checks port64 bit2 and branches to 88CEh or 8A04h.
- D724h explicitly clears BP at D743h; D74Ch may set BP.12 and BP.15, not BP.13.
- The E3xx route reaches the early POST bitmap consumer, but its relationship to the D604h reset dispatcher remains unproven.

### Unresolved
- Which D604h selector/branch, if any, eventually transfers control to the E2C6h/E3xx route.
- The upstream caller that supplies BP at 5194h.
- The producer of BP.13.
