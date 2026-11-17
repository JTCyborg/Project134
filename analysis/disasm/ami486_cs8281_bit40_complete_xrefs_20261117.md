# ami486.bin — CS:[8281] bit 6: complete direct-reference audit

Date: 2026-11-17  
ROM: `ami486.bin`, 64 KiB, branch `main`.

## Corrected interpretation

The previous description of `CS:[8281].40h` as a global reset-request flag was too broad. The bit is tested by multiple routines with different branch destinations. It is a shared CPU/firmware state bit used by several code paths. Only some consumers route a set bit to the 8042 reset routine.

The ROM image has `CS:[8280]=2Fh` and `CS:[8281]=00h` initially. The bit-40 direct-reference scan found the following instruction sites; the occurrence at `F43Dh` tests bit `80h`, not bit `40h`. The byte sequence at `AC6Ah` is data, not a memory reference.

## Bit 40h consumers

| TEST instruction | Conditional branch | Set-bit path | Clear-bit path / effect |
|---|---|---|---|
| `5272h` | `JZ 527Dh` | `JMP 8AD6h` — 8042 reset body | `JMP F068h` — final mode decision |
| `5478h` | `JZ 5483h` | `JMP 8AD6h` — 8042 reset body | `JMP F068h` — final mode decision |
| `8B11h` | `JNZ 8B2Dh` | skips CMOS[2Dh] read/convert sequence | reads CMOS[2Dh], returns transformed value |
| `8BE9h` | `JNZ 8BF2h` | skips 32-bit register push | executes `PUSH EAX` |
| `8C41h` | `JNZ 8CA6h` | skips 32-bit register pop / restore path | executes restore sequence |
| `8C4Eh` | `JNZ 8CAFh` | takes alternate path around save/restore setup | executes `PUSH EAX` and setup |
| `8CA6h` | `JNZ 8D02h` | skips 32-bit register pop | executes `POP EAX` / return sequence |
| `9150h` | `JNZ 91B4h` | skips a block-copy / CPU-transition setup path | executes the copy and subsequent mode setup |
| `91FBh` | `JNZ 91BCh` | loops to the marker/transition continuation | takes the alternate near-jump path |
| `D657h` | `JNZ D690h` | bypasses the CR0/descriptor transition block | executes SMSW, CR0 test/update, then common setup |
| `D724h` | `JNZ D73Bh` | bypasses SMSW/CR0 manipulation | executes SMSW/CR0 test/update, then common setup |
| `F069h` | `JZ F074h` | `JMP 8AD5h` — 8042 reset body | descriptor-table / CR0.PE-clearing transition |

The targets in this table are derived from the actual instruction boundaries in the byte stream, not from linear disassembly assumptions. Some routines contain overlapping entries and short jumps that skip register-save/restore instructions.

## Separate bit-80h consumer

At `F43Dh`, the firmware executes `TEST BYTE PTR CS:[8281],80h`. This confirms `CS:[8281]` is a multi-bit state byte, not a dedicated one-bit reset flag. The `80h` test is separate from the bit-`40h` control-flow family and needs its own semantic trace.

## Reset path (one consumer, not the whole meaning)

The 8042 reset body at `8AD5h` is:

```asm
8AD5: FA          CLI
8AD6: FA          CLI
8AD7: 33 C9       XOR CX,CX
8AD9: E3 00       JCXZ 8ADBh
8ADB: E4 64       IN AL,64h
8ADD: A8 02       TEST AL,02h
8ADF: E0 F8       LOOPNZ 8AD9h
8AE1: B0 FE       MOV AL,FEh
8AE3: E6 64       OUT 64h,AL
8AE5: F4          HLT
8AE6: EB FD       JMP 8AE5h
```

The two POST consumers at `5272h` and `5478h` jump to `8AD6h` when bit 40h is set. The final consumer at `F069h` jumps to `8AD5h`. Other consumers do not directly reset the machine.

## Setter status

The direct-reference audit found TEST operations but no direct immediate write to `CS:[8281]` (MOV/OR/AND with an absolute direct operand). This does not exclude indirect writes, block copies, or external initialization. Since the byte contains at least two independently tested bits, the next search must trace its containing state block and all possible copy/initialization routines rather than search only for a bit-40 setter.

## Implications for replacement BIOS

Do not model `CS:[8281].40h` as a generic reset flag. Preserve the distinct call-site semantics only if they are required by the replacement BIOS architecture. First identify the state-byte producer and classify bit 40h and bit 80h separately. No ROM bytes changed.
