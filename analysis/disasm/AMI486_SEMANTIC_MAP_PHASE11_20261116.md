# AMI486 semantic map — phase 11 (2026-11-16)

## Scope

Decoded the stock Setup record/string areas consumed by the page handlers from phase 10:

- Advanced CMOS page: `B7D0–BD53` (handler `0BDE`).
- Advanced CHIPSET page: `BD54–C5F8` (handler `0C05`).

The bytes below are ROM-resident Setup descriptors, not the separate 81-entry CMOS-application table at `873C–887F`, and not ALi1429 indexed-register records. The page ranges are established by the handler's `E191/E193` start/end assignments. Names and help strings are literal ROM text.

## Record layout evidence

Most ordinary records have this visible shape:

`NUL-terminated label | CMOS/index byte, mask byte, flags byte, option-count byte, option bytes...`

The fields are reported as raw descriptor bytes. Do not assume the index byte is necessarily a CMOS register for every record: some records describe special selectors or chipset functions, and the BIOS has separate consumers. The option bytes are encoded selector values, not necessarily user-visible numeric values. Several records carry extra help strings or multi-line explanatory text after their descriptor.

## Advanced CMOS page: B7D0–BD53

| Label offset | Setup item | Descriptor bytes after label NUL | Notes |
|---:|---|---|---|
| B7D0 | Typematic Rate Programming | `93 80 00 02 01 02` | Two encoded choices |
| B7F2 | Typematic Rate Delay (msec) | `93 60 00 04 11 12 13 14` | Four encoded choices |
| B811 | Typematic Rate (Chars/Sec) | `93 1C 00 08 1C 1B 1A 19 18 17 16 15` | Eight encoded choices |
| B835 | Mouse Support Option | `11 80 00 02 01 02` | Two choices |
| B85D | Above 1 MB Memory Test | `91 40 00 02 01 02` | Two choices |
| B87F | Memory Test Tick Sound | `91 20 00 02 01 02` | Two choices |
| B8A1 | Memory Parity Error Check | `91 10 00 02 01 02` | Two choices |
| B8C3 | Hit <DEL> Message Display | `91 08 00 02 01 02` | Two choices |
| B8E5 | Hard Disk Type 47 RAM Area | `91 04 80 02 0D 0E` | Help text explains RAM use when BIOS shadow RAM is disabled |
| B963 | Wait For <F1> If Any Error | `91 02 00 02 01 02` | Two choices |
| B982 | System Boot Up Num Lock | `91 01 00 02 07 08` | Two encoded choices |
| B9A4 | Numeric Processor Test | `B5 01 01 00` | Descriptor has no option tail |
| B9C7 | Weitek Processor | `2D 80 00 02 03 04` | Two choices |
| B9E6 | Floppy Drive Seek At Boot | `AD 40 00 02 01 02` | Two choices |
| BA08 | System Boot Up Sequence | `AD 20 00 02 10 0F` | Two encoded choices |
| BA2A | System Boot Up CPU Speed | `AD 10 00 02 05 06` | Two encoded choices |
| BA4C | External Cache Memory | `AD 08 00 02 01 02` | Two choices |
| BA6E | Internal Cache Memory | `AD 04 02 00` | Special descriptor; no option tail |
| BA91 | Fast Gate A20 Option | `2D 02 00 02 01 02` | Two choices |
| BAB0 | Turbo Switch Function | `2D 01 00 02 01 02` | Two choices |
| BAD2 | Password Checking Option | `B4 40 00 02 0B 0C` | Two encoded choices |
| BAF4 | Video ROM Shadow C000,32K | `B5 04 00 02 01 02` | Shadow-region option |
| BB16 | Video ROM Shadow C400,16K | `35 02 00 02 01 02` | Shadow-region option |
| BB38 | Adaptor ROM Shadow C800,32K | `B4 20 00 02 01 02` | Shadow-region option |
| BB5A | Adaptor ROM Shadow CC00,16K | `34 10 00 02 01 02` | Shadow-region option |
| BB7C | Adaptor ROM Shadow D000,32K | `B4 08 00 02 01 02` | Shadow-region option |
| BB9E | Adaptor ROM Shadow D400,16K | `34 04 00 02 01 02` | Shadow-region option |
| BBC0 | Adaptor ROM Shadow D800,32K | `B4 02 00 02 01 02` | Shadow-region option |
| BBE2 | Adaptor ROM Shadow DC00,16K | `34 01 00 02 01 02` | Shadow-region option |
| BC04 | Adaptor ROM Shadow E000,32K | `B5 80 00 02 01 02` | Shadow-region option |
| BC26 | Adaptor ROM Shadow E400,16K | `35 40 00 02 01 02` | Shadow-region option |
| BC48 | Adaptor ROM Shadow E800,32K | `B5 20 00 02 01 02` | Shadow-region option |
| BC6A | Adaptor ROM Shadow EC00,16K | `35 10 00 02 01 02` | Shadow-region option |
| BC8C | System ROM Shadow F000,64K | `35 08 00 02 01 02` | System-ROM shadow option |
| BCAE | Shadow RAM Option | `35 0E 00 08 01 00 00 ...` | Eight-choice descriptor; the full option tail needs consumer-level interpretation |
| BCD8 | Video ROM Shadow | `35 06 00 04 01 00 00 02` | Four-choice descriptor |
| BCFC | BootSector Virus Protection | `B4 80 83 00` | Special descriptor followed by explanatory text: disable for FORMAT operations |

The B8E5, BCFC and related explanatory strings are help/description payloads, not additional Setup item labels. The B8E5 help says that if BIOS shadow RAM is disabled, the RAM area is used for the hard-disk type-47 parameter table. The BCFC help explicitly warns that BootSector Virus Protection should be disabled for FORMAT operations.

## Advanced CHIPSET page: BD54–C5F8

| Label offset | Setup item | Descriptor bytes after label NUL | ROM help / interpretation |
|---:|---|---|---|
| BD54 | AUTO Config Function | `B6 01 84 00` | Help says enabling AUTO sets the four items below automatically |
| BE1E | AT Bus Clock Select | `D0 07 05 00` | First AUTO-controlled item |
| BE3E | DRAM Read Wait State | `C6 03 06 00` | AUTO-controlled item |
| BE5E | DRAM Write Wait State | `C6 0C 07 00` | AUTO-controlled item |
| BE7E | SRAM Read Wait State | `C9 40 08 00` | AUTO-controlled item |
| BE9E | SRAM Write Wait State | `C9 20 09 00` | AUTO-controlled item |
| BEBE | Cycle Check Point | `C7 03 0A 00` | Fourth item in AUTO help list (the displayed list groups DRAM/SRAM waits as items 2–3) |
| BEDE | Flash ROM Function | `42 20 0B 00` | Parent/selector descriptor |
| BEFE | Select C0000–C7FFF | `42 40 00 02 01 02` | Two choices |
| BF1D | Select C8000–CFFFF | `42 80 00 02 01 02` | Two choices |
| BF3F | I/O Recovery Feature | `D2 01 80 02 01 02` | Two choices; help explains the period cannot be changed while disabled |
| BFA6 | I/O Recovery Period | `D2 F0 0C 00` | Selector/period descriptor |
| BFC6 | On-Chip I/O Recovery Funct. | `52 02 00 02 01 02` | Two choices |
| BFE5 | Memory Remapping | `C2 04 00 02 01 02` | Two choices |
| C007 | Parity Check | `C7 04 00 02 01 02` | Two choices |
| C029 | Slow Refresh | `D5 30 00 04 59 5A 5B 5C` | Four encoded choices |
| C04B | Hidden Refresh | `C2 10 00 02 01 02` | Two choices |
| C06F | RAS Active Timeout | `42 08 00 02 01 02` | Two choices |
| C091 | VL Preempt Feature | `44 20 00 02 01 02` | Two choices |
| C0B3 | Hcachej Latch | `44 80 00 02 01 02` | Label spelling preserved as stored in ROM |
| C0D5 | VL Master WB Cycle Restart | `47 08 80 02 01 02` | Help distinguishes restart vs non-restart cycle behavior |
| C13C | HITMJ Sampling Timing | `C7 30 00 04 24 25 26 27` | Four encoded choices |
| C15B | Snoop Filter Miss Feature | `47 40 80 02 01 02` | Help describes force-snoop-miss vs normal operation |
| C1C3 | KEN# Check Timing | `C7 80 00 02 61 62` | Two encoded choices |
| C1E2 | Cyrix CPU Write Burst Mode | `48 08 00 02 01 02` | Two choices |
| C204 | Snoop WB CHOLD operation | `48 80 80 02 02 01` | Help explains CHOLD assertion after first ADS# during HITM# |
| C292 | Cache Hit Feature | `49 80 80 02 01 02` | Help: Enabled = Always Hit; Disabled = Normal operation |
| C2E5 | Ext. Cache WB/WT Feature | `C9 08 00 02 2A 29` | Two encoded choices |
| C304 | Int. Cache WB/WT Feature | `C9 04 00 02 2A 29` | Two encoded choices |
| C326 | Int. Cache Below 16M WB/WT | `C9 10 00 02 2A 29` | Two encoded choices |
| C348 | Shadow Cacheable | `CA 01 00 02 01 02` | Two choices |
| C36A | HITMJ# To IOCHRDYJ# Delay | `4A 30 00 04 24 25 26 27` | Four encoded choices |
| C38C | Non-CPU Cycle RAS-CAS Delay | `CA C0 00 04 27 24 26 00` | Four encoded choices |
| C3B5 | Polling Clock Select | `D0 70 00 08 2C 2E 2F 30 ...` | Eight-choice descriptor |
| C3DD | DMA Clock Select | `D0 80 00 02 38 37` | Two encoded choices |
| C3FC | VL Master Cycle Cache Read | `CE 08 00 02 41 42` | Two encoded choices |
| C41E | VL Master Cycle Cache Write | `CE 04 00 02 41 42` | Two encoded choices |
| C440 | CPU Reset Clock Select | `51 08 80 02 3D 3E` | Help names OSC 14.318 MHz as one displayed option |
| C476 | CPU Reset Dummy Hold | `51 40 00 02 02 01` | Two encoded choices |
| C495 | ISA Write Cycle Insert WS | `D2 04 00 02 01 02` | Two choices |
| C4B7 | 16-Bit ISA I/O Command WS | `D5 03 00 04 41 42 43 44` | Four encoded choices |
| C4D9 | 16-Bit ISA Mem. Command WS | `D5 0C 00 04 41 42 43 44` | Four encoded choices |
| C4FD | 16-Bit R/W WS In 32-Bit ISA | `55 C0 00 04 24 26 27 28` | Four encoded choices |
| C521 | VL Device Ready Syn. Mode | `D7 01 00 02 63 64` | Two encoded choices |
| C545 | Delay Internal ADSJ Feature | `D7 02 00 02 01 02` | Two choices |
| C567 | Cache WR Hit CWEJ Pulse Set | `57 04 80 02 01 02` | Help: function only used in 386 system |
| C5B1 | Delay ISA Cycle LDEVJ WS | `D7 30 00 04 5D 5E 5F 60` | Four encoded choices |
| C5D0 | TAGWEJ Delay Rising Timing | `57 C0 00 04 45 46 47 48` | Four encoded choices |

## Cross-checks against code

1. The page handlers set the editor's start/end pointers to the ranges above; the strings are therefore associated with the two Setup pages, not merely nearby text.
2. The Advanced CHIPSET page's AUTO help text enumerates AT bus clock, DRAM read/write wait states, SRAM read/write wait states and cycle-check point. This is a textual relationship; do not infer that all records are changed by the AUTO routine until its exact write set is traced.
3. The BIOS has a separate direct ALi1429 indexed access path through ports `22h/23h` (phase 9). The descriptor bytes here are not themselves proof that their first byte is an ALi1429 register index.
4. Many descriptor values are encoded selectors. Without decoding the editor's value translation and the associated chipset write routines, labels such as wait-state or clock selection do not establish the physical register bit meanings.

## Corrections and unresolved work

- This phase identifies item labels and raw descriptor bytes; it does not claim every item's final displayed option strings or numeric values are decoded.
- `BCAE`, `C3B5` and other multi-choice records need their complete option tails decoded against the editor's translation logic.
- The Advanced CHIPSET item `AUTO Config Function` has descriptor `B6 01 84 00`; its CMOS/index and flag fields should be interpreted only after tracing the editor's special-flag path.
- Continue by tracing `0C7D` and its record consumers to establish descriptor-field semantics, option display translation, and per-item write-back side effects.


## Erratum — authoritative record boundaries (phase 13)

The label offsets in the original phase-11 tables were approximate and several drifted after variable-length auxiliary help strings. Do not use those offsets as record starts. The record walker at `6024` advances by `20h + [record+1F]` and, when `[record+1E].7` is set, skips NUL-terminated auxiliary strings through the empty-string terminator. The exact record-start lists are now documented in phase 13: [AMI486_SEMANTIC_MAP_PHASE13_20261116.md](AMI486_SEMANTIC_MAP_PHASE13_20261116.md). The descriptor byte interpretations in phase 12 remain based on the fixed record-relative offsets and are not changed by this correction.
