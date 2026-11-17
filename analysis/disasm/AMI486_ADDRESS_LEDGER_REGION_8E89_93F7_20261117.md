# AMI486 address-ledger extension: timing calibration and INT 15h services

Date: 2026-11-17  
ROM: ami486.bin, 65,536 bytes  
SHA-256: 91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b

## 1. Region selected by reference density

The uncovered interval 8E5Ch–9FFFh had 452 direct near-branch/CALL references into it in the complete Capstone linear listing, with 316 distinct target offsets. The first coherent, well-bounded clusters are the timing-calibration routines at 8F12h–90B0h and the INT 15h service dispatcher at 90E7h–93F7h.

The scan is a prioritization aid, not a CFG proof: linear decode can produce false targets in data and alternate streams. Each target below is retained only where instruction alignment, raw bytes, table use or a caller establishes it.

## 2. Overlapping dispatch table at 8EA7h

The routine at 8E89h saves DS/SI, sets DS=0040h, extracts the high byte of AX, masks it to an index 0–15, and for indices below five calls a word pointer through CS:[8EA7h + 2*index]. It restores DS/SI and executes IRET at 8EA6h.

The five little-endian words at 8EA7h–8EB0h are:

| Index | Target |
|---:|---:|
| 0 | 8EB1h |
| 1 | 8EC2h |
| 2 | 8EC1h |
| 3 | 8ECEh |
| 4 | 023Ch |

This is a confirmed overlapping code/data view: the table bytes are also decoded as instructions by the linear listing. The 8EB1h handler calls either 8BA3h or 8B5Eh according to AL; 8EC2h returns AL=0 or 2 according to BDA 0040:0016h bit 20h; 8ECEh reads CMOS register 33h and combines its bit 0 with SMSW and BDA 0016h bit 10h before returning status in AL and AH=E2h. The interrupt vector identity and the fifth target's role are not established here.

## 3. Timing calibration at 8F12h–90B0h

### 3.1 Result classifier

8F12h calls 8F50h for a timing sample, then maps AX through thresholds 10h, 14h, 19h, 21h, 28h, 32h and 42h into a bucket in DI. It writes the bucket to port 80h and to BDA 0040:00E2h, and returns the bucket in AX.

### 3.2 Measurement loop

8F50h creates two temporary instruction streams in ES=1000h:
- at 1000:0000, repeated F3F7h words followed by CBh;
- at 1000:0800, repeated F3F6h words followed by CBh.

It calls 9033h to measure the two far-call execution paths with PIT channel 2, records 40 samples at 1000:F000h, averages them, stores the average at F800h, divides 236Eh by that value and selects a timing bucket. It clears the 64 KiB temporary area at ES:0000h before restoring ES/DS.

The instruction words are executable timing payload, not ordinary text or pointer data. The routine is consistent with a CPU execution-time classifier; the exact marketing speed label represented by each bucket is not established.

### 3.3 PIT primitives

- 9033h saves port 61h, configures PIT channel 2, gates the counter, far-calls the two temporary streams at 1000:0000h and 1000:0800h, reads the counter and returns the elapsed difference.
- 9087h reads the channel-2 counter through port 42h and returns the complemented word in AX.
- 9096h programs PIT channel 2 through ports 43h/42h using mode/control byte B4h.
- 9025h is the shared 8000h-word ES:0000h clear and return block.
- 8F0Bh returns CX=8000h and DX=8080h for the 8ECEh status path.

Direct callers of 8F12h in the linear listing include 1C44h, 1C79h, 1F54h and 23F7h. The call graph beyond those sites remains subject to independent-entry and stack-flow checks.

## 4. INT 15h AH=80h–91h service dispatcher

### 4.1 Dispatch mechanism

9220h calls 8AE8h, enables interrupts, preserves AX, computes AH-80h, rejects indices outside 0–11h, reads a near target from the 18-word table at 90BAh and jumps to it.

The exact table at 90BAh–90DDh is:

| INT 15h AH | Table target | Classification |
|---:|---:|---|
| 80h | 9294h | shared successful RETF 2 epilogue |
| 81h | 9294h | shared successful RETF 2 epilogue |
| 82h | 9294h | shared successful RETF 2 epilogue |
| 83h | 92E3h | event-wait service |
| 84h | 9309h | joystick service |
| 85h | 9294h | shared successful RETF 2 epilogue |
| 86h | 929Bh | wait service |
| 87h | 90E1h | block-move service; alternate entry into 90E7h stream |
| 88h | 927Ch | extended-memory-size service |
| 89h | 933Ah | protected-mode switch service |
| 8Ah | 9271h | unsupported/error return |
| 8Bh | 9271h | unsupported/error return |
| 8Ch | 9271h | unsupported/error return |
| 8Dh | 9271h | unsupported/error return |
| 8Eh | 9271h | unsupported/error return |
| 8Fh | 9271h | unsupported/error return |
| 90h | 9294h | shared successful RETF 2 epilogue |
| 91h | 9278h | zero-status IRET stub |

This mapping follows the AH-80h index calculation and the raw little-endian words, not inferred BIOS convention alone. The service names are additionally confirmed by the handler bodies.

### 4.2 AH=87h block move

The AH=87h table entry points to 90E1h, an alternate entry which pops the saved AX and jumps into the body at 90ECh. The separate entry at 90E7h checks AH=87h and routes non-87h calls to the common dispatcher at 9220h.

The block-move body saves the caller state, builds a temporary GDT descriptor using the caller's SI structure, loads GDTR/IDTR, sets PE through LMSW, performs the transfer using MOVSD or MOVSW according to CS:8281h bit 40h, restores real mode and returns with RETF 2. The failure path restores SS:SP and uses the ROM helper at 8AD2h before returning.

### 4.3 AH=83h event wait

92E3h distinguishes AL=0 (register/enable event wait) from AL=1 (cancel/clear). The registration path calls 9379h. The cancellation path clears BDA 0040:00A0h and updates the interrupt-controller/event state through EE80h/EE8Ch.

9379h rejects an already-active event flag at BDA 0040:00A0h; otherwise it calls EE75h, sets the active flag, stores BX, ES, DX and CX into BDA 0040:0098h–009Fh, then updates the associated controller state through EE80h/EE8Ch.

### 4.4 AH=84h joystick

9309h accepts the supported selector in DL. The direct read path samples port 201h and masks AL with F0h. The measurement path calls 93B3h for the four axis bits. 93B3h triggers the game port and measures elapsed PIT channel-0 counts using 93E3h; 93ABh is a 32-bit CX:DX right-shift helper used in the calculation.

### 4.5 AH=86h wait

929Bh saves the caller state, uses ES=0040h and BX=00A0h as the BDA event state, and calls 9379h to register the wait. It then combines the supplied time fields and uses E902h plus the timer state to wait until completion or timeout. Busy/error paths return through the shared epilogue at 9294h/9295h.

### 4.6 AH=88h extended memory size

927Ch reads CMOS registers 31h and 30h through EEAAh and returns the two bytes in AX via IRET.

### 4.7 AH=89h protected-mode switch

933Ah disables interrupts, checks the transition precondition through F66Ah and EEEFh, loads the caller-provided GDT and IDT pointers from SI+8 and SI+10, sets PE through SMSW/LMSW, then loads SS=0028h, DS=0018h and ES=0020h. Failure returns AX=FFFFh with CF set; success returns through RETF 2.

## 5. Confirmed entries and data boundaries added to the candidate generator

- Code windows: 8E89h, 8EB1h, 8EC1h, 8EC2h, 8ECEh, 8F0Bh, 8F12h, 8F50h, 9025h, 9033h, 9087h, 9096h, 90B2h, 90B3h, 90B4h, 90B7h, 90E1h, 90E7h, 9220h, 9240h, 9271h, 9278h, 927Ch, 928Bh, 9294h, 929Bh, 92E3h, 9309h, 933Ah, 9379h, 93ABh, 93B3h and 93E3h.
- Data table: 8EA7h–8EB0h, five callback words overlapping the 8E89h linear instruction view.
- Data table: 90BAh–90DDh, 18-word INT 15h service dispatch table.

The generator assigns explicit bounds to each seeded window; the generated artifact and manifest must be verified after the workflow completes.

## 6. Remaining open items

- The interrupt vector identity for the 8E89h dispatcher and the fifth target 023Ch remain unresolved.
- The exact semantic labels for the 8F12h timing buckets remain unknown.
- The complete runtime context and stack discipline for the 90E1h/90E7h AH=87h transfer path still require trace reconstruction.
- The remaining INT 15h subfunctions 80h/81h/82h/85h/90h share a success epilogue, but their device-level contracts are not implemented in this ROM path.
- The service at 9240h is an alternate feature-gated path and should not be merged with the AH=80h–91h table without proving its entry source.
- The code at 93F8h–9FFFh contains further controller and video services and remains outside this extension.

This is a bounded address-ledger extension, not a whole-ROM semantic completion claim.
