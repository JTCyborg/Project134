# AMI486 semantic map — phase 81 (corrected, 2026-11-16)

## 1. CMOS[B8h] selector

A raw scan of the 64 KiB ROM finds only one immediate `MOV AX,00B8h` read/write pair, in the routine at 5D6Ah and 5D72h. The first call reads CMOS[B8h] into AX and copies it to DI; the second writes zero to CMOS[B8h]. This establishes a one-shot use in this POST path, but does not exclude indirect/register-indexed accesses elsewhere.

## 2. CMOS[8Eh] is shared

Immediate CMOS[8Eh] reads through EE94h are found at these selector/call pairs:

- 121Ah
- 1271h
- 1338h
- 140Eh
- 15ACh
- 1C64h
- 5D78h
- 5EDFh
- 84D3h
- 8630h
- 8649h
- 8662h
- F481h

Each sequence selects index 8Eh and calls EE94h. The 5D78h caller tests mask C0h and skips the BEh:BFh adjustment if either bit 6 or bit 7 is set. Other callers need separate control-flow analysis; 8Eh is a shared status/configuration byte, not a private flag for the 5D block.

The similar byte patterns at CC87h and CD8Bh, and at F10Dh, resolve to EEAAh rather than EE94h. They are not yet classified as CMOS reads; the alternate EEAAh entry must be decoded separately.

## 3. Corrected keyboard-controller status call

The actual caller bytes are:

```asm
5D4E  MOV AL,25h
5D50  OUT 80h,AL
5D52  CALL F5D9h
5D55  MOV [0012h],AL
5D58  TEST AL,20h
5D5A  JNZ 5D9Ch
```

The CALL displacement at 5D52h resolves to F5D9h, not F5DBh. F5D9h begins with `IN AL,64h`; the following code tests status bit 0 and conditionally reads port 60h. The caller stores the returned AL at DS:0012h and tests bit 5. The exact hardware meaning of the returned bit 5 is not established yet.

## 4. BEh:BFh and unresolved work

CMOS[BEh:BFh] has at least two distinct writers: the range-sum write-back path at 17F0h/1810h and the conditional subtraction path at 5D81h..5D99h. Its global semantic role and the ordering of those writers remain open.

Still unresolved:
- indirect CMOS accesses that may also use B8h or 8Eh;
- individual bit meanings for the other 8Eh readers;
- readers and update ordering for BEh:BFh;
- producer of BP.13;
- dynamic/indirect entry into DA5Eh/DA61h.
