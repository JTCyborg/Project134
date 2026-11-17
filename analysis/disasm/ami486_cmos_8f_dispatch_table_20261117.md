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

## Resolved D691h targets for marker 09h and 0Ah

The dispatch table at D6A8h has now been traced one step further:

- Marker 09h selects 8A06h. Because the preceding bounded loop leaves CX=0000h and OR AL,FFh leaves ZF=0, the instruction at 8A06h (`LOOPNZ 89B0h`) decrements CX to FFFFh and branches to 89B0h. 89B0h is a RET. Thus this marker path returns through the stack frame prepared by the D691h setup; it does not enter the following bytes at 8A0Bh.
- Marker 0Ah selects 9237h. At that entry:
  ```asm
  9237: 8B E8          MOV BP,AX
  9239: 2E 8B 46 00    MOV AX,CS:[BP+00h]
  923D: 5D             POP BP
  923E: FF E0          JMP AX
  ```
  D691h has left AX=0030h, so this reads the word at CS:0030h. In the current ROM image bytes 0030h–0031h are 4Dh 4Dh, yielding target 4D4Dh. It then restores BP from the stack and jumps to 4D4Dh.
- The 4D4Dh target is a real routine that manipulates variables in the E1xx/E4xx areas and performs further calls. Its full purpose is not yet established; do not classify it as a disk or password routine solely from this entry.

This resolves the actual destinations for CMOS[8Fh] marker 09h and 0Ah: marker 09h returns via 89B0h; marker 0Ah enters 4D4Dh via the ROM pointer at CS:0030h.

### Stack precondition at D691h

D691h sets SS=0030h and SP=0100h. The resulting linear stack address is 0030h*10h+0100h = 00400h, i.e. the beginning of the BIOS Data Area, not a private stack region. Neither D691h nor the short marker-specific trampolines shown above initialize this stack word:
- marker 09h reaches RET at 89B0h, which consumes the word at physical 00400h as its return IP;
- marker 0Ah reaches 9237h, whose POP BP consumes the same stack word before jumping to 4D4Dh.

Therefore these paths depend on a pre-existing value at 00400h supplied by earlier initialization/caller context. The return target for marker 09h and the restored BP value for marker 0Ah cannot be claimed until the writer/initializer of physical 00400h is located. This is a key unresolved dependency in the POST state machine.

## Marker 0Ah target 4D4Dh: menu/event handler and saved-frame dependency

The marker-0Ah destination at 4D4Dh is not a password or disk routine. It is part of a menu/event-dispatch path:

- Entry sequence at 9237h: `MOV BP,AX`; `MOV AX,CS:[BP]`; `POP BP`; `JMP AX`. With AX=0030h from D691h, the jump target is the word at CS:0030h = 4D4Dh.
- The preceding `SHL SI,1` in D6A1h sets ZF=0 for marker index 0Ah. MOV/POP/JMP preserve flags, so the first instruction at 4D4Dh (`JNZ 4D64h`) is taken. This is the actual entry path, not the fall-through code at 4D4Fh.
- At 4D64h the routine tests the menu/state word E423h. If nonzero, it updates E19Fh from E1A7h, calls helpers at 4DDCh/591Eh/5904h, and interprets the returned key/action.
- The key value is compared with 0Dh (Enter). On Enter, E185h is used as an index into a word table at CS:393Dh; the selected handler pointer is stored at SS:[BP-2] and called indirectly through that slot.
- Other key values are compared against escape/navigation/edit values (including 1Bh and 012Dh); the routine adjusts E185h and loops back through the menu state. The exact key-to-action labels need further tracing.
- The common exit at 4DD9h is `POP SI; POP DI; MOV SP,BP; POP BP; RET`. This is a conventional frame teardown: BP is a saved caller frame pointer, and MOV SP,BP restores the caller's stack before popping its prior BP.

This explains why the word read at physical 00400h matters: the value is consumed as BP, then used as the frame base by the handler's eventual epilogue. It is therefore functioning as a saved-frame value for this dispatch, not as an ordinary COM1 port value in this path. The exact earlier writer or frame-construction step is still not found.

A byte-pattern scan of ami486.bin found no direct absolute stores to offset 0000h using common encodings (A3 0000, 89 [0000], C7 [0000], or ES:A3 0000). This does not rule out an indirect write through a register or string instruction; the producer of the saved BP remains unresolved.

### Marker 0Ah identification: hard-disk format/geometry UI

The string table adjacent to the 4D4Dh handler resolves its purpose. ROM strings include:
- `Enter Cylinder # :` at 3945h
- `Enter Head # :` at 3958h
- `Entry Present. Enter Again` at 3961h
- `All Data on Specified` at 3982h
- `Harddisk will be LOST` at 3998h
- `Want to Continue (Y/N) ?` at 39AEh
- `Status` at 39C8h
- `Hit <ESC> if You Want to Abort` at 39D0h
- `User Break` at 39EAh
- `Operation Completed` at 39F8h
- `FATAL ERROR : Bad ...` at 3A0Ch (string continues beyond this excerpt).

The handler table at CS:393Dh contains four words:
- index 0 -> 4DE7h
- index 1 -> 4E1Fh
- index 2 -> 4E2Eh
- index 3 -> 4E5Fh

The main handler uses E185h as the selected menu index and dispatches through this table when Enter (key 0Dh) is received. The two explicit geometry prompts and destructive-operation warning establish this as the hard-disk geometry / low-level-format user interface. Thus CMOS[8Fh]=0Ah is a path into a disk-format utility, not the password path previously suspected. The exact low-level disk operation and its INT 13h calls still need tracing; the warning text alone does not prove which sectors are written or whether formatting is destructive in the same way on every branch.

### Saved frame value at physical 00400h, refined

The 4D4Dh menu handler ends with `MOV SP,BP; POP BP; RET`. Therefore the value loaded into BP from SS:0100h (physical 00400h) is the caller's saved frame pointer for this UI dispatch. It is a temporary frame/stack linkage value, not the COM1 base used semantically by this routine. The producer is still unresolved; no direct absolute store to offset 0000h was found in the first static opcode-pattern scan.

### Refined handler roles: 4EE7h is numeric input, not the destructive disk operation

Cross-references refine the menu handler interpretation:

- The table at 393Dh points to 4DE7h, 4E1Fh, 4E2Eh, and 4E5Fh.
- 4DE7h calls 4EE7h at 4E09h; 4E1Fh calls 4EE7h at 4E2Ah.
- 4EE7h has a conventional BP stack frame and local 6-byte workspace. It displays the prompts using string pointers 3945h (`Enter Cylinder # :`) and 3958h (`Enter Head # :`), and calls the established video/text helpers at 578Dh, 5862h, and 58D3h. It is therefore the shared numeric-entry/input routine for cylinder/head parameters.
- The 4DE7h and 4E1Fh handlers are the two menu actions that invoke this common entry routine. The other handlers 4E2Eh and 4E5Fh remain to be classified in detail.
- The warning/confirmation strings around 3982h–39C0h and status/error strings around 39C8h–3A28h show that this UI belongs to a hard-disk destructive-operation utility, but the actual sector/track formatting engine has not yet been isolated. A scan for literal `INT 13h` instructions in 4EE7h–53FFh found none; disk I/O may be performed through an indirect BIOS wrapper or a helper outside that range.

Thus the safe conclusion is: marker 0Ah opens the hard-disk format/geometry interface; the identified 4EE7h routine gathers cylinder/head input. Do not yet claim which INT 13h services or physical write pattern performs the format.

### Remaining menu handlers: counter reset and selected-entry removal

The two previously unclassified menu-table handlers are now traced at instruction level:

- Handler index 3, entry 4E5Fh, is exactly `MOV WORD PTR [E423h],0000h; RET`. It clears the menu's E423h state/counter. This is a reset/clear action, not a disk-format command.
- Handler index 2, entry 4E2Eh, is a selected-entry edit/removal path:
  - Calls the overlapping entry at 4E64h (the byte at 4E64h is part of a different instruction stream; do not decode the handler solely from linear fall-through).
  - If returned AL is 1Bh (Escape), returns without applying the edit.
  - Otherwise reads E427h as the selected entry index, derives an offset using the fixed entry stride, and calls the helper at 578Dh/adjacent display code to refresh the selected row.
  - It updates the E423h/E427h counters and loops through the list bounds, including comparisons against the active entry count at E425h/E427h.
  - The exact semantic label of this action (delete, shift, or replace selected geometry entry) is not proven from the control flow alone. It is clearly list-entry maintenance, not the low-level track-writing engine.
- The 4E64h address is an overlapping entry: byte 4E64h is `00 C3` (ADD BL,AL), while the handler body beginning at 4E65h starts `PUSH SI`. Keep the entry-point distinction in the disassembly listing.

The four-entry menu table at 393Dh can now be summarized:
0 -> 4DE7h (cylinder input)
1 -> 4E1Fh (head input)
2 -> 4E2Eh (selected-entry/list maintenance; exact UI label unresolved)
3 -> 4E5Fh (clear E423h counter/state)

No evidence in these handlers identifies the actual physical format/write routine. The next useful step is to follow the helper chain after the confirmation/status prompts in the 4Fxx–52xx region and identify any indirect disk-service dispatch, rather than treating these menu callbacks as the formatter itself.

### Correction to the 4E2Eh helper references

A byte-accurate relative-CALL recalculation corrects the preceding summary: the 4E2Eh/4E65h handler does not directly call 578Dh. Its CALL targets in the 4E64h–4EE6h span are:
- 4E70h -> 4CE6h
- 4E7Ah -> 581Ch
- 4E83h -> 5902h
- 4E92h -> 581Ch
- 4EC3h -> 4BDAh

The 581Ch and 5902h helpers belong to the display/input support layer; the 4CE6h and 4BDAh helpers remain to be decoded. Remove the earlier shorthand claim that this handler itself calls 578Dh. The geometry-entry handlers at 4DE7h/4E1Fh still call the shared 4EE7h numeric-input routine, which independently calls 578Dh.

### Follow-up: list helpers and the disk-service boundary

Further inspection of the 4BDAh/4CE6h call chain confirms these are support routines for the menu/list layer, not the formatter's disk-write worker:

- `4BDAh` builds/refreshes the on-screen list and maintains the E423h/E425h/E427h list counters and indices. It calls display/input helpers (`578Dh`, `58D3h`, `5891h`, `581Ch`, `58B5h`, `5862h`) and list-processing code at `4CA2h`.
- `4CA2h` calls `4CE6h` and iterates fixed-stride entries, copying/normalizing fields in the E4xx list area. `4CE6h` itself is a tiny arithmetic helper: it forms AX from AL shifted into AH, clears AL, adds 0C3Bh, and returns. It is not a disk-service call.
- `4CEEh` is a separate list/menu processing routine. Its calls include `578Dh`, `58BEh`, `5862h`, `4DDDh`, and `58D3h`; it updates E185h (selected item index) and redisplays the selected entry. This reinforces that the 4E2Eh callback is part of the interactive list editor.
- Error/status processing around `4AF0h–4B66h` maps controller status bytes (E1ADh/E1AEh) to user-visible error letters/messages, including the disk-controller/drive-failure strings. It is diagnostic handling, not evidence of a successful format operation.
- Keyboard input helper `4B68h` waits for a key and recognizes Escape; the adjacent code handles a Y/N confirmation and associated UI state.

A ROM-wide byte scan found direct `INT 13h` instructions at offsets:
`3008h, 6C1Fh, 7018h, 701Ch, 7024h, 7075h, AA19h, AA72h, AA7Ch, AAA9h, AAAFh, CC29h, CC3Bh, F777h, F81Ah, F822h`.
These are not all formatter calls; several are clearly in the boot path (F777h/F81Ah/F822h), and the 70xx/6Cxx locations are generic disk-service support. The hard-disk utility's 4Axx–50xx control path contains no literal `CD 13` instruction, so its disk operation must be reached through a wrapper/indirect dispatch or a different controller interface.

The code at `AA70h` issues INT 13h with AH=08h (get drive parameters), then AH=04h (verify sectors), and later AH=09h/11h in its retry/status path. This is a disk-parameter/verification routine, not yet proven to be the low-level formatter. No direct IDE data-port accesses were identified in the immediate 4Axx–50xx utility path. The formatter's actual write operation remains unresolved; do not label any of these helpers as the format engine until the AH=05h/format-track or equivalent command path is traced.


### Byte-level continuation: 4CA2h / 4CE5h overlap and 4Fxx boundary (2026-11-17)

A fresh decode of the current `ami486.bin` (65536 bytes) confirms an important entry-point distinction:

- `4CE5h` is the single-byte instruction `RET`. The call at `4CA7h` targets `4CE5h`, not the arithmetic helper at `4CE6h`. Thus the call from `4CA2h` is a no-op/early-return stub when entered at that exact address.
- `4CE6h` is a separate overlapping entry: `MOV AH,AL; SUB AL,AL; ADD AX,0C3Bh; RET`. The call at `4E70h` targets this entry. It returns the computed value `0C3Bh + (AL << 8)`.
- `4CA2h` is a list-record processing routine, not a disk I/O worker. After the no-op call it uses the caller's stack argument at `[BP-2]`, works with the `E436h` record area and fixed three-byte record stride, and calls shared helpers outside this local range. The instruction sequence performs indexed record/field processing; it contains no INT 13h or controller-port transaction.

The `4F00h–50A0h` bytes were also checked as a separate boundary. The apparent entry at `4FD0h` is a frame-based routine that formats/displays values from the `3BECh`-based table, calls UI helpers, compares a selected record, and updates that record; it does not itself contain an INT 13h instruction or direct IDE data-port access. At `50A0h` a distinct port-80h diagnostic/POST trace sequence begins (writes marker bytes such as 40h–59h), so this boundary must not be misclassified as the disk formatter merely because it follows the menu code in ROM address order.

No formatter command has been established by this pass. The next trace target is the call graph reached from the confirmation/record-update routine at `4FD0h`, plus the indirect service wrappers it invokes; the physical write operation remains unlocated.


### 4FD0h call-target trace: stack-sensitive port-61h helper

The direct relative-call targets from the `4FD0h` record/UI routine include display/input helpers in the `5780h–59xx` region and a nonstandard entry at `F56Dh` (the call at `5006h`, displacement `A564h`). At `F56Dh` the bytes decode as:

```asm
F56D  POP AX
F56E  OUT 61h,AL
F570  RET
```

This is a stack-sensitive entry, not an ordinary callable subroutine: it consumes the near-call return IP as the value sent to port `61h`, then returns using the next word on the stack. Consequently the call at `5006h` must be analyzed together with the caller's stack frame; it is not a disk-controller command. The surrounding `F56Ah` entry is a different instruction stream, beginning with `CALL F93Ch`, so linear decoding across `F56Dh` would also be misleading.

The helpers reached from `4FD0h` therefore remain UI/record-maintenance or platform-I/O support. This pass still does not identify a physical format-track/write command. Continue by tracing the caller's stack setup around `4FD0h` and the service dispatch reached after the Y/N confirmation path; do not infer that port `61h` is a disk data port.


### Correction: exact CALL target at 500Ah and PC-speaker/beeper sequence

The previous note incorrectly assigned the `POP AX / OUT 61h,AL` entry at `F56Dh` to the CALL at `500Ah`. Recalculation using 16-bit near-relative arithmetic gives:

- `5007h: CALL 58BEh` (bytes `E8 B4 08`).
- `500Ah: CALL F571h` (bytes `E8 64 A5`), **not** `F56Dh`.

The actual `F571h` sequence is:

```asm
F571  MOV AL,B6h
F573  OUT 43h,AL
F575  JMP short $+2       ; delay
F577  JMP short $+2       ; delay
F579  MOV AL,05h
F57B  OUT 42h,AL
F57D  JMP short $+2
F57F  JMP short $+2
F581  OUT 42h,AL
F583  IN  AL,61h
F585  PUSH AX
F586  JMP short $+2
F588  JMP short $+2
F58A  OR  AL,03h
F58C  OUT 61h,AL
F58E  MOV CX,0020h
F591  CALL F93Ch
F594  POP AX
F595  OUT 61h,AL
F597  RET
```

This is a PIT channel-2 / port-61h speaker-gate sequence (beep/tone timing), not a disk command. The `F56Dh` entry remains a separate stack-sensitive `POP AX; OUT 61h,AL; RET` sequence, but it is not the target of the `500Ah` call. The routine at `3E3Fh`, reached from `5040h`, also belongs to the menu/display support chain; its visible prologue and calls build/display UI data and do not establish a disk write.

This correction supersedes the earlier statement that `5006h` called `F56Dh`; that address/call attribution was wrong. The physical format/write path remains unresolved.


### Disk-service driver discovery: INT 13h AH=05h write path (candidate, not yet tied to format UI)

A scan of the disk-service region identified a concrete BIOS write-sector operation in the code stream around `6F7Ch–6FA5h`:

```asm
6F7C  CALL 72DBh
6F7F  CALL 6F42h
6F82  MOV CX,[BP+04h]       ; decode is entry-context dependent
6F85  ...
6F90  MOV BX,0E1B8h
6F93  MOV AH,05h
6F95  MOV AL,[1FE4h]
6F98  CALL 6C1Ah
6F9B  JC  6FA?              ; error path
6F9D  CALL 72F3h            ; success/continuation helper (verify target in full trace)
6FA0  ...
```

The byte-level fact is that the routine prepares `AH=05h`, loads `AL` from absolute data byte `1FE4h`, sets `BX=E1B8h`, and calls `6C1Ah`. The wrapper at `6C1Ah` enters the common disk-call path which reaches `INT 13h` at `6C1Fh`; it records returned status in `B9E3h` and propagates carry/status to its caller. Under the standard IBM-compatible INT 13h interface, AH=05h is Write Sectors. This is the first concrete BIOS write command found in the nearby disk service code.

However, the call graph has not yet been connected to the hard-disk utility's Y/N confirmation path. The `6F7Ch–6FA5h` sequence appears embedded in a larger disk-service routine, and `1FE4h` plus the segment/register setup must be resolved before interpreting the actual LBA/CHS, drive, count, or data buffer. It may be a generic sector writer used by multiple functions. Therefore this is a confirmed INT 13h AH=05h invocation, but **not yet proof that this is the format-track operation**.

Related distinction: the separate `AA70h` path uses AH=08h (drive parameters), AH=04h (verify), and AH=09h/AH=11h status/recalibration-style operations; it is not the AH=05h writer. The code at `7075h` sets AX=0228h before INT 13h, so its AH=02h read request has AL=28h (40 sectors) and must not be confused with AH=05h write.

Next trace: identify all entries/callers of the `6F7Ch–6FA5h` worker and all references to `1FE4h`; then connect the hard-disk utility's confirmation path to that worker or rule it out. Keep the formatter classification open until that link and the data-buffer geometry are proven.


### Critical correction to the AH=05h writer attribution (2026-11-17)

The previous section misread the absolute operand at `6F95h`: bytes `A0 1F E4` mean `MOV AL,[E41Fh]`, **not** `[1FE4h]`. A fresh scan finds these direct references to `E41Fh`:

- `5BDDh`: `MOV AL,[E41Fh]` followed by arithmetic involving words at `E413h` and `E411h` (the associated routine is a geometry/range calculation; decode the full entry before assigning semantics).
- `69A6h`, `69B9h`: used in the record/geometry loop in the `6970h` routine.
- `6A1Ch`: `MOV AL,[E41Fh]` immediately before the AH=05h disk call.
- `6D08h`, `6DD1h`: used in the `6Dxx` operation state machine.
- `6F95h`, `6FA5h`: used by the `6F75h` routine.

The actual AH=05h invocation is visible in **two distinct code paths**:

```asm
; routine beginning at 69D0h (frame-based; exact entry callers unresolved)
6A10  ...                  ; computes CH/CL/DH from inputs
6A1A  MOV AH,05h
6A1C  MOV AL,[E41Fh]
6A1F  CALL 6C18h            ; shared INT 13h path
6A22  POP CX
6A23  POP BX
6A24  PUSHF
...

; separate worker beginning at 6F75h, called from 6F23h
6F90  MOV BX,E1B8h
6F93  MOV AH,05h
6F95  MOV AL,[E41Fh]
6F98  CALL 6C18h
6F9B  JC ...
...
6FA5  MOV AL,[E41Fh]
```

The earlier claim that `6F7Ch` was a routine entry is withdrawn. It is an instruction boundary inside the frame-based worker at `6F75h`; a direct CALL xref to that worker is from `6F23h`. The AH=05h call at `6A1Ah` is another independent callsite, inside the larger routine whose visible prologue begins at `69D0h`. No direct near-CALL xref to `69D0h` was found in the ROM scan; it may be reached by an indirect dispatch or alternate entry, so its caller must not be guessed.

Important conclusion: the ROM contains at least two AH=05h sector-write callsites, both using the same count byte `E41Fh`. The path at `69D0h` explicitly derives CH/CL/DH immediately before the write call, making it a stronger candidate for track/sector formatting than the previously isolated `6F75h` worker. Nevertheless, the utility-menu Y/N chain has not yet been linked to either callsite. The meaning/value of `E41Fh`, drive number `DL`, buffer segment `ES`, and the producer of the CHS inputs still need to be established.

This replaces the earlier tentative attribution that the `6F7Ch–6FA5h` range was the unique sector writer. Treat AH=05h as confirmed sector-write functionality, but keep its association with low-level format unproven.


### Overlapping INT 13h wrapper entry correction: 6C14h vs 6C15h

A further exact relative-target calculation corrects the preceding dual-writer conclusion:

- The call at `6A1Eh` has displacement `01F3h`; next IP is `6A21h`, so target is `6C14h`. Byte `6C14h` is `C3` (`RET`). Therefore this call does **not** reach the INT 13h wrapper. It is an overlapping one-byte return entry. The AH=05h setup at `6A1Ah` is not evidence of an actual BIOS write on this path.
- The call at `6F98h` has displacement `FC7Ah`; next IP is `6F9Bh`, so target is `6C15h`. This is a separate entry one byte later, beginning `80 3E BB E3 FF 74 03 E8 1A 00 CD 13`. That entry conditionally invokes helper `6C32h`, then executes `INT 13h` at `6C1Fh`, stores returned AH in `B9E3h`, and propagates status/carry.

Accordingly, the previous section's statement that both AH=05h callsites reach the common INT 13h path is withdrawn. The only presently confirmed actual AH=05h BIOS write path is the call from the worker at `6F75h` through `6C15h`. The `69D0h` frame-based routine's `6A1Ah` AH=05h setup remains a prepared-but-not-issued operation at this particular callsite; do not classify it as a second disk write.

This is another case where linear disassembly obscures intentional/overlapping entry points. Keep the disk formatter link open: the confirmed sector write still needs to be connected to the hard-disk menu's confirmation handler, and the worker's caller parameters must be resolved.


### Cross-reference inventory for E41Fh and the 6F75h worker (2026-11-17)

A fresh byte-pattern scan confirms direct moffs references to `E41Fh` at:

- `5BD5h`
- `6984h`, `69A2h`, `69A7h`, `69BAh`
- `6A1Dh` (AH=05h setup whose CALL target is the overlapping `6C14h RET`, not INT 13h)
- `6AC1h`
- `6D09h`, `6DD2h`
- `6EFFh`
- `6F58h`, `6F96h`, `6FA6h`
- `706Ch`
- `723Fh`

No direct `A2/A3` moffs store to `E41Fh` appears in this scan; this does not exclude stores through ModR/M addressing, string operations, or a table/indirect pointer. In particular, `706Ch` loads CL from `E41Fh` in a separate path that subsequently issues `INT 13h AH=02h, AL=28h` at `7075h`. This is evidence that E41Fh is shared state used by more than the AH=05h worker; it is not yet safe to label it simply as the write-sector count.

The confirmed direct CALL xref into the worker entry `6F75h` remains `6F23h`. At `6F75h` the bytes begin an ENTER frame (`C8 10 00 00)); the worker then calls a register/frame helper at `72D8h` and another internal entry at `6F3Eh`. The call at `6F98h` reaches `6C15h`, the wrapper entry that conditionally reaches `INT 13h` at `6C1Fh`. The worker's success/failure handling follows at `6F9Bh–6FA7h`. The worker's caller state and the producer of the `E1B8h` buffer remain unresolved.

A separate path at `706Ch` loads `CL=[E41Fh]`, decrements CX, then sets `AX=0228h` and performs a 40-sector read at `7075h`. Do not conflate that read with the AH=05h write worker. This further supports treating E41Fh as shared disk-operation state until its producer and complete dataflow are traced.

Current classification: one confirmed AH=05h INT 13h write callsite (`6F98h -> 6C15h -> 6C1Fh`); no proof yet that this worker is the menu's low-level format implementation.


### Correction: 6F75h is an alternate entry/caller, not an ENTER prologue

Reconstructing exact byte offsets (rather than reading the 16-byte dump rows as instruction boundaries) corrects the previous description of `6F75h`:

- `6F37h` begins `ENTER 0010h,00h` and is the frame-based helper.
- `6F75h` begins `CALL 6F37h` (bytes `E8 BF FF`), so it is an alternate entry into a wrapper/caller sequence, not an ENTER instruction.
- The direct CALL from `6F23h` targets `6F75h` and therefore enters this wrapper.
- The helper at `6F37h` sets up a 16-byte local frame, calls register/frame support at `72D8h`, then calls the routine at `696Bh` (relative target from `6F49h`). It reads `CL=[E41Fh]`, clears CH, sets `SI=E1B8h` and `DI=E3CFh`, then loops copying two-byte records: `AL=[SI]` to `[DI]`, while reading `[SI+1]` into BL; SI advances by two. The exact semantic fields of each record remain unresolved.
- After the helper returns, the wrapper continues at `6F78h`, calls `72D8h`-adjacent register support at `72D8h` (call site `6F79h`), then calls back into `6F37h`? No: the actual call at `6F75h` is the helper invocation; subsequent bytes at `6F78h` are the continuation and include `8B 0C 86 E9 C0 E1 06...`. The CHS preparation and AH=05h issue remain in this continuation at `6F80h–6F98h`.

The confirmed disk-write path remains `6F98h -> 6C15h -> INT 13h` at `6C1Fh`. However, the wrapper/helper relationship is more complex than previously stated: `6F75h` is a call sequence that first invokes the record-preparation helper at `6F37h`, and the worker is not a standalone ENTER-framed routine. Previous wording calling `6F75h` a frame-based worker is withdrawn.


### Follow-up byte-accurate correction for helper calls in 6F37h

The relative targets within the `6F37h` helper were recalculated byte-for-byte and correct the immediately preceding note:

- CALL at `6F3Bh` targets `72D1h`, which is a one-byte `RET` entry (not a register-save helper).
- CALL at `6F49h` targets `6968h`, whose bytes are `A2 21 E4 C3`: `MOV [E421h],AL; RET` (not a routine beginning at 696Bh).

Thus the helper at `6F37h` saves the byte read from `E422h` into `E421h` through this overlapping entry, then performs the two-byte record-copy loop from `E1B8h` to `E3CFh`, with loop count loaded from `E41Fh`. This establishes an additional state byte `E421h` adjacent to the shared `E41Fh` variable, but does not yet identify the record format. The prior description of calls to `72D8h` and `696Bh` from this helper is withdrawn.


### Definitive offset-boundary correction for 6F3Eh/6F75h and E1B8h record flow

The last two notes contained an address-boundary error caused by reading grouped hex rows as if the row start were the instruction address. Recomputed offsets from the ROM byte array establish:

- `6F3Eh` begins `ENTER 0010h,00h` (bytes `C8 10 00 00`). It is a helper entry.
- `6F75h` also begins `ENTER 0010h,00h`. This is the worker entry reached by the direct CALL at `6F23h`.
- `6F7Ch` is `CALL 6F3Eh`, not the worker entry.
- `6F79h` calls `72D8h`.
- The helper at `6F3Eh` calls `72D8h`, reads `AL=[E422h]`, saves it to `E421h` through the overlapping entry at `6968h`, then loads `CL=[E41Fh]`, `SI=E1B8h`, `DI=E3CFh`. It copies `[SI]` to `[DI]` and also reads `[SI+1]` into BL, advancing SI by 2 per iteration. Exact record semantics remain open.
- Worker `6F75h` then calls helper `6F3Eh`, continues through CHS setup, sets `BX=E1B8h`, `AH=05h`, `AL=[E41Fh]`, and calls `6C15h`; this reaches the actual `INT 13h` at `6C1Fh`.

The direct-reference scan also found an important producer/update path at `6FCCh–6FDCh` (the code starts at `6FCCh` only if entered there; instruction boundaries must be established by tracing its caller):

```asm
; byte stream at 6FCCh
BE B8 E1       MOV SI,E1B8h
89 1C          MOV [SI],BX
88 44 02       MOV [SI+2],AL
83 C6 03       ADD SI,3
81 FE B8 E3    CMP SI,E3B8h
72 F2          JB ...
```

This is a 3-byte record writer over the region `E1B8h..E3B7h` (end-exclusive `E3B8h`), with record stride 3. It writes a word from BX at offsets 0–1 and a byte from AL at offset +2. This is distinct from the helper's 2-byte read/copy loop: that helper copies the first byte of each 2-byte source pair to `E3CFh`, while taking the second byte into BL; it does not copy the entire record verbatim. The record producer's caller and the meaning of the three fields are not yet identified.

The earlier note saying `6F75h` was not an ENTER prologue is withdrawn; the correct ENTER entries are `6F3Eh` and `6F75h`. The earlier note that `6F37h` was the helper is also withdrawn. The actual helper entry is `6F3Eh`.


### Address correction for E1B8h record writer

The record-writer byte sequence previously labelled `6FCCh–6FDCh` actually starts at **`6FD0h`**, not `6FCCh`. Exact offsets:

- `6FD0h`: `BE B8 E1` — `MOV SI,E1B8h`
- `6FD3h`: `89 1C` — `MOV [SI],BX`
- `6FD5h`: `88 44 02` — `MOV [SI+2],AL`
- `6FD8h`: `83 C6 03` — `ADD SI,3`
- `6FDBh`: `81 FE B8 E3` — `CMP SI,E3B8h`
- `6FDFh`: `72 F2` — loop back to `6FD3h`

This confirms a 3-byte-stride record writer spanning `E1B8h` up to (but excluding) `E3B8h`. It is preceded by a dispatch/selection sequence at `6FB7h–6FCFh` that chooses BX and AL values. Do not assign meaning to those fields until the incoming register values and caller path are traced.


### Track-buffer fill pattern and its caller-side setup (2026-11-17)

The code at `6D94h` (not `6D93h`; `6D91–6D93` are `CLC; JMP 6D8Ch`) establishes a concrete call chain into the buffer-pattern generator:

- `6D94h` begins `PUSH BP; MOV BP,SP`, loads SI from `[BP+4]`, DI from `[BP+6]`, and sets `CX=3`.
- It clears `[E3BFh]`, pushes CX, sets `BX=E1B8h`, then calls `6FAEh`.
- `6FAEh` is the pattern-fill routine. It preserves the caller registers through helper `72D8h`, tests CX, and chooses one of three 3-byte patterns:
  - CX=1: `BX=DB6Dh; AL=B6h` -> bytes `6D DB B6`.
  - CX=2: `BX=B6DBh; AL=6Dh` -> bytes `DB B6 6D`.
  - other CX (including the caller's CX=3): `BX=6DB6h; AL=DBh` -> bytes `B6 6D DB`.
- It writes the word BX at `[SI]` and AL at `[SI+2]`, advances SI by 3, and loops while SI < `E3B8h`. Starting at `E1B8h`, this produces 171 records (513 bytes): the final record occupies `E3B6h–E3B8h`, so the final byte is exactly at the comparison limit. Treat the endpoint as an observed boundary condition, not as proof of a 512-byte allocation.
- Returning to `6D94h`, calls at `6DACh` and `6DB1h` target `6E1Eh` and `6E27h`, respectively; both are single-byte `RET` entries (overlapping entrypoints, no operation). It then calls `6C9Dh` (keyboard/abort poll) and processes retry/track-state flags around `E3BFh`, `E3C0h`, and `E3BAh`.

This is now stronger evidence of a disk-format/fill operation: a three-byte repeating pattern is prepared in the same buffer later supplied to the confirmed `INT 13h AH=05h` write path. However, two things remain unresolved: how the `6D94h` routine is entered (no direct near-CALL xref or far CALL immediate target found; it may be reached through a dispatch/jump table), and whether its CHS state progression corresponds to the hard-disk UI's explicit Y/N confirmation path. Do not yet state that the menu confirmation is linked.

Correction to the previous buffer-size wording: the loop does 171 three-byte stores and the final store touches `E3B8h`; it is inaccurate to describe the written range as ending at `E3B7h`.


### Confirmed caller loop tying pattern generation to repeated AH=05h writes

A control-flow scan found two actual near-CALL references to the routine entry `6D94h`: `6D2Ch` and `6F12h`. The second callsite is especially important because it is part of the same loop that subsequently calls the confirmed AH=05h writer:

- At `6EF0h` onward, code initializes state `[E3C0h]=1`, clears a region beginning at `E3D0h` using a count from `E41Fh`, then loads a 3-byte record from `DS:[SI]` / `DS:[SI+2]` (`BX=[SI]`, `AL=[SI+2]`).
- It saves the working registers and pushes the record-derived values as arguments, then `CALL 6D94h` at `6F12h`.
- After the call it checks the carry/status state (including `SS:[B9E3h]`), restores the saved register set, and calls `6F75h` at `6F23h`.
- `6F75h` calls the helper at `6F3Eh`, prepares CHS, sets `BX=E1B8h`, `AH=05h`, `AL=[E41Fh]`, then calls `6C15h` -> `INT 13h` at `6C1Fh`.
- On success, the caller advances `SI` by 3 and loops back to process the next record. Thus the records are not just a static fill table: they drive repeated prepare/write iterations.

The first caller, `6D2Ch`, is in the `6CF0h–6D8xh` state/geometry path and also invokes `6D94h`; its arguments and role are still being decoded. The entry `6D94h` takes two stack arguments into SI and DI, sets CX=3, and calls the pattern generator `6FAEh`, which fills the write buffer with the selected three-byte repeating pattern. It then processes retry/abort and track-state variables.

This is now strong evidence that the ROM contains a low-level disk formatting/write-track workflow: record-driven repeated calls to `INT 13h AH=05h`, with a synthesized repeating fill pattern. What remains unproven is the final UI linkage: the explicit hard-disk warning/confirmation string and Y/N handler have not yet been connected by a verified call path to the `6D94h / 6EF0h` sequence. Keep that distinction in the documentation.


### Hard-disk destructive-operation confirmation path (2026-11-17)

The UI confirmation sequence is now located precisely in the large routine spanning at least `4890h–4AEFh`:

- `499Fh` loads the string at `3982h` (`All Data on Specified`).
- `49A9h` loads `3998h` (`Harddisk will be LOST`).
- `49B3h` loads `39AEh` (`Want to Continue (Y/N) ?`).
- `49BDh` stores `0E49h` in `[E180h]`, then calls keyboard/input helpers at `49C0h` and `49C3h`.
- `49C6h: CMP AL,59h`; `49C8h: JE 49CDh`. Thus only uppercase `Y` follows the continue branch at `49CDh`; all other returned characters take the jump at `49CAh` to `4ACCh`.

The Y branch then presents further data-entry/status UI and processes additional state at `E1A4h`, `E1A7h`, `E1ACh`, and local stack variables. It reaches the helper calls in the `4Axxh` range and eventually returns at `4AEFh`. The non-Y branch jumps to `4ACCh`, which also flows through the tail of this routine. This confirms the warning and explicit Y gate are executable code, not merely unused strings.

Important limitation: a static near-CALL xref scan finds no direct CALL to the `4890h`-range routine or to `6D94h` from the UI block. The two direct calls to `6D94h` remain `6D2Ch` and `6F12h`. The Y-confirmation routine is therefore now identified, but the interprocedural bridge from its caller/return path to the disk-track worker has not yet been proven. The `6D2Ch` caller still appears to be entered through a non-near-CALL dispatch or an indirect control transfer; do not claim the UI Y branch directly invokes formatting until that dispatch is traced.


### Stack arguments passed by the earlier 6D2Ch caller

The caller setup immediately before `CALL 6D94h` at `6D2Ch` is:

- `6D0Ah`: loads `AL=[E41Fh]` and stores it in `[E3C0h]`, then pushes AX (the count/state value).
- `6D14h`: pushes `WORD [E1B2h]`.
- `6D18h`: loads `AL=[E1B7h]`, zero-extends through `XOR AH,AH`, and pushes AX.
- `6D1Eh`: pushes `WORD [E1B5h]`.
- `6D22h–6D27h`: initializes `[E3BAh]=1` and `[E3BBh]=11h`.
- `6D2Ch`: calls `6D94h`.

Since `6D94h` uses `ENTER 0010h`, its `[BP+4]` and `[BP+6]` parameters are therefore the just-pushed `E1B5h` word and zero-extended `E1B7h` byte, respectively. It loads these into SI and DI. The next stack arguments are `E1B7h` and `E1B2h`; the final pushed argument is the `E41Fh` byte. The routine's local loop increments `E3BAh` and compares it with `E41Fh`, while using `E3BFh`, `E3C0h`, and `E3BBh` as operation state.

This provides a concrete caller-side parameter map, but does not yet justify assigning human labels such as cylinder/head/sector to `E1B5h`, `E1B7h`, or `E1B2h`. Those labels require tracing their producers and the BIOS disk geometry/track parameter conventions. The UI's cylinder/head prompts exist elsewhere in the same hard-disk interface, but no direct data-flow edge from those input fields to these variables has yet been proven.


### Parameter provenance refinement: E1B2/E1B4 and E1B5/E1B7

The latest byte-level pass narrows the provenance but also corrects an overstatement in the previous note:

- At `7258h`, `AX` is stored to `E1B2h`. The preceding arithmetic beginning near `7238h` uses constants `0780h`, `[E41Fh]`, and `[E413h]`, with unsigned DIV operations; it derives a geometry-dependent limit. Immediately before the store, `BL) is decremented and stored at `E1B4h`. This is a calculated geometry path, not a direct keystroke store.
- At `72B7h`, a second path stores `[E411h]-1` into `E1B2h`, then clears `E1AFh). Thus `E1B2h` is a geometry/range limit with at least two producers, not the user's entered cylinder/head value.
- At `6954h–6962h`, another setup path copies `[E411h]-1` to `E1B2h` and `[E413h]-1` to `E1B4h`; it also stores related values into `E1B1h`, `E1B5h`, and `E1B7h`. These appear to initialize bounds/state from the geometry variables.
- The code at `6A60h) writes a 16-bit value to `E1B5h` and an 8-bit value to `E1B7h`, after comparisons against stack-supplied bounds. On the failure path it clears both. This is consistent with a bounded numeric-entry helper, but a direct CALL xref to `6A60h` was not found in the current static scan; its entry/caller context still needs confirmation. Therefore the earlier wording that it is definitively the shared UI input procedure should be treated as provisional.

For the `6D94h` caller, `E1B5h` and `E1B7h` are indeed passed as arguments, but their exact semantic labels are not yet established. `E1B2h` is passed as another argument and is better characterized as a derived geometry/range bound. Next step is to follow the dispatch/entry path into `6A60h` and trace the values from the UI handlers `4DE7h/4E1Fh` through `4EE7h` and their helper calls.


### Follow-up: separate geometry setup from UI rendering; no direct entry to 6A60h found

A fresh pass over `4D80h–5050h` and `68E0h–6AD0h` establishes the following:

- `4EE7h` is a field/UI construction and validation routine, not evidence by itself of the numeric-entry routine that writes `E1B5h/E1B7h`. It calls display/layout helpers at `578Dh`, `5862h`, and `58D3h`, then assembles values from the current geometry/state and calls lower-level helpers. No direct CALL from this routine to `6A60h` or `69D0h` exists.
- The block at `6930h` initializes the geometry/state fields when `[E1ABh]` is zero: it clears `E1AFh`, `E1B1h`, `E1B5h`, and `E1B7h`, then clears `[E1B9h]` and `[E1BDh]`. It sets `E1B2h=[E411h]-1` and `E1B4h=[E413h]-1`. This is a confirmed initialization path, not a UI keystroke path.
- `69D0h` begins a separate stack-frame routine (`ENTER 0010h` is not used; it has `PUSH BP / MOV BP,SP / SUB SP,0010h`). Its body consumes stack arguments at `[BP+4]` and `[BP+6]`, works with the buffer at `E1B8h), and manipulates display/record data. The static near-CALL scan found no direct CALL to `69D0h`.
- `6A60h` writes `[BP+0Ah]` to `E1B5h` and `[BP+08]` (low byte) to `E1B7h`, after comparisons against `[BP+08]` and `[BP+0Ah]` bounds. Its rejection path clears both fields. The direct near-CALL scan still finds no CALL to `6A60h`; this address is therefore a local/indirect entry candidate, not yet a proven standalone function entry.
- The bytes at `6A53h` form a short flag/state-return path (`POPF; [E3B9h]=1; CLC; JMP` backward), immediately before the `6A60h` comparison/store block. This adjacency cautions against assigning an independent procedure boundary at `6A60h` without tracing incoming branches or indirect dispatch.

Consequently, the previous hypothesis that `6A60h` is the common UI numeric-input handler remains unproven. The reliable conclusions are limited to its writes and bounds checks, the initialization at `6930h`, and the separate display/record work at `4EE7h` and `69D0h`. Next investigation should target indirect/far dispatch and branch predecessors for `69D0h`/`6A60h`, then correlate those with the destructive-confirmation UI state machine; the UI-to-`6D94h` link is still not established.


### Address-boundary correction: 69D0h is not a routine entry

A fresh byte-offset audit corrects the earlier subsection that described `69D0h` as the start of a stack-frame routine. The bytes around the boundary are:

- `69CDh–69CEh`: `5D C3` (`POP BP; RET`), completing the preceding routine.
- `69CFh–69D0h`: `EB C3` (`JMP SHORT 6992h`). Thus `69D0h` is the signed displacement byte, not an instruction boundary or procedure entry.
- `69D1h`: `55 8B EC 83 EC 10` (`PUSH BP; MOV BP,SP; SUB SP,0010h`), the actual beginning of the following stack-frame code sequence.

The earlier statement that a routine begins at `69D0h` is withdrawn; references to that routine should use `69D1h` as the byte-level start candidate. A fresh scan of standard near relative `CALL/JMP`, short conditional branches, and near conditional branches found no direct branch target at `69D1h`, `6A60h`, or `6CE5h`. This does not exclude far transfers, register-indirect dispatch, computed jumps, or entry through an overlapping decode; those require separate analysis. In particular, the absence of direct relative references is not proof that any of these sequences are unreachable.

The bytes at `6A60h` still decode as a valid instruction boundary in the current linear view, but the preceding bytes include a control-flow path that must be considered before treating it as a standalone function. No new caller-to-entry relationship is established by this pass.


### Recovered direct callers for the corrected 69D1h entry

The corrected routine boundary at `69D1h` now has two confirmed near-CALL references in the ROM. A fresh relative-branch scan found:

- `6AF9h: CALL 69D1h`.
- `6BB8h: CALL 69D1h`.

The first call is in the record/buffer-processing path around `6AE0h–6B10h`. Before the call, the caller pushes several values assembled from the current record and loop state (including values loaded from the record at `[SI+2]`, `[SI]`, and related registers). It then restores the stack by adding `000Ah` after the call and continues its record loop. This is direct evidence that the `69D1h` routine is used as a lower-level worker in the E1B8 record-processing path.

The second call at `6BB8h` follows explicit setup from disk geometry/state:

- push zero-extended `[E1B4h]`;
- push `WORD [E1B2h]`;
- push zero-extended `[E1B7h]`;
- push `WORD [E1B5h]`;
- set `[E3BBh]=10h`;
- call `69D1h`.

The caller then tests carry/status and the state byte `[E3B9h]`, and may call the adjacent retry/error helpers. This establishes a concrete call path from geometry/state preparation into `69D1h`; it does not yet assign semantic labels to each argument or prove a connection to the destructive-confirmation Y branch.

A second boundary correction is also recorded: `6CE5h` is not a code entry. The bytes at `6CE4h` begin `C6 06 AB E1 01` (a store to `[E1ABh]`), followed at `6CE9h` by `C8 10 00 00` (`ENTER 0010h,0`). Thus `6CE4h` is the start of this instruction sequence and `6CE9h` is the ENTER instruction within it; neither has a direct near-relative branch reference in the current scan. The preceding routine ends at `6CE3h: RET`. Do not refer to `6CE5h` as an entry point.

This pass therefore resolves one missing call graph: `6AF9h` and `6BB8h` both call the actual `69D1h` worker. The separate `6CE4h` sequence and the UI-to-disk confirmation relationship remain open questions.


### Argument and prologue audit for the 69D1h worker

The entry at `69D1h` begins `PUSH BP; MOV BP,SP; SUB SP,0010h`. Its first relative call is at `69D7h` and targets `72D7h`, a register-save helper that copies the general registers and segment registers into the local frame. The worker then loads `SI=[BP+4]`, `CX=[BP+6]`, and sets `BX=E1B8h`. This is consistent with a buffer/record operation parameterized by a word and a second word, but it is not enough to label those values as cylinder/head/count.

For the confirmed caller at `6BB8h`, the stack arguments immediately before the call are pushed in reverse order:

- `6BA0h`: push zero-extended `[E1B4h]`;
- `6BA6h`: push `WORD [E1B2h]`;
- `6BAAh`: push zero-extended `[E1B7h]`;
- `6BB0h`: push `WORD [E1B5h]`;
- `6BB4h`: set `[E3BBh]=10h`;
- `6BB8h`: call `69D1h`.

Therefore, at the callee the four arguments are exactly `[BP+4]=E1B5h`, `[BP+6]=zero_extend(E1B7h)`, `[BP+8]=E1B2h`, and `[BP+10]=zero_extend(E1B4h)`. The last argument is not zero; the prior addendum's description of a zero fourth argument applied to a different call context and must not be reused for `6BB8h`.

The other direct caller at `6AF9h` builds its arguments from a record currently addressed through `SI`: it pushes the record's byte at `[SI+2]` (zero-extended), the word at `[SI]`, plus the current loop/index registers. It then calls `69D1h` and removes ten argument bytes. This is consistent with the same worker being used both for a table-driven record path and for a geometry-derived setup path.

The return handling at `6BB8h` is also now clearer: the caller executes `PUSHF; POP AX; ADD SP,000Ah; PUSH AX; POPF`, then branches on carry. Thus the callee's CF is deliberately preserved across stack cleanup and is a meaningful status result, not incidental flag state. The subsequent checks of `[E3B9h]` select additional helper/error handling. The exact semantic meaning of CF and of the E3B9h substate remains to be decoded from the callee's exits and the helper calls it makes.


### 69D1h disk-write result handling and abort key

A byte-accurate decode of the worker body establishes the following sequence:

1. The worker prepares the BIOS disk-write-track request. It loads the drive number from `[E421h]`, derives the CHS register encoding from the caller-supplied `SI` and `CX` values, sets `AH=05h`, loads `AL=[E41Fh]`, and calls `6C15h`. The wrapper at `6C15h` reaches `INT 13h` at `6C1Fh`.
2. Immediately after the INT 13h call, the worker restores saved `CX` and `BX`, then executes `PUSHF` and calls `6CA0h`.
3. `6CA0h` is a keyboard-abort poll: it checks with `INT 16h, AH=01h`; if a key is pending, it reads it with `INT 16h, AH=00h`. It returns CF set only when the read character is ESC (`1Bh`); otherwise it returns CF clear. If no key is pending, it returns CF clear without blocking.
4. If the keyboard helper reports ESC, the worker restores the original INT 13h flags with `POPF`, sets `[E3B9h]=1Bh`, sets CF, and routes to its common exit/restore path. Thus ESC is an explicit abort condition and is distinguished from a BIOS disk error.
5. If no ESC was detected, the worker restores the saved INT 13h flags and tests the original carry flag. CF clear enters the success path; CF set enters the retry/error-response path.

The success path increments its local attempt/index register and checks whether it has reached two attempts. If another pass is needed it calls `6A93h`; otherwise it enters the response/cleanup path. The error path also uses the keyboard/response helpers and preserves a status in `[E3B9h]`. The full meanings of response characters and the precise retry policy are not yet established; do not label the non-ESC response keys as Retry/Ignore without tracing the helper at `6A93h` and the subsequent caller logic.

This clarifies the CF contract: `6CA0h` reports keyboard ESC in its own CF, while the worker deliberately restores the earlier INT 13h flags before deciding whether the disk operation succeeded. The outer caller's saved-CF test therefore receives the worker's disk/abort status, not the keyboard helper's transient flags.


### Disk status classification and error-code lookup (69D1h continuation)

The retry decision helper at `6A93h` is a direct `AH` classifier:

- `AH = AAh, CCh, 01h, 80h` -> returns CF=0.
- Any other `AH` -> returns CF=1.

In the worker, this helper is reached only after the second failed INT 13h attempt (`DI` has been incremented and compared with 2). CF=0 falls through to the response/error-display path; CF=1 branches back to the retry loop. This is a classification of the BIOS status byte, not a keyboard response decoder.

The following response path at `6A3Ah` calls `6CC2h`. That helper does not use the incoming AL: it loads `AL=[E3B9h]`, then scans a 13-byte status list at `6CB5h`:

`01 02 04 05 07 0A 10 11 20 40 80 AA CC`

On a match, it returns the one-based position in the list in AL (1 through 13). If no match is found, it sets AL=1. It then calls `4FCDh` with that index, apparently entering the status-specific UI/error presentation path; the exact display text/control flow at `4FCDh` remains to be decoded.

The source of `E3B9h` is now confirmed in the INT 13h wrapper at `6C15h`: immediately after `INT 13h`, it stores the BIOS status register `AH` to `[E3B9h]`. The wrapper returns CF clear when the BIOS call succeeded and CF set when it failed. Thus `E3B9h` is the latched INT 13h status byte used by both the retry classifier and the later status-list lookup. The worker can also explicitly overwrite it with `1Bh` on ESC abort; callers test that sentinel separately.

Do not infer the semantic labels of the 13 status codes from their numeric values alone. The table ordering and index mapping are byte-confirmed; the corresponding UI strings and user choices still need cross-reference.


### INT 13h error index -> message pointer table

The error-message pointer table is located at `3BEEh` and contains 13 little-endian offsets. Its order exactly matches the 13-byte status-code list at `6CB5h`, because `6CC2h` returns a one-based index into that list and calls the display routine at `4FCFh` with that index.

| Index | INT 13h status | Message offset | ROM text |
|---:|---:|---:|---|
| 1 | `01h` | `3AAEh` | Undefined Error - Command Aborted |
| 2 | `02h` | `3AD0h` | Address Mark Not Found |
| 3 | `04h` | `3AE7h` | Requested Sector Not Found |
| 4 | `05h` | `3B02h` | Reset Failed |
| 5 | `07h` | `3B0Fh` | Drive Parameter Activity Failed |
| 6 | `0Ah` | `3B2Fh` | Bad Sector Flag Detected |
| 7 | `10h` | `3B49h` | Bad ECC on Disk Read |
| 8 | `11h` | `3B5Eh` | ECC Corrected Data Error |
| 9 | `20h` | `3B77h` | Controller has Failed |
| 10 | `40h` | `3B8Dh` | Seek Operation Failed |
| 11 | `80h` | `3BA3h` | Attachment Failed to Respond |
| 12 | `AAh` | `3BC0h` | Drive Not Ready |
| 13 | `CCh` | `3BD0h` | Write Fault on Selected Drive |

The adjacent string at `3C0Dh` is `Abort, Retry, Ignore ?`. The presence of this prompt is byte-confirmed, but the exact key-to-action dispatch and whether every listed error uses the same prompt must be established by tracing the continuation of `4FCFh` and its caller(s). The table mapping above is established by the status-code array and pointer array ordering, not by assuming standard PC BIOS error text.


### Abort / Retry / Ignore key path

The prompt string at `3C0Dh` is consumed by the UI path reached from the error-message display routine at `4FCFh`. The key-input loop in that routine stores the accepted key in `[E182h]` and accepts only ASCII `A` (`41h`), `I` (`49h`) and `R` (`52h`); other keys loop back for another input. The routine returns the selected key in AL.

The worker at `69D1h` compares this returned AL:

- `A`: branches to a path that explicitly sets CF, then restores saved registers and returns. This is the Abort result.
- `I`: enters the branch that clears CF and returns from the worker. This is the Ignore result (the failed operation is accepted as non-fatal by the caller).
- `R`: takes the retry branch back to the disk-operation loop.

This establishes the actual user-action semantics from the character comparisons and branch destinations; it is not merely inferred from the prompt wording. The status code `1Bh` remains a separate ESC/user-break sentinel and is not one of the three A/R/I responses.


### Caller-level result handling: batch record worker at 6ACEh

The second direct caller of `69D1h` is not an independent disk command: it is called from `6ACEh`, a batch walker over 3-byte records beginning at `3939h`.

Confirmed control flow in `6ACEh`:

- If `WORD [E423h] == 0`, it returns immediately with CF clear.
- Otherwise it calls `6AADh`, loads the record count from `[E423h]`, initializes `[E3BDh]=1`, and sets `SI=3939h`.
- For each record it pushes the current count, record pointer, and record-derived values, then calls `69D1h` at `6AF9h`.
- After the call it removes 10 argument bytes and restores SI/CX. It then tests `[E3B9h]`: zero advances SI by 3 and loops; nonzero exits with CF set. Exhausting the loop returns CF clear.

This means the batch caller's final status is based on the latched BIOS status byte `[E3B9h]`, not solely on the worker's returned CF. It stops at the first record for which the status byte remains nonzero; otherwise it advances to the next 3-byte record.

### Correction: Ignore branch is not a simple clear-CF return

The earlier shorthand that described the worker's `I` response as “clear CF and return” was too strong. At `69D1h`, after the `I` comparison, the equal branch enters code at `6A5Dh`, which modifies the record/geometry progress state using the current stack arguments and updates `[E1B5h]` / `[E1B7h]`. Depending on the bounds checks it either advances the progress pair or clears it, then rejoins the worker's operation path. It is therefore an in-operation Ignore/advance path, not a direct epilogue. The exact semantic names of those two state fields remain intentionally unresolved.

The `A` response is still directly confirmed to reach `STC` and the worker epilogue. The non-`I`/non-`A` accepted response (`R`) takes the retry branch back to the operation loop. ESC remains the separate `[E3B9h]=1Bh` path.


### Exact Ignore progress update in 69D1h (6A5Eh–6A92h)

The `I` response is selected at `6A43h`; the code preserves the original INT 13h flags around the character-register exchange and branches to `6A5Eh` when AL is `'I'`. The update block is:

- `6A5Eh`: `XOR CH,CH` (clear the high byte of CX).
- `6A60h`: compare CX with the word argument at `[BP+0Ah]`.
- If CX is below that limit, branch to `6A80h`, increment CX, and loop to the field-update sequence.
- Otherwise set CX=0, increment SI, store SI to `[E1B5h]`, and store CL to `[E1B7h]`.
- Compare the updated SI against the two word bounds `[BP+08h]` and `[BP+0Ah]`; if the bound tests permit continuation, jump back to the disk-operation loop at `69FEh`.
- If the bounds are exceeded, clear `[E1B5h]` and `[E1B7h]`, then rejoin the worker's common status/return path at `6A4Fh`.

This proves the structural behavior: Ignore advances the worker's current SI/CX position across a bounded range and updates the persistent progress pair `E1B5h:E1B7h`; it may restart the disk operation at the next position, or terminate the range and clear the progress pair. It is not a generic “ignore this one error and continue the same request” action.

Do not yet rename SI/CX or E1B5/E1B7 as cylinder/head/sector/count. Their caller-provided bounds differ between the record-based caller at `6AF9h` and the geometry-derived caller at `6BB8h`; the semantic unit still needs confirmation from the record layout and the caller's state setup.
