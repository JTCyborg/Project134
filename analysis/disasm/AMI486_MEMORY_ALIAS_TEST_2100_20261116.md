# AMI486 memory-alias / DRAM mapping test — 2100h region

Date: 2026-11-16  
Source: `ami486.bin` (65,536 bytes)  
Candidate windows: 2100h–217Fh, 2187h–2206h, 222Dh–22ACh, 2253h–22D2h, 22DBh–235Ah, 2381h–2400h and related short stack-thread entries.

## 1. Classification and entry status

The 2100h stream is a **memory-alias / address-line probe**, not a generic byte-copy routine. It writes two complementary 32-bit patterns, places a sentinel at offset 0100h, compares the base location, then checks whether the same pattern is visible at a set of low and high offsets. The resulting selector bytes are packed and written to indexed chipset registers 10h and 11h.

The 2100h start is still an **entry candidate**, not a proven direct-call target:
- Raw-ROM scan found no direct near CALL/JMP target to 2100h.
- No literal far pointer to F000:2100h was found.
- The only occurrence of the little-endian word 2100h elsewhere in the image is inside a text string, not a pointer.
- Internal branch targets 2187h and 222Dh are directly confirmed from the test stream.

The exact caller, initial DS/ES/DI/AL values and initial CR0 state remain unresolved. In particular, do not assume ES=0000h merely because the tested offsets are physical-looking.

## 2. First pattern pass — 2100h–222Dh

The aligned stream begins:

```asm
2100  MOV word ptr [0000h],5555h       ; default DS
2106  STOSB                            ; ES:DI, AL
2107  STOSB                            ; ES:DI+1, AL
2108  MOV dword ptr ES:[0100h],FFFFFFFFh
2112  CMP dword ptr ES:[0000h],AAAA5555h
211C  JNE 2187h
2120  MOV dword ptr ES:[0000h],5555AAAAh
212A  MOV dword ptr ES:[0100h],FFFFFFFFh
2134  CMP dword ptr ES:[0000h],5555AAAAh
213E  JNE 2187h
```

The two STOSB operations are caller-dependent; their role is consistent with completing the upper half of the first 32-bit pattern, but the required initial AL and DI values have not been proven.

The stream then compares ES-relative locations against 5555AAAAh and records a two-bit selector in DL:

| Address checked | Selector placed in DL | Branch on alias |
|---|---:|---|
| ES:00800000h | 0 | 2187h |
| ES:00000800h | 2 | 2187h |
| ES:00001000h | 1 | 2187h |
| ES:00002000h | 3 | 2187h |

These are address-alias checks against the base pattern, not ordinary data comparisons.

## 3. High-memory pass — 2187h–222Dh

The continuation repeats the complementary-pattern/sentinel test at ES:04000000h (64 MiB) and ES:04000100h, then checks alias candidates:

| Address checked | Selector placed in DH | Branch on alias |
|---|---:|---|
| ES:04800000h (72 MiB) | 0 | 222Dh |
| ES:04000800h | 2 | 222Dh |
| ES:04001000h | 1 | 222Dh |
| ES:04002000h | 3 | 222Dh |

DH starts at FFh before the 64-MiB pattern test. If the base write/read test fails, or one of the alias comparisons matches unexpectedly, control goes to 222Dh.

## 4. Stack-threaded chipset update — 222Dh onward

At 222Dh the code sets AX=1616h, sets SP=2236h and jumps to 8DCFh. The 8DCFh helper performs indexed I/O through ports 22h/23h (write index, read data, RET into the stack-selected continuation). The stack-threaded continuation at 2236h modifies the returned value and uses 8DDCh to write it back. Additional stack-selected I/O steps follow at 2242h/224Eh.

This is not a normal linear subroutine: SP is deliberately redirected into embedded instruction/data sequences. The first read-modify-write clearly targets chipset index 16h; the complete meaning of the subsequent stack-threaded operations is not yet established.

## 5. Second pattern pass and chipset registers 10h/11h

At 2253h the code repeats the base/sentinel pattern test with the opposite initial dword and stores the low-address alias class in BL. At 22DBh it repeats the 64-MiB/high-address pass and stores the high-address class in BH.

The results are then packed and written:

```asm
2381  AND DX,0F0Fh
2385  MOV AH,DH
2387  SHL AH,4
238A  OR AH,DL
238C  MOV AL,10h
238E  MOV SP,2394h
2391  JMP 8DDCh              ; write chipset index 10h

2396  AND BX,0F0Fh
239A  MOV AH,BH
239C  SHL AH,4
239F  OR AH,BL
23A1  MOV AL,11h
23A3  NOP
23A4  MOV SP,23AAh
23A7  JMP 8DDCh              ; write chipset index 11h
```

Therefore register 10h receives the packed DH:DL alias classifications, and register 11h receives BH:BL. The nibble packing is directly byte-verified; the chipset-specific semantic names for these fields are not yet proven.

## 6. Protected-mode exit sequence

The later stack-threaded stream contains:

```asm
23B6  MOV AX,B823h
23BB  MOV ES,AX
23BD  MOV EAX,CR0
23C0  AND AL,0FEh
23C2  MOV CR0,EAX
23C5  JMP 23C7h
```

This explicitly clears CR0.PE after loading ES with B823h. It is consistent with a protected-mode-to-real-mode transition, but the selector descriptor and the entry-time segment state must be traced before assigning a physical base to ES=B823h.

The later continuation at 23E4h sets SS=0030h and SP=0100h, calls 240Ah/2495h/29EDh, then sets DS=ES=0000h, restores SS=CS and jumps to D9DCh.

## 7. Confirmed facts vs open items

**Confirmed from bytes**
- Two complementary dword patterns are used.
- A sentinel at offset 0100h participates in the alias tests.
- Low-memory alias selectors are accumulated in DL/BL; high-memory selectors in DH/BH.
- The 64-MiB and 72-MiB locations are explicitly probed with 32-bit addresses.
- Packed alias results are written to indexed chipset registers 10h and 11h via ports 22h/23h.
- A later stream clears CR0.PE.

**Still open**
1. The true entry/caller for 2100h and the mechanism that transfers control there.
2. Initial DS, ES, DI and AL values; especially whether ES is a flat/large protected-mode segment.
3. The full stack-threaded operations at 2236h–224Eh and their chipset-register effects.
4. The descriptor associated with selector B823h and the exact protected-mode transition context.
5. The semantic names of chipset register 10h/11h fields.

Do not assign a whole-ROM semantic coverage percentage from these selected windows. This report classifies only the 2100h memory-alias region and its traced continuations.
