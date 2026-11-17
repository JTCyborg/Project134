# AMI486 address ledger — I/O resource-conflict probes and profile dispatch stubs (18E5h–19AFh)

Date: 2026-11-17  
Repository: JTCyborg/Project134, branch main  
Source: ami486.bin, 65,536 bytes  
SHA-1: 480c7520c93e6c7ed437cf3ad214da7503f82ec6  
ROM SHA-256 recorded by the existing ledger: 91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b

## 1. Scope and boundaries

The preceding data range 188Eh–18E4h contains the four resource-conflict messages, including “Hard Disk Conflict”. The code begins at 18E5h. The region then contains port-probe helpers, a small profile dispatch pointer table and four tiny dispatch targets.

| Range | Classification |
|---|---|
| 18E5h–18FCh | I/O port pattern-test helper |
| 18FDh–1913h | Four-port probe over CS:8248h |
| 1914h–197Fh | I/O conflict aggregator over CS:8248h/CS:8240h and fixed ports |
| 1980h–198Eh | Port 0170h write/read helper |
| 198Fh–19A1h | Port 0170h/0171h dual-write helper |
| 19A2h–19AAh | CPU/cache profile dispatch pointer table |
| 19ABh–19ACh | JMP DI dispatch trampoline |
| 19ADh–19AFh | Three one-byte RET stubs |
| 19B0h onward | Next data block, already separately classified |

## 2. I/O pattern-test helper — 18E5h–18FCh

The helper accepts the I/O port in DX and uses AH as an accumulating status byte.

It shifts AH right once, writes/tests 55h through the generic port test helper F691h, then repeats with AAh. If both pattern tests succeed, it sets bit 3 in AH. It restores BX and returns at 18FCh.

Direct CALL sites inside this region are 190Eh, 1928h and 1974h. The F691h helper is the previously mapped generic I/O write/read/compare routine.

## 3. Four-port probe — 18FDh–1913h

The routine initializes AX, points SI at CS:8248h, and processes four little-endian I/O base addresses. Zero entries are skipped. Each nonzero port is passed to 18E5h, which shifts and accumulates the result bit in AH. The loop returns at 1913h.

This ties the probe to the board's I/O resource table rather than to a hard-coded single device.

## 4. I/O conflict aggregator — 1914h–197Fh

The routine builds a combined status in DX from two port tables and two fixed controller ports.

First it iterates the four entries at CS:8248h, calling 18E5h for each nonzero port. It then iterates four entries at CS:8240h, reads from each base+2 port, tests the returned value against F8h, and shifts the accumulated result into the status byte.

After the table scans it:
- reads port 03F4h and sets DH bit 0 when the value is not FFh;
- probes port 01F4h through 18E5h and sets DH bit 1 when the pattern test succeeds;
- returns at 197Fh.

The adjacent strings identify parallel, serial, floppy and hard-disk resource conflicts. The code's port tables and fixed-port checks are consistent with that purpose, but the exact bit-to-message mapping is not assigned without the caller's formatting logic.

No direct near CALL/JMP reference to 1914h was found in the raw ROM scan; its external entry mechanism remains unresolved.

## 5. Port 0170h helpers — 1980h–19A1h

1980h writes AL to port 0170h, inserts short JMP-based I/O delays, increments DX to 0171h, reads AL, delays again and returns.

198Fh writes AL to 0170h, delays, increments DX, exchanges AL/AH, writes the second byte to 0171h, delays, restores AL/AH and returns.

These are low-level I/O helpers for the 0170h/0171h pair. Their external caller provenance is unresolved in this pass.

## 6. CPU/cache profile dispatch pointer table — 19A2h–19AAh

The nine-byte data block is:

- 19A2h: 00h
- 19A3h: 19ABh
- 19A5h: 19ADh
- 19A7h: 19AEh
- 19A9h: 19AFh

The four words are little-endian offsets to the tiny dispatch targets at 19ABh and 19ADh–19AFh. The broader pointer table at CS:82C6h references this area, linking these offsets to the CPU/cache profile selection code mapped in the 81EEh–8377h phase.

Targets:
- 19ABh: FF E7 — JMP DI
- 19ADh: C3 — RET
- 19AEh: C3 — RET
- 19AFh: C3 — RET

The table and targets are kept as separate data/code ranges. The JMP DI is an indirect dispatch trampoline; the three RET bytes are valid one-byte stubs, not padding.

## 7. Generator integration

The candidate generator now seeds 18E5h, 18FDh, 1914h, 1980h, 198Fh, 19ABh and the three RET stubs at 19ADh–19AFh. It also classifies 19A2h–19AAh as a separate data range.

Generator update commit: 6e4e5beb9e33a52b1618c1e901f57d4246c59bf7.

The manifest has not yet been regenerated after this addition. No new global coverage percentage or CI pass is claimed.

## 8. Remaining uncertainties

- The exact mapping from the returned DX status bits to the four resource-conflict messages.
- External callers of 18FDh, 1914h, 1980h and 198Fh.
- The exact CPU/cache profile selection semantics represented by the 19A2h pointer table.
