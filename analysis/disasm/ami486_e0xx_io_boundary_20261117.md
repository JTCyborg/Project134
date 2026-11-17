# AMI486 — E0xx Setup shadows and hardware-I/O boundary

Date: 2026-11-17  
Repository: `JTCyborg/Project134`, branch `main`  
Input: `ami486.bin` (64 KiB; fetched blob SHA `480c7520c93e6c7ed437cf3ad214da7503f82ec6`).

## 1. Dispatcher stack convention — clarified

The generic dispatcher at `60A0–60B2`:

```
60A0: D1 E3          SHL BX,1
60A2: 56             PUSH SI
60A3: 8B 36 95 E1    MOV SI,[E195]
60A7: 8B 18          MOV BX,[SI]
60A9: 5E             POP SI
60AA: 1E             PUSH DS
60AB: 56             PUSH SI
60AC: 57             PUSH DI
60AD: 55             PUSH BP
60AE: 0E             PUSH CS
60AF: FF D3          CALL BX
60B1: 5D             POP BP
...
```

The table entries are near offsets, called with `CALL BX`. The caller pushes `CS` immediately before the near call; handlers that end with `RETF` pop the near-call return IP and this synthetic CS word. This is a deliberate far-return-compatible wrapper, not a far pointer table. This resolves the convention more precisely than the previous report.

## 2. E0xx fields directly touched by the handlers

The ROM contains these direct references:

| RAM field | Handler offsets | Observed use |
|---|---|---|
| `E036` | `29FD, 2A01, 2A20, 2A35, 2ACE, 2B20, 2B59, 2B9E, 2BE0, 2C2A` | Global enable/valid gate; bit 0 tested/set/cleared |
| `E046` | `2A7F, 2A93, 2B1C, 2B36, 2B40, 2B55, 2B6F, 2B81` | Packed setting value, bit masks and shifts |
| `E047` | `2A84, 2A97, 2C26, 2C40, 2C5B` | Packed setting value, 2-bit field |
| `E049` | `2A89, 2A9B, 2B9A, 2BB5, 2BC7, 2BDC, 2BF7, 2C09` | Packed setting value, multi-bit fields |
| `E050` | `2A8E, 2A9F, 2ACA, 2AE4, 2AFF` | Packed setting value, 3-bit field |
| `E052` | `2CD8, 2CDC, 2CF3, 2D05, D960` | Packed setting value, nibble-sized field |
| `E066` | `2A06, 2A18, 2AA5` | UI toggle state, separate from E036 enable gate |

These are software state variables in RAM. The code extracts bitfields, changes selected values, and looks up display/encoding words. The evidence does not establish that an E0xx address is itself a hardware register.

## 3. Handler family structure

The handlers at `2AC1`, `2B13`, `2B4C`, `2B91`, `2BD3`, `2C1D`, and `2CCF` share a pattern:

1. Read the corresponding RAM shadow byte/word.
2. Check the global state bit `[E036]&1`.
3. Extract a field using masks and shifts.
4. Index a CS-relative word table.
5. Return the selected encoding to the UI caller.

For example, `2AC1` uses `[E050]`, extracts a 3-bit selector, and reads a word from the CS table at `2AB3`. The `2B13` family uses `[E046]` and a 2-bit selector; `2B91/2BD3` use `[E049]` with different masks/shifts. `2CCF` uses `[E052]` and a nibble selector.

This is consistent with a generic Setup editor for packed options. It is not yet a hardware-write path.

## 4. Confirmed I/O sequence near 2E60

The bytes at `2E60–2E70` contain:

```
2E60: B0 B4       MOV AL,B4h
2E62: E6 43       OUT 43h,AL
2E64: EB 00       JMP short $+2
2E66: 2A C0       SUB AL,AL
2E68: E6 42       OUT 42h,AL
2E6A: EB 00
2E6C: EB 00
2E6E: E6 42       OUT 42h,AL
2E70: EB 00
```

This is an actual port-I/O sequence to ports `43h` and `42h`. Those are standard PC-compatible PIT control and channel-2 data ports, respectively. The immediate sequence writes control value B4h and then data bytes. It is evidence of PIT programming, not evidence of ALi1429 configuration.

The code at `2E74` and `2EB4` begins separate CPU/segment-state checks and does not belong to this short PIT sequence.

## 5. What is still missing before chipset mapping

- Determine all references/callers to the port-I/O helper(s) around `2E60`.
- Decode the full call graph from each E0xx handler to any I/O sink.
- Identify the chipset configuration routines separately from PIT, video BIOS, keyboard, and UI routines.
- Determine whether E0xx values are committed to hardware on menu exit, on each selection change, or during a later initialization pass.
- Trace writes to E0xx outside the Setup UI region; some may be initialized from CMOS or chipset probing.

## 6. Correction and scope

The handler table at `B7B2` contains direct near offsets. The dispatcher synthesizes a far-return frame by pushing CS before `CALL BX`; handlers ending in `RETF` are therefore consistent with this scheme. The previous report's broad description of the stack sequence is now refined.

Only the PIT port sequence above has been positively identified as hardware I/O in this analysis slice. No ALi1429 register assignment is made here.
