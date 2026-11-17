# AMI486 — chipset indexed I/O discovered at ports 22h/23h

Date: 2026-11-17  
Repository: `JTCyborg/Project134`, branch `main`  
Input: `ami486.bin`, 65,536 bytes (blob SHA `480c7520c93e6c7ed437cf3ad214da7503f82ec6`).

## 1. A real indexed-register interface is present

The code at `8DCF–8DEC` implements two small helpers:

```
8DCF: E6 22       OUT 22h,AL
8DD1: E3 00       JCXZ $+2
8DD3: E3 00       JCXZ $+2
8DD5: E4 23       IN  AL,23h
8DD7: E3 00
8DD9: E3 00
8DDB: C3          RET

8DDC: E6 22       OUT 22h,AL
8DDE: E3 00
8DE0: E3 00
8DE2: 86 C4       XCHG AH,AL
8DE4: E6 23       OUT 23h,AL
8DE6: E3 00
8DE8: E3 00
8DEA: 86 C4
8DEB: C3          RET
```

The first helper at `8DCF` writes the index to port `22h`, then reads the selected byte from `23h`. The second helper at `8DDC` writes the index from AL to `22h`, exchanges AL/AH, writes the data byte to `23h`, exchanges back, and returns. Thus the caller convention for the write helper is `AL=index, AH=data`.

This is an indexed configuration-register interface. It is distinct from the previously documented PIT ports 42h/43h and speaker port 61h. The port pair is consistent with legacy motherboard chipset configuration access, but this report does not assign a specific chipset vendor/model or register names.

## 2. Confirmed read-modify-write callers

The sequence around `1C88–1DBB` repeatedly:
1. loads the same register index into AX (e.g. `2020h`);
2. calls the read helper at `8DCF`;
3. masks the returned register value and merges bits from BL;
4. exchanges AL/AH to form `AL=index, AH=new data`;
5. calls the write helper at `8DDC`.

Example for register index `20h`:

```
1C8E: B8 20 20       MOV AX,2020h
1C91: E8 3B 71       CALL 8DCFh       ; read config[20h]
1C94: 24 F8          AND AL,F8h
1C96: 0A C3          OR  AL,BL
1C98: 86 E0          XCHG AH,AL
1C9A: E8 3F 71       CALL 8DDCh       ; write config[20h]
```

This is direct evidence of a chipset configuration read-modify-write operation. The low three bits are replaced with the value in BL; the upper five bits are preserved.

## 3. Register indices and masks observed in the setup sequence

The following sequence is decoded directly from the RMW blocks in `1C50–1DBB`. “Mask” is the immediate AND mask applied to the value read from port 23h; the subsequent OR operand is the newly prepared value (usually in BL).

| Config index | AND mask | Meaning proven by code |
|---:|---:|---|
| `13h` | `C1h` | preserve bits 7,6,0; replace the other bits from prepared value |
| `20h` | `F8h` | preserve upper five bits; replace low three bits |
| `17h` | `7Ch` | preserve bits 6..2; replace bits 7,1,0 according to prepared value |
| `12h` | `1Fh` | preserve low five bits; replace upper three bits |
| `14h` | `5Fh` | preserve bits 6,4..0; replace bits 7 and 5 |
| `17h` | `83h` | second update to register 17h, preserving bits 7 and 1..0 |
| `1Eh` | `F3h` | preserve bits 7..4 and 1..0; replace bits 3..2 |
| `1Ah` | `CFh` | preserve bits 7..6 and 3..0; replace bits 5..4 |
| `20h` | `0Fh` | second update to register 20h, preserving low nibble |
| `21h` | `B7h` | preserve bits 7,5..4,2..0; replace bits 6 and 3 |
| `22h` | `08h` | preserve bit 3; replace all other bits |
| `25h` | `30h` | preserve bits 5..4; replace all other bits |
| `27h` | `FEh` | preserve bits 7..1; replace bit 0 |
| `27h` | `CFh` | second update to register 27h, preserving bits 7..6 and 3..0 |

These masks are not semantic bit names. They document only which bits the code preserves/replaces. In several cases the value merged into the register is computed by preceding helpers and must be traced to the source setting before naming the feature.

## 4. Why this is the hardware path we were looking for

The Setup shadow handlers in `2Axx–2Dxx` manipulate software state in `E0xx`. The indexed I/O helpers at `8DD0/8DDD` provide the hardware-facing access mechanism. The sequence at `1C50–1DBB` is an actual group of configuration-register updates through ports `22h/23h`.

This is the first positively identified chipset-style I/O path in the current investigation. It is separate from:
- PIT channel 2 / control port 43h;
- PC speaker/system-control port 61h;
- keyboard controller ports 60h/64h;
- video/CRT controller I/O.

## 5. Important limitation: no ALi1429 naming yet

Although ports 22h/23h are commonly used as chipset configuration index/data ports on legacy x86 motherboards, the ROM bytes alone do not prove that this BIOS targets ALi1429 specifically. Register indices `12h`, `13h`, `14h`, `17h`, `1Ah`, `1Eh`, `20h`–`27h` are therefore kept as raw chipset-config indices.

To map these to ALi1429 functions, next trace:
- where BL is prepared before each RMW block;
- which Setup shadow values or board-detection flags feed those calculations;
- whether the same indices are read during chipset detection and revision checks;
- any chipset ID/signature checks preceding the sequence.

## 6. Next steps

1. Follow each helper that prepares BL immediately before the RMW writes and map it back to the relevant E0xx field or board strap.
2. Trace initialization entry/callers for the `1C50–1DBB` block.
3. Identify the chipset detection signature and supported revisions in the code around `8C80–8D00` and the early startup path.
4. Compare the discovered raw register/mask sequence with primary ALi1429 documentation only after the BIOS-side behavior is fully established.
