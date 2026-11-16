# AMI486 semantic map — phase 74 (2026-11-16)

## 1. CMOS helper family around EE94h

The aligned bytes show three distinct helpers:

```asm
EE94  OUT 70h,AL
EE96  JCXZ EE98h       ; zero-displacement no-op
EE98  JCXZ EE9Ah       ; zero-displacement no-op
EE9A  IN AL,71h
EE9C  RET

EE9D  OUT 70h,AL
EE9F  XCHG AH,AL
EEA1  JCXZ EEA3h       ; zero-displacement no-op
EEA3  JCXZ EEA5h       ; zero-displacement no-op
EEA5  OUT 71h,AL
EEA7  XCHG AH,AL
EEA9  RET
```

EE94h is a CMOS read primitive: AL supplies the index, AL receives the data byte. EE9Dh is the write primitive: AL supplies the index and AH supplies the data byte; the XCHG pair preserves the caller's AX while moving AH into AL for OUT 71h.

The zero-displacement JCXZ instructions do not branch away; they encode short timing gaps.

## 2. CMOS B6h flag read and four consumers

29EDh is exactly:

```asm
29ED  MOV AX,B6B6h
29F0  CALL EE94h
29F3  TEST AL,01h
29F5  RET
```

This selects CMOS/NVRAM index B6h, reads its byte, and returns its bit 0 as ZF (ZF=1 when clear, ZF=0 when set).

Four direct callers were verified:

| Call site | Immediate branch | Consequence when bit 0 is set |
|---|---|---|
| 1A1Dh | JZ 1A5Eh | continues through the conditional initialization block beginning 1A24h |
| 1C72h | JZ 1C80h | executes calls to 8F12h, 2537h and 256Ah |
| 1F4Dh | JZ 1F5Eh | executes calls to 8F12h, 2588h and 25A6h |
| 23F2h | JZ 23FDh | executes calls to 8F12h and 2537h |

The same persistent CMOS bit gates multiple setup/initialization paths, rather than being a one-off test local to the RAM diagnostic. This supports treating B6h.0 as a board/firmware configuration flag. Its human-readable meaning is not yet known.

## 3. Write-side search

EE9Dh is the corresponding CMOS write helper. A full raw-byte scan found many CALL EE9Dh sites, but no direct immediate load of B6h adjacent to those call sites. The only unambiguous immediate B6h selector found in the image is the MOV AX,B6B6h in 29EDh itself.

This does not prove that B6h is never written: callers may supply an index through a register or memory value. The next search must follow the EE9Dh call sites' AX provenance and check direct OUT 70h/71h sites.

## 4. Other CMOS accesses discovered

The raw scan also found direct OUT 70h/71h sequences outside the EE94h/EE9Dh helpers (including offsets 13F8h, 17FAh, 1818h, 5E29h, 8351h, 836Ah, 8A0Dh, 8A15h, 8B1Bh, 910Dh, 912Dh, 9196h, 91C4h, 9216h, D617h, D627h, D710h, E98Dh, E99Eh and F544h). These are candidates for direct CMOS/NVRAM handling and should be decoded at instruction boundaries before assigning register meanings.

## 5. Remaining unresolved items

- The purpose/name of CMOS B6h.0 is still unknown.
- No writer of B6h has yet been proven.
- CMOS B6h.0's four consumers are mapped, but the higher-level configuration branches still need semantic labels.
- BP.13 provenance and dynamic entry into DA5Eh/DA61h remain separate unresolved targets.
