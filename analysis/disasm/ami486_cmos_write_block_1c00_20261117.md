# AMI486 — CMOS write path and gated save block at 1C06

Date: 2026-11-17  
Repository: `JTCyborg/Project134`, branch `main`  
Input: `ami486.bin`, 65,536 bytes.

## 1. CMOS byte-write primitive

The helper at `EE9D` is a direct CMOS indexed write:

```
EE9D: E6 70       OUT 70h,AL       ; select CMOS index
EE9F: 86 C4       XCHG AH,AL       ; move data byte into AL
EEA1: E3 00       JCXZ $+2
EEA3: E3 00       JCXZ $+2
EEA5: E6 71       OUT 71h,AL       ; write CMOS data
EEA7: 86 C4       XCHG AH,AL
EEA9: C3          RET
```

Caller convention is `AL=index, AH=data`. This is the counterpart to the read primitive at `EE94` (AL=index, return AL=data).

## 2. Gated write block at 1C06

The routine begins at `1C06` (not `1C00`). The bytes at `1C00` belong to the displacement of a conditional branch from the preceding routine. At `1C01` there is a separate `CALL 2415h; RET; RET` stub. The routine at `1C06` first calls the optional callback in `CS:[82DE]`, then tests bit `40h` in `CS:[8280]`. If that bit is clear, it skips the CMOS writes and continues at `1C44`.

When the bit is set, the following writes are performed:

| Call site | Index (AL) | Data (AH) | Proven source |
|---|---:|---:|---|
| `1C1C` | `95h` | `DS:[0013]` | `MOV AH,[0013]` immediately before |
| `1C25` | `96h` | `DS:[0014]` | `MOV AH,[0014]` immediately before |
| `1C2B` | `B0h` | `97h` | `MOV AX,97B0h` |
| `1C30` | `97h` | `B0h` | `XCHG AH,AL` then second write |
| `1C36` | `B1h` | `98h` | `MOV AX,98B1h` |
| `1C3B` | `98h` | `B1h` | `XCHG AH,AL` then second write |

The exact instruction sequence, with corrected offsets, is:

```
1C16: 8A 26 13 00    MOV AH,[0013]
1C1A: B0 95          MOV AL,95h
1C1C: E8 7E D2       CALL EE9Dh

1C1F: 8A 26 14 00    MOV AH,[0014]
1C23: B0 96          MOV AL,96h
1C25: E8 75 D2       CALL EE9Dh

1C28: B8 B0 97       MOV AX,97B0h
1C2B: E8 66 D2       CALL EE9Dh
1C2E: 86 C4           XCHG AH,AL
1C30: E8 6A D2       CALL EE9Dh

1C33: B8 B1 98       MOV AX,98B1h
1C36: E8 5B D2       CALL EE9Dh
1C39: 86 C4           XCHG AH,AL
1C3B: E8 5F D2       CALL EE9Dh
```

The paired writes create reciprocal marker bytes:
- CMOS[B0h] = 97h and CMOS[97h] = B0h;
- CMOS[B1h] = 98h and CMOS[98h] = B1h.

Do not infer the purpose of these markers yet; their reciprocal pattern is confirmed, but the validation/read path that consumes them has not been traced.

## 3. Follow-on work after CMOS writes

After the six writes, the routine calls additional helpers at `1C3E`, `1C41`, `1C44`, and `1C47`, then stores AX to `DS:[00E6]` at `1C4A`. Their exact effects remain to be decoded.

## 4. Relation to chipset restore sequence

The earlier sequence at `1C80–1DBB` reads CMOS configuration bytes via `EE94` and copies masked fields into chipset registers via ports `22h/23h`. The gated block at `1C00` is a separate CMOS write path, guarded by `CS:[8280]&40h`.

This establishes that the BIOS both:
- restores chipset indexed-register fields from persistent CMOS values; and
- writes selected state/marker bytes back into CMOS under a mode flag.

It does not yet prove that the Setup UI's `E0xx` variables are the source of these six CMOS writes.

## 5. Next steps

1. Trace who sets `CS:[8280]&40h` and when the `1C00` routine is invoked.
2. Trace reads of CMOS `B0h/B1h/97h/98h` to identify the reciprocal markers' purpose.
3. Decode the helper calls after `1C3E` and the meaning of `DS:[0013]`, `DS:[0014]`.
4. Compare this save block with Setup handler writes and the CMOS-to-chipset restore block; only then connect E0xx fields to persistent settings.


## 6. Cross-reference audit of the 8280h flag byte

A full scan of direct 16-bit offset references to `CS:[8280]` in the 64 KiB ROM found tests of bits `80h`, `40h`, `20h`, `10h`, `08h`, `04h`, `02h`, and `01h` in multiple routines. In the audited direct-reference sites, the instruction form is `TEST byte ptr CS:[8280h],imm8` (`2E F6 06 80 82 imm8`).

No direct immediate `OR`, `AND`, or `MOV` store to `CS:[8280]` was found in the ROM by searching the corresponding direct-address instruction encodings. This does not prove that the flag is never modified: it could be initialized by a block copy, a pointer-based write, or an external/runtime mechanism. It does mean that the flag's setter has not yet been identified.

The complete direct-reference offsets found include:
`10EE, 114C, 12F4, 1371, 15A7, 1C0C, 5CAB, 8403, 8645, 865E, 8677, 867E, 9243, D7ED, D843, D85D, DA24, DA49, DA90, E2EF, E321, E33A`.

The next investigation should identify initialization/copy routines that populate the CS-resident workspace and search for pointer-based writes into the region containing `8280h`.


## 7. Caller and default-ROM behavior

A near-call target scan identifies a direct caller at `52A1`:

```
529C: B0 57          MOV AL,57h
529E: E6 80          OUT 80h,AL       ; POST checkpoint 57h
52A0: E8 62 C9       CALL 1C06h       ; conditional CMOS save block
52A3: B0 58          MOV AL,58h
52A5: E6 80          OUT 80h,AL       ; POST checkpoint 58h
```

Thus the CMOS-save block is called during POST between checkpoints 57h and 58h. It is not an isolated Setup menu callback.

The ROM image's initial byte at `CS:8280` is `2Fh` (bytes at `8280–8287`: `2F 00 E7 03 00 00 12 00`). Bit `40h` is clear in this ROM image. Since the audited code at `1C0C` tests that bit and skips the writes when it is clear, the six CMOS writes are conditional and are not taken with the unmodified ROM-resident initial value.

The setter for bit `40h` remains unidentified. This reinforces that the byte may be changed by runtime initialization or a shadowed/copy-backed workspace; it must not be described as an unconditional CMOS save. The callback at `CS:[82DE]` currently resolves to `19AD` (`RET`), so that callback contributes no visible setter in the current image.
