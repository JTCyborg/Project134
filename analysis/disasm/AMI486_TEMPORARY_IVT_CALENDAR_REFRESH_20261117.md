# AMI486 temporary IVT hooks and timer-driven calendar refresh

Date: 2026-11-17  
ROM: `ami486.bin`, 65,536 bytes  
ROM SHA-256: `91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b`  
Related report: [AMI486_LOW_ROM_SETUP_VIDEO_ENTRY_20261117.md](AMI486_LOW_ROM_SETUP_VIDEO_ENTRY_20261117.md)

## 1. Install/restore pair

The screen-presentation stream at `00EFh–0235h` calls `626Bh` at `01EAh` and `62BDh` at `0210h`. The raw bytes at 0210h are `E8 AA 60`; next IP 0213h plus signed displacement 60AAh resolves to 62BDh. This is not a call to 6220h.

### 626Bh — install temporary IVT hooks

```asm
626B CLI
626C PUSH AX
626D PUSH DS
626E XOR AX,AX
6270 MOV DS,AX
6272 MOV AX,62ECh
6275 XCHG AX,[0040h]     ; INT 10h offset
6279 MOV [0280h],AX      ; save old INT 10h offset
627C MOV AX,CS
627E XCHG AX,[0042h]     ; INT 10h segment
6282 MOV [0282h],AX      ; save old INT 10h segment
6285 MOV AX,62FCh
6288 XCHG AX,[0068h]     ; INT 1Ah offset
628C MOV [0284h],AX
628F MOV AX,CS
6291 XCHG AX,[006Ah]     ; INT 1Ah segment
6295 MOV [0286h],AX
6298 MOV AX,631Ch
629B XCHG AX,[0070h]     ; INT 1Ch offset
629F MOV [0288h],AX
62A2 MOV AX,CS
62A4 XCHG AX,[0072h]     ; INT 1Ch segment
62A8 MOV [028Ah],AX
62AB MOV AX,[046Ch]     ; BIOS tick count
62AE SUB AX,0011h
62B1 MOV [028Ch],AX     ; timer baseline
62B4 XOR AX,AX
62B6 MOV [028Eh],AX     ; active INT 10h/1Ah nesting counter = 0
62B9 POP DS
62BA POP AX
62BB STI
62BC RET
```

The hook saves the prior six IVT words at `0000:0280h–028Ah` and installs:
- INT 10h -> `F000:62ECh`
- INT 1Ah -> `F000:62FCh`
- INT 1Ch -> `F000:631Ch`

It also stores a tick baseline derived from BDA `0040:006Ch` and clears the active-handler counter at `0000:028Eh`.

### 62BDh — restore previous vectors

```asm
62BD CLI
62BE PUSH AX
62BF PUSH DS
62C0 XOR AX,AX
62C2 MOV DS,AX
62C4 MOV AX,[0280h] / MOV [0040h],AX
62CA MOV AX,[0282h] / MOV [0042h],AX
62D0 MOV AX,[0284h] / MOV [0068h],AX
62D6 MOV AX,[0286h] / MOV [006Ah],AX
62DC MOV AX,[0288h] / MOV [0070h],AX
62E2 MOV AX,[028Ah] / MOV [0072h],AX
62E8 POP DS
62E9 POP AX
62EA STI
62EB RET
```

This exactly reverses the three vector substitutions performed by 626Bh.

## 2. Installed handler entries

### INT 10h handler — 62ECh

- Saves AX/DS, switches DS to zero, increments byte `[028Eh]`.
- Restores DS/AX and invokes `INT A0h`.
- Jumps to shared exit at 630Ah.

### INT 1Ah handler — 62FCh

- Saves AX/DS, switches DS to zero, increments `[028Eh]`.
- Restores DS/AX and invokes `INT A1h`.
- Falls through to the same shared exit at 630Ah.

### Shared exit — 630Ah

```asm
630A PUSHF
630B CLI
630C PUSH AX
630D PUSH DS
630E XOR AX,AX
6310 MOV DS,AX
6312 DEC BYTE [028Eh]
6316 POP DS
6317 POP AX
6318 POPF
6319 RETF 2
```

The counter brackets the INT A0h/A1h forwarding paths. The exact contracts of INT A0h and INT A1h are not defined by this ROM excerpt; they are pre-existing vectors, not installed by 626Bh.

### INT 1Ch timer handler — 631Ch

The timer hook:
1. Saves AX/DS and sets DS=0000h.
2. Reads the BIOS tick count at `0040:006Ch` and subtracts the baseline `[028Ch]`.
3. Does nothing while the elapsed count is below `0Bh`.
4. Applies a second threshold of `11h` for selected ranges of the saved INT 10h segment `[0282h]`; otherwise the `0Bh` threshold is sufficient.
5. When the threshold is reached, advances `[028Ch]` by the elapsed count and sets `[028Fh]=FFh` (refresh pending).
6. Defers the refresh while `[028Eh]` is nonzero, so it does not redraw while INT 10h/1Ah forwarding is active.
7. When the counter is zero and the pending flag is FFh, saves all general registers, calls `6616h`, restores registers and clears the pending flag.
8. Restores DS/AX, invokes `INT A2h` and returns with `RETF 2`.

INT A2h is also an existing external vector; its contract remains unresolved.

## 3. Calendar refresh helper — 6616h

The raw instruction stream at `6616h–6757h` ends with a RET at 6757h. Its first instructions:
- save BP and allocate 0Ah bytes of local state;
- read the current video cursor state through INT 10h AH=03h;
- save cursor position/shape;
- call 0995h to normalize/preserve cursor shape;
- call 6774h to obtain a validated BIOS date.

### Date validation and conversion

- `6774h` calls INT 1Ah AH=04h (read RTC date), retries on carry, and validates the returned BCD year/month/day.
- `68E2h` validates packed BCD nibbles (each decimal nibble must be below 0Ah).
- If the date is invalid/out of range, `6774h` substitutes a default date: CX=1980h, DX=0101h.
- `68FDh` converts a packed two-byte BCD value to binary: it converts the high byte as hundreds and the low byte as units, then adds the two results.
- `6616h` converts the year/month/day fields, derives calendar offsets using CS tables at `6164h` and `616Bh`, and formats the weekday/calendar positions.

### Display update

The updater writes date/calendar fields at fixed cursor coordinates, draws the calendar grid, then restores the saved cursor position and cursor shape before returning. The table at `6164h–6175h` and the weekday/layout bytes at `616Bh` are used as lookup data; their exact field names should remain tied to the observed indexing arithmetic.

This is a **timer-driven calendar/date display refresh**, not a direct CPU MHz measurement and not a generic RTC setter. The visible code reads the date with INT 1Ah AH=04h; it does not itself write the RTC date.

## 4. Integrated control flow

```text
00EFh screen-presentation stream
  |
  +-- CALL 626Bh: install INT 10h / INT 1Ah / INT 1Ch hooks
  |
  +-- render labels and linked callback records
  |
  +-- periodic INT 1Ch -> 631Ch
        |
        +-- wait for tick threshold
        +-- defer while [028Eh] != 0
        +-- CALL 6616h: refresh calendar display
        +-- INT A2h
  |
  +-- CALL 62BDh: restore original INT 10h / INT 1Ah / INT 1Ch vectors
  |
  +-- restore DS:E000h scratch block and cursor state
  +-- RET
```

The timer hook is temporary because the screen routine explicitly calls the restore helper at 62BDh before returning. The saved old vectors and counter fields are part of this short-lived screen/refresh mechanism.

## 5. Open points

- The semantics and installation provenance of existing INT A0h, INT A1h and INT A2h vectors remain unknown.
- The exact segment-range rationale for the 0Bh/11h timer thresholds is not proven.
- The caller stack precondition for 00EFh (the saved BP/SI/DI words consumed by its epilogue) remains unresolved.
- The generator source now requests a 6616h window through 6757h; the currently fetched generated listing still shows the earlier 80h-byte window. Do not claim the extended generated window until the listing/manifest refresh is verified.


## 16-bit mnemonic correction

The byte at 6643h is unprefixed 99h and therefore CWD, not CDQ. Bytes 665Dh and 6669h are unprefixed 98h and therefore CBW, not CWDE. These are essential 16-bit sign-extension instructions in the calendar arithmetic. The Capstone candidate generator and full-linear workflow have been patched to normalize unprefixed 98h/99h. The regenerated artifacts still need verification.
