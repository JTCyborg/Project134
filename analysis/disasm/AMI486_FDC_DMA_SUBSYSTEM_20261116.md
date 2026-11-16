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

The sequence is bracketed by CLI/STI and preserves AX/DX. This directly confirms channel-2 DMA programming; the exact transfer direction/mode depends on the caller-supplied AH mode byte.

### FDC command/result protocol

- D243h waits for MSR 03F4h to indicate that the controller accepts a host byte, then outputs the command byte to 03F5h.
- D294h waits for the controller-to-host/result phase, then reads one byte from 03F5h.
- D270h collects a result block into memory, then checks the MSR result status.
- D2FDh sends command 08h and stores two returned bytes at 0042h/0043h. Command 08h is the 8272/765 Sense Interrupt Status command; the subsequent top-bit test checks the ST0 interrupt/status class.
- D2BDh translates bits in the stored status word into BIOS error codes.

### Drive type and rate

D3B5h reads CMOS register 10h and selects one of its two nibbles based on DL. This is the standard CMOS floppy-drive-type field. D3CFh uses the returned type to choose a controller setup sequence. D517h writes the derived rate/control value to port 03F7h. The exact meaning of each byte sequence at D40Ah–D462h remains open; the raw command bytes are preserved in the candidate decode and are not assigned speculative names.

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

A95Eh saves the previous INT 13h vector into the INT 40h vector slot. A08Dh forwards requests with DL<80h by executing INT 40h. This is the chain to the legacy floppy handler. C610h is the matching in-ROM floppy INT 13h implementation and is the strong candidate for the saved target; the actual runtime segment:offset stored at 0000:0100h should still be confirmed from a trace or initialized IVT snapshot.

## 5. Remaining work

1. Identify the INT 40h vector target and prove whether it enters this FDC subsystem.
2. Trace callers and parameter contracts for D104h, D156h, D1C0h, D216h, D2FDh, D3CFh and D520h.
3. Decode the command bytes at D40Ah–D462h against the 8272/765 command format and the state at BP+0Eh / [BX+90h].
4. Verify the DMA mode byte at D156h at every call site to determine read versus write direction.
5. Determine whether D520h/D5DDh are media-change checks, drive-type probes or a separate controller diagnostic.

No whole-ROM semantic percentage is inferred from this subsystem map.
