# AMI486 floppy-controller and DMA subsystem — 2026-11-16

Source: ami486.bin (65,536 bytes), SHA-256 91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b  
Decode: Capstone x86-16, bounded independent seeds in ami486_candidate_windows_20261116.txt. Near relative targets are wrapped to 16-bit IP.

## 1. Hardware interface

This is a separate floppy-disk-controller (FDC) and DMA subsystem. It must not be conflated with the IDE/ATA hard-disk INT 13h handler at A000h–AFFFh.

| Port | Observed use |
|---:|---|
| 03F2h | FDC Digital Output Register (reset/enable/motor state) |
| 03F4h | Main Status Register polling |
| 03F5h | FIFO command bytes and result bytes |
| 03F7h | Digital Input / Configuration Control Register; code writes rate/control bits |
| 000Ch | DMA clear flip-flop |
| 000Bh | DMA mode |
| 0005h | DMA channel-2 count low/high |
| 0004h | DMA channel-2 address low/high |
| 0081h | DMA channel-2 page |
| 000Ah | DMA channel mask; value 02h unmasks channel 2 |

## 2. Entry-to-return map

| Entry | Span / exit | Function and evidence |
|---:|---|---|
| D104h | D155h RET | Drive/media state path; checks CMOS-derived drive state, disk-change input at 03F7h and invokes controller helpers |
| D156h | D196h RET | Programs DMA channel 2: clear flip-flop, mode, count, address, page; unmasks channel 2 |
| D197h | D1BFh RET | Converts ES:BX plus BP-relative offset into a DMA-addressable segment:offset and detects carry/overflow |
| D1C0h | D215h RET | Builds an FDC command packet from SI, DI, BP frame and register bytes; emits each byte through D243h |
| D216h | D242h RET | Transaction coordinator using state byte 003Eh; optionally sends command packet, invokes INT 15h AX=9001h wait, then waits for controller state |
| D243h | D26Fh RET | FIFO command-byte writer: waits on MSR 03F4h, then writes AL to FIFO 03F5h |
| D270h | D293h RET | Reads CX result bytes via D294h into DS:BX, then checks result-phase status |
| D294h | D2BCh RET | Reads one result byte from FIFO after MSR indicates controller-to-host phase |
| D2BDh | D2FCh RET | Maps status bits from word at 0042h into BIOS AH error values |
| D2FDh | D347h | Reset/sense-status path; uses D348h, sends FDC command 08h and collects ST0/cylinder result bytes |
| D348h | D3A2h | Toggles FDC DOR 03F2h through reset/enable sequence, waits, invokes INT 15h AX=9001h and polls controller state |
| D3A3h | D3A4h RET | STC error stub |
| D3A5h | D3B4h RET | Waits for state byte 003Eh through helper E902h |
| D3B5h | D3CEh RET | Reads CMOS register 10h (floppy drive type nibbles), selected by DL; first checks CMOS register 0Eh state |
| D3CFh | D46Ch RET | Per-drive setup using CMOS drive type; configures rate and issues FDC command sequences |
| D46Dh | continuation | Alternate drive-configuration path; full entry/caller contract remains to be traced |
| D499h | D4E9h RET | FDC command transaction/retry helper; uses D216h, collects seven result bytes with D270h and maps status with D2BDh; retry count is three |
| D4EAh | D516h RET | Compares and updates per-drive rate/state bits in 008Bh using table at 0090h |
| D517h | D51Fh RET | Writes DH to FDC control/configuration port 03F7h |
| D520h | D5DCh RET | Multi-stage FDC status/configuration probe; checks response 90h, collects result bytes and reads CMOS 0Eh/10h |
| D5DDh | D601h RET | Builds a selector from AL, issues a short FDC command/result exchange and compares returned value |

The D100h seed itself is not a safe subsystem entry: it begins with a register/return fragment. The better aligned roots are the direct call targets D104h, D156h, D197h, D1C0h, D216h, D243h, D270h, D294h, D2BDh, D2FDh, D348h, D3A5h, D3B5h, D3CFh and D499h.

## 3. Verified control details

### DMA channel 2 setup (D156h)

The code writes:
1. AL (derived from AH) to port 0Ch to clear the DMA flip-flop.
2. AL to port 0Bh as the DMA mode byte.
3. CL then CH to port 05h as the 16-bit transfer count.
4. BL then BH to port 04h as the 16-bit DMA offset.
5. ES low byte to port 81h as the page.
6. 02h to port 0Ah to unmask DMA channel 2.

The sequence is bracketed by CLI/STI and preserves AX/DX. Direct callers supply two concrete mode bytes: C8BBh supplies AH=46h, while C936h/C913h supply AH=4Ah. Under the 8237 DMA mode format, 46h selects channel 2, single-transfer mode, memory-to-device (FDC write); 4Ah selects channel 2, single-transfer mode, device-to-memory (FDC read). This resolves the transfer direction at these call sites.

### FDC command/result protocol

- D243h waits for MSR 03F4h to indicate that the controller accepts a host byte, then outputs the command byte to 03F5h.
- D294h waits for the controller-to-host/result phase, then reads one byte from 03F5h.
- D270h collects a result block into memory, then checks the MSR result status.
- D2FDh sends command 08h and stores two returned bytes at 0042h/0043h. Command 08h is the 8272/765 Sense Interrupt Status command; the subsequent top-bit test checks the ST0 interrupt/status class.
- D2BDh translates bits in the stored status word into BIOS error codes.

### Drive type and rate

D3B5h reads CMOS register 0Eh and tests bits C0h (RTC power-loss / CMOS-checksum status). If both are clear, it reads CMOS register 10h and selects the drive-type nibble based on DL (DL=0 selects the high nibble; nonzero selects the low nibble), then deliberately returns ZF=1. If either 0Eh bit 7 or bit 6 is set, it returns ZF=0 without reading 10h; D3CFh then takes the conservative alternate rate-probe path at D46Dh. CMOS register 10h is the standard floppy-drive-type field; type 05h is 2.88-MB 3.5-inch drive. D517h writes the derived rate code to port 03F7h. The exact meaning of each byte sequence at D40Ah–D462h remains open; the raw command bytes are preserved in the candidate decode and are not assigned speculative names.

## 4. Legacy floppy INT 13h handler and INT 40h chain

A separate legacy floppy INT 13h handler is present at C610h. It:
- saves the interrupt context, sets DS=0040h and validates AH;
- accepts AH=00h–05h, AH=08h and AH=15h–18h;
- dispatches through the 11-word table at C5FAh;
- returns through the common IRET epilogue at C648h–C68Fh.

The native little-endian table at C5FAh is:

| Service | Target | Interpretation |
|---:|---:|---|
| AH=00h | C69Ah | Reset |
| AH=01h | C6CEh | Return last status |
| AH=02h | C7E2h | Read sectors |
| AH=03h | C7E2h | Write sectors |
| AH=04h | C7E2h | Verify sectors |
| AH=05h | C8E1h | Format track |
| AH=08h | C999h | Get drive parameters |
| AH=15h | C6D9h | Get disk type |
| AH=16h | C78Bh | Disk-change/status path |
| AH=17h | C716h | Set media type |
| AH=18h | CB09h | Set media type/format parameters |

The AH=02h/03h/04h shared target uses request state to choose the data direction/operation. The direct paths from C8BBh and C936h call D156h for DMA channel-2 setup; C913h calls D4EAh, D381h, D197h, D156h, D216h, D270h and D2BDh. C6BCh jumps into D2FDh for Sense Interrupt Status. This directly connects the C610h legacy floppy handler to the D100h–D5FFh FDC/DMA routines.

A95Eh is the INT 13h hook installer. Its exact operations are:

```asm
A95E  CLI
A95F  CLD
A960  MOV SI,004Ch
A963  MOV DI,0100h
A966  MOV AX,A08Dh
A969  XCHG AX,[ES:SI]       ; new INT 13h offset, old offset -> AX
A96C  STOSW                 ; save old offset at ES:0100h (INT 40h)
A96D  MOV AX,CS
A96F  XCHG AX,[ES:SI+02h]   ; new INT 13h segment, old segment -> AX
A973  STOSW                 ; save old segment at ES:0102h
```

Thus INT 13h is replaced with **CS:A08Dh**, while INT 40h is dynamically set to the *previous* INT 13h vector. A08Dh forwards floppy requests (DL<80h) through INT 40h; it also forwards AH=00h through INT 40h. Therefore INT 40h is a chain to the pre-existing INT 13h handler, not a ROM-hardcoded pointer.

Important precondition: A95Eh uses ES-relative IVT addresses but does not itself load ES=0000h. Its direct caller is at 134Eh. The caller's ES value at that point must be verified before treating the writes as proven IVT writes; the routine's intent and address constants clearly target the IVT, but the ES setup is a separate unresolved caller contract.

C610h is the in-ROM legacy floppy INT 13h implementation candidate. A separate in-ROM near JMP at EC59h targets C610h, which supports a relationship between the two streams, but the ROM contains no direct far-pointer literal C610h:F000h and A95Eh does not hardcode C610h. Consequently C610h is a strong candidate for the prior handler, not a proven runtime INT 40h target. The actual INT 40h segment:offset is inherited dynamically and requires an initialized IVT snapshot or trace.

## 5. Remaining work

1. Identify the INT 40h vector target and prove whether it enters this FDC subsystem.
2. Trace callers and parameter contracts for D104h, D156h, D1C0h, D216h, D2FDh, D3CFh and D520h.
3. Trace the remaining drive-type/state branches around D407h–D462h; the D499h transaction is now identified as a Read ID probe and the immediate AL values are rate/state tokens, not command bytes.
4. Capture the initialized INT 40h vector to confirm the exact runtime segment:offset of the legacy floppy handler (C610h is the strong in-ROM candidate).
5. Trace the source of the two configuration bytes read through EEAAh before the perpendicular-mode setup; the extended FDC feature sequence itself is now identified.

No whole-ROM semantic percentage is inferred from this subsystem map.


## 6. DMA transfer direction verified at callers

The mode bytes passed to D156h are visible in the direct callers:
- C8BBh loads AH=46h before calling D156h. With 8237 mode bits, 46h = channel 2, single mode, transfer type 01b (write: memory to FDC). This is the disk-write direction.
- C936h and C913h load AH=4Ah before calling D156h. 4Ah = channel 2, single mode, transfer type 10b (read: FDC to memory). This is the disk-read direction.

Thus the FDC DMA channel is channel 2, with direction selected by the caller's AH mode byte. The D156h helper itself writes the supplied mode byte unchanged to DMA port 0Bh.


## 7. D40Ah–D462h: data-rate probing and Read ID transaction

The bytes loaded into AL in this region are **not FDC command opcodes**. They are drive-state/rate tokens passed through D3EDh/D499h:

- D3EDh extracts AL[7:6] into DH and calls D517h.
- D517h writes DH (0..3) to port 03F7h, the Configuration Control Register/data-rate selector.
- D3FAh stores the full token in [BX+90h], then tests bit 4 as part of the drive-state path.
- D499h repeats the rate selection from AL[7:6] before probing the selected drive.

D499h performs a two-byte **READ ID** command transaction:

1. It loads the selected drive number from [BP+0Eh], sets SI to 4Axxh, and sets CH=2.
2. D1C0h emits exactly two FIFO bytes: 4Ah, then the drive/head byte. The opcode 4Ah is the µPD765 READ ID command (base opcode 0Ah with MFM bit 6 set).
3. D270h reads exactly seven result bytes: ST0, ST1, ST2, C, H, R and N.
4. D2BDh maps status bytes into the BIOS error code; D499h retries up to three times and returns CF on failure.

This matches the µPD765 READ ID command's two command bytes and seven-byte result phase. The D40Ah–D462h constants therefore select candidate data rates and saved per-drive state, while the actual command is constructed in D499h/D1C0h. The exact meaning of every low-bit state token in [BX+90h] still needs caller/state-transition tracing.

## 8. D520h–D5D9h: enhanced FDC identification and configuration

The sequence is a controller-capability/configuration path, not a media-change-only routine:

| Address | Bytes / action | Interpretation |
|---:|---|---|
| D520h | CH=1, SI=0010h; D216h sends one byte; D294h reads one byte; compare AL=90h | VERSION command 10h; response 90h identifies the 82077AA-class enhanced controller family |
| D53Bh | CH=1, SI=000Eh; D216h sends one byte | DUMPREG command 0Eh |
| D54Ah–D567h | Reads 7 + 1 + 2 result bytes | Ten-byte enhanced DUMPREG result block |
| D584h–D589h | AL=00h; call D5DDh | UNLOCK command 14h; expects returned lock state 00h |
| D58Bh–D59Bh | CH=4, SI=0013h, DI=0008h; D216h sends 13 00 08 00 | CONFIGURE command 13h with parameters 00h,08h,00h |
| D59Dh–D5C1h | Reads CMOS 0Eh; if valid, reads CMOS 10h and tests both drive-type nibbles for 05h | Sets the per-drive bits in the PERPENDICULAR MODE parameter for 2.88-MB drives |
| D5C4h–D5D2h | SI receives command 12h plus the computed parameter; CH=2; D216h sends both bytes | PERPENDICULAR MODE command 12h |
| D5D4h–D5D9h | AL=80h; call D5DDh | LOCK command 94h; expects returned lock state 10h |

D5DDh is a generic lock-state verifier. It computes expected result CL=AL>>3, constructs the command byte AL OR 14h, sends one command byte through D216h, reads one result byte through D294h and compares it with CL. Thus AL=00h produces UNLOCK 14h and expected result 00h; AL=80h produces LOCK 94h and expected result 10h. This is the 82077AA LOCK/UNLOCK extension.

The VERSION response 90h, DUMPREG, LOCK/UNLOCK, CONFIGURE and PERPENDICULAR MODE sequence is consistent with an 82077AA-or-later enhanced 765-compatible controller. It does not by itself distinguish an 82077AA from later compatible variants. The actual controller model fitted to the board is not established by the ROM bytes alone.



## 9. D3B5h/D3CFh: CMOS drive-type dispatch and data-rate fallback

D3B5h and D3CFh together explain the selection logic that feeds D40Ah–D462h:

1. D3CFh reads the drive selector from [BP+0Eh], places it in DL and calls D3B5h.
2. D3B5h reads CMOS 0Eh. If bits C0h are set, it returns with ZF=0; D3CFh jumps to the alternate path at D46Dh.
3. If CMOS 0Eh bits C0h are clear, D3B5h reads CMOS 10h, selects the high nibble for DL=0 or the low nibble for DL!=0, masks to 4 bits, executes CMP SP,SP to return ZF=1, and returns the drive-type value in AL.
4. D3CFh uses the returned ZF to select the normal CMOS type-dispatch path. It clears [BX+90h], then decrements AX through the type cases.

### Normal CMOS type path

| CMOS type nibble | Probe order (data-rate code written to 03F7h) | Stored [BX+90h] result token |
|---:|---|---|
| 1 | No READ ID probe; select rate 2 | 93h |
| 2 | 0, then 1 | 15h on code 0 success; 74h on code 1 success; 02h if both fail |
| 3 | 0, then 2 | 17h on code 0 success; 97h on code 2 success; 07h if both fail |
| 4 | 3, then 0, then 2 | D7h, 17h or 97h on first successful probe; C7h if all fail |
| 0 or other | Same fallback as type 4 | D7h, 17h, 97h or C7h |

The rate code is AL[7:6], shifted down and written to 03F7h by D517h. The common D3FAh path stores the full token and tests bit 4: bit 4 set clears CF and returns success; bit 4 clear sets CF and returns failure. Thus bit 4 is a confirmed success flag and bits 7:6 are the data-rate selector. The exact meaning of bits 3:0 beyond the observed per-type values remains unresolved.

### CMOS 0Eh alternate path at D46Dh

When CMOS 0Eh bits C0h are set, the code bypasses the normal type-nibble switch and probes in this order:

| Probe order | Rate code | Success token |
|---:|---:|---:|
| 1 | 0 | 15h |
| 2 | 1 | 74h |
| 3 | 2 | 97h |
| 4 | 3 | D7h |

Each successful READ ID exits through D3FAh. If all four probes fail, the routine returns with CF set. The new candidate window D46Dh–D498h records this previously clipped alternate path, including the final JMP back to D3FAh.

This maps the high-bit rate and success fields of [BX+90h], but it does not assign meanings to every low nibble bit or identify the exact CMOS 0Eh board-specific flag semantics.


## 10. C84Bh caller: state-byte validity and SPECIFY timing selection

The caller at C846h–C855h independently confirms the state-byte contract:

- C846h tests bit 4 of the per-drive byte at [SI]. If set, it skips D3CFh and calls D4EAh; if clear, it calls D3CFh at C84Bh. CF from D3CFh controls retry through C838h.
- After successful setup, C855h indexes the per-drive state array at 0090h+DX and selects the three-byte FDC SPECIFY command through D216h:
  - token D7h -> SI=AF03h, DI=0002h, CH=3 -> command bytes 03 AF 02;
  - token 17h -> SI=BF03h, DI=0002h, CH=3 -> command bytes 03 BF 02;
  - all other observed tokens -> SI=DF03h, DI=0002h, CH=3 -> command bytes 03 DF 02.

This is the µPD765 SPECIFY command (03h). It confirms that [BX+90h] is a per-drive configuration/status token: bit 4 marks a successful/valid setup, bits 7:6 carry the data-rate selector, and selected full-byte values D7h/17h choose distinct step-rate/head-unload timing parameters. The remaining low-nibble distinctions are not yet fully explained. The C84Bh caller is a verified direct near-CALL xref to D3CFh; the larger caller's own entry boundary remains outside this FDC-focused pass.


## 11. D4EAh: global data-rate synchronization

D4EAh provides an independent confirmation of the [BX+90h] rate field:

- SI is set to 0090h+drive-index and DH is loaded from the per-drive state byte.
- DL is loaded from the global byte at 008Bh.
- AND DX,C0C0h isolates the top two bits of both values; CMP DL,DH compares the global selected rate with the per-drive rate.
- If they differ, the code preserves the low six bits of [008Bh], copies the per-drive rate bits into [008Bh], shifts DH[7:6] down to DH[1:0] and calls D517h to write the rate code to port 03F7h.

Therefore [BX+90h] bits 7:6 are definitively the per-drive data-rate selector, while [008Bh] stores the currently programmed global rate. D4EAh restores the original drive selector in DX before returning. The token's bit 4 success flag and its D7h/17h SPECIFY timing uses are established in section 10; the remaining low-nibble flags still need caller tracing.


## 12. CMOS helper and perpendicular-mode parameter source

EE94h is the raw CMOS read helper: it writes the register selector to port 70h, performs the short delay sequence, reads the data from port 71h and returns it in AL. EEAAh is the protected read entry: it disables interrupts, sets the CMOS/NMI index bit for ordinary register selectors, calls EE94h and returns the read byte while restoring the saved flags. Therefore the EEAAh calls in D3B5h and D5A1h are CMOS reads, not opaque hardware-port probes.

D5A1h reads CMOS 0Eh. If either bit 7 or bit 6 is set (RTC power-loss / CMOS checksum-invalid status), it skips the drive-type-dependent perpendicular flags and uses the base parameter 80h. If both are clear, it reads CMOS 10h, splits the drive A high nibble and drive B low nibble, and compares each with type 05h (2.88-MB 3.5-inch drive). A match in drive B sets CH bit 3; a match in drive A sets CH bit 2. The resulting parameter is sent with FDC PERPENDICULAR MODE command 12h. This resolves the former EEAAh parameter-source question and establishes the CMOS 0Eh fallback behavior. The remaining state-token question is limited to the low-nibble meanings of [BX+90h] beyond the observed SPECIFY cases.


## 13. A95Eh ES precondition trace

A95Eh is called at 134Eh from the alternate entry stream beginning at 131Fh; 131Fh is a direct CALL target from 1BAAh. This stream reads CMOS 0Eh and 92h and calls A95Eh only when the CMOS status gate is clear and register 92h is nonzero. The 1BAAh caller saves/restores DS around a C000h option-ROM signature check but does not initialize ES. The earlier 1303h sequence that temporarily sets ES=0000h belongs to a different linear instruction stream and is not executed by a call entering at 131Fh. Therefore the 131Fh call path does not prove ES=0000h; A95Eh's IVT write interpretation remains conditional on inherited ES. The generated candidate listing includes the direct-call target window 131Fh–1364h.
