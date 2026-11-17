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

## Follow-up: entry-state contract and all local calls to F810h

A second pass over the call sites confirms four near CALL references to the retry helper at F810h:

- F782: CALL F810h (displacement 008Bh)
- F79D: CALL F810h (displacement 0070h)
- F7D5: CALL F810h (displacement 0038h)
- F7E7: CALL F810h (displacement 0026h)

These calls belong to the disk boot/validation code around F780h. The helper itself sets CX=1 for each INT 13h read and AX=0201h, while the caller-provided DL and ES:BX are not overwritten by the helper. The routine preserves the retry counter on the stack; it does not preserve AX after a successful read (AX is the BIOS return value).

The common dispatcher at D691h performs:
- AX=0040h; DS=0040h
- AL=00h; ES=0000h
- AL=30h; SS=0030h; SP=0100h
- SI is doubled and used to index the table at D6A8h

It does **not** initialize BX, CX, DX, or DI. Thus BX/CX/DL are inherited from the state-machine path. In particular, the F786h path must not be described as having a fully known disk I/O register contract yet.

For marker 06h, SI=0006h on entry to D6A1h; shifting left once produces SI=000Ch and CF=0. The table jump selects F786h. F786h loads SI=7B22h, but at F78Eh the JNC is taken, transferring directly to F7FAh. Therefore this path bypasses the message-output call at F795h. The strings at 7B22h/7B3Ah/7B52h are alternate error paths, not evidence that marker 06h prints an error.

At F7FAh the code copies BX to DI, reads the first word at ES:DI into AX, sets CX=0080h, and scans using REPNZ SCASB with AL equal to the low byte of that first word. The scan is therefore a search for the first byte value in the first word, not itself an AA55 signature comparison. The scan result controls the branch at F807h. A separate AA55 comparison exists in the alternate boot path around F7A3h/F7DBh and must not be conflated with this scan.

### Remaining unknowns
- The precise producer of BX/CX/DL on the marker-06 dispatch path.
- Whether ES:BX at F7FAh refers to a sector buffer or another boot image buffer (ES is definitely 0000h from D691h unless changed by an intervening path).
- The exact role of the F736h helper and the caller context around F780h.

## Follow-up: F736h is a far-jump vector trampoline

The byte sequence at F736h is:

```asm
F736: FF 2E 67 00    JMP FAR PTR [0067h]
F73A: FA             CLI
F73B: 8B EC          MOV BP,SP
F73D: 8C C8          MOV AX,CS
...
```

Thus F736h is not a normal local helper body: it is an indirect far jump through the memory pointer at DS:0067h (the active vector/dispatch pointer in the current data segment). The instructions after F736h are a separate fall-through/alternate entry and must not be attributed to the trampoline's normal execution.

The F810h helper has four local CALL sites (F782, F79D, F7D5, F7E7). At each call, DL and ES:BX remain caller-supplied; the helper sets CX=1 and AX=0201h for INT 13h. The call at F782 is in the first disk-validation path; the other three are in alternate/error/retry paths. More precise semantics require decoding each branch from its actual entry point, because this ROM region contains overlapping entry points and shared tails.

## Correction to the AA55 description

The code at F7A3h compares the word at ES:BX+01FEh against AA55h. This is a genuine boot-sector signature check in the branch that reaches F7A3h. It is distinct from the REPNZ SCASB byte scan at F7FAh. The marker-06 route through F786h takes JNC F7FAh, so it does not execute the F7A3h comparison before the F7FAh scan.

## Adjacent validator at F6D8h — separate entry, do not merge with marker-06 path

A linear decode from F6D8h shows a distinct routine:

```asm
F6D8: FA             CLI
F6D9: FC             CLD
F6DA: 1E             PUSH DS
F6DB: 8E DB          MOV DS,BX
F6DD: 33 F6          XOR SI,SI
F6DF: AD             LODSW
F6E0: 35 55 AA       XOR AX,AA55h
F6E3: 75 32          JNZ F717h
F6E5: B9 80 00       MOV CX,0080h
F6E8: 81 FB 00 E0    CMP BX,E000h
F6EC: 74 03          JZ F6F1h
F6EE: AC             LODSB
F6EF: 8B C8          MOV CX,AX
F6F1: C1 E1 05       SHL CX,5
F6F4: 03 D9          ADD BX,CX
F6F6: C1 E1 04       SHL CX,4
F6F9: 33 F6          XOR SI,SI
F6FB: AC             LODSB
F6FC: 02 E0          ADD AH,AL
F6FE: E2 FB          LOOP F6FBh
F700: 75 19          JNZ F71Bh
...
```

The exact full routine contains a checksum-like byte accumulation and a special case when BX equals E000h. It is adjacent to the disk boot code but is not reached by the marker-06 dispatch directly: the marker-06 table target is F786h. Treat F6D8h as a separate validation/loader entry until a caller or far-entry contract proves the relationship.

## Entry-point audit

A scan of the 64 KiB image for relative CALL/JMP/Jcc targets finds no direct relative branch targeting F780h or F786h. The known marker-06 entry is the indirect word-table jump at D6A3h through D6A8h (table index 6 = F786h). The F810h retry helper has four direct local CALL sites: F782h, F79Dh, F7D5h, and F7E7h.

This distinction matters: F780h is not a separately established public entry point. F786h is the table-selected entry; F7FAh is reached by its conditional branch for marker 06h. The neighboring routines contain overlapping control-flow and must be decoded from their actual entry offsets, not merely from the byte stream in ascending order.

## Related non-disk continuation: D724h path for CMOS[8Fh] > 0Ah

The dispatcher at D643h sends marker values greater than 0Ah to D724h. This is not the disk boot entry and should be documented separately from marker 06h.

Initial sequence:

```asm
D724: 2E F6 06 81 82 40  TEST BYTE PTR CS:[8281h],40h
D72B: 75 0F             JNZ D73Ch
D72D: 0F 01 E0          SMSW AX
D730: 0A E4             OR AH,AH
D732: 74 08             JZ D73Ch
D734: 0F 20 C0          MOV EAX,CR0
D737: 0C 10             OR AL,10h
D739: 0F 22 C0          MOV CR0,EAX
D73C: B0 03             MOV AL,03h
D73E: E6 80             OUT 80h,AL
```

This branch checks the same independent `CS:[8281h].40h` reset/mode selector already seen at POST checkpoints. If that bit is set, it bypasses the SMSW/CR0 adjustment and continues at D73Ch. If clear, it inspects the machine status word and, when the tested high byte is nonzero, sets CR0 bit 4 before continuing. This is a CPU/mode-recovery continuation, not a disk boot routine.

The following code:
- loads SS=CS and establishes stack state;
- emits POST code 04h;
- sets DS=0040h and ES=0000h;
- checks port 64h bit 2 and the BIOS data-area word at 0040:0472h against 1234h;
- conditionally modifies BP flags;
- emits POST code 05h and then code 06h;
- performs a 128-word accumulation from CS:SI before deciding whether to continue or enter a fallback routine.

The meaning of the BP flags and the full checksum/fallback destination remain unresolved. Do not label this as a memory test or warm reset without tracing the subsequent branch and caller contract.

This gives a useful separation of CMOS[8Fh] continuation classes:
- 06h: table index 6 -> F786h, disk/boot-sector path.
- >0Ah: D724h, CPU/mode-recovery and platform-state checks.
- 04h/05h: special stack setup at D646h -> EEE7h.
- Other values <=0Ah (except 04h/05h): 8A20h path, still being classified.
