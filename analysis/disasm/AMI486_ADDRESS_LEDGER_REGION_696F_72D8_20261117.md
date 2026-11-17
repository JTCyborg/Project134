# AMI486 address-ledger extension: fixed-disk INT 13h diagnostics and throughput benchmark

Date: 2026-11-17  
Source: `ami486.bin`, 65,536 bytes  
SHA-256: `91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b`

## 1. Scope and boundary

The candidate gap D697Dh–D7144h is now decoded as part of a fixed-disk diagnostic/benchmark subsystem. The earlier candidate window at 68FDh ended at 697Dh, so the first continuation was extended from the aligned BP-frame entry at 696Fh. The code uses INT 13h, drive numbers with bit 7 set, CHS geometry fields, a three-way mode dispatch, disk read/write/verify operations, keyboard abort/retry handling and a throughput display.

The region is not one linear function. It contains multiple routines, two small dispatch/status tables, an INT3 guard byte, a NOP alignment byte and the inline display label at 7145h.

## 2. Three-way disk-mode dispatch

### 2.1 Dispatch table at 6BD8h

The six bytes at 6BD8h–6BDDh are three near-call pointers:

| Selector | Stored word | Target |
|---:|---:|---|
| 0 | 6B14h | controller diagnostic/parameter initialization |
| 1 | 71E4h | alternate geometry initialization path |
| 2 | 6CE3h | main disk test state machine |

The dispatcher at 6BDEh uses the selector byte at E1ACh, doubles it, and executes:

```asm
6BDE  MOV BYTE PTR [E3BBh],0FFh
6BE3  MOV BL,[E421h]
6BE7  ADD BL,80h
6BEA  MOV [E421h],BL
6BEE  MOV SI,E1ACh
6BF3  MOV AL,[SI]
6BF5  MOV [E3BCh],AL
6BF8  MOV BL,AL
6BFA  XOR BH,BH
6BFC  SHL BX,1
6BFE  CALL WORD PTR CS:[BX+6BD8h]
```

After the selected handler returns, it reads the status byte at E3B9h and returns with CF set on a nonzero status, clear on success. The addition of 80h to the drive number at E421h is consistent with selecting a fixed-disk BIOS drive (DL bit 7 set).

The caller that enters 6BDEh and the source/meaning of the E1ACh selector are not yet proven.

### 2.2 Selector 0 — 6B14h

6B14h sets E1ABh, clears E3BDh, then calls the INT 13h wrapper at 6C15h with AH=14h, AH=08h and AH=09h. It repeats the AH=09h call on the error path. The error classifier at 6CC2h supplies a response token; AL=52h ('R') retries, AL=49h ('I') continues/ignores, and other responses return CF set through the common error stub at 6BD1h.

### 2.3 Selector 1 — 71E4h

71E4h checks E1ABh, E1B5h and E1B7h. Depending on those state fields it initializes E3C3h/E422h, sets E3C1h to FFFFh, initializes E3C6h/E3C7h, and calculates drive geometry from the fixed total 0780h using the values at E41Fh and E413h. It stores the resulting head/cylinder values at E1B4h/E1B2h and calls 6B19h. Failure routes through the status stubs at 72D0h.

This is a distinct, confirmed dispatch target; it must not be conflated with the 714Eh screen-output routine.

### 2.4 Selector 2 — 6CE3h

6CE3h is the main disk-test state machine. It calls 6FE3h for controller/drive diagnostics, builds a parameter frame from E1B2h/E1B4h/E1B5h/E1B7h, and invokes 6D94h for the read/write/verify loop. It then invokes 6EE0h for saved-record processing. Status code 52h causes a retry; 49h is the ignore/continue path. The routine advances the cylinder/head state and returns with CF on a hard error.

## 3. INT 13h wrapper, display and status helpers

- 6C15h–6C38h is the common INT 13h wrapper. If E3BBh is not FFh it calls the display helper at 6C39h first; it then executes INT 13h, stores AH in E3B9h and returns CF clear on success or set on error.
- 6C39h–6C9Fh is a BP-framed geometry/status display helper. It uses INT 10h cursor positioning and the numeric formatting helpers at 72D8h/7323h.
- 6CA0h–6CB3h polls INT 16h for keyboard input and provides the abort path used by the disk test.
- 6CB4h–6CC0h is a 13-byte status-token lookup table:
  `01 02 04 05 07 0A 10 11 20 40 80 AA CC`.
- 6CC1h is a single INT3 trap/alignment byte. The lookup/classifier begins at 6CC2h, not 6CC1h.

## 4. Disk request and transfer helpers

- 6D94h–6E2Fh is a BP-framed disk request/transfer helper. It iterates the selected CHS range, calls the read/write/verify subhelpers, polls the keyboard between operations, updates head/cylinder state and returns CF on error or abort.
- 6E1Eh selects operation 03h; 6E27h selects operation 04h. Both call the common transfer routine at 6E30h.
- 6E30h–6EA2h builds CHS register values from SI/DI and E3BAh/E3BEh/E3C0h, calls 6C15h, retries, and classifies BIOS status codes 10h, 0Ah, 04h, 02h and 11h.
- 6EA3h–6EDFh stores completed request records in the array at E439h and updates the E3D0h working buffer.
- 6EE0h–6F3Dh iterates the saved records, clears the working buffer and replays the disk request sequence through 6D94h.
- 6F3Eh–6F74h prepares disk parameters from the E1B8h structure and the E3CFh lookup data.
- 6F75h–6F85h is a separate geometry/command preparation entry. The instruction at 6F83h is the three-byte `SHL CL,6`; its immediate byte at 6F85h is not an entry.
- 6F86h–6FA2h is an alternate INT 13h AH=05h request continuation. Its caller is unresolved.
- 6FA3h–6FACh is a short AH=05h request/error continuation.
- 6FADh–6FE2h is an ENTER-framed drive signature/geometry probe.
- 6FE3h–7011h performs INT 13h diagnostics with AH=14h, AH=08h, AH=09h and AH=11h. 7011h is the RET target on one failure branch.
- 7012h–7029h is a separate AH=11h status sequence followed by AH=09h.
- 702Ah–7032h calls INT 12h and checks that reported conventional memory is at least 80h KiB before continuing to the benchmark.

## 5. Throughput benchmark at 7033h

7033h–7144h is a disk throughput benchmark and screen-output routine.

- It saves/restores the master PIC mask at port 21h.
- It uses ES:BX with BX=8000h as the transfer buffer.
- It performs INT 13h reads with AX=0228h: AH=02h, AL=28h (40 sectors per request).
- CX starts at 30h (48 iterations). The loop advances CH when the drive reports the specific retry condition and checks the cylinder bound in E1B2h.
- It records elapsed BIOS ticks from BDA 0040:006Ch, accumulates the per-iteration timing value at E1AFh, and computes quotient/remainder fields at E3C9h/E3CBh using divisor 4440h.
- It calls 714Eh to render the numeric fields, then uses INT 10h AH=13h with BP=7145h to print the inline label.

The nine bytes at 7145h–714Dh are the ASCII label `KB/sec ms`. The display routine beginning at 714Eh is separate code and is already covered by its own candidate window.

## 6. Data and alignment ledger

| Range | Classification | Meaning |
|---|---|---|
| 6B61h | Single NOP byte | Alignment between the preceding short jump and the 6B62h status-query entry |
| 6BD8h–6BDDh | Three words | Near-call dispatch targets 6B14h, 71E4h, 6CE3h |
| 6CB4h–6CC0h | 13 bytes | Status-token/error lookup table |
| 6CC1h | INT3 | Trap/alignment byte before the 6CC2h classifier |
| 7145h–714Dh | 9 ASCII bytes | `KB/sec ms` display label |

The candidate generator keeps the two tables, the INT3 byte, the NOP alignment byte and the display label outside executable windows.

## 7. Remaining uncertainties

- The caller of the 6BDEh mode dispatcher and the origin/semantics of E1ACh are not yet established.
- The exact meaning of all three mode selectors is not fully documented, although their target routines and observed behavior are mapped.
- The 13-byte 6CB4h status table is confirmed, but each token's exact relationship to BIOS AH status values needs a separate trace.
- The E1B2h/E1B4h/E1B5h/E1B7h geometry fields and E3Bxh state bytes need a global writer/reader cross-reference.
- The 6F86h alternate AH=05h entry has no confirmed caller.
- The benchmark's precise unit conversion should be checked against the tick arithmetic and screen output; the sector count and loop count are byte-confirmed.

**The D697Dh–D7144h candidate gap is now represented by aligned code windows and explicit data ranges. This is a region map, not a whole-ROM completion claim.**
