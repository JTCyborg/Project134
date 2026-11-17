# AMI486 address-ledger extension: PS/2 auxiliary device and IRQ12 mouse path

Date: 2026-11-17  
ROM: ami486.bin, 65,536 bytes  
SHA-256: 91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b

## 1. Scope

The interval 93F8h–9870h is the next continuation after the INT 15h service cluster. The aligned streams and their tables describe a PS/2 auxiliary-device interface: commands F4h/F5h/F2h/F3h/E8h/E9h/FFh, 8042 command D4h, BDA mouse state at 0040:0026h–0028h, a callback pointer at 0040:0022h, and a packet handler that acknowledges both PICs.

The INT 15h C2h mouse-service identity is strongly supported by the eight AL subfunctions and command contracts, but the full IVT/vector installation path is not yet proven.

## 2. Feature-gated controller path at 93F8h

93F8h checks that PE is clear, CS:8256h is nonzero, and BDA 0040:0016h has the expected feature bits before touching the controller. It reads PIC state through the helper at EAE0h, writes controller commands AFh and C0h through port 64h, waits for controller responses, then issues command 20h and writes data 30h to port 60h. It updates BDA 0040:0016h and calls either 8BA3h or 8B5Eh on the respective path.

This is a feature-gated 8042 auxiliary-device/controller initialization path. The exact runtime entry and the precise meaning of every BDA flag are still open.

The small helpers are:
- 949Fh: OUT AL,64h.
- 94A1h: wait for controller input/output-buffer state through port 64h; returns status in AH/flags.
- 94B3h: wait for output-buffer full and read port 60h.

## 3. Eight-function mouse service dispatcher at 94C2h

94C2h saves BP/DS/DI/AX, rejects AL>=8, loads DS from BDA 0040:000Eh (the extended-BIOS-data segment), and dispatches through the eight-word table at 94FAh. On return it copies AH into the caller's saved AX frame and updates the saved FLAGS carry bit before restoring registers and executing IRET at 94F4h. The error path sets AH=1 and CF.

The table at 94FAh–9509h is:

| AL | Target | Handler contract established from bytes |
|---:|---:|---|
| 0 | 950Ah | Enable/disable mouse data reporting |
| 1 | 954Fh | Reset mouse with FFh |
| 2 | 955Bh | Set sample rate with F3h |
| 3 | 9590h | Set resolution with E8h; alternate entry |
| 4 | 959Ah | Read device ID with F2h |
| 5 | 95A5h | Configure auxiliary-device mode/state and IRQ12 mask; parameter details partly open |
| 6 | 9530h | Read mouse status with E9h |
| 7 | 95E2h | Install/remove user callback pointer at BDA 0040:0022h |

The table is a confirmed data view at 94FAh–9509h. Its targets are not all aligned with the global linear decode; in particular target 9590h enters the middle of the instruction that the linear decoder starts at 958Eh.

## 4. Mouse command handlers and tables

### 4.1 Reporting enable/disable — 950Ah

BH=0 sends F5h (disable data reporting) and sets BDA 0040:0026h bit 80h. BH=1 checks BDA 0040:0027h bit 80h, sends F4h (enable data reporting), and returns an error if the device has not been initialized. Other BH values return AH=1 with CF.

### 4.2 Reset — 954Fh

Sends FFh through the common transaction wrapper at 9603h and clears BDA 0040:0026h after the transaction.

### 4.3 Sample rate — 955Bh and 9589h

Sends F3h, then a sample-rate byte selected by BH from the seven-byte table at 9589h–958Fh:

| BH | Value | Decimal rate |
|---:|---:|---:|
| 0 | 0Ah | 10 |
| 1 | 14h | 20 |
| 2 | 28h | 40 |
| 3 | 3Ch | 60 |
| 4 | 50h | 80 |
| 5 | 64h | 100 |
| 6 | C8h | 200 |

Values are the standard PS/2 sample-rate sequence. The table ends at 958Fh; the alternate resolution entry begins at 9590h.

### 4.4 Resolution — 9590h alternate entry

The callback table points directly to 9590h, which begins with CMP BH,03h. This is an aligned alternate stream entry inside the bytes 958Eh–9592h, which the linear listing interprets as ENTER. The alternate stream sends E8h followed by a parameter in the range 0–3. Preserve both views; do not shift the table boundary to make the linear decode appear contiguous.

### 4.5 Device ID and status — 959Ah / 9530h

959Ah sends F2h and returns the device-ID response. 9530h sends E9h and requests the three-byte mouse status response.

### 4.6 Mode and callback — 95A5h / 95E2h

95A5h validates BH, updates BDA 0040:0027h state bits, retries the reset transaction through 954Fh, and on success unmasks IRQ12 by clearing bit 4 in the slave PIC mask at port A1h. The exact meaning of the BH mode value is not yet confirmed.

95E2h writes BX and ES to BDA 0040:0022h and 0040:0024h, and sets/clears BDA 0040:0027h bit 80h according to whether the callback pointer is nonzero.

## 5. 8042 transaction helpers

- 9603h is the common mouse-command/response wrapper. It uses 96F2h/96F6h to issue controller commands, sends the mouse byte through 965Ch, reads ACK/data bytes through 96BBh, and returns the received bytes in AL/BL/BH/DL as requested by the caller.
- 965Ch sends command D4h to port 64h, then the supplied byte to the auxiliary device via port 60h. It retries/waits and checks the controller response; timeout/error is returned through CF/AH.
- 96BBh polls the 8042 status helper at 97FAh and reads port 60h when output is ready.
- 96D2h waits for input-buffer availability and writes AL to port 60h.
- 96F2h selects controller command 65h; 96F6h selects command 47h; 96F8h sends the command through the ROM wait helper F635h.
- 97FAh reads port 64h, masks with 21h and compares against 21h.

## 6. IRQ12 packet handler at 9712h

9712h is an interrupt-style handler: it sends no normal RET, restores its saved state and ends with IRET at 97F9h. It reads the auxiliary-device byte from port 60h and uses BDA 0040:0026h as packet state and 0040:0028h onward as the packet-byte buffer.

- It distinguishes protocol/status bytes FEh, FCh and FAh and updates the packet state flags in BDA 0040:0026h.
- It stores incoming bytes into the buffer at BDA 0040:0028h, using the low bits of the state byte as the current packet position.
- When a complete packet is available, it extracts the packet fields and dispatches through the eight-word table at 9784h–9793h.
- The selected packet decoder builds the callback arguments and executes a far call through the user callback pointer at BDA 0040:0022h.
- It sends EOI to the slave PIC through port A0h and to the master PIC through port 20h before restoring registers and IRET.

The table at 9784h–9793h is:

| Index | Target |
|---:|---:|
| 0 | 97D9h |
| 1 | 97D5h |
| 2 | 97CEh |
| 3 | 97C5h |
| 4 | 97BBh |
| 5 | 97B1h |
| 6 | 97A1h |
| 7 | 9794h |

These eight words overlap the linear instruction view at 9784h. Each target is an alternate instruction entry; retain the target-aligned decodes separately from the apparent linear opcodes.

## 7. Auxiliary-port reset/initialization at 9801h

9801h saves flags, masks IRQ12 by setting bit 4 in the slave PIC mask at A1h, sends controller command 5Ch through F651h, and calls 1870h. It then performs a bounded sequence:
- sends D4h to port 64h;
- sends FFh to the auxiliary device through F5C9h;
- handles FEh (RESEND) and checks the expected AA/00 reset/device-ID response;
- on success sets bit 2 in BDA 0040:0010h;
- restores controller command 65h through F651h and restores flags.

This is a strong mouse-port reset/initialization candidate. The direct caller/vector provenance for 9801h remains to be located.

## 8. Generator and remaining gaps

The candidate generator now includes bounded seeds for 93F8h–9801h, the eight mouse-service callbacks, the 8042 transaction helpers, IRQ12 handler and its alternate packet-decode entries. It emits these tables separately:
- 94FAh–9509h: eight mouse-service callback offsets;
- 9589h–958Fh: seven sample-rate values;
- 9784h–9793h: eight IRQ12 packet-dispatch offsets.

The 93F8h–9870h report does not include the following video-BIOS region beginning at 9870h. That region is the next subsystem to map. The 93F8h routine and 9801h initializer still need their exact runtime entry/vector sources.

This is a bounded subsystem extension, not a claim that all bytes 93F8h–9870h are semantically complete.
