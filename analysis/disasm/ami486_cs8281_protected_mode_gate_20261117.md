# ami486.bin — CS:[8281] shared CPU-state byte

Date: 2026-11-17  
ROM: `ami486.bin`, 64 KiB, branch `main`.

## Supersedes earlier interpretation

This document supersedes the earlier interpretation of `CS:[8281].40h` as a general protected-mode capability or global reset-request flag.

The direct-reference audit shows that `CS:[8281]` is a shared state byte. Bit `40h` is tested in several unrelated-looking CPU/firmware paths, with different branch destinations and effects. Some consumers route a set bit to the 8042 reset routine; others use it to select CMOS access, preserve/restore registers with different operand sizes, or bypass CR0 transition code.

Bit `80h` is also tested at `F43Dh`, confirming that the byte is not a dedicated one-bit flag.

## Confirmed reset behavior at specific consumers

- POST test at `5272h`: if bit 40h is set, jump to `8AD6h`; otherwise jump to `F068h`.
- POST test at `5478h`: if bit 40h is set, jump to `8AD6h`; otherwise jump to `F068h`.
- Final transition test at `F069h`: if bit 40h is set, jump to `8AD5h`; otherwise continue at `F074h` into the descriptor-table / CR0.PE-clearing sequence.

The reset routine at `8AD5h` sends command `FEh` to port `64h` after polling the 8042 input-buffer status, then halts awaiting hardware reset.

## Other confirmed consumers

- `8B11h`: bit 40h selects whether the routine reads and transforms CMOS[2Dh].
- `8BE9h`, `8C41h`, `8C4Eh`, and `8CA6h`: bit 40h affects 32-bit register save/restore paths and whether an operand-size prefix is executed.
- `9150h) and `91FBh`: bit 40h gates a block-copy / CPU-transition path and a related loop/branch.
- `D657h` and `D724h`: bit 40h gates code that reads machine status and accesses CR0.
- `F43Dh`: a separate test checks bit 80h.

See `ami486_cs8281_bit40_complete_xrefs_20261117.md` for the full branch-target table and exact instruction offsets.

## Setter remains unresolved

No direct immediate write to `CS:[8281]` was found in the direct-address scan. This does not exclude indirect writes, block copies, or initialization outside the ROM. The next task is to trace the producer/initializer of the containing state byte and determine the meaning of its individual bits.

## Replacement BIOS guidance

Do not implement `CS:[8281].40h` as a standalone “reset flag” or “protected-mode available” flag. Reconstruct the state-byte initialization and each consumer's local semantics first. No ROM bytes changed.
