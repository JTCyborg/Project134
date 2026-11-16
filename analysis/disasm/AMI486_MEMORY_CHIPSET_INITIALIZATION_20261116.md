# AMI486 memory-alias probe and chipset initialization sequence — 2026-11-16

Source: ami486.bin (65,536 bytes), SHA-256 91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b  
Decode: Capstone x86-16 seeded windows, with near-relative targets normalized to 16-bit IP. See ami486_candidate_windows_20261116.txt.

## 1. Memory pattern and alias probes

### 2100h stream

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
