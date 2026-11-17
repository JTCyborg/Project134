# AMI486: CMOS[8Fh]=06h — disk boot handoff path

Date: 2026-11-17  
Source: `ami486.bin`, 64 KiB, branch `main`  
Binary blob SHA at inspection: `480c7520c93e6c7ed437cf3ad214da7503f82ec6`

## Dispatch path

The previously mapped continuation table at `D6A8h` contains `F786h` at index 6. The state-machine path for CMOS marker 06h is:

`D615` reads CMOS[8Fh] into SI, clears CMOS[8Fh] to zero, and dispatches through `D691`. The common setup at `D691–D6A3` establishes DS=0040h, ES=0000h, SS=0030h, SP=0100h, doubles SI, then jumps through the word table at `D6A8h`. Marker 06h therefore selects `F786h`.

## F786h entry and branch behavior

Bytes/instructions:

```asm
F786: BE 22 7B       MOV SI,7B22h
F789: E3 08          JCXZ F793h
F78B: BE 3A 7B       MOV SI,7B3Ah
F78E: 73 6A          JNC F7FAh
F790: BE 52 7B       MOV SI,7B52h
F793: B0 0E          MOV AL,0Eh
F795: E8 13 F7       CALL EEABh
```

The three referenced NUL-terminated strings are:

- `7B22h`: `DISKETTE BOOT FAILURE`
- `7B3Ah`: `INVALID BOOT DISKETTE`
- `7B52h`: `DRIVE NOT READY ERROR`

Important correction: it is not valid to say that marker 06h necessarily prints one of these messages. The dispatcher enters `D691` with SI=0006h; `D6A1: SHL SI,1` leaves CF=0 for this value. At `F78E`, JNC is consequently taken to `F7FAh`, bypassing both the `7B52h` selection and the `EEABh` message-output call. The three-message block is shared code whose other entry conditions still need mapping.

CX is not initialized by the common setup at D691. Its value is inherited from the preceding path; therefore the JCXZ branch determines whether the provisional string pointer would be 7B22h or 7B3Ah if execution reaches the message block.

## Boot-sector validation and handoff

The path at `F7FAh` begins:

```asm
F7FA: 8B FB          MOV DI,BX
F7FC: 26 8B 05       MOV AX,ES:[DI]
F7FF: B9 80 00       MOV CX,0080h
F802: FA             CLI
F803: FC             CLD
F804: F3 AE          REPNZ SCASB
F806: FB             STI
F807: E3 A5          JCXZ F7AEh
F809: E8 2B F7       CALL F736h
F80C: EA 00 7C 00 00 JMP 0000:7C00h
```

This establishes a bounded 128-iteration byte scan at ES:DI, followed by a helper call and a far jump to the conventional boot-sector entry 0000:7C00h. The exact byte being searched for depends on AL at entry and is not yet established. Do not label this scan as an AA55 signature check: the separate AA55 comparison seen elsewhere in the surrounding boot code is at a different address/path.

## INT 13h read retry helper

At `F810h`:

```asm
F810: B9 04 00       MOV CX,4
F813: 51             PUSH CX
F814: B9 01 00       MOV CX,1
F817: B8 01 02       MOV AX,0201h
F81A: CD 13          INT 13h
F81C: 59             POP CX
F81D: 73 0C          JNC F82Bh
F81F: 50             PUSH AX
F820: 33 C0          XOR AX,AX
F822: CD 13          INT 13h
F824: 58             POP AX
F825: D0 E4          SHL AH,1
F827: 72 02          JC F82Bh
F829: E2 E8          LOOP F813h
F82B: C3             RET
```

This routine performs up to four INT 13h reads with AX=0201h (read one sector), preserving the outer retry count on the stack. On failure it issues INT 13h with AX=0000h before retrying. The carry branch at F825/F827 can terminate the retry loop early. The drive number and transfer buffer are supplied by the caller and must be traced at each call site before assigning this helper to a specific drive or buffer.

## What is established / still open

Established:
- CMOS[8Fh]=06h selects the F786h dispatch entry.
- F786h is part of the disk-boot/error-handling region.
- The path includes a scan/check stage and a far handoff to 0000:7C00h.
- F810h is a bounded INT 13h sector-read retry helper.
- The message strings and their exact ROM addresses are confirmed.

Still open:
- The caller state supplying CX, BX, AL, DL and ES at F786h/F7FAh.
- The semantic purpose of the REPNZ SCASB scan and the value expected in AL.
- The precise condition that reaches the AA55 comparison at F7A3h in the alternate branch.
- Why POST writes 06h to CMOS[8Fh] before the CPU-mode/reset checkpoints.

## Next analysis target

Trace all callers/entry paths into F736h, F780h, F786h, F7FAh and F810h. Reconstruct the complete register contract (especially BX, AL, DL, ES, CX), and distinguish the normal disk boot path from the three error-message branches.
