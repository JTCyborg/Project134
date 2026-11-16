# AMI486 semantic map — phase 32 (2026-11-16)

## 1. POST memory setup tables at 8E4Eh / 8E76h

The block at 1AFBh–1B58h begins by arranging a return trampoline at 1B04h and jumping to EE94h with AL=B3h. EE94h is the protected CMOS read helper. On return, AL is the CMOS B3h value.

At 1B12h the code tests AL bit 2:
- If bit 2 is set, SI=8E4Eh and CX=8E62h.
- If bit 2 is clear, SI=8E76h and CX=8E7Ah.

The selected words are then loaded from CS:[SI] and written through the ALi indexed-register helper 8DDCh using the stack-return trampoline at 1B24h–1B2Ah. The loop at 1B20h–1B2Ch advances by words and decrements CX by LOOP.

Important correction: this is not the same table at 8750h–87A4h used by the later 208Dh setup loop. These are two separate tables with different selectors and purposes. The 8E4Eh/8E76h selection is controlled by CMOS B3h bit 2.

## 2. What happens after the ALi table writes

After the table loop:
- Writes FCh to port 61h.
- Writes 00h to port 8Fh.
- Programs PIT control port 43h with 54h.
- Loads CS:[8286h] and writes it to port 41h.
- Fills 400h bytes at ES:0000 with the resulting AL value.
- Jumps to 208Dh.

The 208Dh block separately selects ALi register 03h, iterates the word table 8750h–87A4h, transforms each entry's low byte by subtracting 30h, skips entries whose adjusted low byte is 26h, and writes the selected values via 8DDCh. It then reaches 20C9h and enables A20 before the protected-mode address test.

This confirms two distinct chipset-configuration stages before the memory probe: a CMOS-B3-selected small table at 8E62h/8E76h, followed by a larger 8750h table at 208Dh.

## 3. Interpretation of the address-test result encoding

The protected-mode probe performs two closely related passes. The first stores per-boundary results in DL and DH; the second stores corresponding results in BL and BH. Each byte is initialized to FFh and may be replaced by one of 00h, 01h, 02h, 03h, or 04h depending on which address alias/collision test fails first.

The tested low-memory offsets are 00000800h, 00001000h, and 00002000h against a base pattern at offset 0. The high-memory pass repeats the same tests at 04000800h, 04001000h, and 04002000h against base 04000000h; it also checks the 04800000h address. These are alias/collision probes: the code writes a signature at the base and checks whether another address reads the same signature, which would indicate aliasing rather than an independent location.

At 2381h the code masks DX with 0F0Fh, packs DH into the high nibble and DL into the low nibble of AH, and writes the result to ALi indexed register 10h. It then merges the second pass's BL/BH result into AL and writes ALi indexed register 11h. The exact physical address decoding and semantic names of registers 10h/11h are not established by the ROM alone.

Caution: the values 0..4 are ordinal outcomes of the probe branches, not directly documented megabyte counts. FFh is the initial/no-early-collision marker. Do not translate these into installed-memory sizes without decoding the ALi register map or comparing a verified chipset implementation.

## 4. Entry point limitation

No direct near CALL/JMP reference to 1B20h, 1AFBh, or 1B04h was found in the linear listing. The CMOS read trampoline at 1AFBh uses `mov sp,1B04h; jmp EE94h`, so the return from EE94h resumes at 1B04h and falls through the table selection. This proves the local entry/return mechanics but does not identify the upstream control-flow edge that first reaches 1AFBh. The initial entry may be a computed transfer or a distinct decode stream; that remains open.

## 5. Confirmed findings

- 8E4Eh/8E76h is a separate CMOS-B3-bit2-selected ALi configuration table.
- The table is written via 8DDCh before port-61/PIT setup and before the later 8750h table.
- The memory test encodes four probe-result bytes across ALi registers 10h/11h; values are ordinal branch results, not yet verified capacities.
- The high-memory probe explicitly tests 64 MiB base and 72 MiB alias-related address (04000000h and 04800000h), plus offsets 800h/1000h/2000h.
- No direct conventional xref to the start of the 1AFBh trampoline was found; upstream entry remains unresolved.
