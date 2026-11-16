# AMI486 semantic map — phase 31 (2026-11-16)

## 1. CS:[8281h].6 — no in-ROM initializer found

The stock byte at CS:8281h is 00h (data bytes at 8280h begin `2F 00 E7 03...`). The full linear disassembly contains reads/tests of bit 6 at:

- 5272h, 5478h
- 8B11h, 8BE9h, 8C41h, 8C4Eh, 8CA6h
- 9150h, 91FBh
- D657h, D724h
- F06Ah (without an explicit CS override)

No direct static write to CS:8281h was found in the complete linear listing. No instruction with an absolute memory destination 8281h was found either. Therefore the available ROM evidence does not identify an in-ROM initializer or setter for this flag. Since the stock byte is zero, all those bit-6 branches are inactive in the unmodified ROM unless another actor patches/initializes the RAM-visible code/data segment at runtime. Do not claim the bit is set by a BIOS CMOS option: no such path has been demonstrated.

The related byte CS:8280h is separately tested at 1C0Ch; it is not the same flag.

## 2. The 20C9h A20/memory probe is reached from POST block 1B20h–1B58h

The only direct near transfer into 208Dh is an unconditional jump at 1B58h. The preceding block performs the following operations:

- 1B20h–1B2Ch: iterates a word table through CS:SI and writes each value through the ALi indexed-register helper (8DDCh), using stack-return trampolines.
- 1B2Eh–1B42h: writes FC to port 61h, zero to port 8Fh, and 54h to PIT control port 43h.
- 1B46h–1B4Ah: reads CS:[8286h] and writes it to port 41h.
- 1B50h–1B56h: fills 400h bytes at ES:DI with AL.
- 1B58h jumps to 208Dh.

At 208Dh the code selects ALi register 03h, scans a table from 8750h through 87A4h in word steps, subtracts 30h from each entry's low byte, skips entries whose adjusted value is 26h, and writes the selected table values through 8DDCh. At 20C6h it arranges a return trampoline through 8DDCh and tail-jumps to F66Ah at 20C9h to enable A20.

The subsequent 20DAh–23C2h sequence enters protected mode, uses selector 4410h, writes and verifies complementary 32-bit patterns at several offsets, derives a compact result from successful/failing address tests, and writes the result through ALi registers 10h and 11h. It clears CR0.PE at 23BDh–23C2h and disables A20 at 23CBh. The routine then resumes ordinary POST work at 23CEh and proceeds through 240Ah, 2495h, and 29EDh.

This establishes that the A20-bracketed protected-mode memory test/configuration is embedded in the POST path reached from 1B58h. It does not yet identify the external entry/caller of the larger 1B20h block or the board-specific meanings of ALi registers 03h, 10h, and 11h.

## 3. 20C9h is not independently called

No direct CALL/JMP instruction targets 20C9h, 20DAh, or 23CEh. Entry into the block is by the direct jump 1B58h -> 208Dh; the 20C9h transfer to F66Ah is part of that fall-through routine. The ALi helper trampolines use MOV SP, return-address / JMP 8DDCh patterns, so a conventional call-reference search alone misses the internal helper edges.

## 4. What remains unknown

- The upstream entry into 1B20h and the caller's purpose.
- Whether CS:[8281h].6 is modified by an external patch, option ROM, chipset hook, or a different execution view; the stock ROM's static code does not set it.
- The board-specific semantics of ALi registers 03h, 10h, and 11h.
- The precise memory-map interpretation of each tested address and how the final register values encode detected memory boundaries.

## 5. Evidence limits

This report uses the full 64 KiB linear 16-bit decode. It is sufficient to enumerate direct references in that decode, but it is not a complete control-flow graph. Computed far/near jumps, callbacks, and alternate decode streams may add paths not represented by direct xrefs.
