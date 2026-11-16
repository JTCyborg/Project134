# AMI486 semantic map — phase 16 (2026-11-16)

## Scope

Continue POST tracing after the main chipset apply at checkpoint 8Ch. This phase follows the independent POST callers of `1E78`, `1E9D`, and `1F47`, and records the second CMOS-to-ALi1429 register-programming group.

## POST call sites

| Caller | POST checkpoint | Target | Proven role |
|---|---:|---|---|
| `1402` | `98h` | `1E9D` | conditional per-window ROM/shadow setup |
| `14B2` | `9Bh` | `1E78` | conditional ALi1429 register 14h bit update |
| `1608` | `A4h` | `1F47` | second chipset register configuration group |
| `17AD` | inside memory/ROM descriptor construction | `1E4B` | set ALi1429 register 14h bit 1 |
| `17E2` | inside descriptor construction | `1E5F` | clear ALi1429 register 14h bit 1 |

## 1F47: second CMOS-to-ALi1429 programming group

`1F47` first selects ALi register bank/index `C5h` and calls `29ED` to test CMOS `B6.0` (AUTO Config Function).

### AUTO Config branch

If `B6.0=1`:

1. Calls CPU/timing measurement routine `8F12`.
2. Calls `2588`, which merges a derived value into ALi register `16h` low nibble.
3. Calls `25A6`, which merges a derived value into ALi register `19h` bits selected by mask `60h`.
4. Jumps to the common continuation at `1F90`.

### Manual branch

If `B6.0=0`, the BIOS reads CMOS fields and merges them into ALi1429 registers:

| ALi1429 index | CMOS source | Bits sourced | Bits preserved in current register |
|---|---:|---:|---:|
| `16h` | `46h` | `0Fh` | `F0h` |
| `19h` | `49h` | `60h` | `9Fh` |

### Common continuation (both branches)

Both branches then execute these RMW operations:

| ALi1429 index | CMOS source | Bits sourced | Bits preserved |
|---|---:|---:|---:|
| `19h` | `49h` | `9Ch` | `63h` |
| `25h` | `55h` | `30h` | `CFh` |
| `12h` | `42h` | `18h` | `E7h` |
| `18h` | `48h` | `88h` | `77h` |
| `1Ah` | `4Ah` | `C0h` | `3Fh` |
| `27h` | `57h` | `C6h` | `39h` |

Finally, it reads ALi register `1Ah`, preserves its upper nibble, and sets its low nibble to `0Fh` when CMOS register `4Ah` bit 0 is set; otherwise it leaves the low nibble cleared by the `F0h` mask. This is another CMOS-controlled field in the same chipset register.

All writes use the already-confirmed `8DCF/8DDC` indexed I/O helpers and ports `22h/23h`.

## 1E78: conditional register 14h bit 3

`1E78` checks OEM feature-presence byte `CS:B513` through helper `8300`. If present, it selects ALi register `14h`, sets bit 3, and writes it back. If absent, it returns without a write.

This is a presence-gated chipset operation. The ROM alone does not establish the feature's user-facing name.

## 1E9D: conditional shadow-window setup

`1E9D` checks three OEM feature-presence bytes `CS:B51F`, `CS:B521`, and `CS:B523`. For each present feature it calls, respectively:

- `2420`
- `242B`
- `2436`

Those targets configure distinct memory windows by updating ALi1429 shadow-control registers and copying the corresponding ROM window. Their exact window/bit assignments are catalogued in the call targets; this caller establishes that the three actions are optional and independently gated by OEM feature bytes.

## 1E4B / 1E5F: temporary register 14h bit 1 control

Both routines select extended index `C503h` and update ALi register `14h` bit 1:

- `1E4B` sets bit 1.
- `1E5F` clears bit 1.

Their callers at `17AD` and `17E2` execute only when the descriptor loop's segment value is `F000h`. The code is therefore scoped to the F000 segment while constructing/processing ROM memory descriptors. The exact external effect of bit 1 should not be named without the ALi1429 register specification.

## Consolidated result

There are at least two distinct POST chipset programming phases:

- POST `8Ch` / `1C5E`: initial ALi register setup, including AUTO Config/manual selection for indices `20h` and `17h`, followed by the common register group from phase 15.
- POST `A4h` / `1F47`: a second AUTO Config/manual selection for indices `16h` and `19h`, followed by a common group writing `19h,25h,12h,18h,1Ah,27h`.

Additional feature-gated operations occur at POST `98h` and `9Bh`, and around F000 ROM descriptor processing. This demonstrates that chipset initialization is distributed across the POST sequence rather than performed by one monolithic routine.

## Next trace

Decode `2420`, `242B`, and `2436` with their callers and exact shadow-window register masks, then follow `1EC8 -> 2850 -> 26F9` to identify the separate chipset/cache initialization that runs at POST `A1h`.
