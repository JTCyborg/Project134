# AMI486 address-ledger extension: interrupt handlers, CMOS/RTC, protected mode and video diagnostics

Date: 2026-11-17  
Source: `ami486.bin`, 65,536 bytes  
SHA-256: `91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b`

## 1. Region boundary and evidence

The former candidate-mask gap E865h–F52Dh is not a single unknown code block. It contains a short delay helper beginning at E862h, port-polling helpers, interrupt/exception handlers, a protected-mode instruction path, RTC/CMOS and PIC services, diagnostic strings, opaque data blocks, Setup routines, and video/ROM checks.

The current candidate generator uses bounded seeds and separate data ranges. These are independent inspection windows, not a complete control-flow graph. An aligned entry is considered confirmed only where a direct branch/call, a stack-return word, or a clear handler structure supports it. For several IRET entries the exact IVT vector installation remains unproven.

## 2. POST notification and polling helpers

### 2.1 E831h/E845h notifications and E862h delay

- E831h sets bit 7 in BDA byte 0040:003Eh, sends EOI to the master PIC, and invokes INT 15h with AX=9101h before IRET.
- E845h sets BDA byte 0040:008Eh to FFh, sends EOI to the slave and master PICs, invokes INT 15h with AX=9100h, then IRETs.
- E862h–E87Ah is a delay helper consisting of twelve short JCXZ timing steps followed by RET. E966h calls it.

The exact interrupt vectors associated with E831h/E845h are not established by this local block alone.

### 2.2 E87Bh parameter bytes

E87Bh–E88Dh is a 19-byte data area:
`00 00 00 52 3A 45 46 38 1D 2A 36 80 40 20 10 08 04 02 01`.

It resembles timing/poll parameters, but no direct consumer was confirmed in the inspected callers. It is retained as data with unresolved semantics, not decoded as instructions.

### 2.3 Port-polling helpers

- E88Eh–E8C7h polls the port in DX against the mask in AH. It uses CS:8285h as an inner delay count and PIT channel-2 bit 10h for transition waits; timeout returns with CF set.
- E8C8h–E901h is the inverse-polarity variant.
- E902h–E93Bh polls bit 80h at [BX], also using CS:8285h and PIT timing.
- E93Ch–E965h waits for PIT channel-2 bit 10h transitions. Confirmed callers: F56Ah, F591h and F8B6h.
- E966h–E97Ah polls the port in DX until `AL & BL == BL`, using E862h for delay and DI as an outer retry count. Confirmed callers: F9EFh and F9F8h.

E97Bh–E986h is twelve zero bytes. E987h is a three-byte near-JMP stub to AE60h.

## 3. Parity/NMI diagnostics and error strings

E98Ah–E9A1h is an IRET handler candidate. It selects CMOS register 8Dh, reads port 61h and tests bits C0h. If neither parity/channel-check bit is set, it calls 8B10h, restores CMOS index 0Dh and IRETs. If either bit is set, it branches to E9A2h.

E9A2h–EA3Eh is the alternate diagnostic path:
- It calls 8300h using the status byte at CS:B50Eh.
- On the non-diagnostic path it sets bits 0Ch at port 61h and restores CMOS index 8Dh.
- On the diagnostic path it scans memory in 64-KiB chunks, tests port 61h bits 80h/40h while reading words, and records the segment/address of the failure.
- It prints one of the parity messages, then the address in hexadecimal and a final diagnostic string using F52Eh/F53Ch and the helpers EA1Ah/EA25h/EA31h.

The text at EF5Ah–EFAAh confirms the message roles:
- `ON BOARD PARITY ERROR`
- `OFF BOARD PARITY ERROR`
- `ADDR (HEX) = (`
- `PARITY ERROR ????`

This strongly supports a parity/channel-check diagnostic handler. The exact interrupt vector that enters E98Ah is not established here.

## 4. RTC, PIC and timer handlers

### 4.1 RTC interrupt handler candidate at EA42h

EA42h–EA96h reads CMOS status C and B through EE86h/EE80h, tests the 60h/40h bits, updates BDA words at 0040:009Ch/009Eh and byte 0040:00A0h, clears a status-B bit through EE8Ch, and invokes INT 4Ah when the pending flag requires it. This is consistent with an RTC alarm/periodic-interrupt handler; the vector installation still needs confirmation.

### 4.2 PIC in-service handler at EA97h

EA97h–EACCh reads the master and slave PIC in-service registers through EAE0h, conditionally issues EOIs through EACDh, and stores the resulting interrupt state in BDA byte 0040:006Bh before IRET. EACDh writes a PIC command/mask value; EAE0h selects ISR read mode and returns the value.

### 4.3 Timer and floppy-motor handlers

- ECE7h–ED15h updates the BDA tick count at 0040:006Ch/006Eh, sets the midnight flag at 0040:0070h on rollover, and jumps to the prior timer path at 8898h.
- ED16h is a separate aligned continuation: it selects ED1Bh or 93F8h.
- ED1Bh–ED38h decrements the floppy-motor timeout at 0040:0040h, writes 0Ch to the floppy DOR port 3F2h when it expires, invokes INT 1Ch, sends PIC EOI and IRETs.
- FEA5h directly jumps to ECE7h.

## 5. Instruction-exception and protected-mode paths

### 5.1 EAEBh/EB43h saved-IP decoders

EAEBh–EB42h examines the saved CS:IP at the interrupt stack frame. It skips WAIT (9Bh) and segment-override prefixes, recognizes x87 ESC opcodes D8h–DFh, calculates the ModRM/displacement length, updates the saved IP and IRETs. Non-matching instructions fall through to the EA97h handler.

EB43h–EB64h is a second entry for special opcode sequences. It recognizes F0h and the 0Fh/05h sequence; the 0F05h path branches to EB65h. Other cases adjust the saved IP or route to EA97h. This is an instruction/exception dispatch path; the exact interrupt vector is not assigned in this report.

### 5.2 EB65h protected-mode-assisted 0F05h path

EB65h–EC2Bh is entered from EB43h when the saved instruction is 0F05h. It:
- disables interrupts and creates a 32-byte scratch area on the current stack;
- copies 32 bytes from CS:E270h;
- calls EC2Ch twice to build/adjust descriptor entries;
- loads a temporary GDT, sets CR0.PE and far-jumps to selector 0010h;
- conditionally loads DS=0008h and ES=0018h;
- clears CR0.PE, far-jumps back to F000:EBF3h, restores the original stack/register state and IRETs.

EC2Ch–EC49h is the descriptor builder used by this path. This is a protected-mode-assisted handler for the special 0F05h instruction sequence; it should not be conflated with the separate INT 15h AH=89h service invoked elsewhere in POST.

### 5.3 F065h/F068h protected-mode exit/reset path

F065h–F067h is a near-JMP stub to 9870h. F068h–F098h is a separate aligned entry:
- tests CS:8281h bit 40h;
- loads the GDT pointer at CS:E268h;
- loads DS/ES/SS=0040h, clears CR0.PE and far-jumps to F000:F090h;
- F090h loads the IDT pointer at CS:E2B8h and F096h jumps to the reset entry E05Bh.

The code uses the E260h descriptor/parameter area already classified in the previous region report. Its caller/entry provenance remains unresolved.

## 6. Printer, INT 1Ah and CMOS/PIC helpers

- EC5Ch–ECD2h is reached by the direct JMP at FF54h. It queries INT 17h printer status; on the normal path it queries video mode/cursor geometry and uses INT 10h to write screen characters, then restores state and IRETs. It is an interrupt-handler-like printer/status path; the precise vector mapping is not inferred from the JMP alone.
- ECD3h–ECDDh emits CR/LF through INT 17h; ECDEh–ECE6h is the printer-byte output helper.
- ED3Dh–ED71h is an INT 1Ah-compatible time/date dispatcher. AH=0/1 reads or updates the BDA tick count and rollover flag; AH=2–7 dispatches to RTC/CMOS operations; AH>=8 returns the error path. It returns with RETF 2.
- ED72h–EE18h contains the AH sub-dispatch and the associated RTC/CMOS transactions.
- EE19h–EE42h checks RTC readiness and performs initialization; EE43h–EE51h polls a status bit; EE52h–EE62h reads multiple RTC bytes; EE63h–EE74h writes multiple RTC bytes.
- EE75h–EE7Fh updates the slave PIC mask.
- EE80h/EE86h/EE8Ch are CMOS status-B read, status-C read and status-B write helpers.
- EE94h reads the CMOS index/data ports 70h/71h; EE9Dh writes them. EEAAh/EEB9h wrap read/write while preserving flags and the NMI-mask state.
- EED2h and EEDBh are separate interrupt stubs: one sends slave EOI then invokes INT 0Ah; the other clears port F0h, calls the PIC EOI helper and invokes INT 02h.
- EEE7h writes the port-F1h command used by POST. EEEFh–EF35h initializes and programs the master/slave PIC masks.
- EF36h–EF56h is a CMOS 8Dh/port-61h NMI status helper, called from F724h and F808h. EF57h is a near-JMP stub to E831h.

## 7. Embedded strings and opaque data

| Range | Classification | Status |
|---|---|---|
| E87Bh–E88Dh | 19-byte delay/poll parameter table | Consumer unresolved |
| E97Bh–E986h | 12 zero bytes | Padding |
| EA3Fh–EA41h | CR/LF/NUL | String/control data |
| EF5Ah–EF6Fh | ON BOARD PARITY ERROR | ASCII including NUL |
| EF70h–EF86h | OFF BOARD PARITY ERROR | ASCII including NUL |
| EF87h–EF89h | CR/LF/LF | Control data |
| EF8Ah–EF98h | ADDR (HEX) = ( | ASCII including NUL |
| EF99h–EFAAh | PARITY ERROR ???? | ASCII including NUL |
| EFABh–EFC6h | 28 zero bytes | Padding |
| EFC7h–F041h | Opaque 123-byte binary block | No confirmed consumer |
| F042h–F064h | 35 zero bytes | Padding |
| F099h–F0A2h | 10 zero bytes | Padding |
| F0A3h–F103h | 97-byte parameter/lookup block | Four 16-byte records plus timing-like values; consumer unresolved |
| F371h–F38Fh | Encoded string | Decodes to “EVALUATION COPY, NOT FOR SALE” plus CR/LF |
| F38Eh–F38Fh | Encoded CR/LF suffix | Alternate overlapping string view |
| F3BCh–F3D9h | 30-byte encoded signature | Compared by F419h against CS:FF9Bh |

The F371h string decoder is F35Ch: it reads a byte from CS:SI, inverts it, rotates left five bits, prints the low seven bits, and stops after the high-bit terminator. F38Eh is a second pointer into the final CR/LF bytes of the first string; both views are preserved.

## 8. CMOS Setup and video/ROM diagnostics

- F104h–F10Ch is a small hardware-state helper.
- F10Dh–F16Dh validates CMOS B7h/B8h state and displays a diagnostic prompt when the values are inconsistent.
- F16Eh–F1C7h checks the option state at CS:8237h and scans the option bytes at CS:8238h–823Dh.
- F1C8h–F1E6h is a Setup callback entry.
- F1E7h–F302h is the interactive CMOS Setup editor. It copies the current 64-byte state to a stack buffer, validates/edits settings, reads RTC time/date through INT 1Ah, and writes the updated state back.
- F303h–F35Bh contains the prompt, keyboard-input filter, uppercase conversion and CMOS scanning helpers.
- F3DBh–F418h reads the current screen through INT 10h and compares transformed screen characters against the ROM bytes at CS:FF9Bh.
- F419h–F42Dh compares 30 bytes at F3BCh against CS:FF9Bh.
- F42Eh–F4A4h displays the encoded evaluation-copy warning and related video/keyboard diagnostics.

F3DBh/F419h are video/ROM signature checks, not generic parity checks. Their direct callers are E2FBh and E343h respectively.

## 9. Fatal POST error path and external references

F4A5h–F506h is the fatal POST error routine. It emits the BP/SI/DI diagnostic values to ports 80h–84h and uses F4E7h to generate a speaker/PIT beep-delay loop. F509h–F50Ch is a separately reached entry (`XOR AX,AX; INT 10h`) with direct jumps from E385h, E38Bh and E391h. F50Dh–F52Dh prints diagnostic text, polls the keyboard-controller state through F5D9h, and routes to the beep path.

Confirmed external code references into this region include:
- F56Ah/F591h/F8B6h -> E93Ch
- F9EFh/F9F8h -> E966h
- FF54h -> EC5Ch
- FEA5h -> ECE7h
- E2C3h -> 90B7h -> E98Ah
- E2FBh -> F3DBh
- E343h -> F419h
- F724h/F808h -> EF36h
- D6C1h/D797h/D7F5h/D8BBh/DA98h/F721h -> F4A5h
- E385h/E38Bh/E391h/F755h -> F509h

The direct references establish several of these as live paths. For the IRET-style handlers EA42h, EA97h, E98Ah and the instruction handlers EAEBh/EB43h, the exact vector installation and full runtime reachability remain open.

## 10. Generator and remaining work

The candidate generator now includes bounded code windows for E831h–F52Dh, the aligned helper/handler entries and the data ranges above. The candidate manifest is the reproducible count source; the current windows remain inspection aids, not a full CFG or proof of semantic coverage.

Open items:
- consumer and exact meaning of the E87Bh and F0A3h tables;
- purpose/consumer of the opaque EFC7h–F041h block;
- vector installation for E98Ah, EA42h, EA97h and EAEBh/EB43h;
- exact semantics of the 0F05h protected-mode-assisted path beyond its observed descriptor/CR0 transitions;
- entry/caller for the F068h protected-mode exit/reset path.

**This region extension is not a numbered phase and does not claim whole-ROM semantic completion.**
