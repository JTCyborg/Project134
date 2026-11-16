# AMI486 semantic map — phase 20 (2026-11-16)

## 1. Setup lookup routine 8306h: exact algorithm

The 8300h entry is a small wrapper (PUSH BX / CALL 8306h / POP BX / RET). The worker at 8306h is a CMOS-to-option decoder.

Input: AL = Setup key/index. Output: AL = translated option value (or zero on the no-key path). BX is preserved by the wrapper.

Algorithm:
1. BX starts at B7D0h, the built-in Advanced CMOS record base.
2. AL=0 bypasses record lookup and proceeds to the common CMOS read at 834Fh.
3. It computes the built-in key threshold as B55Dh-B508h = 55h.
4. For key < 55h, it walks the built-in variable-length records from B7D0h. Each record's +1Eh flags and +1Fh option count determine the next record; if flags bit7 is set, it skips the NUL-terminated auxiliary strings until the empty terminator.
5. For key >=55h, it subtracts 55h and obtains the optional extended-record base from CS:[82C6h]. A zero adjusted index exits to the common CMOS path; otherwise it advances through the optional records using the same variable-length record format.
6. At 834Fh it reads CMOS index 8Eh. If CMOS 8Eh has either bit C0h set, it uses the built-in four-byte translation table at 873Ch (or the optional runtime table pointer CS:[82C0h] for keys above threshold 8888h) to obtain a replacement option code.
7. It then uses the record's +1Ch key and +1Dh mask/routing byte, reads the corresponding CMOS byte, extracts/rotates the selected bits, and returns the resulting option value in AL.

This is not a generic Boolean test. Callers commonly test ZF after the wrapper, so zero/nonzero is a derived property of the selected CMOS option and record translation.

## 2. Companion routine 83AEh

83AEh has the same built-in/extended record selection and variable-length record traversal, but its common return at 83F7h returns:
- AL = record byte +1Ch (key / CMOS index)
- AH = record byte +1Dh (mask/routing byte)

This confirms the two entry points are complementary:
- 8300h/8306h: decode a stored CMOS selection into an option value.
- 83AEh: retrieve the selected record's key and mask metadata.

## 3. Runtime extension pointer audit

A complete search of the 64-KiB linear listing finds only these direct references:
- 0C53h reads [82C6h] and [82C8h] as the optional Setup-record range.
- 8306h and 83AEh read CS:[82C6h] as the optional extended-record base.
- No direct static write to 82C6h or 82C8h appears in the ROM listing.

Stock image bytes at these locations remain zero (documented in Phase 8). Therefore the optional extension range is inactive in the unpatched stock image unless an external/runtime mechanism populates it. The identity and provenance of such a mechanism are unresolved; do not infer that B51x keys necessarily resolve to live stock records.

## 4. Confirmed caller groups for Setup lookup

The worker 8300h is called from many parts of POST and Setup. Key caller groups include:
- 1227h, 12FDh, 137Bh, 13A2h, 1523h, 15DEh, 15E7h, 15F1h, 1734h, 1785h
- 1B60h: keys B51Fh, B521h, B523h gate the D000h/D800h-related ROM-window helper calls.
- 1BF6h: key B51Dh gates the C000h helper 2415h.
- 1E9Dh: repeats keys B51Fh/B521h/B523h in the later POST path.
- 1DE8h, 1E20h, 1E7Ch, 1EA1h, 1EAFh, 1EBDh, 1F1Ch, 204Ch, 205Ah and other sites use the same decoder.
- 26FAh: key B518h gates the protected-mode memory test/sizing path at 26F9h–284Fh.

Because 8306h returns a CMOS-derived option code, the callers' JZ/JNZ tests mean “selected option decodes to zero/nonzero”, not necessarily “feature present/absent”.

## 5. POST memory test: precise write/read behavior

At 26F9h, a decoded nonzero value for key B518h enters the test; zero skips directly to 284Fh.

The protected-mode sequence configures ALi registers 19h and 18h before entering 2686h. At 2761h:
- DS is set to 1000h.
- ESI starts at 0.
- EAX is 55AA55AAh.
- CX is 2.

Loop at 2772h:
- Reads dword [ESI] into EBX.
- Writes 55AA55AAh to [ESI].
- Reads dword [ESI+4] into EBX.
- Writes 55AA55AAh to [ESI+4].
- Reads additional dwords at [ESI+800h], [ESI+1000h], [ESI+1800h], [ESI+2000h].
- Compares EAX only with [ESI].
- Advances ESI by 4 and repeats twice.

Thus it writes the pattern at offsets 0, 4 and 8 (the +4 write overlaps the next iteration's base write), but only compares offsets 0 and 4 in the two loop iterations. The additional spaced reads are not compared in this loop.

On success it enters 29BBh:
- Reads 2000h dwords (32 KiB) from DS:0000 using REP LODSD.
- Writes 2000h words (16 KiB) of 55AAh to ES:0000.
- Scans 2000h words with REPE SCASW.
- On mismatch, retries the fill/scan sequence.
- Finally writes 2000h zero words (16 KiB) to ES:0000 and returns.

On failure at the initial comparison, it takes the error path through 8D83h and later restores the saved stack/segments.

The tested region is selected through the preceding ALi register configuration; the physical address interpretation depends on chipset mapping. The code proves the segment-relative accesses and the data pattern, but the exact physical alias/window mapping must not be asserted without the ALi register definitions.

## 6. Corrections and confidence

- Clarifies Phase 19: 8306h returns a decoded CMOS option value, not a simple Boolean lookup result. ZF/JNZ at callers are tests of that returned value.
- Confirms no static ROM writer for 82C6h/82C8h; optional extended records require a runtime/OEM patch or external initialization not found in the ROM listing.
- Refines the memory test description: the loop writes three consecutive dwords (with overlap) and compares two; the later 29BBh routine performs a 16-KiB word fill/check/clear sequence after a 32-KiB read pass.
- Exact physical memory mapping and runtime extension provenance remain open.
