# AMI486 semantic map — phase 34 (2026-11-16)

## 1. Full decode of the 8750h–87A3h table

The POST loop at 2096h–20C4h consumes 84 bytes as 21 records of four bytes. For each record it:
- reads the first word; subtracts 30h from its low byte and saves the result in BL;
- reads the second word; replaces AL with BL, retaining the second word's high byte in AH;
- calls the ALi indexed-write helper 8DDCh.

The helper writes AL to index port 22h and AH to data port 23h. Therefore the effective ALi index is byte0-30h, and the effective value is byte3. Bytes 1 and 2 are not used by this loop. An effective index of 26h is skipped.

| Record offset | Raw bytes | Effective ALi index | Value | Action |
|---|---|---:|---:|---|
| 8750 | 36 FF 01 00 | 06h | 00h | write |
| 8754 | 40 FF 20 F0 | 10h | F0h | write |
| 8758 | 41 FF 0A FF | 11h | FFh | write |
| 875C | 42 FF 10 00 | 12h | 00h | write |
| 8760 | 43 FF 1F 00 | 13h | 00h | write |
| 8764 | 44 FF 0F 00 | 14h | 00h | write |
| 8768 | 45 FF 00 00 | 15h | 00h | write |
| 876C | 46 FF 0F 00 | 16h | 00h | write |
| 8770 | 47 FF 69 3A | 17h | 3Ah | write |
| 8774 | 48 FF 01 01 | 18h | 01h | write |
| 8778 | 49 FF 08 60 | 19h | 60h | write |
| 877C | 4A FF 40 00 | 1Ah | 00h | write |
| 8780 | 4E FF 00 0C | 1Eh | 0Ch | write |
| 8784 | 50 FF 21 40 | 20h | 40h | write |
| 8788 | 51 FF 00 00 | 21h | 00h | write |
| 878C | 52 FF 64 00 | 22h | 00h | write |
| 8790 | 53 FF 5B 5F | 23h | 5Fh | write |
| 8794 | 54 FF 88 00 | 24h | 00h | write |
| 8798 | 55 FF 65 C5 | 25h | C5h | write |
| 879C | 56 FF 00 00 | 26h | 00h | skip |
| 87A0 | 57 FF 30 32 | 27h | 32h | write |

This yields 20 actual writes and one skipped record. In particular, ALi registers 10h–1Ah are configured as a contiguous timing/configuration block except the table's later discontinuity at 1Bh–1Dh. Register 1Eh is also written, followed by 20h–25h and 27h. This is an observation about index coverage only; it is not yet a semantic register map.

## 2. Important distinction: raw record layout vs effective write

The table is not a flat sequence of ALi index/value pairs. Each record is:
- byte 0: encoded index (subtract 30h);
- byte 1: ignored by the current loop;
- byte 2: ignored by the current loop;
- byte 3: written value.

All records currently have byte1=FFh. This strongly suggests a fixed record format or reserved/unused field, but the BIOS code examined here does not read that byte. Byte2 varies and is likewise ignored by this loop. Do not assign meaning to either byte without finding another consumer.

## 3. Relation to the CMOS-B3 selected tables

This 21-record table is applied at 208Dh after the small B3h-selected profile table at 1B0Fh–1B2Ch and after PIT/port61 setup. The B3h-selected tables are separate direct 16-bit index/value words. The 8750h records use the subtract-30h encoding described above.

The execution order is therefore:
1. read CMOS B3h;
2. apply either the 8E4Eh–8E61h profile (B3h bit2=1) or 8E76h–8E79h profile (bit2=0);
3. configure port 61h, port 8Fh, PIT control 43h and channel 1 data 41h;
4. fill 400h bytes at ES:0000;
5. apply the 8750h table (20 ALi writes; index 26h skipped);
6. enable A20 and enter the protected-mode memory alias test.

## 4. External cross-check and limits

The MAME machine entry identifies ALi M1429 A1 / M1431 A2 386 motherboard families, but its machine driver is marked preliminary and does not provide a trustworthy semantic decode of these indexed registers. Therefore this phase records the exact BIOS write sequence, not guessed labels such as DRAM timing, cache, shadow, or refresh.

The Project124 source comparison has not yet produced an independently verified register-name mapping for these exact indices. That comparison remains open. The current BIOS evidence is sufficient to implement the byte-accurate write sequence in an emulator, but not to claim electrical or chipset-level meaning for each register.

## 5. Evidence

- 208Dh–20C4h: table pointer, count, selector transform, skip condition, value extraction, indexed write trampoline.
- 8DDCh–8DECh: index/data port write implementation.
- 8750h–87A3h: 21 four-byte records reconstructed from the linear decode's instruction byte streams.
- 1AFBh–1B58h: CMOS B3h profile selection and ordering before the 8750h table.
