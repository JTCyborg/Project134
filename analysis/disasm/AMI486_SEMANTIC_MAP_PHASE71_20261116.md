# AMI486 semantic map — phase 71 (2026-11-16)

## Scope

Continued the timing/POST investigation by separating the confirmed live memory-timing path from the still-unresolved DA5Eh/DA61h alternate routine. Sources: `ami486_ram_timing_origin_156A_20261116_01.txt`, `ami486_ram_timing_caller_1EC8_20261116_01.txt`, `ami486_ram_timing_entry_20261116_01.txt`, `ami486_ram_timing_loop_20261116_01.txt`, and `ami486_ram_timing_tail_20261116_01.txt`.

## 1. Confirmed live POST caller

At 156Ah, the POST path calls 1EC8h. That wrapper explicitly saves BP around the call to 2850h:

```asm
156A  CALL 1EC8
...
1EC8  PUSH DS
1EC9  PUSH ES
1ECA  PUSH BP
1ECB  CALL 2850
1ECE  POP BP
1ECF  POP ES
1ED0  POP DS
1ED1  AND byte [0016h],EFh
```

Thus the BP value returned from 2850h is discarded/restored by the wrapper. The direct caller at 156Ah continues with its own later checks and a separate BP-preserving diagnostic sequence at 1576h–158Fh.

## 2. 2850h is a live RAM scan / timing calibration routine

The entry sequence:

```asm
2850  MOV AX,C503h
2853  CALL 8DDCh
2856  MOV DI,285Ch
2859  JMP 8CB2h
...
2883  MOV DI,2889h
2886  JMP 8DEDh
...
2893  CALL 28F2h
```

The helper 28F2h starts with interrupts disabled, selects DS=9C00h, and scans successive 16-KiB segment windows using REP LODSW. It decrements the segment high byte by 4 and continues until the tested range is exhausted, then enters the continuation at 2911h.

The core segment-count path is:

```asm
2911  MOV DX,BX
2913  XOR BP,BP
2915  MOV DI,291Bh
...
292A  INC BP
292B  MOV AX,DS
292D  ADD AH,4
2930  CMP AH,A0h
2933  MOV DS,AX
2935  JNZ 2915h
2937  MOV BX,BP
2939  MOV BP,SP
293B  MOV AX,BX
293D  OUT 81h,AL
...
295D  PUSH DS
295E  MOV BX,0040h
2961  MOV DS,BX
2963  MOV AL,AH
2965  MOV [00E0h],AH
2969  POP DS
296A  RET
```

BP is used as a temporary count of the discovered memory segments. The count is copied to BX at 2937h; BP is then repurposed as the stack pointer value at 2939h. The result is also reported through port 81h and stored at BDA address 0040:00E0h.

The PIT timing sample at 296Bh–2996h programs channel 0 through port 43h, samples port 40h around a REP LODSW delay loop, and calculates a delta in BX. The surrounding code at 299Bh onward performs additional memory traversal/clearing tests; it is not an entry into DAxx.

## 3. Consequence for BP.13 and DAxx

This live POST route cannot be the missing BP.13 producer:

- The wrapper at 1EC8h saves and restores BP around the entire 2850h call.
- The internal BP value is a temporary segment counter, then replaced with SP at 2939h.
- The result exported by this routine is the memory count via BX, port 81h and BDA 0040:00E0h, not a persistent BP status bitmap.
- No transfer from this routine to DA5Eh/DA61h is present in the inspected control flow.

The distinction is now explicit:

| Routine | Evidence | Function / status |
|---|---|---|
| 2850h | Called by 1EC8h from live POST at 156Ah | Confirmed RAM scan and PIT timing calibration |
| DA5Eh/DA61h | Internal crafted-stack continuation, no confirmed static caller | Alternate/legacy timing path; runtime entry unresolved |

The absence of a direct caller to DAxx remains a scoped negative result, not proof the code is unreachable under all runtime or external-hook conditions.

## 4. Next analysis

1. Continue from 299Bh–29EAh to classify the subsequent RAM clear/verify helpers and their callers.
2. Audit all writes to BP on the 5Cxx/509Eh path and distinguish temporary stack/register values from persistent bitfield updates.
3. Keep searching for an actual incoming edge or dynamic dispatch selecting DA5Eh/DA61h; do not conflate it with the confirmed 2850h routine.
