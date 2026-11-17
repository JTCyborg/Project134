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

## F1E2h continuation: video initialization call

The continuation selected by the CMOS[B3h] branch enters the byte stream at F1E2h. This is an intentional overlapping entry: decoding from that exact offset gives CMP BYTE PTR [0E38h],CL (bytes 38 0E 38 0E), followed by a near CALL whose target wraps to 578Dh:

```asm
F1E2: 38 0E 38 0E    CMP BYTE PTR [0E38h],CL
F1E4: E8 A6 65       CALL 578Dh
```

At entry 578Dh:

```asm
578D: 89 16 9B E1    MOV [E19Bh],DX
5791: 89 1E 9D E1    MOV [E19Dh],BX
5795: E8 66 FF       CALL 5704h
5798: B0 00          MOV AL,00h
579A: E8 88 FF       CALL 5725h
579D: 8A C8          MOV CL,AL
579F: E8 AB FF       CALL 5753h
57A2: 8A D0          MOV DL,AL
57A4: B0 01          MOV AL,01h
57A6: E8 7C FF       CALL 5725h
```

The called helpers include explicit writes to the CGA-compatible mode-control port 3D8h. At 5706h the code loads AL=21h and writes it to DX=03D8h; at 5715h it similarly writes AL=29h to 03D8h. The 578Dh routine repeatedly calls parameter/CRTC helpers and reads/writes the E19x working variables. This is strong evidence for a video-adapter initialization/configuration stage, not a generic CMOS parser.

The F1E2h caller then saves registers and performs a larger startup sequence: copies a 64-byte block from region E000h to a stack-local buffer, calls helper routines around F309h and F10Ah, and proceeds into further platform initialization. Later in this same block it invokes INT 1Ah functions 02h and 04h (RTC time and date), then continues into disk/boot preparation. Thus the CMOS[B3h] branch feeds into a broader platform startup path that includes display setup and RTC services.

**Caution:** the 3D8h writes and E19x variable use establish video initialization, but the exact chipset/adapter model and complete CRTC register table still need a dedicated decode. Do not claim a specific VGA/CGA card from these ports alone.

## Decode correction for F1E2h / F1E4h overlap

Correction to the preceding F1E2h note: the CPU continuation established by the synthetic return address is F1E2h, not F1E4h. Starting at F1E2h, bytes `38 0E E8 A6` decode as `CMP BYTE PTR [A6E8h],CL`; the bytes E8 A6 65 are therefore also a possible overlapping CALL encoding only when decoding from F1E4h. There is no independent evidence that execution enters F1E4h on this path. The earlier claim that the CMOS[B3h] continuation calls 578Dh is withdrawn.

The 578Dh routine is independently called from numerous other ROM locations (including 0159h, 0FD9h, 3E52h, 3F28h, 48CAh, 4990h, 49D7h, 4A29h, 4BF0h, 4D05h, 4EFEh, 4FE2h, 5066h, and 597Dh), so its video-configuration behavior remains valid as a separate finding. It must not be attributed to the F1E2h continuation without proving an alternate entry.

The F1E2h continuation instead proceeds through an overlapping instruction stream beginning with the CMP above, then pushes registers, allocates a 40h-byte stack frame, and copies 20h words from DS:E000h to the stack-local ES:DI buffer. It calls offsets F309h and F108h, both of which require entry-point-aware decoding (F309h is inside the bytes of a nearby INT 16h instruction when decoded from F300h). Their exact semantics are not yet established. The later visible INT 1Ah calls for functions 02h and 04h read RTC time/date. The remainder of this continuation is still under analysis.

### Follow-up: indirect call chain confirms video setup is reached

A subsequent call-graph pass found the indirect chain from the actual F1E2h entry to the independently identified video routine:

```asm
F1FD: E8 0E 01       CALL F30Eh
F30E: E8 AD 16       CALL 0FBEh
0FD9: E8 B1 47       CALL 578Dh
```

Thus the earlier direct-call attribution was wrong, but the broader conclusion that this startup continuation reaches 578Dh is now confirmed through two intermediate routines. The correction above should be read as: F1E2h does not directly call 578Dh; it reaches it through F30Eh -> 0FBEh.

At 0FBEh the routine first updates working variables in the E18Fh/E19Fh/E1A0h area, derives parameters from the caller frame, then calls 578Dh. After returning, it continues through calls to 5862h and 58C2h and updates a buffer addressed via [E18Fh]. The exact data structure and meaning of these fields remain to be mapped. This is likely part of the display/platform initialization block, but do not assign a specific video adapter model yet.

## F1E2h startup continuation: indirect video setup and password gate

The actual F1E2h entry continues through the overlapping CMP instruction, register saves, a 40h-byte local stack frame, and a 20h-word copy from DS:E000h to SS:SP. The call chain after this copy is now resolved:

```asm
F1FD: E8 0E 01       CALL F30Eh
F30E: E8 AD 16       CALL 0FBEh
0FD9: E8 B1 47       CALL 578Dh
```

Thus the startup continuation does reach the 578Dh video-configuration routine, but only indirectly through F30Eh and 0FBEh. The separate E8 A6 65 byte sequence at F1E4h is part of the displacement of the overlapping CMP when execution starts at F1E2h; it is not the executed CALL on this path.

After the 0FBEh call returns, F200h calls F10Dh. This is a password-validation gate:

- F10Dh reads CMOS indices 8Eh, B7h, and B8h through the CMOS read helper (EEAAh).
- It tests CMOS[8E]&C0h, then checks the upper nibble of CMOS[B7] and the value of CMOS[B8]. Depending on these fields it may skip the CMOS password prompt or enter the current-password path.
- The current-password prompt uses string 7BB9h: "Enter CURRENT Password:".
- A separate ROM-password path reads CS:[8237h], tests its upper nibble, and if enabled uses the string at 7BA0h: "Enter ROM Password". The stored comparison bytes are in CS:8238h–CS:823Dh.
- The input and character-validation helpers are called around F316h/F339h; their full keyboard semantics are being traced separately.
- F1C6h executes CMP SP,SP and returns with ZF=1 (success/skip). F1C3h executes OR SP,SP and returns with ZF=0 (failure).
- The caller at F200h tests ZF. On failure it emits BEL through INT 10h (AX=0E07h) and jumps to the common stack cleanup path; on success it continues into the next startup checks.

This establishes a BIOS password gate in the CMOS[8Fh] continuation before the later low-memory scan and RTC time/date reads. It does not yet establish the exact encoding of the CMOS password bytes or all policy meanings of the 8Eh/B7h/B8h fields.

## Password-change subflow in F1E2h continuation

The code after the F10Dh password gate contains a second, distinct password-entry sequence. Its strings identify the purpose directly:

- F261h loads SI=7BD2h: "Enter NEW Password".
- F2A5h loads SI=7BEBh: "Re-Enter NEW Password".
- F2DAh loads SI=7C36h: "ERROR, Press Any Key....".
- F2E3h loads SI=7C04h: "Password Now Enabled".

The first entry loop sets DI=0038h and CX=6, then calls the keyboard character helper at F337h. The helper reads keystrokes through INT 16h, accepts printable ASCII, converts lowercase letters to uppercase, and distinguishes Enter/Esc control results. The caller stores the entered characters in its BP-based local stack frame. The second prompt repeats input and compares it with the first entry. A mismatch reaches the error string and emits BEL through INT 10h; the success path displays "Password Now Enabled".

After the success message, the code copies 20h words (40h bytes) from the stack-local buffer at SS:BP to ES:E000h, then restores the stack frame and returns. This is a RAM-buffer transfer; it is not, by itself, proof that the password is immediately committed to CMOS. The later persistence path and the exact layout of the 64-byte buffer remain to be traced.

The surrounding F1E2h routine also:
- scans the first 64 KiB of physical memory by setting DS=0000h, SI=0000h, CX=8000h and summing 8000h words into DX;
- reads RTC time via INT 1Ah/AH=02h and RTC date via INT 1Ah/AH=04h, with retry branches on carry;
- combines the returned RTC fields with the low-memory accumulation before continuing into the password-entry section.

These operations identify this as a startup recovery/configuration path that validates an existing password, gathers platform state, and can request a new password. Do not yet label the 64-KiB accumulation as a definitive RAM test: the code computes a sum but the comparison/use of that value is still being traced.

## Critical correction: CMOS[B3h] path does NOT enter F1E2h

The previous notes incorrectly interpreted the two bytes E2 F1 at 8A68h as a synthetic return address to F1E2h. They are actually the displacement bytes of the instruction `LOOP 8A5Bh`. The control flow is:

```asm
8A4A: BF 62 8E       MOV DI,8E62h
8A4D: B9 0A 00       MOV CX,000Ah
8A50: F6 C2 04       TEST DL,04h
8A53: 75 06          JNZ 8A5Bh
8A55: BF 7A 8E       MOV DI,8E7Ah
8A58: B9 02 00       MOV CX,0002h
8A5B: 2E 8B 05       MOV AX,CS:[DI]
8A5E: 47             INC DI
8A5F: 47             INC DI
8A60: BC 66 8A       MOV SP,8A66h
8A63: E9 76 03       JMP 8DDEh
8A66: 68 8A          ; immediate word of PUSH 8A68h at the synthetic stack location
8A68: E2 F1          LOOP 8A5Bh
8A6A: 8B C3          MOV AX,BX
8A6C: 66 C1 C8 10     ROR EAX,10h
8A70: 0C FF          OR AL,0FFh
8A72: E9 E0 4B       JMP D655h
```

The short delay/return stub is at 8DDEh (RET at 8DDEh; preceding bytes are port-I/O delay instructions). With SS still inherited from the D615h path (SS=CS), the synthetic stack word sends execution to 8A68h. The bytes E2 F1 are therefore an executed LOOP instruction, not a word F1E2h. The loop reads 10 words from CS:8E62h or 2 words from CS:8E7Ah, advancing DI by two each time; the loaded AX is overwritten after the loop. There are no port writes in this loop. Its precise purpose is not yet established; describe it as a bounded ROM-read/delay loop, not as applying a chipset table.

After the loop, execution forces ZF=0 with OR AL,FFh and enters D655h. For marker 09h or 0Ah, if CS:[8281].40h is clear, D66Dh adjusts CR0 before D691h:
- Reads SMSW AX and tests AH.
- If AH is nonzero, sets CR0 bit 4 (ET).
- Clears CR0 bits 31 and 30 (CD/NW) with AND EAX,9FFFFFFFh.
- Writes CR0 and continues to D691h.
If CS:[8281].40h is set, this CR0 adjustment is bypassed and execution goes directly to D691h.

D691h then dispatches using the preserved marker index SI. Index 9 selects 8A06h; index 10 selects 9237h. Those are the actual marker-specific entries. 8A06h and 9237h must be analyzed as independent entry points; F1E2h is not the destination of this CMOS[B3h] branch.

## Separate correction: F1E2h routine is not proven to belong to CMOS[B3h] dispatch

The bytes at F1E2h begin an independently decodable routine. Its earlier password/RTC analysis remains a description of that byte range, but no verified edge from the CMOS[B3h] loop above enters F1E2h. Likewise, F1FDh CALLs F30Eh, and F30Eh is a RET stub. The separate entry at F30Fh contains `MOV AX,0C1Dh; CALL 0FBEh; RET`; this is not a continuation of the F1FDh call. Therefore withdraw the earlier claimed chain F1E2h -> F30Eh -> 0FBEh -> 578Dh. The video routine 578Dh remains independently identified by its own call sites.

## Addressing correction for the password buffer copy at F2EAh

The prologue at F1EAh executes PUSH ES, PUSH DS, PUSH SS, POP ES, so ES=SS for this routine. At F2EAh, `MOV DI,E000h; MOV SI,BP; MOV CX,20h; SS: REP MOVSW` copies 40h bytes from SS:BP to ES:E000h, which is SS:E000h. In the known D691h dispatch setup SS is 0030h, making the linear destination 0E300h, not a CMOS index and not segment 0000h:E000h. This is a RAM buffer copy; it does not itself prove persistent password storage.
