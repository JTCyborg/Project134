# AMI486 — CMOS configuration bytes copied into chipset indexed registers

Date: 2026-11-17  
Repository: `JTCyborg/Project134`, branch `main`  
Input: `ami486.bin`, 65,536 bytes.

## 1. CMOS read helper

At `EE94` the BIOS has a direct CMOS read primitive:

```
EE94: E6 70       OUT 70h,AL
EE96: E3 00       JCXZ $+2
EE98: E3 00       JCXZ $+2
EE9A: E4 71       IN  AL,71h
EE9C: C3          RET
```

The caller places the CMOS index in AL. The helper selects that index through port 70h and returns the data byte from port 71h in AL.

At `EE9D` a corresponding write primitive exists:
- `OUT 70h,AL` selects the CMOS index;
- `XCHG AH,AL` moves the data byte into AL;
- `OUT 71h,AL` writes it;
- `XCHG AH,AL` restores the register pair.

A wrapper at `EEB9` surrounds CMOS writes with interrupt/NMI-state handling and restores the prior flags. This is distinct from the chipset indexed interface at ports 22h/23h.

## 2. Direct CMOS-to-chipset read/modify/write mappings

The initialization sequence at `1C9D–1DBB` reads CMOS bytes using the `EE94` helper, then merges selected bits into chipset configuration registers using the indexed read/write helpers at `8DCF` and `8DDC`.

The confirmed mappings are:

| CMOS source | Source mask | Chipset index | Preserved chipset mask | Result |
|---:|---:|---:|---:|---|
| `47h` | `83h` | `17h` | `7Ch` | source bits 7,1,0 copied |
| `42h` | `E0h` | `12h` | `1Fh` | source bits 7..5 copied |
| `44h` | `A0h` | `14h` | `5Fh` | source bits 7 and 5 copied |
| `47h` | `7Ch` | `17h` | `83h` | source bits 6..2 copied |
| `4Eh` | `0Ch` | `1Eh` | `F3h` | source bits 3..2 copied |
| `4Ah` | `30h` | `1Ah` | `CFh` | source bits 5..4 copied |
| `50h` | `F0h` | `20h` | `0Fh` | source bits 7..4 copied |
| `51h` | `48h` | `21h` | `B7h` | source bits 6 and 3 copied |
| `52h` | `F7h` | `22h` | `08h` | all bits except bit 3 copied |
| `55h` | `CFh` | `25h` | `30h` | bits 7,6,3..0 copied |
| `57h` | `01h` | `27h` | `FEh` | bit 0 copied |
| `57h` | `30h` | `27h` | `CFh` | bits 5..4 copied |

The two writes to chipset register `17h` use complementary source/preserve masks. Together they copy all eight bits of CMOS byte `47h` into chipset register `17h` (first bits 7,1,0, then bits 6..2).

For the remaining rows, the masks prove exactly which bits are copied and which existing chipset bits are retained. They do not yet identify the feature names represented by those bits.

## 3. Representative exact sequence: CMOS 47h → chipset 17h

```
1C9D: B0 47          MOV AL,47h
1C9F: E8 F2 D1       CALL EE94h       ; read CMOS[47h]
1CA2: 24 83          AND AL,83h
1CA4: 8A D8          MOV BL,AL
1CA6: B8 17 17       MOV AX,1717h
1CA9: E8 23 71       CALL 8DCFh       ; read chipset[17h]
1CAC: 24 7C          AND AL,7Ch
1CAE: 0A C3          OR AL,BL
1CB0: 86 E0          XCHG AH,AL
1CB2: E8 27 71       CALL 8DDCh       ; write chipset[17h]
```

A second sequence shortly afterward reads CMOS[47h] again, masks with `7Ch`, and merges it into chipset register `17h` while preserving `83h`. This completes the full-byte transfer.

## 4. Consequence for the E0xx Setup shadow investigation

This is a distinct configuration-restore path: it copies persistent CMOS settings into chipset configuration registers. The path is not simply “E0xx shadow → hardware”; the BIOS also has a CMOS-backed initialization stage that programs chipset registers directly.

Therefore, the working model now has at least three layers:
1. CMOS persistent configuration bytes (ports 70h/71h).
2. Chipset indexed configuration registers (ports 22h/23h).
3. Setup UI shadow state and option handlers (RAM E0xx), which may read, edit, or later commit settings.

The relationship between each E0xx shadow field and the CMOS byte/register bitfields remains to be traced rather than assumed.

## 5. Limits and next steps

- The raw index/mask mappings above are directly supported by the instruction stream.
- No semantic names are assigned to chipset registers 12h–27h.
- Some neighboring operations use the CMOS write wrapper at EE90/EEB9; those must be analyzed separately from the direct CMOS read sequences.
- Next, identify the callers/entry path of the restore sequence and compare it with Setup handlers to determine whether the UI edits these same CMOS bytes or only an intermediate RAM copy.
