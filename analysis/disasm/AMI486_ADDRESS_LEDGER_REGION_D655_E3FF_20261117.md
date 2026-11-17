# AMI486 address-ledger extension: CMOS 8Fh POST selector, 8042/CMOS tests and protected-mode data

Date: 2026-11-17  
Source: `ami486.bin`, 65,536 bytes  
SHA-256: `91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b`

## 1. Why the candidate interval is not one homogeneous gap

The candidate-mask gap was reported as D65Bh–E400h. Byte-aligned inspection shows that D65Bh is **not an entry point**: it lies inside the immediate/displacement bytes of the instruction beginning at D657h:

```asm
D655  JZ  D690h
D657  TEST BYTE PTR CS:[8281h],40h
D65D  JNZ D690h
```

The relevant executable stream starts at D655h, a continuation after the separate D652h -> 8A20h path documented in phases 51–52. The interval then contains POST code, a CMOS selector table, many stack-return words, a large zero-filled pad, ROM strings, descriptor-like structures and another POST chipset-port stream. A single linear decode obscures these boundaries.

## 2. CMOS 8Fh selector and indirect near-jump table

The path at D615h reads CMOS register 8Fh, clears it, and keeps the old value in SI. D637h diverts selectors 04h/05h to the EEE7h stack continuation; the 8A20h path applies additional tests before the D655h continuation reaches the indexed dispatch.

At D6A0h–D6A6h:

```asm
D6A0  SHL SI,1
D6A2  JMP WORD PTR CS:[SI-2958h]
```

The table base is D6A8h. Its eleven words are:

| Selector | Target |
|---:|---:|
| 0 | D724h |
| 1 | 91D1h |
| 2 | F71Eh |
| 3 | 5280h |
| 4 | F724h |
| 5 | F731h |
| 6 | 5486h |
| 7 | 1B5Bh |
| 8 | 8A1Dh |
| 9 | 9206h |
| 10 | F737h |

This confirms phases 51–52. The table is limited to these eleven words; selector reachability is constrained by the earlier branch gates. The table ends at D6BDh. D6BEh is executable code, not part of the table: `MOV BP,5; JMP F4A5h`, the error path also reached by the stack/register test.

## 3. Stack/register/segment test

D6C4h copies AX successively into BX, CX, DX, SI, DI and BP, then transfers those values through ES, DS and SS before executing `JMP SP`. D6DEh first compares SP against 5555h and AAAAh. It then loads AX with each pattern, sets SP to D6FCh/D709h and returns through the D6C4h `JMP SP` trampoline. The continuations XOR AX against the expected pattern and branch to D6BEh on mismatch.

Important alignment:
- D6FCh and D709h are **code continuations**, because control reaches them through `JMP SP`; they are not return-address data.
- D6BEh is the common failure path and sets BP=5 before entering F4A5h.

This is a deliberate stack/register/segment integrity test. It is not a normal function with a conventional CALL/RET frame.

## 4. POST stages, 8042 and CMOS sequence

The subsequent D7xx–D9xx stream emits POST status values to port 80h and performs hardware checks. The status bytes are diagnostic markers; they are not function numbers.

### 4.1 Memory checksum and keyboard-controller exchange

- D724h checks CS:8281h bit 6 and the SMSW/CR0 state, then emits status 03h and restores SS/DS/ES for the next POST path.
- D74Ch emits status 04h, reads 8042 status port 64h, conditionally sets BP bit 12, checks the equipment-signature word at 0040:0472h for 1234h and conditionally sets BP bit 15. It then emits status 05h and transfers to 8A78h.
- D777h emits status 06h and sums 8000h words from CS:0000h using `CS:LODSW`. A nonzero final checksum result sets BP=9 and enters F4A5h. The success path polls the 8042.
- D79Ah drains port 60h when the 8042 output-buffer-full bit is set and waits for the input-buffer state. The following code emits status 07h and sends the AA/command sequence through port 64h.
- D7DAh/D7E6h continue after the F659h/F60Fh wait helpers. D7E6h checks the 55h response and the CS:8280h feature flag; the conditional path sends command A1h, checks the returned byte against 38h, then sends FFh.
- D82Fh onward contains additional 8042 command/data writes. CS:8280h bits 10h and 20h select the data/command variants at D83Ch and D856h. D870h sends FFh to port 64h.

### 4.2 CMOS register checks and updates

The D884h–D9A0h area uses the common CMOS helpers:
- EE9Dh is the CMOS write helper; examples are `MOV AX,558Fh; JMP EE9Dh` and `MOV AX,AA8Fh; JMP EE9Dh`.
- EE94h is the CMOS read helper.
- The D8xx continuations compare the written/read values and inspect CMOS 8Dh/8Eh state. D8DAh tests bits and conditionally modifies BP status bits.
- D94Eh sends command AEh to port 64h (enable keyboard interface); D97Ch sends ADh (disable keyboard interface).
- D9xx then continues through chipset/port programming and the PIC setup path.

The byte-aligned alternate entries are not the same as the linear listing at each stack-return slot; see the return-slot table below.

### 4.3 PIT tests

D9DCh begins the status-14h path. It configures PIT channel 2 via ports 43h/42h, writes 55AAh test bytes, reads the count back and compares it. A mismatch conditionally sets BP bit 0 when the CS:8280h feature gate is enabled.

The following status-15h path programs PIT channel 0 through ports 43h/40h. Under the feature and CS:8285h gates, it measures port 61h transitions using F598h. If the measured difference reaches the threshold 0Ah, it sets BP=1 and enters F4A5h. The success path emits status 1Bh and jumps to 5BF8h.

## 5. Stack-return words: data, not instructions

The POST code repeatedly sets SP to an inline word and jumps to a shared helper. The helper returns by popping that word. The two bytes at each slot are therefore **return-address data**, not an instruction stream.

| Stack slot | Stored word | Aligned continuation |
|---:|---:|---:|
| D650h | D652h | D652h |
| D7D8h | D7DAh | D7DAh |
| D7E4h | D7E6h | D7E6h |
| D806h | D808h | D808h |
| D826h | D828h | D828h |
| D83Ah | D83Ch | D83Ch |
| D854h | D856h | D856h |
| D86Eh | D870h | D870h |
| D882h | D884h | D884h |
| D892h | D894h | D894h |
| D89Ah | D89Ch | D89Ch |
| D8AAh | D8ACh | D8ACh |
| D8B2h | D8B4h | D8B4h |
| D8CAh | D8CCh | D8CCh |
| D8D8h | D8DAh | D8DAh |
| D904h | D906h | D906h |
| D91Ah | D91Ch | D91Ch |
| D926h | D928h | D928h |
| D930h | D932h | D932h |
| D93Ch | D93Eh | D93Eh |
| D94Ch | D94Eh | D94Eh |
| D958h | D95Ah | D95Ah |
| D96Eh | D970h | D970h |
| D97Ah | D97Ch | D97Ch |
| D986h | D988h | D988h |
| D9A0h | D9A2h | D9A2h |
| DA64h | DA66h | DA66h |

These words are now emitted as separate data ranges in the candidate-window generator. D6FCh and D709h are deliberately excluded from this list because the test reaches them through `JMP SP`, not through a helper RET.

## 6. Newly resolved path to 8400h

This cross-reference is important to the earlier BP.13 investigation.

At D8FEh the code sets SP=D904h and jumps to EE9Dh. The word at D904h is 06 D9h, so the helper returns to D906h. The aligned continuation is:

```asm
D906  MOV AL,0Fh
D908  OUT 80h,AL
D90A  JMP 8400h
```

The near-jump displacement is F3AAh and resolves exactly to 8400h. This is a confirmed direct entry into 8400h, independent of the D6A2h selector table. It corrects phase 52's earlier statement that any non-table entry into 8400h remained unresolved; the phase-51 statement that no D6A2h table word equals 8400h remains true.

At 8400h:
- CS:8280h bit 40h selects the CMOS 8Eh path; if clear, control jumps to D90Dh.
- The aligned path reads CMOS 8Eh, clears BP bits 3–5 with `AND BP,FFC7h`, then loops through CMOS registers 8Eh–FFh writing zero.
- It then loads bytes from the ROM table at 820Eh and writes the 32-byte block to CMOS registers 8Eh–ADh; subsequent code reads and merges further table-driven values (including the table at 873Ch).

This proves a CMOS 8Eh extended-register clear/restore path. The `AND BP,FFC7h` operation preserves BP bit 13; it does not create BP.13. Thus the BP.13 producer question remains open.

The 8400h routine has now been added as a separately aligned candidate window. Its own stack-return slots at 8414h, 842Ah, 8444h, 8460h, 847Eh, 849Eh and 84BCh are recorded as data; the aligned continuations are 8416h, 842Ch, 8446h, 8462h, 8480h, 84A0h and 84BEh.

## 7. DAA2h–E3FFh: padding, strings and descriptor blocks

| Range | Classification | Evidence/status |
|---|---|---|
| DAA2h–DFFFh | 1,374 zero bytes | Verified directly from the ROM; DA9Fh's JMP immediate ends at DAA1h |
| E000h–E004h | Far JMP to F000:E005h | Alternate ROM entry stub |
| E005h–E007h | Near JMP to F73Bh | Second entry trampoline |
| E008h–E00Dh | Zero padding | Six bytes |
| E00Eh–E057h | ASCII text | “IBM COMPATIBLE IBM IS A TRADEMARK OF INTERNATIONAL BUSINESS MACHINES CORP.” |
| E058h–E05Ah | Zero terminator/padding | Three bytes |
| E05Bh–E05Dh | Reset entry | `JMP D604h`; the reset vector at FFF0h targets F000:E05Bh |
| E05Eh–E0CAh | Opaque binary block | Raw bytes are not a meaningful linear code stream; semantic owner not established |
| E0CBh–E138h | ASCII text | AMI copyright/address/telephone string |
| E139h–E15Fh | Zero padding | 39 bytes |
| E160h–E25Fh | 32 x 8-byte descriptor-like records | Most repeat `68 F0 20 00 00 87 00 00`; E1A0h and E1D8h differ. Architectural role/consumer unresolved |
| E260h–E2BFh | 96-byte protected-mode parameter/descriptor block | Copied from CS:E260h to ES:0600h before INT 15h AH=89h; internal field semantics partly unresolved |
| E2C0h–E2C2h | Zero prefix | Three bytes before E2C3h |
| E2C3h–E2C5h | JMP 90B7h | 90B7h forwards to E98Ah; direct caller unresolved |
| E2C6h–E3D6h | Separate POST chipset-port stream candidate | Contains I/O to ports 0Dh, DAh, 08h, D0h, 80h, 0Ch, D8h, D2h, D4h, D6h and 0Bh; entry provenance unresolved |
| E3D7h–E3FFh | 41 zero bytes | Padding before the E400h parameter-table area |

The descriptor-like array at E160h is not labelled as a live IDT or GDT: the repeated 87h attribute and nonzero low words are insufficient to prove that architectural interpretation. The E260h block has a stronger consumer relationship because its bytes are copied as a 48-word block immediately before INT 15h/AH=89h.

## 8. Generator and remaining work

The candidate-window generator now includes:
- the aligned D655h–D9xxh POST continuations;
- the D6A8h eleven-word selector table;
- every identified two-byte stack-return slot in this region;
- DAA2h–DFFFh zero padding, ROM identity strings, the opaque block and descriptor structures;
- E000h/E005h/E05Bh entry stubs and the E2C3h/E2C6h alternate streams;
- the direct D906h -> 8400h CMOS path and its aligned stack-return continuations.

The generated candidate manifest is the reproducibility check for the updated window/data counts. These bounded windows are not a complete CFG. The caller of E2C6h, the purpose of the E160h descriptor array, and the remaining continuation after the 8400h CMOS restore path still need investigation.

**This region extension is not a numbered phase and does not claim whole-ROM semantic completion.**


## 9. POST 8042 keyboard-controller self-test command at D7B3h–D7D7h

The POST stream at D79Ah polls the 8042 status/data ports and emits checkpoint 07h to port 80h at D7ABh. The aligned continuation at D7B3h then performs the following:

~~~asm
D7B3  MOV AL,0AAh
D7B5  XCHG BX,BX
D7B7  XCHG BX,BX
D7B9  XCHG BX,BX
D7BB  XCHG BX,BX
D7BD  XCHG BX,BX
D7BF  XCHG BX,BX
D7C1  XCHG BX,BX
D7C3  NOP
D7C4  JMP D7C6h
D7C6  OUT 64h,AL
D7C8  IN AL,64h
D7CA  XOR DI,DI
D7CC  TEST AL,01h
D7CE  JE D7D1h
D7D0  DEC DI
D7D1  NOP
D7D2  MOV SP,D7D8h
D7D5  JMP F659h
~~~

The command byte AAh is sent to the 8042 command port 64h, which is the keyboard-controller self-test command. The repeated XCHG BX,BX instructions do not change architectural state and provide an explicit delay sequence. The routine then reads port 64h and records whether status bit 0 is set: DI remains 0000h when clear and becomes FFFFh when set.

It sets SP=D7D8h and transfers to F659h, the shared keyboard-controller input-buffer wait helper. The crafted return word at D7D8h–D7D9h is D7DAh, so the helper returns to the status-08h continuation at D7DAh. The stack word remains data, not an opcode.

This closes the 37-byte candidate-mask hole D7B3h–D7D7h. The generator now has a bounded seed at D7B3h with length 25h, ending immediately before the D7D8h return word. The command sequence and status-bit test are byte-confirmed; this note does not infer the full controller self-test result protocol from this one status read.
