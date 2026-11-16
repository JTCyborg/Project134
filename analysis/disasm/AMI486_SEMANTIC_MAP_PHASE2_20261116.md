# AMI486 semantic disassembly — phase 2

Date: 2026-11-16  
ROM: `ami486.bin`, 64 KiB  
SHA-256: `91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b`  
Branch: `main`

Phase 2 resolves the indirect dispatcher target table and tightens the interpretation of the setup-record walkers. It also records a correction to the interpretation of the memory pattern routine.

## 1. Dispatcher at 8E89: exact five target addresses

The dispatcher performs:

1. Save DS and SI.
2. Set DS = 0040h.
3. Copy AX to SI; extract AH with `shr si,8`; mask to a nibble.
4. Reject values 5–15.
5. Double SI (opcode `D1 E6`, shift by one).
6. Call the near pointer at `CS:[8EA7h + SI]`.
7. Restore SI and DS, then IRET.

The table at `8EA7–8EB0` contains five little-endian near offsets:

| Selector (AH low nibble) | Table slot | Target | What is currently established |
|---:|---:|---:|---|
| 0 | 8EA7 | **8EB1** | Checks AL against 2; chooses one of two callbacks at 8BA3/8B5E and calls it indirectly. |
| 1 | 8EA9 | **8EC2** | Returns AL=0 or AL=2 according to bit 5 of BDA byte `0040:0016`. |
| 2 | 8EAB | **8EC1** | Immediate RET; deliberate no-op handler. |
| 3 | 8EAD | **8ECE** | AL=0 path probes CMOS/chipset state; AL=1/2 selects callback at 8C4D/8BE8; values >2 exit through 8F0A. |
| 4 | 8EAF | **8E3C** | Enters an overlapping code/data area; target's full instruction stream still needs separate decoding. |

### Handler 0 (8EB1)

The entry compares AL with 2. Values above 2 return. Otherwise it selects SI=8BA3 when AL=0 or SI=8B5E when AL is nonzero, then calls SI through `FF D6`, preserving CX around the callback. This is a callback dispatcher, not a direct device I/O routine.

### Handler 1 (8EC2)

`mov al,0; test byte [0016],20h; if bit 5 is clear, return AL=2; otherwise return AL=0.` Since DS was set to 0040h by the outer dispatcher, the tested byte is BDA `0040:0016`. This is a small status query.

### Handler 2 (8EC1)

A single RET. It intentionally does nothing.

### Handler 3 (8ECE)

If AL is nonzero, it selects one of two callback routines:
- AL=1: SI=8C4D
- AL=2: SI=8BE8
- AL>2: return via 8F0A

The selected callback is invoked indirectly with CX saved. The result in CH determines the subsequent branch. If AL=0, the handler reads CMOS register 33h using the helper at EE94, tests bit 0, and if needed checks the machine-status word. It then returns a state code in AL, additionally considering bit 4 of BDA byte `0040:0016`.

The exact semantic names of callbacks 8C4D and 8BE8 are not assigned yet; their call contracts and all callers need to be traced before naming them.

## 2. Setup record walker at 8300 / 83AE

Both routines accept an 8-bit record selector in AL and use BX as the record pointer.

### Record source selection

- Selector 0 starts from default record base `B7D0h`.
- For nonzero selectors, the code computes `B55Dh - B508h = 55h`.
- Selectors below 55h walk from `B7D0h`.
- Selectors 55h and above subtract 55h and use the pointer stored at `CS:[82C6h]`.
- A zero adjusted selector uses the pointer directly; otherwise the walker advances through records.

This proves that `82C6h` is a runtime-selected record-table base for the upper selector range, while `B7D0h` is the built-in/default base used by the lower range. It does not yet prove which initialization routine installs the pointer at 82C6h.

### Record stepping

At each record:
- `[BX+1Eh]` is loaded as a flags/count byte.
- `[BX+1Fh]` is added to the low byte of BX, with carry propagated to BH.
- BX is then advanced by 20h.
- If bit 7 of the flags/count byte is set, the walker skips a variable-length tail by advancing in two-byte steps until it encounters a zero word at `[BX-2]`.
- The selector counter is decremented and the process repeats.

This is a variable-length record format with a fixed 20h-byte header/stride component and an optional terminated tail. The exact meanings of the two header fields are not inferred beyond their demonstrated use as flags/count and length/advance metadata.

### CMOS access and value transformation in 8300

After locating the selected record, 8300:
1. Reads CMOS register 8Eh.
2. Loads the record bytes at offsets +1Ch and +1Dh.
3. Tests CMOS status bits C0h.
4. If both status bits are clear, sets bit 7 in the record's +1Ch value and reads that CMOS index; the returned byte feeds the conversion routine.
5. If either status bit is set, clears bit 7 and performs a translation lookup. The default table begins at 873Ch; if the input value exceeds the threshold byte at 8888h, the lookup base comes from `CS:[82C0h]`.
6. The translation table is scanned in four-byte entries: byte 0 is compared with the requested value and byte 3 is returned.
7. The byte at +1Dh supplies the bit-selection/rotation mask used by the following eight-step transform. The result is returned in AL.

### Helper 83AE

Uses the same selector and variable-record traversal, but returns the two metadata bytes `[BX+1Ch]` in AL and `[BX+1Dh]` in AH. This is the metadata-query counterpart to the CMOS-aware conversion in 8300.

### Pointer fields still unresolved

- `CS:[82C0h]`: alternate four-byte translation-table base, selected when the value exceeds the built-in threshold.
- `CS:[82C6h]`: runtime-selected record-table base for selector values at or above 55h.

The static bytes around 82C0–82E7 are not a valid ordinary instruction stream. They include initial pointer/word values and a series of words that resemble near offsets into the 19A0 region. Their runtime writers and exact structure must be identified before assigning stronger names.

## 3. Correction: memory pattern sequence 2761–27B8

The earlier phase-1 summary described this as a broader multi-offset read-back test. The instruction sequence supports a narrower statement:

- DS is set to 1000h.
- ESI starts at zero; ECX is set to 2.
- EAX is loaded with pattern 55AA55AAh.
- In each iteration, the routine reads the old dword at [ESI], writes the pattern there, also reads [ESI+4] and writes the pattern there, and performs additional reads at offsets +800h, +1000h, +1800h and +2000h.
- Only the dword at [ESI] is explicitly compared with EAX.
- ESI advances by 4 and the loop repeats twice.

Thus the code explicitly verifies two consecutive dwords at the start of the 1000h segment. The other offset reads are present, but the visible sequence does not compare their values. Do not describe those additional reads as independently verified locations.

On failure, the code sets bit 14 in BP and jumps to the error path at 8D83. On success, it continues through 29BB. The exact meaning of the additional reads and the subsequent 29BB path remain to be established.

## 4. Open questions carried forward

1. Find all writes to `CS:[82C0h]` and `CS:[82C6h]`, including indirect writes and initialization copies.
2. Trace the five dispatcher entries back to their vector/interrupt installation sites; determine who supplies AH and AL.
3. Decode the overlapping entry at 8E3C separately from the linear stream around 8E40.
4. Trace callback routines 8BA3, 8B5E, 8BE8 and 8C4D, preserving their actual input/output contracts.
5. Recover the complete setup-record data at B508–B7D0 and identify which BIOS setup item each record represents.
6. Trace the 2761–27B8 failure/success exits through 29BB and 8D83.

## Evidence files

- `ami486_ali1429_tables_and_dispatch_20261116_01.txt`
- `ami486_boot_cleanup_8300_20261116_01.txt`
- `ami486_vector_targets_20261116_01.txt`
- `ami486_vector_dispatch_callers_20261116_02.txt`
- `ami486_26BE_20261116_01.txt`
- `ami486_full_linear_16bit.manifest.txt`
