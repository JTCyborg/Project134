# AMI486 semantic map — phase 35 (2026-11-16)

## 1. Indexed ALi access helpers and call-site audit

The ROM has separate helpers:
- 8DCF: OUT 22h,AL; IN AL,23h; RET — select an indexed register and read its value.
- 8DDC: OUT 22h,AL; XCHG AL,AH; OUT 23h,AL; XCHG AL,AH; RET — write AH to the selected register.
- 8DED is another indexed-read trampoline ending at 8DF3; 8DFB is the corresponding write trampoline ending at 8E03. These are used by stack-return/continuation sequences as well as direct calls.

This confirms the table decoder's effective write semantics: for 8DDC the index is AL and data is AH. The 8750h table loop deliberately constructs that register pair after decoding each four-byte record.

## 2. CMOS-driven read/modify/write block at 1C85h–1DD0h

The manual POST configuration path first checks CMOS 8Eh bit 6/7 at 1C64h–1C6Fh; if either is set, it skips this block and jumps to 1DD3h. Otherwise, when AUTO Config is disabled, it reads CMOS values and merges selected bits into existing ALi registers. The following table records the source CMOS byte, mask applied to the CMOS value, ALi register, mask applied to the old ALi value, and resulting formula.

| CMOS source | CMOS mask retained | ALi index | Old ALi mask retained | Result |
|---|---:|---:|---:|---|
| 50h | 07h | 20h | F8h | (old & F8h) | (CMOS50 & 07h) |
| 47h | 83h | 17h | 7Ch | (old & 7Ch) | (CMOS47 & 83h) |
| 42h | E0h | 12h | 1Fh | (old & 1Fh) | (CMOS42 & E0h) |
| 44h | A0h | 14h | 5Fh | (old & 5Fh) | (CMOS44 & A0h) |
| 47h | 7Ch | 17h | 83h | (old & 83h) | (CMOS47 & 7Ch) |
| 4Eh | 0Ch | 1Eh | F3h | (old & F3h) | (CMOS4E & 0Ch) |
| 4Ah | 30h | 1Ah | CFh | (old & CFh) | (CMOS4A & 30h) |
| 50h | F0h | 20h | 0Fh | (old & 0Fh) | (CMOS50 & F0h) |
| 51h | 48h | 21h | B7h | (old & B7h) | (CMOS51 & 48h) |
| 52h | F7h | 22h | 08h | (old & 08h) | (CMOS52 & F7h) |
| 55h | CFh | 25h | 30h | (old & 30h) | (CMOS55 & CFh) |
| 57h | 01h | 27h | FEh | (old & FEh) | (CMOS57 & 01h) |
| 57h | 30h | 27h | CFh | (old & CFh) | (CMOS57 & 30h) |

The register 17h update is intentionally split into two passes with disjoint masks. Register 20h is likewise updated in two passes, low nibble and high nibble. Register 27h receives two separate CMOS57h fields. The code preserves unrelated bits rather than replacing whole registers.

The code proves which CMOS bits are transferred to which ALi register bits. It does not prove human-readable Setup labels for those bitfields.

## 3. AUTO Config branch

At 1C72h the BIOS calls 29EDh to test AUTO Config. If enabled, it calls:
- 8F12h (memory/clock detection helper);
- 2537h (derives and writes ALi register 20h using the 87B5h lookup table and register 20h's low three bits);
- 256Ah (derives and writes ALi register 17h using the 87ADh lookup table).

If AUTO Config is disabled, the BIOS follows the CMOS-driven RMW sequence above. This makes the two configuration paths explicit: auto-derived settings vs CMOS-preserved/manual bitfields.

The later POST A4 block at 1F47h has a related but distinct branch: AUTO Config calls 8F12h, 2588h and 25A6h; manual mode uses CMOS 46h,49h,55h,42h,48h,4Ah,57h to update ALi registers 16h,19h,25h,12h,18h,1Ah,27h. Do not merge this A4 set with the 1C85h–1DD0h sequence; they are separate POST stages.

## 4. Additional chipset controls and option-ROM shadowing

- 1C50h reads ALi register 13h, ANDs it with C1h, then writes it back. It clears bits 1–5 while preserving bits 7 and 0.
- 1E4Bh and 1E5Fh select ALi register 14h and set/clear bit 1 respectively.
- 1E78h conditionally sets ALi register 14h bit 3 when the OEM/setup-record check at 8300h succeeds.
- 2457h reads ALi register 13h and ORs a caller-supplied mask; it then updates register 14h to clear low two bits and set bit 1, copies a 32KB segment to itself (REP MOVSW, 4000h words), and finally changes register 14h to clear bit 1 and set bit 0. This is the option-ROM shadow-copy path described in earlier phases.
- 1A90h reads ALi registers 12h and 13h and uses their bits to adjust the BIOS memory-size value at E017h. This is a normalization of the reported memory size, not a write to chipset registers.

## 5. CMOS protection gate and hook

At 1C5Eh the BIOS calls the hook pointer at CS:82E2h. Stock value is 19AEh (RET). It then reads CMOS 8Eh; if bits C0h are set, it skips the normal 1C72h–1DD0h chipset configuration path. This is a distinct protection/configuration gate from the AUTO Config bit in CMOS B6h.

## 6. Implementation-relevant conclusions

An emulator implementing the BIOS chipset interface needs both indexed read and write semantics, not just the write helper used by the table loop. The manual path performs masked read/modify/write operations and relies on preservation of unrelated register bits. A correct model must preserve those bits across each operation. The CMOS-to-register masks above are directly recoverable from the BIOS and can be implemented without inventing semantic register names.

Unknown: documented ALi M1429 meanings for each field, electrical timing effects, and the precise labels of the Setup options that populate all CMOS fields. These require an authoritative chipset data sheet or independently validated emulator source.
