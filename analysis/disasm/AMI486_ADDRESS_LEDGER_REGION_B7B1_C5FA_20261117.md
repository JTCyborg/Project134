# AMI486 address-ledger extension: Advanced Setup option catalog B7B1h–C5F9h

Date: 2026-11-17  
ROM: ami486.bin, 65,536 bytes  
SHA-256: 91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b

## 1. Region classification

The previously uncovered B7B1h–C5F9h interval is not a code gap. It is a large Setup data catalog containing a callback-offset table, two contiguous Setup-page text/descriptor blocks, and numerous NUL-terminated labels/help strings. A linear 16-bit decode produces many false branches and calls because the labels and descriptor bytes are being interpreted as opcodes.

The page boundaries are established by executable code:
- The Setup entry at 0BE5h sets E191=B7D0h, E193=BD54h and E195=B7B2h.
- The alternate Setup entry at 0C05h sets E191=BD54h, E193=C5F9h and again sets E195=B7B2h.
Thus B7D0h–BD53h and BD54h–C5F8h are two distinct page data ranges; C5FAh is the next executable entry.

## 2. Callback pointer table at B7B2h

The word at E195 is consumed by the generic option callback dispatcher at 6092h–60BAh:
- it obtains the selected type index from [BX+1Eh], masks it with 7Fh, subtracts one and doubles it;
- loads SI from E195;
- reads the callback offset from [SI+2*index];
- performs a near CALL through CS to that offset while preserving DS/SI/DI/BP.

The 15 little-endian entries at B7B2h–B7CFh are:

| Index | Target | Coverage/status |
|---:|---:|---|
| 0 | 2E74h | already seeded |
| 1 | 2EB4h | already seeded |
| 2 | 86DBh | newly seeded from this confirmed indirect target |
| 3 | 29F6h | newly seeded from this confirmed indirect target |
| 4 | 2AC1h | already seeded |
| 5 | 2B13h | already seeded |
| 6 | 2B4Ch | already seeded |
| 7 | 2B91h | already seeded |
| 8 | 2BD3h | already seeded |
| 9 | 2C1Dh | already seeded |
| 10 | 2C69h | already seeded |
| 11 | 2CCFh | already seeded |
| 12 | 2C84h | already seeded |
| 13 | A505h | already seeded |
| 14 | 0008h | unresolved sentinel/placeholder; not treated as executable code |

The preceding byte at B7B1h is 0Ch. It is retained as a separate data/header byte; its exact meaning is not established. The table itself begins at B7B2h because that exact address is written to E195.

### 2.1 Newly confirmed callback bodies

- 29F6h is a far callback. It saves ES/SI/DI, updates E036h/E066h state, reads the current option configuration from the CS-resident table at 87A9h, calls 8DCFh, updates E046h/E047h/E049h/E050h bitfields, and returns with RETF at 2AB2h.
- 86DBh is a far callback. It obtains the current option value through 83AEh using selector byte CS:B52Ch, masks the result, applies the selected bit operation to E000h-relative state when running from F000h, and returns a status/value through RETF at 873Bh.

These are confirmed indirect callback entries because the B7B2h table is loaded by the 6092h dispatcher. Their full option-label mapping still requires correlating the descriptor type values with the callback indices.

## 3. First Setup page: B7D0h–BD53h

The first page begins with the following labels and option records:
- Typematic Rate Programming
- Typematic Rate Delay (msec)
- Typematic Rate (Chars/Sec)
- Mouse Support Option
- Above 1 MB Memory Test
- Memory Test Tick Sound
- Memory Parity Error Check
- Hit <DEL> Message Display
- Hard Disk Type 47 RAM Area, followed by explanatory help text about the BIOS shadow-RAM requirement
- Wait For <F1> If Any Error
- System Boot Up Num Lock
- Numeric Processor Test
- Weitek Processor
- Floppy Drive Seek at Boot
- System Boot Up Sequence
- System Boot Up CPU Speed
- External Cache Memory
- Internal Cache Memory
- Fast Gate A20 Option
- Turbo Switch Function
- Password Checking Option
- Video ROM Shadow C000,32K and related shadow options

The labels are NUL-terminated and are followed by compact option metadata. The byte sequences immediately following the first records demonstrate the variable-length form:
- 93 80 00 02 01 02
- 93 60 00 04 11 12 13 14
- 93 1C 00 08 1C 1B 1A 19 18 17 16 15
- 11 80 00 02 01 02
- 91 40 00 02 01 02

The first three bytes and count/value tail are retained as opaque per-option metadata until every field is tied to a consumer. Do not label these bytes as executable code or assume all records have the same length.

## 4. Second Setup page: BD54h–C5F8h

The second page begins with “AUTO Config Function” and includes chipset/timing options such as:
- AT Bus Clock Select
- DRAM Read Wait State / DRAM Write Wait State
- SRAM Read Wait State / SRAM Write Wait State
- Cycle Check Point
- Flash ROM Function
- Select C0000-C7FFF / Select C8000-CFFFF
- I/O Recovery Feature / I/O Recovery Period / On-Chip I/O Recovery Function
- Memory Remapping
- Parity Check / Slow Refresh / Hidden Refresh / RAS Active Timeout
- VL Preempt Feature / Hcache Latch / VL Master WB Cycle Restart
- HITM# Sampling Timing / Snoop Filter Miss Feature / KEN# Check Timing
- Cyrix CPU Write Burst Mode / Snoop WB CHOLD operation
- Cache Hit Feature / External and Internal Cache WB/WT features
- Shadow Cacheable
- HITM# to IOCHRDY# delay and non-CPU RAS-CAS delay
- Polling Clock Select / DMA Clock Select
- VL Master Cycle Cache Read/Write
- CPU Reset Clock Select / CPU Reset Dummy Hold
- ISA write/I/O/memory wait-state options
- VL Device Ready Sync Mode
- Delay Internal ADS# Feature
- Cache WR Hit CWE# Pulse Set
- Delay ISA Cycle LDEV# WS
- TAGWE# Delay Rising Timing

This range also contains NUL-terminated explanatory text, including the note that one function is only used in 386 systems. The option labels and help text are mixed with compact metadata records, not a linear code stream.

## 5. Generator update

The candidate generator now classifies:
- B7B1h–B7B2h: one unresolved header byte;
- B7B2h–B7D0h: 15-word option callback table;
- B7D0h–BD54h: first Setup page strings and variable-length option metadata;
- BD54h–C5FAh: second Setup page strings and variable-length option metadata.

The two callback entries 29F6h and 86DBh are added as bounded code windows. The other callback targets were already covered.

## 6. Remaining open items

- Determine the exact meaning of the B7B1h header byte 0Ch.
- Map callback indices to specific option records by tracing the record type byte at +1Eh through the Setup descriptor tables.
- Decode the variable-length option metadata fields without assuming a uniform record size.
- Determine whether 0008h at callback index 14 is an intentional null/sentinel or an alternate low-ROM entry.
- The exact per-option help-string ownership and default-value table references remain to be reconciled.

This region is classified as Setup data with a confirmed callback table; it is not a whole-ROM semantic completion claim.
