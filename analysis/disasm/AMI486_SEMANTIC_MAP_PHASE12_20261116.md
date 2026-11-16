# AMI486 semantic map — phase 12 (2026-11-16)

## Scope

Traced the common Setup editor at `0C7D` and its record-navigation/value helpers. This resolves the descriptor bytes catalogued in phase 11 and confirms how the BIOS walks the variable-length records in `B7D0–C5F8`.

## Confirmed record layout

For a record whose label begins at address `R`:

| Offset | Meaning established by consumers |
|---:|---|
| `R+00...` | NUL-terminated item label |
| `R+1C` | Configuration key/index used to select a byte in the editor's `DS:E000` working image |
| `R+1D` | Bit mask / bit-routing pattern used when extracting and inserting the selected value |
| `R+1E` | Flags and optional callback selector; bit 7 enables special tail/callback handling, low 7 bits select a callback slot |
| `R+1F` | Number of option-code bytes following the fixed 20h-byte record header |
| `R+20...` | Option-code bytes; count is `R+1F` |

The next record is not necessarily at `R+20`. The walker advances by `20h + [R+1F]`; if bit 7 of `[R+1E]` is set, it then scans a NUL-terminated auxiliary tail. This matches the variable record lengths seen in the ROM tables. The option-code bytes are followed by the next record or optional text according to that flag.

## Record walker and visibility

- `6024` computes the next record address: add the option count at `+1F`, add the fixed `20h` header, and, when `+1E.7` is set, scan through the NUL-terminated auxiliary tail.
- `6008` repeatedly calls `6024`, stops at the page end pointer `[E193]`, and skips records whose `+1C` byte has bit 7 clear. The high bit of the key byte therefore acts as the record visibility/enabled marker in this editor path.
- `5FE9` sets the current-record pointer `[E18F]` from page start `[E191]`, checks the same `+1C.7` marker, and advances over hidden records.
- `614D` counts visible records by repeatedly invoking the current/next-record logic. The count is stored in `E18E`; the active record pointer is `E18F`.

## Reading and writing a selected option

- `603F` reads the working configuration byte at `DS:E000 + ([record+1C] & 7Fh)`, then uses the mask/routing byte at `+1D` to rotate the selected bits into the returned value. The key's high bit is not part of the byte offset.
- `6066` performs the inverse operation: it takes the caller's selected value, routes bits using `+1D`, and writes the updated byte back to the same `DS:E000` working image.
- `60BB` is the editor's option-change path. It obtains the current option, bounds/normalizes the new selection against the record's option count, invokes the optional callback dispatcher, and writes the resulting selection through `6066`.
- `6092` checks `[record+1E] & 7Fh`. A nonzero selector indexes a word callback table at `[E195]` (two-byte entries, one-based selector) and calls the selected routine. With a zero selector it returns without a callback.

## Option label translation

- `6115` obtains the selected option code from the record's option list, then uses `[E197]+2` as the start of a string-pointer/translation sequence. It advances through that sequence using helper `592A` and returns the pointer corresponding to the selected code.
- `603F` supplies the currently selected ordinal/code from the working configuration byte; `6115` uses that result to index the record's option-code list at `+20`.
- This explains why the descriptor option bytes (for example `01 02`, `11 12 13 14`, or `1C...15`) are not literal display strings. They are selectors consumed by the common translation path.

## Common editor entry and UI loop

`0C7D`:

1. Saves BP/BX and calls `614D` to count visible items in the supplied page range.
2. Initializes the current selection and clamps the visible row count to `24h`.
3. Sets up the page frame/title and UI controls through drawing helpers.
4. Runs the keyboard/event loop using `E18B` (state), `E18C` (page/row position), `E185` (selected visible item), `E18D` (visible row count), and `E18E` (total visible items).
5. Uses `5FE9/6008` to navigate visible records and `60BB` to change an option.
6. Handles navigation, page movement, selection, and exit keys through the dispatch around `0D34–0E12`.

The editor stores its active record pointer in `E18F`. It also uses `E191`/ `E193` for the page's record-range start/end, `E195` for callback pointers, and `E197` for option-label translation data. The handlers in phase 10 populate these values before entering `0C7D`.

## Important distinction

The editor reads/writes a RAM working image at `DS:E000`; this is not direct ALi1429 I/O. Separate code later applies configuration data to hardware or CMOS. A changed selection in this editor is therefore not, by itself, proof that a chipset register has already been written.

## Remaining work

- Trace the callback tables supplied through `E195` and identify which flagged records invoke them.
- Trace the commit/apply path after leaving Setup to determine how the `E000` working image is converted into CMOS writes and ALi1429 indexed-register writes.
- Decode the option-label translation data reached through `E197`, including the full strings for the multi-choice records.
