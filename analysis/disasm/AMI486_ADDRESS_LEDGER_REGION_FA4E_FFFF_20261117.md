# AMI486 address ledger — upper-ROM tail FA4Eh–FFFFh

Date: 2026-11-17  
Repository: `JTCyborg/Project134`, branch `main`  
ROM: `ami486.bin`, 65,536 bytes  
ROM SHA-256: `91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b`  
Selected candidate-mask gap: `FA53h–FFFFh`, 1,453 bytes. The executable checksum entry begins at `FA4Eh`, seven bytes before the mask gap.

## 1. Confirmed executable entry: FA4Eh checksum/integrity comparison

The routine is reached from the POST stream at E34Ah–E350h:

```asm
E34A  68 51 E3       push  E351h
E34D  68 4E FA       push  FA4Eh
E350  C3             ret                 ; transfer to FA4Eh
```

Byte-aligned routine:

```asm
FA4E  60             pusha
FA4F  BE 70 FF       mov   si,FF70h
FA52  B9 4C 00       mov   cx,004Ch       ; 76 bytes
FA55  BB FF F9       mov   bx,F9FFh
FA58  2E AC          cs lodsb             ; AL = CS:[SI], SI++
FA5A  43             inc   bx
FA5B  F6 D0          not   al
FA5D  2E 32 07       xor   al,CS:[BX]
FA60  E1 F6          loopz FA58h
FA62  74 E8          jz    FA4Ch
FA64  C3             ret
FA4C  61             popa
FA4D  C3             ret
```

The comparison is byte-for-byte established by the instruction operands:
- source sequence: `FF70h–FFBBh`;
- comparison sequence: `FA00h–FA4Bh`;
- length: `004Ch` = 76 bytes;
- comparison condition: `NOT source_byte XOR comparison_byte = 0`, i.e. the two ranges are bytewise complements.

On a fully matching 76-byte sequence, LOOPZ exhausts CX with ZF still set, branches to the shared `POPA; RET` epilogue at FA4Ch, and returns to E351h. On a mismatch, execution falls through to the RET at FA64h instead of the POPA epilogue. Because PUSHA has occurred, that path consumes the saved stack contents as a return address; the exact resulting destination depends on the saved DI value. This is a concrete failure-path control-flow effect, not a guessed error message or POST code.

The checksum routine's caller context is a POST hardware-initialization sequence that writes progress values to port 80h and performs DMA/PIC-related I/O around the call. The precise user-visible POST meaning of the comparison is not yet proven.

## 2. FA65h–FA6Fh boundary bytes

- `FA65h–FA6Dh`: nine consecutive FFh bytes.
- `FA6Eh–FA6Fh`: the first two 00h bytes of the bitmap block beginning at FA6Eh.
- The checksum routine ends at FA64h; the nine FFh bytes at FA65h–FA6Dh are the actual fill boundary.

## 3. FA6Eh–FE6Dh bitmap-like block

The exact span is 1,024 bytes (`0400h`) and is naturally divisible into 128 eight-byte records. The bytes show repeated high-contrast row patterns and recognizable character-like shapes, consistent with an 8×8 glyph/bitmap table. The range begins at FA6Eh and ends at FE6Dh; FE6Eh–FE70h is the following three-byte JMP and is not part of the bitmap.

Current classification: **bitmap/glyph data candidate, high confidence as non-random structured data; exact character encoding, glyph index origin, and runtime consumer not yet proven**.

Do not decode this block as a single 16-bit instruction stream. The reset-linear disassembly's apparent instructions in this span are artifacts of decoding bitmap bytes as x86.

## 4. FE71h–FEA0h and FEA1h–FEE1h

- `FE71h–FEA0h`: 48-byte structured blob following the three-byte JMP at FE6Eh–FE70h. It is not part of the FA6Eh–FE6Dh 1-KiB bitmap block. Its exact role is unresolved.
- `FEA1h–FEA7h`: bytes `01 06 06 92 E9 3F EE`; preserve as a separate short data/control record candidate.
- `FEA8h–FEE3h`: zero-filled area; classify as padding/reserved bytes unless an incoming reference proves otherwise.

## 5. FEE4h–FF4Fh mixed upper-ROM table region

This interval contains many repeated `97 EA` byte pairs, short far-jump-shaped sequences, and interspersed zero bytes. The linear decoder emits far JMP instructions at several offsets, but no exclusive instruction alignment or caller provenance has been established for the whole block.

Classification: **mixed dispatch/relocation data candidate**. Do not label every decoded far JMP as executable code. The region needs a separate consumer/xref pass before individual entries can be named.

## 6. FF50h–FF6Fh identification text and adjacent fields

The bytes at FF59h onward contain the readable ASCII sequence:

```text
(1992AMI,404-263-8181
```

The preceding bytes FF50h–FF58h are non-text fields/terminators. Preserve the printable string as embedded ROM identification/contact text; the precise formatting contract is not established.

## 7. FF70h–FFBBh mirrored comparison data

This 76-byte range is read by the FA4Eh routine. It is compared against the bitwise complement of FA00h–FA4Bh. This confirms the range is data, not executable code in the observed call path.

The adjacent bytes FF BCh–FFC6h are FFh fill. The block FFC7h–FFEFh duplicates bytes FE75h–FE9Dh exactly (41 bytes), including the leading FFh. Keep the duplicate as a distinct physical copy; do not merge its address identity with the FE75h source.

## 8. Reset vector and BIOS date

- `FFF0h–FFF4h`: exact reset vector bytes `EA 5B E0 00 F0`, i.e. far JMP to `F000:E05Bh`.
- `FFF5h–FFFCh`: ASCII date `04/04/93`.
- `FFFDh–FFFFh`: `00 FC 00`; retain as trailing metadata/reserved bytes pending a consumer.

## 9. Classification summary and open work

| Range | Current classification | Confidence |
|---|---|---|
| FA4Eh–FA64h | POST-called 76-byte complement comparison routine | High |
| FA65h–FA6Dh | FFh fill; FA6Eh begins the bitmap block | High |
| FA6Eh–FE6Dh | 1-KiB bitmap/glyph table candidate, 128 × 8-byte records | Medium-high |
| FE71h–FEA0h | Structured data blob | Medium |
| FEA1h–FEA7h / FEA8h–FEE3h | Short record plus zero-filled area | Medium |
| FEE4h–FF4Fh | Mixed dispatch/relocation data candidate | Low-medium |
| FF50h–FF6Fh | Embedded identification/contact text and fields | High |
| FF70h–FFBBh | 76-byte comparison data | High |
| FF BCh–FFC6h | FFh fill | High |
| FFC7h–FFEFh | 41-byte duplicate of FE75h–FE9Dh | High |
| FFF0h–FFF4h | Reset vector | Certain |
| FFF5h–FFFCh | BIOS date string | Certain |
| FFFDh–FFFFh | Trailing metadata/reserved bytes | Low |

Open tasks:
1. Find the consumer of the bitmap block and prove its glyph index/encoding.
2. Trace all incoming references into FEE2h–FF4Fh and classify each table entry individually.
3. Determine whether FE71h–FEA0h is a pointer table, compressed/encoded data, or another checksum/relocation block.
4. FA4Eh and FE6Eh seeds plus the confirmed bitmap/data ranges have been added to the candidate generator. GitHub Actions completed successfully: 733 candidate windows and 223 data ranges. The generator manifest does not calculate the byte-union mask, so the next-gap ranking still needs a separate mask recomputation.
5. Compare the POST complement-check routine with the matching source-level initialization flow in `docs/627.10`; source is architectural evidence only and must not be copied into the independent implementation.

The generator now emits the FA4Eh routine and upper-ROM data ranges. GitHub Actions run 44082032224 completed successfully and regenerated the full linear listing plus candidate listing (733 windows / 223 data ranges). This closes the byte-inspection pass for the former FA53h–FFFFh candidate gap, but does not claim semantic completion of every byte in the upper ROM or a recomputed whole-ROM candidate-mask percentage.
