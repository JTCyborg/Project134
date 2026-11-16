# AMI486 semantic map — phase 81 (2026-11-16)

## 1. CMOS[B8h] writer/reader search

A raw scan of the 64 KiB ROM finds only two immediate `MOV AX,00B8h` instructions, both in the adjustment routine at 5D6Ah and 5D72h. The routine reads CMOS[B8h] into DI, then writes zero back to CMOS[B8h]. No other aligned immediate selector for B8h was found in the image.

This makes the old CMOS[B8h] byte a one-shot adjustment input in this POST path, but does not prove there are no indirect/register-indexed accesses to B8h.

## 2. CMOS[8Eh] is a shared status/configuration byte

The ROM contains multiple immediate CMOS[8Eh] reads through the common EE94h helper. Confirmed CALL sites include:

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

These sites all resolve to EE94h. The 5D78h caller tests bits C0h (bits 6 and 7) and conditionally skips the BEh:BFh adjustment. Other callers need separate path analysis; the byte is clearly shared, not a private flag for the 5D block.

Two apparent immediate 8Eh selectors at CC87h and CD8Bh, and one at F10Dh, resolve to EEAAh rather than EE94h. They must not be labelled reads without decoding the alternate helper entry and its exact operation.

## 3. Corrected POST status helper address

The call at 5D54h is:

```asm
5D50  MOV AL,25h
5D52  OUT 80h,AL
5D54  CALL F5DBh
5D57  MOV [0012h],AL
5D5A  TEST AL,20h
5D5C  JNZ 5D9Eh
```

The target is F5DBh, not E5DBh. The earlier report's E5DBh target was a hex-address arithmetic typo. F5DBh begins with `TEST AL,01h` and then a conditional keyboard-controller status/data path using ports 64h/60h (the preceding byte F5D9h is `IN AL,64h`). This path returns a status/data byte in AL; the caller stores it at DS:0012h and tests bit 5.

Do not yet assign a hardware meaning to bit 5 without tracing the full caller and the possible return paths through F5DBh.

## 4. Corrections and limits

- CMOS[B8h] has one clearly decoded immediate read/write pair in the ROM, at 5D6Dh/5D75h.
- CMOS[8Eh] has many readers and is a shared byte.
- The 5D54h helper target is F5DBh, not E5DBh.
- CMOS[BEh:BFh] still has at least two distinct writers: the checksum sum writer at 17F0h/1810h and the conditional adjustment at 5D8Fh..5D99h. The adjustment reads its old value through EE94h, subtracts CMOS[B8h]'s saved byte, and writes it back.
- BP.13 provenance and dynamic entry into DA5Eh/DA61h remain unresolved.

## 5. Next steps

- Trace the other CMOS[8Eh] readers, especially 121Ah, 1271h, 1338h, 140Eh and 1C64h, to label the individual bits.
- Trace all indirect CMOS index paths to rule out additional B8h readers/writers.
- Establish ordering between checksum refresh and BEh:BFh adjustment.
- Continue BP.13 and DA5Eh/DA61h control-flow reconstruction.
