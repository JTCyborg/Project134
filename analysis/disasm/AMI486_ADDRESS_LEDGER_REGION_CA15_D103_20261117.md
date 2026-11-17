# AMI486 address-ledger region CA15h–D103h: INT 13h diskette and drive-parameter subsystem

Date: 2026-11-17  
Source image: `ami486.bin`, 65,536 bytes  
SHA-256: `91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b`  
Candidate-mask gap selected: `CA16h–D0FFh`, 1,770 bytes. The aligned code entry begins one byte earlier at `CA15h`; the final helper continues through `D103h`.

## 1. Scope and confidence

This region is not a generic undifferentiated code block. It contains:
- an INT 13h drive-parameter/geometry path;
- two parallel lookup arrays and six 13-byte diskette-parameter records;
- diskette media-type selection and parameter-table return;
- POST/controller initialization and per-drive detection;
- floppy-controller command/status handling;
- motor-start/readiness timing;
- comparison against the INT 1Eh diskette parameter-table vector.

Direct near CALL/JMP references and the raw-byte boundaries establish the major entries below. `CB09h` and `CBF8h` decode as coherent routines but have no direct near xref in the complete linear listing; they remain candidate indirect/POST entries until their dispatch provenance is established.

## 2. Incoming control-flow references

Direct references from outside the gap include:

| Source | Target | Instruction |
|---:|---:|---|
| C74Bh, C7B9h, C82Fh, C906h, CCC5h | D058h | CALL |
| C838h, C8C7h, C90Eh, C98Ah | D0D9h | CALL |
| C8C4h | CFA7h | JMP |
| C93Ch, D134h, D13Bh, D4ADh, D4B2h | CEAAh | CALL |
| C9BFh | CA7Dh | conditional branch |
| C9C7h | CA7Fh | conditional branch |
| C9D1h, C9E2h, C9E6h | CA1Bh | conditional branch |
| C9F7h | CA44h | conditional branch |
| C9FEh, CA05h, CA0Ch, CA13h | CA17h | conditional branch |
| CA24h | CA8Fh | conditional branch |
| CA98h, CA9Ch, CAA5h | CA7Dh | conditional branch |
| CC02h | CDDFh | CALL |
| CC5Dh, CC68h | CC87h | CALL |
| CC7Eh | CD88h | CALL |
| CCC8h | CE45h | CALL |
| CCD8h, CCE4h | CD22h | CALL |
| CCEEh | CD6Ah | CALL |

The code at CA15h is the fall-through instruction immediately after the conditional branch at CA13h; CA17h is also a confirmed branch target. D0D9h is a separately confirmed entry from four callers.

## 3. Address classification

| Range | Classification | Evidence / role |
|---|---|---|
| CA15h–CAA6h | Code | Media-type selection, BDA drive-state update and construction of INT 13h geometry/ES:DI parameter response |
| CAA7h–CAB0h | Data: five-word geometry/selector array | Read at CA4Bh using `DI=(SI-1)*2` |
| CAB1h–CABAh | Data: five-word parameter-pointer array | Read at CA54h using the same selector index |
| CABBh–CB08h | Data: six contiguous 13-byte extended diskette-parameter records | Used by the geometry/media dispatchers; each record boundary is 13 bytes |
| CB09h–CBF7h | Candidate code entry | Diskette media-type/geometry validation, selects parameter record, writes controller value and returns INT 13h state; no direct near xref found |
| CBF8h–CC86h | Candidate code entry | POST diskette/controller initialization, BDA reset and drive-reset sequence; no direct near xref found |
| CC87h–CD21h | Code | CMOS 8Eh/90h drive-state helper; direct callers CC5Dh/CC68h |
| CD22h–CD69h | Code | Diskette wait/parameter helper; direct callers CCD8h/CCE4h; uses the INT 15h wait service |
| CD6Ah–CD87h | Code | INT 1Eh parameter-table geometry comparison; direct caller CCEEh |
| CD88h–CDDEh | Code | Parses CMOS 8Eh/90h drive nibbles and updates BDA drive-type/state bytes; direct caller CC7Eh |
| CDDFh–CE44h | Code | Controller-presence probe; direct caller CC02h |
| CE45h–CEA9h | Code | Floppy-drive status/media test using D216h/D270h and FDC ports 3F4h/3F5h; direct caller CCC8h |
| CEAAh–CFA6h | Code | Per-drive media/state detection; callers C93Ch, D134h, D13Bh, D4ADh and D4B2h |
| CFA7h–D057h | Code | Diskette parameter/drive-state setup; direct JMP from C8C4h |
| D058h–D0D8h | Code | Floppy motor/start/readiness helper; callers C74Bh, C7B9h, C82Fh, C906h and CCC5h |
| D0D9h–D103h | Code | Reads the INT 1Eh table through IVT offset 0078h, compares CH/DH against current geometry, updates BDA 0040h and returns the sector-related result in BL |
| C8CAh–C8D6h | Overlapping data view | 13-byte parameter record selected by CAB3h; the same bytes are also an executable continuation after CALL D0D9h at C8C7h |

The byte at CA16h is the immediate operand C7h of the instruction `CA15 B0 C7`; it is not a separate entry. The next instruction begins at CA17h.

## 4. Geometry and parameter tables

The two arrays at CAA7h are exact and independently read by the code at CA4Bh/CA54h:

| Selector index | Geometry/signature word | Parameter-record pointer |
|---:|---:|---:|
| 0 | 2709h | CABBh |
| 1 | 4F0Fh | C8CAh |
| 2 | 4F09h | CAD5h |
| 3 | 4F12h | CAE2h |
| 4 | 4F24h | CAFCh |

The first array is at CAA7h–CAB0h; the second at CAB1h–CABAh. The routine computes `(SI-1)*2`, reads the selected word from each array, stores the geometry word in the saved CX slot, and returns the selected parameter-record address in ES:DI. This is consistent with an INT 13h drive-parameter response; the exact caller service dispatch remains tied to the surrounding INT 13h handler.

The six 13-byte records at CABBh–CB08h are:

| Start | 13 bytes |
|---:|---|
| CABBh | `DF 02 25 02 09 2A FF 50 F6 0F 08 27 80` |
| CAC8h | `DF 02 25 02 0F 1B FF 54 F6 0F 08 4F 00` |
| CAD5h | `DF 02 25 02 09 2A FF 50 F6 0F 08 4F 80` |
| CAE2h | `DF 02 25 02 12 1B FF 6C F6 0F 08 4F 00` |
| CAEFh | `DF 02 25 02 09 2A FF 50 F6 0F 08 27 40` |
| CAFC h | `DF 02 25 02 24 1B FF 50 F6 0F 08 4F C0` |

These are parameter records, not executable code. The repeated first word DF02h is a field within each record; its exact interpretation is not inferred here. The 13-byte record at C8CAh begins `0A C0 74 04 2A D9 8A C3 8A 26 41 00 0A`; its first word C00Ah points into the `Parity` text at C00Ah. Because C8CAh is also an executable continuation after C8C7h, both views must be preserved.

## 5. Main routine behavior

### 5.1 CA15h–CAA6h: INT 13h drive parameters

The path chooses a drive/media selector from the incoming drive number and the BIOS drive-state bytes at 0090h+DL. It writes a media code back to that BDA extension, chooses the geometry and parameter-record pointer from the two arrays at CAA7h/CAB1h, places geometry in the saved CX slot and ES:DI in the saved register frame, clears/sets the status fields, and returns through the common INT 13h epilogue at C648h.

The code has distinct branch entries at CA17h, CA1Bh, CA44h, CA7Dh, CA7Fh and CA8Fh. CA17h is the common media-code store; CA44h is the shared table lookup/return-frame builder.

### 5.2 CB09h–CBF7h: media-type and geometry dispatch

The aligned entry at CB09h begins `CMP DL,01h`. Drive numbers above 1 return AH=01h with CF set. The path calls D3B5h to obtain CMOS drive-type state; when the CMOS state is not available it returns AH=0Ch with CF set.

For accepted type/geometry combinations it chooses one of the 13-byte records, writes the selected media code into the BDA drive slot, calls D517h to write DH to port 3F7h, and builds the returned ES:DI parameter pointer. The CX comparisons include 2709h, 4F0Fh, 4F09h, 4F12h and 4F24h. The CB09h entry itself has no direct near xref in the linear listing, so its dispatch provenance remains open.

### 5.3 CBF8h–CDDEh: controller initialization and drive-state helpers

The CBF8h candidate path sets the disk-related state bit at DS:0010h, calls CDDFh for controller detection, clears/initializes BDA drive state, issues the INT 13h reset service and calls the lower-level diskette helpers. CC87h, CD22h, CD6Ah and CD88h are independently confirmed by direct CALL instructions.

### 5.4 CDDFh–CE44h: controller-presence probe

The routine checks ports 3F1h, 5F7h and 1F7h. It also writes AA/55h patterns to port 1F4h and reads them back. The result is stored as 80h/81h at the BDA extension byte 008Bh. This is evidence of a controller-presence test involving legacy floppy and ATA-like I/O ranges; the exact board-level meaning of the 3F1h probe remains unresolved.

### 5.5 CE45h–D103h: floppy status, motor and geometry

CE45h uses D216h/D270h to issue/read floppy-controller commands through ports 3F4h/3F5h and updates BDA drive state. CEAAh iterates per-drive media/status information. CFA7h sets up the diskette parameter state and is reached by a direct JMP from C8C4h.

D058h updates the BDA motor/status bytes, writes the motor-control value to FDC port 3F2h, invokes INT 15h with AX=90FDh for the wait service, and polls the readiness helper. D0D9h loads the INT 1Eh diskette parameter-table pointer from IVT offset 0078h, compares CH/DH with the current geometry bytes at BDA 0042h+3/+4, conditionally returns the sector value from +5 in BL, and stores the timing/status byte at BDA 0040h. The aligned helper ends at D103h (`POP AX; RET`).

## 6. Overlap and unresolved items

- C8CAh is both an ES:DI parameter-table target and executable code reached by fall-through after CALL D0D9h at C8C7h. Keep both views.
- The 13-byte parameter records at CABBh–CB08h contain a repeated DF02h first word; its exact field meaning and whether it is interpreted as a callback, selector or data value are not proven.
- CB09h and CBF8h are coherent code streams but have no direct near xref in the linear listing. Their exact entry provenance (indirect dispatch, POST entry or dead code) remains unresolved.
- BDA extension bytes 008Bh, 008Fh, 0090h–0096h are read/written repeatedly; their full vendor-specific bit meanings are not established.
- The exact board-level meaning of the 3F1h/5F7h/1F7h/1F4h controller probe is not established.
- This map does not claim a complete semantic interpretation of every instruction in the larger C000h–DFFFh subsystem.

## 7. Candidate-generator integration

The candidate generator adds byte-aligned seeds at CA15h, CB09h, CBF8h, CC87h, CD22h, CD6Ah, CD88h, CDDFh, CE45h, CEAAh, CFA7h, D058h and D0D9h. It adds data ranges for the two five-word tables, the six 13-byte parameter records, and the overlapping 13-byte data view at C8CAh. D0D9h is extended through D103h so its POP/RET epilogue is not left outside the window.

This is a bounded diskette/INT 13h subsystem map, not a whole-ROM completion claim.
