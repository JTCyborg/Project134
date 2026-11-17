# AMI486 memory-alias probe and chipset initialization sequence — 2026-11-16

Source: ami486.bin (65,536 bytes), SHA-256 91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b  
Decode: Capstone x86-16 seeded windows, with near-relative targets normalized to 16-bit IP. See ami486_candidate_windows_20261116.txt.

## 1. Memory pattern and alias probes

### 20FCh–2186h stream (first memory-probe continuation)

The code writes alternating 32-bit patterns at the low-memory base and uses a sentinel at offset 0100h:
- 0xAAAA5555
- 0x5555AAAA
- ES:[0100h] = 0xFFFFFFFF

It then compares the expected pattern at:
- ES:[000000h]
- ES:[00800000h] (8 MiB)
- ES:[00000800h] (2 KiB)
- ES:[00001000h] (4 KiB)
- ES:[00002000h] (8 KiB)

The result selector is placed in DL (values 00h, 02h, 01h, 03h) as the code checks the candidate alias locations. These are 32-bit address-size accesses in 16-bit code.

### 2187h / 2253h / 22DBh streams

A second set of tests writes and compares the same patterns at:
- ES:[04000000h] (64 MiB)
- ES:[04000100h] sentinel
- ES:[04800000h] (72 MiB)
- ES:[04000800h]
- ES:[04001000h]
- ES:[04002000h]

The selector is carried in DH or BH. These are explicit 32-bit absolute-address probes. The routine is testing address aliasing and memory-map boundaries, not simply checking a conventional low-memory block.

The callers that establish ES, the actual installed RAM map and the meaning of each selector value remain unresolved. Do not translate these probes directly into a physical-memory size without the caller and chipset register context.

## 2. Stack-threaded chipset I/O

The branches from the pattern tests do not enter ordinary error-report functions. They construct a return stack in the inline bytes and jump into shared port-22h/23h helpers. RET then resumes execution at the crafted inline continuation. This is deliberate stack-threaded control flow.

### Shared indexed-I/O helpers

| Entry | Instructions | Meaning |
|---:|---|---|
| 8DCFh | OUT 22h,AL; delay; IN AL,23h; delay; RET | Read indexed chipset register: AL selects register, returned AL is data |
| 8DDCh | OUT 22h,AL; delay; XCHG AH,AL; OUT 23h,AL; delay; XCHG AH,AL; RET | Write indexed chipset register: AL selects register, AH supplies data |
| 8DEDh | OUT 22h,AL; delay; IN AL,23h; delay; JMP DI | Read variant with indirect continuation |
| 8DFBh | OUT 22h,AL; delay; XCHG; OUT 23h,AL; delay; XCHG; JMP DI | Write variant with indirect continuation |

The delay sequences use JCXZ with zero displacement as short timing gaps. The exact chipset vendor and register meanings are not identified from these bytes alone.

### 222Dh stack-threaded sequence

1. AX=1616h; SP=2236h; JMP 8DCFh.
2. 8DCFh selects register 16h and reads its current value; RET resumes at 2238h.
3. 2238h ORs the returned value with 30h, swaps it into AH, sets SP=2242h and jumps to 8DDCh.
4. 8DDCh writes the modified value back to register 16h; RET resumes at 2244h.
5. 2244h loads AX=4411h, sets SP=224Eh and jumps to 8DDCh.
6. 8DDCh writes 44h to indexed register 11h; RET resumes at 2250h.

This is a confirmed read-modify-write of indexed register 16h (OR 30h), followed by a write of 44h to indexed register 11h.

### 2381h stack-threaded sequence

The routine masks DX with 0F0Fh, packs DH/DL into AH, sets AL=10h, prepares SP=2394h and jumps to 8DDCh. The return resumes at 2396h, where the code masks the packed value, constructs a second byte, selects register 11h and writes it through 8DDCh. The following sequence at 23AAh–23E1h continues through further stack-crafted return points, clears CR0.PE, and jumps to F66Eh.

This links the memory-probe result path to chipset register programming and a protected-mode-to-real-mode transition. The exact register 10h/11h field meanings and the later 23AAh/23B6h control flow still require caller-aware validation.

## 3. What can be concluded

- The BIOS tests aliasing at 8 MiB and 64 MiB boundaries, as well as at low offsets 2 KiB/4 KiB/8 KiB.
- The result values in DL/DH/BL/BH are consumed by stack-threaded chipset register updates.
- Ports 22h/23h form an indexed-register interface in these routines.
- 8DCFh and 8DDCh are shared indexed-register read/write primitives.
- The path at 23B6h clears CR0.PE and proceeds through a real-mode transition path at F66Eh.

## 4. Open questions

1. Find the caller/entry that establishes ES, DS, DI and the initial patterns for 2100h/2253h.
2. Identify the chipset family and map indexed registers 10h, 11h and 16h using board/BIOS context.
3. Trace the meaning of DL/DH/BL/BH selector values and how they alter the memory map.
4. Resolve the return-stack continuations at 23AAh, 23B6h, 23CEh and the F66Eh target.
5. Determine whether the memory alias tests are sizing RAM, selecting a memory bank configuration, or validating a preconfigured map.

No physical RAM capacity or whole-ROM semantic coverage percentage is claimed from these routines alone.


## 5. Raw-entry and segment-context audit — corrected 2026-11-17

The earlier 2026-11-16 alignment note incorrectly treated 2100h as the start of an independent stream. It is withdrawn. The actual stack-threaded return chain is:
- 20F4h: `MOV SP,20FAh`
- 20F7h: `JMP 8DDCh`
- 20FAh–20FBh: word `20FCh`
- RET from 8DDCh resumes at 20FCh.

The aligned entry and first instructions are:

```asm
20FC  B2 FF                         MOV DL,FFh
20FE  26 66 C7 06 00 00 55 55 AA AA  ES: MOV DWORD PTR [0000h],AAAA5555h
2108  26 66 C7 06 00 01 FF FF FF FF  ES: MOV DWORD PTR [0100h],FFFFFFFFh
2112  26 66 81 3E 00 00 55 55 AA AA  ES: CMP DWORD PTR [0000h],AAAA5555h
211C  0F 85 67 00                    JNE 2187h
```

The GDT pseudo-descriptor at 2068h contains limit 0017h and base 0F2070h. The GDT at 2070h contains a null descriptor, a base-zero writable 32-bit 4-GiB data descriptor at selector 0008h, and a base-zero writable 64-KiB data descriptor at selector 0010h. The code at 20DAh sets CR0.PE, loads this GDT, and loads ES=0008h before the probe. Thus the first pattern store is an operand-size-prefixed 32-bit write through ES to the flat segment. The opcode byte at 2100h belongs to the instruction beginning at 20FEh; 2100h is not an entry point.

The first pattern is not a DS:[0000h] word store followed by two STOSB instructions. The previous claim about caller-dependent AL=AAh and DI=0002h for those bytes is withdrawn. The first dword store is explicitly `ES:[0000h] = AAAA5555h`; the sentinel is `ES:[0100h] = FFFFFFFFh`.

The full setup path into this stream is now byte-confirmed through stack return words:
`D9D9h -> 1AFBh -> 1B06h -> 1B2Ch -> 208Dh -> 2098h -> 20C4h -> 20CEh -> 20DAh -> 20FCh`.
The CMOS B3h table selection at 1AFBh/1B06h and the indexed-register list at 2098h are detailed in `AMI486_ADDRESS_LEDGER_REGION_19F8_20FB_20261117.md`.

The result-selector order remains exact: DL=00h before testing ES:00800000h; DL=02h before ES:00000800h; DL=01h before ES:00001000h; DL=03h before ES:00002000h. The high-address pass similarly sets DH=00h/02h/01h/03h before checking ES:04800000h, ES:04000800h, ES:04001000h and ES:04002000h. The second pattern pass repeats this with BL/BH.

At 23B6h the continuation loads AX=B823h into ES, reads CR0, clears bit 0 (PE) and writes CR0 back. The selector descriptor/base and the initial protected-mode ES value are not known from that local stream. The later 23E4h continuation sets SS=0030h/SP=0100h, calls 240Ah/2495h/29EDh, then sets DS=ES=0000h and SS=CS before jumping to D9DCh. The segment setup and actual installed RAM map remain partly caller-dependent.

The previous section's stack-threaded decode remains authoritative: 222Dh reads indexed chipset register 16h, ORs 30h and writes it back, then writes 44h to register 11h; 2381h/2396h pack the probe selectors into chipset registers 10h/11h. This report does not claim a physical RAM capacity or whole-ROM semantic coverage percentage.


## 6. Stack-return alignment correction at 2381h–23DCh (2026-11-17)

The earlier prose that treated 23AAh and 23B6h as code continuations is withdrawn. They are stack-return words:
- 238Eh sets SP=2394h and jumps to 8DDCh; 2394h–2395h contains 2396h.
- 23A4h sets SP=23AAh and jumps to 8DDCh; 23AAh–23ABh contains 23ACh.
- 23B0h sets SP=23B6h and jumps to 8DDCh; 23B6h–23B7h contains 23B8h.
- 23C8h sets SP=23CEh and jumps to F66Eh; 23CEh–23CFh contains 23D0h.
- 23D4h sets SP=23DAh and jumps to 552Dh; 23DAh–23DBh contains 23DCh.

The aligned streams are 2396h (ALi register 10h), 23ACh (ALi register 11h), 23B8h (ES=0010h, clear CR0.PE, then A20 disable), 23D0h (2-KiB 552Dh pattern test because BX=0400h words), and 23DCh (tests returned ZF and enters the 23E4h POST continuation on success). The helper at 552Dh is variable-length: it uses BX as the number of words and verifies patterns 8080h, 5555h, 3333h and 0000h. It is not intrinsically a 64-KiB test.

The 23CEh–29F5h continuation and the full shadow/memory-test chain are documented in `AMI486_ADDRESS_LEDGER_REGION_23CE_29F6_20261117.md`.
