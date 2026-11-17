# AMI486 — repeated PIT / PC speaker I/O sequences

Date: 2026-11-17  
Repository: `JTCyborg/Project134`, branch `main`  
Input: `ami486.bin`, 65,536 bytes.

## 1. Three independent code locations program PIT ports

The ROM contains repeated sequences using the PC-compatible PIT ports:

### Routine fragment at 2E60

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

### Routine fragment at 5580

```
5580: C3
5581: B0 B6       MOV AL,B6h
5583: E6 43       OUT 43h,AL
5585: 32 C0       XOR AL,AL
5587: E3 00       JCXZ $+2
5589: E3 00
558B: E6 42       OUT 42h,AL
558D: E3 00
558F: E3 00
5591: E6 42       OUT 42h,AL
```

### Routine fragment at 90A0

```
909C: B0 B4       MOV AL,B4h
909E: E6 43       OUT 43h,AL
90A0: EB 00
90A2: 2A C0       SUB AL,AL
90A4: E6 42       OUT 42h,AL
90A6: EB 00
90A8: EB 00
90AA: E6 42       OUT 42h,AL
90AC: EB 00
```

The repeated structure and port numbers support identifying these as PIT channel-2 programming sequences. Control words B4h/B6h differ and must be preserved as separate variants; do not normalize them into one routine without proving callers and intended mode.

## 2. Port 61h speaker/system-control access

At `2E50–2E5E`:

```
2E50: 42
2E51: EB 00
2E53: 86 E0       XCHG AL,AH
2E55: F7 D8       NEG AX
2E57: C3          RET
2E58: E4 61       IN AL,61h
2E5A: 24 FC       AND AL,FCh
2E5C: E6 61       OUT 61h,AL
2E5E: EB 00
```

The `IN AL,61h / AND AL,FCh / OUT 61h,AL` sequence clears bits 0 and 1 of port 61h, conventionally disabling the PC speaker gate and PIT channel-2 speaker data path. The nearby PIT setup fragments are consistent with speaker/timer support.

A second access pattern at `5580–55A8` writes PIT channel 2, then reads port 61h, modifies it, and writes it back. A related helper at `9090–90A8` also reads/modifies port 61h and writes PIT control/data ports.

## 3. Separate system-control / chipset candidates

At `93E0–93F0`, code reads port `40h` twice and combines the values. At `D950–D980`, code reads port `60h`, compares against a RAM state word, and then writes `ADh` to port `64h`; this is consistent with keyboard-controller command handling, not ALi1429 chipset setup.

These examples illustrate why raw OUT opcode scans are insufficient: the ROM contains PIT, speaker, keyboard-controller, video, and other legacy I/O. Each must be classified by its surrounding routine and call graph before treating it as a chipset configuration operation.

## 4. Implication for Setup-handler investigation

No direct edge has yet been proven from the E0xx Setup shadow handlers to the PIT/speaker helpers above. The PIT code is documented as a separate legacy-I/O subsystem until callers establish a connection. It must not be presented as the destination of the ALi1429 Setup settings.

## 5. Next steps

1. Resolve callers of the PIT helper fragments at `2E58`, `5581`, and `909C`.
2. Identify the actual chipset setup I/O block by tracing the handler tables and writes to E0xx shadows.
3. Classify the remaining port-I/O clusters by port and surrounding code before assigning hardware identities.
