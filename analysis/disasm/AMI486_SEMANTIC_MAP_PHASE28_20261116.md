# AMI486 semantic map — phase 28 (2026-11-16)

## 1. Protected-mode transitions with A20 sequencing

### INT 15h, AH=87h extended-memory move path (90E7h–9224h)

- 90E7h selects AH=87h; 90F3h calls 8ACFh, which jumps to F66Ah and writes 8042 output-port value DFh (A20 enabled).
- Only after the enable call succeeds does the routine prepare the descriptor tables and set CR0.PE at 9139h–9141h.
- The protected-mode copy path starts at 9143h. The normal path clears CR0.PE at 917Bh–9183h.
- 9191h then calls 8AD2h, which jumps to F66Eh and writes DDh (A20 disabled). This occurs after clearing PE, before restoring the caller's segments/registers and returning with RETF 2 at 91B1h.
- If the alternate path is taken because CS:[8281].6 is set, execution branches at 9150h to 91B4h. That path does not enter the same protected-mode copy sequence; it performs its own checks and may return through the alternate recovery code.
- The routine's error path at 90F8h branches to 921Ah; do not assume every failure path has the same A20 cleanup without following the full caller state.

This is a clear enable-before-PE / disable-after-PE-clear pairing for the standard protected-mode copy path.

## 2. Additional protected-mode transition pair at 20C9h–23CBh

- 20C9h is a direct near jump to F66Ah (write DFh, enable A20).
- 20DAh reads CR0, sets PE (bit 0), and writes CR0; execution continues through the protected-mode section.
- 23BDh reads CR0, clears PE (bit 0), and writes CR0.
- 23CBh is a direct near jump to F66Eh (write DDh, disable A20).

The instruction order therefore forms a second enable/enter-PM and leave-PM/disable-A20 pair. The surrounding 20xx/23xx routine also performs memory-address tests and manipulates protected-mode segment state. The exact external entry/caller for this linear region is not resolved by the current static direct-call search, so it is not assigned a BIOS service number here.

## 3. Other explicit A20 call sites

- 933Ah disables interrupts, preserves CX, and calls F66Ah to enable A20 before setting CR0.PE at 9357h–935Ch. The sequence then loads protected-mode segment selectors and returns far at 9376h. This is another enable-before-PM entry. The matching return/cleanup path is not statically paired in this linear decode; do not assume the routine itself disables A20.
- 528Eh calls 8AD2h (disable A20) and then calls F66Eh directly (disable again). The repeated write is real in the byte stream; its surrounding POST/control-flow context is not enough to infer a separate state transition.
- 9211h disables A20 on an alternate/error return path within the AH=87h service.
- F47Eh disables A20 in the firmware diagnostic/error path before continuing to inspect CMOS state.
- 8ACFh and 8AD2h are tiny jump veneers to the enable and disable routines respectively.

## 4. A20 state is not restored from a saved output-port byte

F66Ah and F66Eh write constants DFh and DDh through command D1h. The code does not first issue D0h to read the old output-port value and does not preserve an arbitrary prior value. It explicitly selects the A20 bit while forcing the other output-port bits to the corresponding constant. Therefore, describe this as BIOS policy (enable for a transition, disable on selected exits), not as save/restore of the caller's original 8042 output-port state.

## 5. Relationship to Fast Gate A20 Setup

The Setup/POST path at 1DD8h–1E18h uses the Fast Gate A20 option selector B51Bh and reads the 8042 input port with F5D9h (command C0h). This is a separate probe/configuration decision. The actual output-port writes used by transition code are F66Ah/F66Eh (D1h + DFh/DDh).

## 6. Confidence and unresolved items

- High confidence: the AH=87h normal path enables A20 before setting PE and disables it after clearing PE.
- High confidence: the 20C9h–23CBh sequence has the same instruction ordering around CR0.PE.
- High confidence: 933Ah enables A20 before setting PE; no matching disable in the immediately decoded routine has been established.
- Unresolved: the exact high-level entry point for the 20C9h–23CBh region and the external return path corresponding to 933Ah.
- The A20 interpretation uses the standard AT 8042 output-port bit 1 assignment. Board-specific wiring cannot be established from this ROM alone.