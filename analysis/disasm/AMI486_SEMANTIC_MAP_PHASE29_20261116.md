# AMI486 semantic map — phase 29 (2026-11-16)

## 1. INT 15h AH=89h: confirmed purpose of the 933Ah entry

The dispatcher at 9220h handles INT 15h extended services. It computes `AH - 80h`, bounds-checks against 12h, and dispatches through the word table at CS:90BAh (922Fh–923Eh). For AH=89h, the table index is 9, so the entry at 90CCh contains the word 933Ah (bytes 3A 93). This confirms that 933Ah is the INT 15h AH=89h protected-mode entry service, not an unclassified internal transition.

Sequence at 933Ah–9376h:

- CLI; saves CX; calls F66Ah (8042 D1h, output-port value DFh, A20 enable).
- Restores CX and tests the helper's status. On failure, returns AX=FFFFh with CF set at 9372h–9376h.
- On success, calls EEefh to complete parameter/descriptor setup, loads caller-supplied GDT and IDT from the parameter block via LGDT/LIDT, then sets CR0.PE with SMSW/OR 1/LMSW.
- Loads protected-mode selectors SS=0028h, DS=0018h, ES=0020h and returns far at 9376h with AX=0.

This service intentionally returns to the caller in protected mode. It does not clear CR0.PE or disable A20 before RETF 2; those actions belong to the protected-mode caller's later transition back. Thus the absence of a local F66Eh call is expected, not evidence of an incomplete local cleanup path.

The nearby 9379h routine is a separate BIOS service helper: it uses the BDA flag at 0040:00A0, saves caller state at 0040:0098–009Eh, and calls EE75h/EE80h/EE8Ch. It is not the return path for AH=89h.

## 2. The 20C9h–23CBh transition is part of a memory-address test/configuration sequence

The byte stream around 20C9h uses stack-return trampolines into the indexed ALi register writer (8DDCh). At 20C6h, SP is set to 20CCh and execution jumps to 8DDCh; the helper's RET resumes at 20C9h, which jumps to F66Ah. A similar pattern appears immediately before 23CBh: SP is set to 23CEh, the code jumps through 8DDCh, and the helper returns at 23CBh, which jumps to F66Eh.

Between these points, the routine:

- Enters protected mode after enabling A20.
- Uses selector 4410h and 32-bit operand/address-size instructions to probe memory at low offsets and at 4 MiB / 64 MiB-related addresses, with complementary patterns 5555AAAAh and AAAA5555h.
- Records the detected address-boundary results in DL/DH and BL/BH.
- Combines the results and writes a chipset configuration value through ALi indexed register 10h (the value is derived from the probe results; the register's board-specific semantic name is not established here).
- Clears CR0.PE at 23BDh–23C2h and disables A20 at 23CBh before continuing at 23CEh.

The two A20 writes therefore bracket this protected-mode memory-address probe/configuration routine. The exact external entry name and the physical memory map represented by the probe offsets remain unresolved; do not label this as a specific memory-size service without identifying its caller and the ALi register 10h meaning.

## 3. Reassessment of the AH=87h extended-memory move exits

The AH=87h dispatcher entry is confirmed at 90E7h. The normal path enables A20 at 90F3h, enters protected mode at 9139h–913Eh, clears PE at 917Bh–9180h, then disables A20 at 9191h before restoring the caller context.

Additional exits visible in the linear decode:

- If the initial A20-enable helper reports failure, 90F8h branches to 90E4h/921Ah and then the common register-restore/return path at 91A2h–91B1h. This path does not attempt an unconditional second A20 write after a failed enable.
- The error/recovery paths around 91DEh–920Eh include both the ordinary protected-mode exit and the alternate path selected by CS:[8281h].6. One branch explicitly calls 8AD2h or F66Eh; another branches through the alternate RTC/port-61 recovery sequence.
- Therefore the earlier statement that all AH=87h exits share one A20 cleanup sequence would be too broad. The normal copy path is paired; alternate/error paths must be considered separately and are not all equivalent.

## 4. Confirmed conclusions

- 933Ah is the INT 15h AH=89h protected-mode entry service, established from the dispatcher table rather than inferred from nearby instructions.
- AH=89h enables A20 and returns with PE set; it deliberately leaves A20 enabled for the caller's protected-mode execution.
- 20C9h–23CBh brackets a protected-mode memory-address probe/configuration routine, with A20 enabled on entry and disabled after PE is cleared.
- The AH=87h normal path has a clear enable/PE-on/copy/PE-off/disable sequence; alternate exits have distinct cleanup logic.
- A20 control uses fixed 8042 output-port values DFh/DDh; it does not preserve an arbitrary previous output-port byte.

## 5. Remaining work

- Identify the external caller/POST stage for the 20C9h–23CBh memory-address probe.
- Trace the full AH=87h alternate path selected by CS:[8281h].6 and enumerate every route to 91A2h/91B1h, 91CEh, and F068h.
- Identify the protected-mode caller contract for AH=89h and the corresponding return-to-real-mode entry.
- Keep ALi register 10h unnamed until corroborated by chipset documentation or an independently verified implementation.
