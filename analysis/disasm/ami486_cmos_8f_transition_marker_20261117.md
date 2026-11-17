# ami486.bin — CMOS[8Fh] transition marker lifecycle

Date: 2026-11-17  
ROM: `ami486.bin`, 64 KiB, branch `main`.

## POST writes the marker

At `5472h–5477h`:

```asm
5472: B8 8F 06       MOV AX,068Fh
5475: E8 25 9A       CALL EE9Dh
```

`EE9Dh` writes AL to CMOS index port 70h, then AH to CMOS data port 71h. Thus this call writes `CMOS[8Fh]=06h`. Immediately afterward POST tests `CS:[8281]&40h`; if set, it branches to the 8042 reset body, otherwise it continues to `F068h`.

## A CPU-mode failure path clears the marker before reset

At `8A04h`:

```asm
8A04: 0F 01 E0       SMSW AX
8A07: A8 01          TEST AL,01h
8A09: 74 0F          JZ 8A1Ah
8A0B: B0 8F          MOV AL,8Fh
8A0D: E6 70          OUT 70h,AL
8A0F: E3 00          JCXZ 8A11h
8A11: E3 00          JCXZ 8A13h
8A13: B0 00          MOV AL,00h
8A15: E6 71          OUT 71h,AL
8A17: E9 BB 00       JMP 8AD5h
8A1A: E9 F8 4B       JMP D615h
```

The two `JCXZ 0` instructions are delay slots used by the firmware; they do not change the control decision. `SMSW` obtains the machine-status word, and `TEST AL,1` checks CR0.PE.

- If PE is set, the routine writes `CMOS[8Fh]=00h` and requests a hardware reset through `8AD5h`.
- If PE is clear, it jumps to `D615h`.

This is direct evidence that the CMOS byte participates in CPU-mode transition/recovery handling. It does not yet prove the exact meaning of marker value `06h`.

## D615h reads and clears the marker

At `D615h`:

```asm
D615: B0 8F          MOV AL,8Fh
D617: E6 70          OUT 70h,AL
D619: E3 00          JCXZ D61Bh
D61B: E3 00          JCXZ D61Dh
D61D: E4 71          IN AL,71h
D61F: B4 00          MOV AH,00h
D621: 8B F0          MOV SI,AX          ; preserve old marker
D623: B0 8F          MOV AL,8Fh
D627: E6 70          OUT 70h,AL
D629: B0 00          MOV AL,00h
D62F: E6 71          OUT 71h,AL          ; clear CMOS[8Fh]
D631: 8C C8          MOV AX,CS
D633: 8E D0          MOV SS,AX
D635: 8B C6          MOV AX,SI           ; restore old marker
```

The routine then compares the saved low byte against `04h`, `05h`, and `0Ah`, and branches into different follow-up paths. Value `06h` is not an exact match for 4 or 5; it falls through the range check for values up to 0Ah. This makes the subsequent branch logic important before assigning semantic names to the marker values.

## Relationship to CS:[8281].40h

The `8A04h` path checks CR0.PE, while `D615h` later tests `CS:[8281]&40h` as part of its follow-up logic. This links the CMOS marker handling to the same CPU-mode/reset state machine, but the direction of causality is not yet fully established.

The marker is not a direct setter for `CS:[8281]`: the observed CMOS helpers only access ports 70h/71h. A separate producer for the flag remains to be found.

## Working interpretation

`CMOS[8Fh]` is a one-byte transition/recovery marker:
- POST writes `06h` immediately before its reset-request check.
- A path that detects CR0.PE still set clears the marker and resets the machine.
- A path that detects PE clear reads and clears the marker, then dispatches according to the previous value.

The precise meanings of marker values 04h, 05h, 06h, and 0Ah remain unresolved. Do not label `06h` as a generic “protected-mode enabled” marker until the dispatch targets are fully traced.

No ROM bytes changed.
