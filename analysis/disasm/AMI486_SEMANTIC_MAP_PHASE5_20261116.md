# AMI486 semantic disassembly — phase 5

Date: 2026-11-16  
ROM: 64 KiB; SHA-256 `91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b`

This phase decodes the built-in four-byte configuration tables at 873Ch–887Fh and the count/threshold words at 8880h–8889h. It resolves the table sizes used by 8400, 85C0, 85CB and 85D6.

## 1. Exact count and threshold fields

Raw bytes:

```
8880: 05 00 4C 00
8884: 00 00 51 00
8888: E0 00
```

Little-endian interpretation:

| Address | Value | Consumer | Proven use |
|---|---:|---|---|
| `8880` | `0005h` (5) | 85F5 | Number of four-byte entries at 873Ch |
| `8882` | `004Ch` (76) | 85C0 | Number of four-byte entries at 8750h |
| `8884` | `0000h` (0) | 85CB | Empty/default table at 8880h |
| `8886` | `0051h` (81) | 8400 | Number of entries starting at 873Ch; 5 + 76 |
| `8888` | `00E0h` | 8300 | Threshold: values above E0h use the alternate table at [82C0] instead of 873Ch |

The count arithmetic is exact:
- `873Ch + 5*4 = 8750h`
- `8750h + 76*4 = 8880h`
- `873Ch + 81*4 = 8880h`

Thus 873Ch–887Fh is one contiguous 81-entry built-in array, with two useful subranges: a five-entry prefix and a 76-entry suffix.

## 2. Table consumers and their exact subranges

### 8300: key-to-value translation

For values at or below E0h, the search begins at 873Ch. For values above E0h, it loads the alternate base from [82C0]. It compares the requested key with entry byte +0, advances by four bytes, and returns byte +3 from the matching entry.

This routine does not load an entry count and does not check [82C2] in its visible search loop. Its caller/data contract must ensure that the key is present or that a valid terminator exists; no explicit bound is enforced in this loop.

### 8400: apply all 81 built-in records to CMOS

The routine loads CX=[8886]=81 and SI=873Ch. The five-entry prefix and 76-entry suffix are processed as a single sequence. For each record it uses:
- +0: CMOS register number (with bit 7 set before calling the CMOS helper)
- +1: mask
- +2: desired value
- +3: not used in this CMOS application loop

After those 81 records, it separately walks the optional runtime range [82C0,82C2), if nonempty.

### 85C0: 76-entry suffix table

Loads CX=[8882]=76 and SI=8750h. This is the suffix of the same 81-entry array.

### 85F5 / 85D6 default path: five-entry prefix

Loads CX=[8880]=5 and SI=873Ch. This is the five-entry prefix.

### 85CB: zero-entry table

Loads CX=[8884]=0 and SI=8880h. The common worker immediately returns when CX is zero. It is a deliberately empty table slot in this built-in configuration set.

## 3. Five-entry prefix at 873Ch

Each row is four bytes: key/index, mask, value A, value B.

| Offset | Key | Mask | Value A | Value B |
|---|---:|---:|---:|---:|
| 873C | 11h | FFh | BBh | ABh |
| 8740 | 13h | FFh | BCh | 30h |
| 8744 | 2Dh | FFh | 1Fh | 70h |
| 8748 | 34h | FFh | 00h | 00h |
| 874C | 35h | FFh | 0Fh | 01h |

These values are literal table payloads. The specific chipset register names for keys 11h, 13h, 2Dh, 34h and 35h should be taken from a matching ALi1429 register map, not inferred from the values alone.

## 4. Seventy-six-entry suffix at 8750h

The suffix begins at 8750h and ends at 887Fh. Its first records are:

| Offset | Key | Mask | Value A | Value B |
|---|---:|---:|---:|---:|
| 8750 | 36h | FFh | 01h | 00h |
| 8754 | 40h | FFh | 20h | F0h |
| 8758 | 41h | FFh | 0Ah | FFh |
| 875C | 42h | FFh | 10h | 00h |
| 8760 | 43h | FFh | 1Fh | 00h |
| 8764 | 44h | FFh | 0Fh | 00h |
| 8768 | 45h | FFh | 00h | 00h |
| 876C | 46h | FFh | 0Fh | 00h |
| 8770 | 47h | FFh | 69h | 3Ah |
| 8774 | 48h | FFh | 01h | 01h |
| 8778 | 49h | FFh | 08h | 60h |
| 877C | 4Ah | FFh | 40h | 00h |
| 8780 | 4Eh | FFh | 00h | 0Ch |
| 8784 | 50h | FFh | 21h | 40h |
| 8788 | 51h | FFh | 00h | 00h |
| 878C | 52h | FFh | 64h | 00h |
| 8790 | 53h | FFh | 5Bh | 5Fh |
| 8794 | 54h | FFh | 88h | 00h |
| 8798 | 55h | FFh | 65h | C5h |
| 879C | 56h | FFh | 00h | 00h |
| 87A0 | 57h | FFh | 30h | 32h |

The remaining records (keys 80h–B6h, with some non-contiguous fields) are preserved verbatim in `ami486_cmos_table_raw_873C_8888_20261116_01.txt`. Their values show repeated groups of configuration entries, but this phase does not assign undocumented register names.

## 5. Relationship to setup editor and CPU/chipset configuration

The 76-entry suffix is not a second unrelated table: it is the contiguous tail of the same array used by 8400. Separate consumers choose different slices:
- 8400: all 81 records;
- 85F5: first 5 records; 85D6: optional runtime table (stock no-op when 82B0h=0);
- 85C0: last 76 records;
- 85CB: zero records.

The values +2/+3 are two alternative configuration profiles. The common worker at 85FE selects +2 when input AL=1 and +3 when AL=2; input AL=0 uses the existing source-window value. This establishes the alternative-profile mechanism, but not which named setup option or CPU state selects each profile. That must be traced through callers such as 5A5E–5A77 and the setup/POST dispatch paths.

## 6. What can now be stated safely

- The built-in configuration payload is exactly 81 fixed four-byte records.
- The first five records and remaining 76 records have separate call sites and count words.
- The CMOS application path consumes all 81 records and uses +0/+1/+2 as register/mask/value.
- The generic configuration worker uses +0/+1/+2/+3 as index/mask/alternative values, and updates two different memory windows.
- The threshold E0h controls when 8300 switches to the optional runtime table at 82C0.
- The runtime table is optional for the bounded 8400 and selected 85D6 paths; 8400 checks [82C0] against [82C2], while 85D6 uses its selector/count contract.

## 7. Next steps

1. Trace the callers that select 85C0, 85CB, 85F5 and 85D6; identify what each profile means.
2. Compare the 81 keys against a reliable ALi1429 register map and annotate only verified matches.
3. Decode the setup items that select alternative values +2/+3.
4. Locate any runtime initialization of [82C0], [82C2], [82B0], [82CA] and explain when the optional extension replaces the built-in defaults.

## Evidence

- `ami486_cmos_table_raw_873C_8888_20261116_01.txt`
- `ami486_cmos_table_873C_20261116_01.txt`
- `ami486_config_tables_8400_20261116_01.txt`
- `ami486_pointer_init_85D0_8640_20261116_01.txt`
- `ami486_cmos_table_callers_context_20261116_02.txt`


## Audit addendum — 85D6 zero-selector correction (2026-11-17)

The original wording in this report that grouped 85F5 and 85D6 as the same five-entry prefix is withdrawn. 85F5 is the five-entry prefix worker. 85D6 is the optional runtime-table worker; with stock `82B0h=0`, it leaves CX zero and does not fall back to the prefix (phase 8 correction). See phase 8 and the region ledger `AMI486_ADDRESS_LEDGER_REGION_873C_8DCE_20261117.md`.
