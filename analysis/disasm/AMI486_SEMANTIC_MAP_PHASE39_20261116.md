# AMI486 semantic map — phase 39 (2026-11-16)

## Scope

This phase corrects the category-7 CPU-speed display interpretation from phase 38, decodes the adjacent L2-cache-size lookup at 19FBh–1A1Ah, and records an additional CMOS B3h profile-selection path at POST A1h.

## 1. CPU speed category 7: effective value is 32

The display routine at 1A24h reads BDA 0040:E2h, adds the category byte to the address 19C2h, reads the selected byte, zero-extends it, and passes it to the numeric printer at 09FDh.

The bytes at 19C2h–19C9h are:

`10 14 19 21 28 32 42 20`

Thus the lookup is not seven bytes long from the point of view of the executable routine. For category 7, the effective lookup address is 19C9h and the byte there is 20h, decimal 32. The following label is then selected at 19DCh or 19ECh, so category 7 is displayed as **32 MHz CPU Clock** or **32 MHz DX2 CPU**, according to CMOS B3h bit 1.

19C9h is also the leading space of the separate NUL-terminated string " KB CACHE MEMORY" used by the preceding cache-display routine. This is a data-layout overlap/alias, not an out-of-range read. The code demonstrably prints 32; whether the alias was deliberate or a firmware layout accident cannot be established from the bytes alone.

Correction to phase 38: remove the claim that category 7 has no numeric display value. Its effective displayed value is 32.

## 2. L2 cache display table at 19B0h

At 19FBh the BIOS reads ALi indexed register 18h. If bit 1 is clear, it skips the cache-size line. If bit 1 is set:

1. It masks AL with 70h.
2. Shifts right by 3, producing byte offsets 00h, 02h, 04h, 06h, 08h, 0Ah, 0Ch or 0Eh.
3. Adds that offset to 19B0h.
4. Reads a word from the resulting table entry and prints it through 09FDh.
5. Prints the suffix string at 19C9h: " KB CACHE MEMORY".

The eight little-endian words at 19B0h–19BFh, in selector order, are:

| ALi 18h bits 6:4 | Table address | Word | Decimal display |
|---:|---:|---:|---:|
| 000b | 19B0h | 0020h | 32 KB |
| 001b | 19B2h | 0080h | 128 KB |
| 010b | 19B4h | 0100h | 256 KB |
| 011b | 19B6h | 0200h | 512 KB |
| 100b | 19B8h | 0040h | 64 KB |
| 101b | 19BAh | 0100h | 256 KB |
| 110b | 19BCh | 0200h | 512 KB |
| 111b | 19BEh | 0400h | 1024 KB |

The words are directly established by the ROM bytes. The table proves the BIOS's displayed cache-size choices, but it does not independently prove the physical cache organization or the hardware meaning of ALi register 18h bitfields.

The final word at 19C0h is 0000h and is not selected by the 70h mask after the shift; the CPU-speed byte table begins at 19C2h.

## 3. Additional CMOS B3h mode-table selection at POST A1h

At 1EC8h–1F18h, POST A1h performs the following sequence:

- Calls 2850h and 26F9h, then reads CMOS B3h and emits its value to POST port 80h.
- Executes SMSW AX and tests AH. If AH is nonzero, it skips the B3h-selected table block and continues at 1F18h.
- If AH is zero, tests B3h mask 0Ch. If both bits 2 and 3 are clear, it skips the table block.
- If either bit is set, it preserves the B3h value in DL and dispatches through 8CCDh to a table walker.
- Bit 2 selects the word list 8E62h–8E75h. If bit 2 is clear (therefore bit 3 is the set selector in this branch), it selects 8E7Ah–8E7Dh.
- Each selected word is passed to 8DDCh, which writes the pair through the ALi indexed-register interface.

This is another consumer of CMOS B3h bits 2–3, distinct from the B3h bit-2 row-bank selection in 25C4h and the B3h bits-2/3 gated writes at 1A60h. Do not infer that the selected lists represent CPU families or specific chipset modes without external documentation.

## Confirmed vs. unresolved

Confirmed:
- CPU category 7 reads byte 20h at 19C9h and is printed as decimal 32 with the CPU Clock/DX2 label.
- 19C9h is also the leading space of the cache suffix string used by the preceding routine.
- ALi register 18h bit 1 gates cache-size display; bits 6:4 select one of eight words at 19B0h–19BEh.
- The eight displayed cache-size values are 32, 128, 256, 512, 64, 256, 512 and 1024 KB.
- POST A1h uses CMOS B3h bits 2–3 to select one of two small ALi index/value lists when SMSW AH is zero.

Unresolved:
- Whether the 19C9h overlap was intentional.
- Exact hardware meaning of ALi register 18h bit 1 and bits 6:4; only the BIOS's read and display behavior is established.
- Hardware/board meaning of the two B3h-selected ALi word lists.

## Reproducibility

Primary listing: `analysis/disasm/ami486_full_linear_16bit.disasm.txt`.
ROM SHA-256: `91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b`.
Key ranges: 19B0h–1A1Ah, 1EC8h–1F18h, 19C2h–19F9h.
