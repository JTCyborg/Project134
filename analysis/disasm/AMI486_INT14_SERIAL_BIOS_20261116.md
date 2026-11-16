# AMI486 serial BIOS dispatcher and UART handlers — 2026-11-16

Source: ami486.bin (65,536 bytes), SHA-256 91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b  
Decode: Capstone x86-16 seeded windows. See ami486_candidate_windows_20261116.txt.

## 1. Dispatcher

F8E7h–F929h is the guarded interrupt-style wrapper candidate (the previous F900h and F8E8h seeds were misaligned):
- uses DX as the COM-port index (0..3), reads the COM base word from the BDA at 0040:0000+2*DX, and skips the service if that word is zero;
- reads the per-port timeout byte from BDA 0040:007Ch+DX, scales its low byte by four into DI, then indexes the six-word AH handler table at F92Ah;
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

The AH function selector, DX=COM-port index, BDA COM-base lookup, per-port timeout lookup and the handlers' direct UART register access identify this as the BIOS INT 14h serial communications service. The wrapper validates DX<4 and AH<6; the valid path begins at F8F2h. The IVT installation/caller for the F8E7h candidate has not yet been found, so the vector target itself remains to be verified.

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
- Derives baud divisor in CX from AL[7:5]: 0=0417h (110 baud), 1=0300h (150), 2=0180h (300), 3=00C0h (600), 4=0060h (1200), 5=0030h (2400), 6=0018h (4800), 7=000Ch (9600). The default path starts with 0417h; other values are 0600h shifted right by the selector count.
- Writes 80h to DX+3 (LCR DLAB).
- Writes CH to DX+1 (DLM) and CL to DX+0 (DLL).
- Writes BH to DX+3 (final LCR format).
- Writes zero to DX+1 (IER disabled).
- Reads DX+5 (LSR) and DX+6 (MSR), returning status in AX.

### AH=01h — F986h: transmit character

- Calls F9E7h with MCR=03h (DTR+RTS), waits for MSR mask 30h (CTS/DSR) and LSR mask 20h (THR empty).
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

The UART identification and INT 14h service mapping are high-confidence: the code accesses the exact DLAB/DLL/DLM/LCR/IER/THR/RBR/MCR/LSR/MSR offsets, uses the standard DLAB sequence and implements the standard baud-rate divisor table. Only the IVT installation/caller for F8E7h remains unresolved.

## 5. Remaining work

1. Find the code that installs or invokes the F8E7h wrapper and verify INT 14h vector provenance.
2. Determine the exact bit meaning of the [BP+0Eh]/BH/BL configuration fields.
3. Confirm the baud-divisor table and supported baud rates.
4. Validate the return flags and AX/AH/AL contracts against the wrapper's caller frame.
5. Trace whether all six selectors are reachable or whether AH=04h/05h are OEM extensions.

No claim is made that the serial BIOS subsystem is fully mapped.


## 6. Verified baud-rate table and line-control field

The AH=00h initializer splits AL into baud selector AL[7:5] and line-control bits AL[4:0]. The divisors are:

| AL[7:5] | Divisor | Baud |
|---:|---:|---:|
| 0 | 0417h | 110 |
| 1 | 0300h | 150 |
| 2 | 0180h | 300 |
| 3 | 00C0h | 600 |
| 4 | 0060h | 1200 |
| 5 | 0030h | 2400 |
| 6 | 0018h | 4800 |
| 7 | 000Ch | 9600 |

The divisor sequence is generated as 0600h shifted right by the selector value, except selector zero which uses 0417h. The low five bits are written to LCR after setting DLAB, matching the standard 8250/16450/16550 line-control layout.


## 7. Wrapper entry alignment correction

Raw bytes establish the guarded entry at F8E7h, not F900h or F8E8h. F8E7h begins `83 FA 04` (CMP DX,04h); the guards at F8EAh and F8F0h branch to the cleanup CALL at F926h. The valid path begins with PUSHA at F8F2h. F900h is the final displacement byte of `MOV DX,[DI+0000h]` at F8FDh, and F8E8h is an interior byte of the CMP instruction. IRET is at F929h; the six-word table begins at F92Ah. The candidate-window generator is now seeded at F8E7h and clipped after F929h. The INT 14h IVT target remains unverified.


## 8. INT 14h vector provenance check

A full 64-KiB raw-byte scan found no direct near CALL/JMP target to F8E7h, no literal word reference F8E7h, and no literal far pointer F000:F8E7h. This does not prove the handler is unused: the IVT entry may be initialized by external firmware, copied from a table, or set dynamically. Until the runtime IVT slot at 0000:0054h/0056h is captured, classify F8E7h as a structurally confirmed INT 14h-style UART dispatcher candidate, not a proven installed INT 14h vector target.
