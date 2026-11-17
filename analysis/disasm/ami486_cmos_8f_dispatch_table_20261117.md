# ami486.bin — CMOS[8Fh] marker dispatch table and value 06h

Date: 2026-11-17  
ROM: `ami486.bin`, 64 KiB, branch `main`.

## Dispatch mechanism

After reading and clearing `CMOS[8Fh]`, routine `D615h` preserves the old byte in SI. The low byte is compared against 04h, 05h, and 0Ah; the selected paths eventually reach a shared dispatcher:

```asm
D691: B8 40 00          MOV AX,0040h
D694: 8E D8             MOV DS,AX
D696: B0 00             MOV AL,00h
D698: 8E C0             MOV ES,AX
D69A: B0 30             MOV AL,30h
D69C: 8E D0             MOV SS,AX
D69E: BC 00 01          MOV SP,0100h
D6A1: D1 E6             SHL SI,1
D6A3: 2E FF A4 A8 D6    JMP WORD PTR CS:[SI+D6A8h]
```

This is a 16-bit offset table indexed by the saved CMOS marker value. The table begins at `D6A8h`.

## Recovered table

| CMOS[8Fh] value | Dispatch offset | Status |
|---:|---:|---|
| 00h | 2490h | Target identified; semantics not yet classified |
| 01h | D7D1h | Target identified; semantics not yet classified |
| 02h | 1E91h | Target identified; semantics not yet classified |
| 03h | F780h | Boot-path region; needs full trace |
| 04h | 2452h | Separate path selected by D615h |
| 05h | F731h | Boot-path region; needs full trace |
| 06h | F786h | Boot-selection / disk-boot routine |
| 07h | 545Bh | Target identified; semantics not yet classified |
| 08h | 1D1Bh | Target identified; semantics not yet classified |
| 09h | 8A06h | CPU-mode helper region |
| 0Ah | 9237h | CPU-mode / low-level transition region |
| 0Bh | F7BDh | Boot-path region |
| 0Ch | 0500h | Target identified; semantics not yet classified |

The values above are raw 16-bit offsets read from the table, not segment:offset far pointers.

## Value 06h path

For marker value `06h`:

1. `D615h` reads the CMOS byte and clears `CMOS[8Fh]` to zero.
2. The range check routes values up to `0Ah` to the path at `D652h`.
3. `D652h` jumps to `8A20h`.
4. `8A20h` compares the saved marker against `05h`, `09h`, and `0Ah`. Value `06h` takes the other path through `8A70h`.
5. `8A70h` executes `OR AL,0FFh`, then jumps to `D655h`. This intentionally supplies flags for the overlapping conditional branch at `D655h`; the branch is not taken.
6. The path reaches the common state setup at `D691h`, scales SI by two, and dispatches through the table.
7. Index 6 selects `F786h`.

The code at `F786h` begins:

```asm
F786: BE 22 7B       MOV SI,7B22h
F789: E3 08          JCXZ F793h
F78B: BE 3A 7B       MOV SI,7B3Ah
F78E: 73 6A          JNC F7FAh
F790: BE 52 7B       MOV SI,7B52h
F793: B0 0E          MOV AL,0Eh
F795: E8 13 F7       CALL EEABh
```

The surrounding `F780–F80F` code performs boot-selection work, attempts a drive-`80h` boot path, checks the boot-sector signature `AA55h`, and falls back through `INT 18h` when the attempt fails. This supports classifying marker `06h` as a boot-flow dispatch value, rather than a raw “protected mode enabled” flag.

## Interpretation

`CMOS[8Fh]` is best described as a one-byte firmware continuation / recovery dispatch code:

- POST writes `06h` before the `CS:[8281].40h` reset-request check.
- The later startup path consumes the value, clears CMOS[8Fh], and dispatches according to the saved code.
- Value `06h` selects the boot-selection path at `F786h`.
- A separate CPU-mode check at `8A04h` clears the marker and resets if CR0.PE is still set.

This does not yet explain why the POST path writes 06h at that point, or which earlier failure/continuation state causes other marker values. Continue tracing the producer of `CS:[8281].40h` and the callers that reach `8A04h`.

No ROM bytes changed.

## Special marker handling discovered in D615h / 8A20h

The early dispatch comparisons are significant:

- `D637h` compares marker against 04h and 05h; either value branches to `D646h`, which sets BX=0870h, SP=D650h, and jumps to `EEE7h`.
- `D63Fh` compares against 0Ah; values 06h–0Ah initially enter the `8A20h` classifier.
- At `8A20h`, values 05h, 09h, and 0Ah share a special setup beginning at `8A2Eh`. Values other than 05h/09h/0Ah take the alternate route through `8A70h` and then `D655h`.
- Value 06h takes the latter route, then proceeds through the table to `F786h` as described above.

The special 05h/09h/0Ah branch at 8A2Eh is not yet fully decoded because it uses overlapping code/data and an indirect control transfer. Do not treat those values as equivalent to the normal table dispatch until their complete path is reconstructed.

## Values 04h and 05h: PIC initialization at EEE7h

The `EEE7h` routine reached by the 04h/05h special case has a strong 8259A PIC initialization signature:

- Writes `00h` to port `F1h`.
- Sends `11h` to slave PIC command port `A0h`.
- Sends `BL` to `A1h`; with the caller's `BX=0870h`, this is `70h` (slave interrupt vector base).
- Sends `BH` to master PIC data port `21h`; with `BX=0870h`, this is `08h` (master interrupt vector base).
- Sends ICW values `02h` and `04h` to the PIC data ports, then `01h` to complete initialization, and finally masks the slave PIC with `FFh`.

This is consistent with remapping the master 8259 vectors to 08h and the slave vectors to 70h, with the slave initially fully masked. This identifies the 04h/05h continuation as an interrupt-controller setup path, not the disk loader.

The routine subsequently reads port 61h and conditionally writes a modified value back, then writes `8Dh` to CMOS index port 70h before returning. The exact meaning of that final CMOS index write and the preceding port-F1 write remains open.

## Special path for markers 09h and 0Ah: CMOS[B3h] and CPU cache control

At 8A20h, values 05h, 09h, and 0Ah branch to the special path beginning at 8A2Eh (marker 05h is already intercepted by D637h in the normal startup dispatcher).

```asm
8A2E: B0 B3          MOV AL,B3h
8A30: BC 36 8A       MOV SP,8A36h
8A33: E9 5E 64       JMP EE94h
8A36: 38 8A          ; word on stack: return IP = 8A38h
8A38: A8 0C          TEST AL,0Ch
8A3A: 74 34          JZ 8A70h
8A3C: 8A D0          MOV DL,AL
8A3E: 66 C1 C8 10     ROR EAX,10h
8A42: 8B D8          MOV BX,AX
8A44: BF 4A 8A       MOV DI,8A4Ah
8A47: E9 83 02       JMP 8CCDh
```

EE94h is the CMOS read helper: it writes AL to port 70h, reads port 71h into AL, and returns. Thus this path reads CMOS index B3h. The synthetic stack pointer at 8A30h makes the helper RET continue at 8A38h.

If (CMOS[B3h] & 0Ch) == 0, execution goes to 8A70h and rejoins the common marker-dispatch path. If either bit 2 or bit 3 is set, the byte is copied to DL and the path reaches 8CCDh.

The code at 8CCDh checks the machine status word:
- If SMSW AX reports PE set, or AH is nonzero, it skips the cache-control write.
- Otherwise it reads CR0, ORs 60000000h into EAX (CR0.CD and CR0.NW), writes CR0, and executes WBINVD.
- It then clears AX and jumps through DI, which was set to 8A4Ah.

At 8A4Ah, the ROM selects one of two tables according to bit 2 of DL:
- bit 2 clear: DI=8E62h and CX=10;
- bit 2 set: DI=8E7Ah and CX=2.

It then loads a word from CS:[DI], advances DI by two, installs a synthetic stack return address, and jumps through a short delay/return stub at 8DDEh. The resulting continuation is F1E2h (the word placed at the synthetic stack top is E2F1h). F1E2h begins a larger initialization path; its complete purpose remains under investigation. The selected table areas at 8E62h and 8E7Ah contain structured configuration data, not executable instruction sequences.

**Interpretation limit:** CMOS[B3h] bits 2/3 select a low-level initialization branch and can cause CR0 cache-disable bits plus WBINVD to be applied. This does not prove that the CMOS byte is simply a cache-enable setting; the selected table and F1E2h continuation must be traced before assigning user-visible semantics.

## Correction: PIC masks in EEE7h

The 8259 initialization sequence ends by writing FFh to both data ports: FFh to A1h masks all slave IRQs, and the same value to 21h masks all master IRQs. Therefore both PICs are fully masked at the end of this routine. The sequence remaps the master base to 08h and slave base to 70h, sets cascade wiring values 04h (master ICW3) and 02h (slave ICW3), then selects 8086 mode via ICW4=01h for both.
