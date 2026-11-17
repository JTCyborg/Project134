# AMI486 address ledger — fixed-disk table and 8042 helpers E481h–E830h

Date: 2026-11-17  
Repository: JTCyborg/Project134, branch main  
ROM: ami486.bin, 65,536 bytes; SHA-256 91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b

## 1. Region layout

The former largest uncovered interval was E481h–E830h (944 bytes). The bytes resolve into a continuation of the fixed-disk parameter table, a near-JMP around an embedded payload, and keyboard-controller helpers.

| Range | Size | Classification |
|---|---:|---|
| E481h–E6F0h | 624 bytes | 39 additional 16-byte fixed-disk parameter records |
| E6F1h | 1 byte | 00h padding |
| E6F2h–E6F4h | 3 bytes | Near JMP to F758h |
| E6F5h–E728h | 52 bytes | Opaque embedded data preamble |
| E729h–E738h | 16 bytes | Eight-word UART baud-divisor table |
| E739h–E73Bh | 3 bytes | INT 14h near-JMP trampoline to F8E3h |
| E73Ch–E7E7h | 172 bytes | Opaque embedded payload/data |
| E7E8h–E7FFh | 24 bytes | 8042 command/status helper |
| E800h–E802h | 3 bytes | ADD AL,B0h / RETF stub candidate |
| E803h–E818h | 22 bytes | 8042 command/echo helper candidate |
| E819h–E82Dh | 21 bytes | 8042 command/read helper |
| E82Eh–E830h | 3 bytes | Near JMP to B3DEh |

## 2. Fixed-disk parameter table continuation

The preceding E401h–E480h range is already classified as eight 16-byte fixed-disk parameter records. E481h–E6F0h continues the same 16-byte stride for 39 further records. Together, E401h–E6F0h is 752 bytes, or 47 records.

Record starts in the new span are E481h, E491h, E4A1h, E4B1h, E4C1h, E4D1h, E4E1h, E4F1h, E501h, E511h, E521h, E531h, E541h, E551h, E561h, E571h, E581h, E591h, E5A1h, E5B1h, E5C1h, E5D1h, E5E1h, E5F1h, E601h, E611h, E621h, E631h, E641h, E651h, E661h, E671h, E681h, E691h, E6A1h, E6B1h, E6C1h and E6D1h, E6E1h.

The records contain repeated 16-byte structures with fields including 16-bit values, byte selectors, FFFFh masks, 0008h flags and references to adjacent record IDs. E4E1h and E6E1h are all-zero records. The table's fixed 16-byte record size and continuity with the already documented E401h table are established; the exact meaning of every field (cylinders/heads/sectors, controller selector, or compatibility flags) is not assigned without tracing its consumer.

## 3. E6F2h near-JMP and embedded payload

E6F2h contains E9 63 10, a near JMP from the post-instruction IP E6F5h to F758h. The target F758h is a boot path: it sets the INT 1Eh vector at 0000:0078 to CS:EFC7h, clears the 7C00h boot-sector buffer, resets disk services with INT 13h, and continues through the BIOS boot-drive helper.

The bytes E6F5h–E7E7h are therefore skipped by this direct JMP path. They include a 16-byte descending-value table at E729h:

```text
17 04 00 03 80 01 C0 00 60 00 30 00 18 00 0C 00
```

The table's consumer is not yet proven. The surrounding 243-byte block includes a zero-heavy preamble and a high-entropy binary tail; retain it as opaque embedded data rather than linear x86 code.

## 4. Keyboard-controller helpers

### E7E8h–E7FFh

The routine:
- disables interrupts;
- calls E819h to issue command CAh and read the 8042 data port;
- checks carry and compares the returned AL value against 04h;
- on success returns AX=0 with interrupts restored;
- on failure writes command EFh to port 64h, reads status port 64h, tests bit 2, restores interrupts and returns.

Direct relative CALL target candidates found at 1506h, 8521h and A826h. The 1506h caller is in the main POST continuation at 14FEh–1510h.

### E800h–E802h

Bytes 04 B0 CB decode as ADD AL,B0h; RETF. Preserve as a three-byte far-return helper candidate; its caller and semantic contract are unresolved.

### E803h–E818h

This helper calls F622h, restores a saved AX/flags frame, checks carry and compares AH/AL. It sends FFh through the F635h 8042 write helper, restores flags, enables interrupts and returns. The carry-error path loops through the send/restore sequence. No direct relative CALL xref was established; retain it as a bounded candidate entry.

### E819h–E82Dh

Called internally by E7E9h. It sends command CAh through F635h, waits through F602h, reads port 60h if the expected status arrives, and returns with CF clear. Failure returns with CF set.

### E82Eh–E830h

Bytes E9 AD CB form a near JMP to B3DEh. Caller provenance remains unresolved.

## 5. Generator integration

The candidate generator now:
- extends the fixed-disk parameter data range through E6F0h;
- records the single E6F1h padding byte;
- separates the E6F2h jump and the embedded payload around the UART divisor table and E739h INT 14h trampoline;
- adds bounded code seeds for E7E8h, E800h, E803h, E819h, E82Eh and EFD2h (INT 17h trampoline).

GitHub Actions run 44083781676 completed successfully. The regenerated manifest reports 779 candidate windows, 232 data ranges, 38,287 unique code-window bytes, 18,888 unique data-range bytes, 290 overlap bytes, and a 56,885-byte union (86.80%). There are 68 uncovered intervals; the next largest is F5AEh–F8E6h (825 bytes).

## 6. Remaining questions

1. Trace all consumers of the 47-record fixed-disk parameter table and map the 16-byte field layout.
2. Identify the consumer of the 16-byte table at E729h and the purpose of the remaining E6F5h–E7E7h payload.
3. Find indirect callers of E800h/E803h and the entry provenance of E82Eh.
4. Compare the fixed-disk parameter records with the BIOS Setup conflict strings and the disk geometry code before assigning semantic field names.

This closes the byte-inspection pass for E481h–E830h, but not the semantic analysis of every table field or opaque payload byte.
