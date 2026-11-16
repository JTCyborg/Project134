# AMI486 semantic map — phase 13 (2026-11-16)

## Scope

This phase follows the page callback dispatcher at `6092`, its table supplied through `E195`, the Setup save command at `2F67`, the CMOS write routine at `854F`, and the configuration-load routine at `84CB`.

## E195 callback table

The Advanced CMOS and Advanced CHIPSET handlers set `E195 = B7B2`. The table is a sequence of little-endian near offsets. The callback dispatcher at `6092` reads the record byte at `+1E`, masks it with `7Fh`, subtracts one, indexes this table, and calls the selected offset in the current code segment. A zero low-seven-bit selector means no callback. Bit 7 is independently used by the record walker to indicate auxiliary NUL-terminated help text.

| Selector | Table word | Associated Setup record in the two pages | Confirmed behavior from target |
|---:|---:|---|---|
| 1 | `2E74` | Numeric Processor Test (`B9A7`, flags `01`) | Special toggle/selection handler; resolves record metadata through `83AE` and updates the RAM configuration image |
| 2 | `2EB4` | Internal Cache Memory (`BA71`, flags `02`) | Similar special handler, with a protected-mode/CPU-state test and RAM-image bit update |
| 3 | `86DB` | BootSector Virus Protection (`BCFD`, flags `83`) | Special toggle handler; also checks `E1AA.0` before changing the shadow configuration image |
| 4 | `29F6` | AUTO Config Function (`BD54`, flags `84`) | AUTO-configuration handler; consults the CMOS/config translation table and ALi1429 register 02h, then updates working-image fields `E046/E047/E049/E050` and state flags |
| 5 | `2AC1` | AT Bus Clock Select (`BE1E`, flags `05`) | Option handler for working-image byte `E050`; returns the corresponding option-label pointer |
| 6 | `2B13` | DRAM Read Wait State (`BE3E`, flags `06`) | Option handler for `E046` |
| 7 | `2B2B` | DRAM Write Wait State (`BE5E`, flags `07`) | Alternate entry within the shared DRAM wait-state option logic; must be decoded from this exact entry, not inferred from the linear instruction boundary |
| 8 | `2B4C` | SRAM Read Wait State (`BE7E`, flags `08`) | Option handler for `E046`, with an additional mode-dependent mapping |
| 9 | `2B91` | SRAM Write Wait State (`BE9E`, flags `09`) | Option handler for `E049` |
| 10 | `2BD3` | Cycle Check Point (`BEBE`, flags `0A`) | Option handler for a separate field in `E049` |
| 11 | `2C1D` | Flash ROM Function (`BEDE`, flags `0B`) | Option handler for `E047` |
| 12 | `2C69` | I/O Recovery Period (`BFA6`, flags `0C`) | Option handler for `E042` |
| 13 | `2CCF` | No selector 0Dh found in these two page ranges | Additional shared option handler; target operates on `E052` |
| 14 | `0584` | No selector 0Eh found in these two page ranges | Shared UI helper entry; not mapped to a record in these two pages |

The table also contains a final zero word after selector 14. The two page ranges contain selectors 1–12; selectors 13–14 belong to other Setup records or shared UI paths and are not assigned here without evidence.

### Callback side-effect boundary

The handlers at `2AC1` through `2CCF` primarily normalize or update the editor's `E0xx` working-image fields and return pointers to option strings. Their code reads/writes RAM state and uses ROM lookup tables; these calls are not themselves proof of direct ALi1429 register writes. The AUTO handler at `29F6` is different: it reads ALi1429 register 02h through the indexed-port helper, combines that state with the configuration table, and updates several working-image bytes. Its visible path still stages values in RAM rather than writing the complete set of chipset registers directly.

The three early special handlers (`2E74`, `2EB4`, `86DB`) use the record metadata translator `83AE` and the shadow image at `DS:E000`/related `E000)-relative windows. They should be treated as special selection handlers, not generic CMOS-bit editors.

## Correct record traversal and authoritative record starts

The record walker at `6024` advances by `20h + [record+1F]`. When bit 7 of `[record+1E]` is set, it skips one or more NUL-terminated auxiliary strings until the empty-string terminator, then begins the next record. This is why simply scanning for the next printable label or skipping only one help string gives incorrect boundaries.

The following are the record starts obtained by executing that exact traversal over the stock ROM bytes. These replace the approximate label offsets in phase 11.

### Advanced CMOS page (`B7D0–BD54`)

`B7D0, B7F2, B816, B83E, B860, B882, B8A4, B8C6, B8E8, B963, B985, B9A7, B9C7, B9E9, BA0B, BA2D, BA4F, BA71, BA91, BAB3, BAD5, BAF7, BB19, BB3B, BB5D, BB7F, BBA1, BBC3, BBE5, BC07, BC29, BC4B, BC6D, BC8F, BCB1, BCD9, BCFD.`

### Advanced CHIPSET page (`BD54–C5F9`)

`BD54, BE1E, BE3E, BE5E, BE7E, BE9E, BEBE, BEDE, BEFE, BF20, BF42, BFA6, BFC6, BFE8, C00A, C02C, C050, C072, C094, C0B6, C0D8, C13C, C160, C1C3, C1E5, C207, C292, C2E5, C307, C329, C34B, C36D, C391, C3B5, C3DD, C3FF, C421, C443, C476, C498, C4BA, C4DE, C502, C526, C548, C56A, C5B1, C5D5.`

## Save/exit path: Setup menu to CMOS

1. Main Setup menu item 10 dispatches to `2F67` (phase 7). The user is prompted with “Write to CMOS and Exit (Y/N)?”.
2. On `Y`, `2F67` calls `852F`.
3. `852F` calls `1A90`, then `854F`. It preserves the flags returned by `1A90` across the CMOS-write routine. In the normal nonzero-stack path, it jumps to the BIOS restart entry `E05B`; this is a save-and-restart path, not a return to the menu.
4. `854F` computes two additive checksums:
   - Sum of 30 bytes `E010–E02D`, stored at `E02E`.
   - Sum of 10 bytes `E034–E03D`, stored at `E03E`.
5. It then writes the CMOS image using the BIOS CMOS write helper at `FFFF:EE9D`. The loop starts at CMOS index `8Eh`, takes bytes from `E00E), and writes through index `E0h`. When the source pointer reaches `E032`, it skips two bytes / two CMOS indices (`B2h–B3h`). The stock bound `[CS:82B3]=00E0h` gives 83 indices in the overall `8Eh–E0h` range before the two-index skip. The routine explicitly clears the word at `E00E` before writing.
6. The two checksum bytes are part of the CMOS image at the positions corresponding to `E02E` and `E03E`; they are calculated immediately before the write loop.

This proves that the menu's “Write settings to CMOS and Exit” path serializes the staged Setup image to CMOS and restarts. It does not merely save a UI selection in RAM.

## Configuration load path

`84CB` is the complementary load/initialization path:

- Reads CMOS index `8Eh` first and tests bits `C0h`.
- If those bits are clear, reads the CMOS configuration range beginning at `90h` into the `E010` working area (the loop bound comes from `[CS:82B3]`).
- If either of those top bits is set, copies the built-in defaults from ROM `CS:8210` into `E010`, then invokes the default/overlay workers `85B3`, `85CB`, and `85D6`.
- Continues through `0A35` and `1A8F`, copies 80h bytes from `E000` to `E080`, and validates/updates the setup-image state via `E7E8`.

The load path therefore distinguishes stored CMOS settings from ROM defaults and then builds the editor's RAM-side working image. This aligns with phase 12's finding that the editor manipulates a RAM image and with the save path above.

## Remaining work

- Decode the alternate callback entry `2B2B` independently and map the extra shared callbacks `2CCF` and `0584` to their other callers/records.
- Trace the complete post-load/apply chain (`0A35`, `1A8F`, `E7E8`) and identify which staged fields ultimately cause ALi1429 indexed writes.
- Compare the CMOS bytes written by `854F` with the initialization and runtime readers to assign exact meanings to each CMOS index, without assuming that a record's key byte is always a direct CMOS register number.
