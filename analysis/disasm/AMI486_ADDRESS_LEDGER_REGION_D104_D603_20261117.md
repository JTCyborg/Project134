# AMI486 address-ledger region D104h–D603h: diskette DMA, FDC command engine and drive initialization

Date: 2026-11-17  
Source image: `ami486.bin`, 65,536 bytes  
ROM Git blob SHA: `480c7520c93e6c7ed437cf3ad214da7503f82ec6`  
ROM SHA-256: `91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b`

## 1. Scope and method

This pass classifies the aligned 16-bit streams in D104h–D603h using the byte-complete Capstone listing and the original ROM bytes. Direct near CALL/JMP references from the surrounding diskette subsystem were checked against the full listing. The region continues the INT 13h/FDC subsystem mapped in `AMI486_ADDRESS_LEDGER_REGION_CA15_D103_20261117.md` and ends immediately before the POST entry at D604h.

This is a semantic map of the routines listed below, not a claim that every alternate entry or every FDC result byte has been fully explained. All port, BDA and CMOS effects stated below are directly visible in the instruction stream.

## 2. Incoming control-flow references

Direct near references from outside D104h–D603h:

| Source | Target | Instruction |
|---:|---:|---|
| C6C1h | D2FDh | JMP |
| C6C6h | D381h | JMP |
| C702h, C745h, C7B4h | D3A3h | CALL |
| C750h, C832h, C909h | D104h | CALL |
| C802h, C823h, CB14h, CC3Fh, CC4Ah | D3B5h | CALL |
| C84Bh | D3CFh | CALL |
| C852h, C913h | D4EAh | CALL |
| C87Ch, C973h, CE55h, CE64h, CF12h, CF24h, D02Eh | D216h | CALL |
| C89Ch, C92Fh | D197h | CALL |
| C8BBh, C936h | D156h | CALL |
| C916h | D381h | CALL |
| C948h, C97Eh, CE6Fh, CF2Fh, CFB5h, D03Ch | D270h | CALL |
| C983h, D045h | D2BDh | CALL |
| CBD1h, CC58h | D517h | CALL |
| CC2Fh | D520h | CALL |
| CD2Bh, CD32h, CD3Bh, CD4Eh, CD6Eh, CD75h | D243h | CALL |
| CD47h | D3A5h | CALL |
| CD53h, CD5Ah, CD7Ah | D294h | CALL |

The D104h entry is reached directly from three INT 13h paths. D2FDh and D381h have direct jump entries from the common INT 13h handler region. D520h is called from the diskette POST/controller initialization path at CC2Fh.

## 3. Address classification

| Range | Classification | Function / evidence |
|---|---|---|
| D104h–D155h | Code | Drive/media-state check and return-status helper; queries CMOS drive type, tests drive/media state and FDC status port 3F7h, invokes per-drive detection at CEAAh and returns status in AH/CF |
| D156h–D196h | Code | 8237 DMA channel-2 programming: clears byte pointer, writes mode, channel-2 address/count, page register 81h, then unmasks channel 2 |
| D197h–D1BFh | Code | Converts caller buffer ES:offset to normalized DMA address ES:BX and checks that transfer length does not cross a 64-KiB DMA boundary; returns AH=09h on boundary overflow |
| D1C0h–D215h | Code | Builds and sends a variable-length FDC command packet from the saved register frame; each command byte is passed to D243h |
| D216h–D242h | Code | FDC command wrapper; handles BDA busy/operation flag 0040:003Eh, calls D1C0h, waits via INT 15h AX=9001h, checks readiness and clears the busy bit |
| D243h–D26Fh | Code | Waits for FDC command-phase readiness through MSR port 3F4h and writes one command byte to FIFO/data port 3F5h; uses timing/status helpers E93Ch, E88Eh and E8C8h |
| D270h–D293h | Code | Reads CX FDC result bytes from 3F5h into DS:BX, then checks controller status at 3F4h |
| D294h–D2BCh | Code | Reads one FDC result byte after waiting for result-phase/DIO status; returns AH=20h with CF on timeout or wrong phase |
| D2BDh–D2FCh | Code | Decodes BDA diskette geometry/status word at 0042h and maps its flag bits to an AH status/media code |
| D2FDh–D345h | Code | Drive/media-status path: starts or checks the drive, issues the FDC sense/status command, reads result bytes, updates BDA geometry bytes 0042h/0043h, then jumps to common INT 13h completion at C6C4h |
| D348h–D380h | Code | Starts the selected floppy motor using DOR port 3F2h, updates BDA activity flags 003Eh/003Fh, waits via INT 15h AX=9001h and polls readiness |
| D381h–D3A0h | Code | Loads the INT 1Eh diskette parameter-table pointer from IVT offset 0078h, obtains parameter bytes, marks the operation active, invokes D216h and jumps to INT 13h completion at C6C9h |
| D3A3h–D3A4h | Code | Minimal error-return helper: sets CF and returns |
| D3A5h–D3B4h | Code | Readiness/poll helper using the shared E902h timing/status service |
| D3B5h–D3CEh | Code | Reads CMOS registers 0Eh and 10h and extracts the diskette drive-type nibble |
| D3CFh–D46Ch | Code | Per-drive initialization from CMOS drive type; writes drive state into BDA 0040:0090h+drive and programs media/rate selection through D517h |
| D46Dh–D496h | Code | Alternate/fallback CMOS drive-type initialization path; issues a sequence of FDC/rate values and updates BDA drive state |
| D499h–D4E9h | Code | Sets the selected drive/rate, calls CE45h for media/controller status, issues command 4Ah, reads seven result bytes into BDA 0042h onward and retries up to three times |
| D4EAh–D516h | Code | Synchronizes the per-drive BDA type/media bits with the shared BDA byte 008Bh and returns the selected drive number |
| D517h–D51Fh | Code | Writes DH to FDC rate-select port 3F7h |
| D520h–D5DCh | Code | FDC initialization/configuration probe: sends command sequences, reads result bytes, checks MSR status, consults CMOS 0Eh/10h and sets feature bits in CH before further controller commands |
| D5DDh–D603h | Code | Parameterized FDC command/result verifier; forms command 14h plus AL-derived selector bits, sends it through D216h, reads one result byte and compares it with the expected selector; returns CF on mismatch |

## 4. DMA programming and boundary behavior

### 4.1 D156h–D196h: DMA channel 2

The routine programs the legacy 8237 DMA controller using the following ports:

- 0Ch: clear channel-2 byte pointer;
- 0Bh: DMA mode;
- 05h: channel-2 count low/high bytes;
- 04h: channel-2 address low/high bytes;
- 81h: DMA page;
- 0Ah: unmask channel 2 (value 02h).

It preserves AX and DX, disables interrupts during programming, and restores the interrupt flag state with STI at the end. The caller supplies the channel mode/address/count in registers. The exact caller-specific transfer direction is therefore determined by the mode byte passed in AH, not by this routine alone.

### 4.2 D197h–D1BFh: DMA address normalization

The routine converts the caller's segment and offset to a linear physical address, normalizes it into ES:BX, and checks the end address against the 64-KiB DMA page boundary using the requested transfer length. A carry sets AH=09h before return. This is a DMA-controller boundary check, not a generic conventional-memory-size test.

## 5. FDC command and result protocol

The helper family is internally consistent:

- D1C0h emits the command bytes assembled from the saved caller register frame.
- D216h wraps command submission with the BIOS activity flag and INT 15h wait service.
- D243h writes a byte to the FDC command/data FIFO at 3F5h after polling MSR at 3F4h.
- D270h reads a caller-selected number of result bytes into the supplied buffer.
- D294h reads a single result byte and returns an error if the controller is not in the expected result phase.

D270h additionally checks MSR bit 4 after the transfer. D294h checks MSR bit 6 before reading 3F5h. The return code AH=20h is explicitly set on these error paths; this map does not assign a higher-level INT 13h status meaning beyond the observed value.

## 6. Drive and media initialization

D3B5h reads CMOS 0Eh and, when the high status bits permit, CMOS 10h; it extracts the appropriate drive-type nibble. D3CFh uses that value to initialize BDA drive slots beginning at 0040:0090h. The normal and fallback branches issue different command/rate sequences, but their exact vendor-specific CMOS encoding is not inferred beyond the bit operations visible in the ROM.

D499h performs a more active media probe. It selects the rate through 3F7h, calls CE45h, sends the 4Ah command sequence, reads seven result bytes into BDA 0042h onward and retries. D4EAh updates the shared drive/media state at BDA 008Bh and calls D517h when the high rate bits differ.

D520h is a separate controller initialization/probe routine called from CC2Fh. It issues several controller command sequences, reads result bytes and tests controller status. It also consults CMOS 0Eh/10h and derives feature bits in CH. D5DDh is its final command/result comparison helper. The exact FDC-generation feature names are left unresolved; the bytes establish the tests, not the intended marketing labels.

## 7. Cross-region relationships

- D104h calls D3B5h, D3A3h and CEAAh, connecting drive-type/media checks to the earlier diskette detection region.
- D156h/D197h are called by C8BBh/C936h and C89Ch/C92Fh, respectively, connecting the INT 13h transfer paths to DMA channel 2 and its page-boundary validation.
- D216h/D270h/D294h are shared by the earlier INT 13h/FDC routines at C87Ch–D03Ch and by the D1C0h command-packet builder.
- D2FDh is a direct entry from C6C1h; D381h is entered from C6C6h and called from C916h.
- D520h is reached from CC2Fh, within the diskette/controller initialization path mapped in the preceding ledger.
- The next byte after this ledger is D604h, the independently identified POST entry stream; it is not included here.

## 8. Reference-source check: docs/627.10

The collection's readable `docs/627.10/ASM1/BIOS.ASM` was checked for diskette/FDC/INT 13h references; it contains no matching implementation in the inspected file. The `docs/627.10/IO.112/SYSTEM` directory contains `RDMA.OBJ` and other prebuilt system objects, but no readable FDC/diskette assembly source. The chipset-specific floppy modules under `IO.112` are also prebuilt `.OBJ` files. These artifacts are not treated as source-level proof and no code is copied from them.

This is consistent with the project rule: use 6.27.10 for architecture only where a readable, applicable source exists; use the exact ROM and the matching ALi 1429 emulator model for target behavior.

## 9. Remaining uncertainties

- The exact semantic names of the D1C0h command-packet fields are not established; their byte ordering and register sources are.
- The full meaning of BDA 003Eh/003Fh/0040h/0041h/0042h/0043h and 008Bh is only partly reconstructed. Their reads/writes are recorded, but vendor-specific bit names should not be invented.
- D3B5h ends with `CMP SP,SP`, which forces ZF=1. Callers that inspect flags after the call therefore see that explicit flag-setting instruction; no separate "CMOS read failed" flag is proven by this helper.
- The exact identity/capability represented by the CMOS-derived CH feature bits in D520h is unresolved.
- This pass does not claim that every command byte or status code is fully decoded against a specific FDC variant.

## 10. Result

D104h–D603h is now classified as the continuation of the INT 13h diskette subsystem: DMA channel-2 programming, DMA page-boundary validation, FDC command/result transport, motor/readiness handling, CMOS drive-type setup and controller initialization. The range ends immediately before the D604h POST entry. This is a bounded semantic region, not whole-ROM semantic completion.
