# AMI486 serial BIOS dispatcher and UART handlers — 2026-11-16

Source: ami486.bin (65,536 bytes), SHA-256 91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b  
Decode: Capstone x86-16 seeded windows. See ami486_candidate_windows_20261116.txt.

## 1. Dispatcher

F900h–F929h is an interrupt-style wrapper:
- obtains a selector from the saved register frame;
- indexes the six-word table at F92Ah;
- loads the selected handler offset from CS-relative memory;
- calls the handler through AX;
- stores returned AX into [BP+0Eh];
- restores DS and general registers;
- calls 90B2h and executes IRET.

The table is native little-endian:

| AH selector | Target |
|---:|---:|
| 00h | F936h |
| 01h | F986h |
| 02h | F9C4h |
| 03h | F977h |
| 04h | F999h |
| 05h | F9D3h |

The wrapper's vector installation/caller has not yet been found. The register convention (AH function, DX port base) and handler behavior are strongly consistent with a BIOS INT 14h serial communications service, but the INT 14h vector itself is not yet byte-verified.

## 2. UART register evidence

Each handler uses DX as a base port and accesses the standard 16550-compatible UART offsets:

| Offset | Register | Evidence |
|---:|---|---|
| +0 | RBR/THR/DLL | read received byte, write transmit byte, or set divisor low with DLAB |
| +1 | IER/DLM | disable interrupts or set divisor high with DLAB |
| +3 | LCR | set DLAB=80h, then configure line format |
| +4 | MCR | set modem-control output bits |
| +5 | LSR | read line status |
| +6 | MSR | read modem status |

This is direct port-offset evidence, not an inference from routine names.

## 3. Function handlers

### AH=00h — F936h: initialize UART

- Reads configuration byte from [BP+0Eh].
- Derives baud divisor in CX; the default path starts with 0417h and the alternate path adjusts the divisor by shifting 0600h.
- Writes 80h to DX+3 (LCR DLAB).
- Writes CH to DX+1 (DLM) and CL to DX+0 (DLL).
- Writes BH to DX+3 (final LCR format).
- Writes zero to DX+1 (IER disabled).
- Reads DX+5 (LSR) and DX+6 (MSR), returning status in AX.

### AH=01h — F986h: transmit character

- Calls F9E7h with MCR/wait parameters.
- Loads the character from [BP+0Eh].
- If the readiness check succeeds, writes AL to DX+0 (THR).
- On failure, sets bit 7 in AH and returns.

### AH=02h — F9C4h: receive character

- Calls F9E7h with receive/wait parameters.
- On success, masks status bits in AH and reads AL from DX+0 (RBR).
- On failure, sets bit 7 in AH and returns.

### AH=03h — F977h: status

F977h is an alternate entry inside the F936h initialization stream:
- reads AL from DX+5 (LSR);
- copies that status to AH;
- reads AL from DX+6 (MSR);
- returns.

This is why F977h must be preserved as an overlapping table-selected entry, not treated as a separate sequential routine.

### AH=04h — F999h: modem-control configuration

Builds a control byte from [BP+0Eh], BH and BL, including bits 08h/10h/20h/04h, merges it into CH and jumps into the shared UART programming sequence at F941h.

### AH=05h — F9D3h: modem-control write/status

- Adds four to DX to address MCR.
- If [BP+0Eh] equals one, writes BL masked to 1Fh to DX+4.
- Then enters the shared LSR/MSR read path at F97Ah.

### Shared helper F9E7h

F9E7h writes AL to DX+4 (MCR), polls status through E966h, optionally changes the output control byte using BH/BL, and restores DX. This helper is used by transmit and receive paths.

## 4. Interpretation and confidence

The six functions correspond closely to the classic BIOS serial-service shape:
- initialize UART;
- transmit character;
- receive character;
- return line/modem status;
- configure modem-control outputs;
- write modem-control outputs and sample status.

The UART identification is high-confidence because the code accesses the exact DLAB/DLL/DLM/LCR/IER/THR/RBR/MCR/LSR/MSR offsets and uses the standard DLAB sequence. The mapping to INT 14h is strongly supported by the AH selector dispatch and DX base-port convention, but remains a candidate until the IVT vector or caller is found.

## 5. Remaining work

1. Find the code that installs or invokes the F900h wrapper and verify INT 14h vector provenance.
2. Determine the exact bit meaning of the [BP+0Eh]/BH/BL configuration fields.
3. Confirm the baud-divisor table and supported baud rates.
4. Validate the return flags and AX/AH/AL contracts against the wrapper's caller frame.
5. Trace whether all six selectors are reachable or whether AH=04h/05h are OEM extensions.

No claim is made that the serial BIOS subsystem is fully mapped.
