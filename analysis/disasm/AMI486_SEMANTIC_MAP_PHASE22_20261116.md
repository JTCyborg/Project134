# AMI486 semantic map — phase 22 (2026-11-16)

## 1. CR0 cache-control helpers 8CB2h and 8CCDh

Both helpers inspect machine status with SMSW and only modify CR0 when the processor is not already in protected mode and the SMSW high byte is zero.

### 8CB2h
- Reads CR0.
- ANDs it with 9FFFFFFFh, clearing CR0 bits 30 and 29 (CD and NW).
- Writes CR0 and tail-jumps through DI.

This is the cache-enable/configuration path: it clears the architectural cache-disable and not-write-through controls. It does not itself execute WBINVD.

### 8CCDh
- Reads CR0.
- ORs it with 60000000h, setting CR0.CD and CR0.NW.
- Writes CR0.
- Executes WBINVD.
- Tail-jumps through DI.

This is the cache-disable path, with cache writeback/invalidation instruction executed after setting the disable controls.

If SMSW indicates protected mode or a nonzero high status byte, both helpers skip the CR0 change and immediately tail-jump through DI. Callers supply DI as a continuation address; these are shared transition helpers, not ordinary near-call routines.

## 2. 8042 command/response helper 8CEAh

Input: AL = command byte for the keyboard controller.

- Copies command to AH.
- Waits for 8042 input-buffer-full bit (port 64h, bit 1) to clear, using CX as a bounded loop counter.
- Writes the command to port 64h.
- Waits for output-buffer-full bit (port 64h, bit 0) to become set.
- Reads the response from port 60h into AL and returns.

The zero initial CX followed by LOOPNE/LOOPE gives a 16-bit wraparound wait budget (up to 65,536 iterations), not an infinite wait. No explicit timeout/error status is returned in this helper; the final AL is the read data byte.

## 3. Paired optional I/O configuration handlers 8B5Eh and 8BA3h

These routines are parameterized by adjacent CS-relative descriptor bytes/words and implement a common optional peripheral setup pattern.

### 8B5Eh descriptor at 8260h–8265h
- If CS:[8260h] is nonzero, calls 8D39h and combines CL into CH.
- If CS:[8261h] is nonzero, sends that byte as an 8042 command through 8CEAh and marks CH as FFh.
- If CS:[8262h] is a nonzero I/O port, reads that port, applies (value AND CS:[8265h]) OR CS:[8264h], and writes the result back; marks CH as FFh.
- If any operation marked CH nonzero, sets bit 5 of [0016h].
- Preserves AX and DX.

### 8BA3h descriptor at 8250h–8255h
- If CS:[8250h] is nonzero, calls 8D09h and combines CL into CH.
- If CS:[8251h] is nonzero, sends that byte to the 8042 through 8CEAh and marks CH as FFh.
- If CS:[8252h] is a nonzero I/O port, reads it, applies (value AND CS:[8255h]) OR CS:[8254h], and writes it back; marks CH as FFh.
- If any operation marked CH nonzero, clears bit 5 of [0016h].
- Preserves AX and DX.

These are not generic Setup menu record handlers: they consume fixed CS-relative hardware-configuration descriptors. The current stock bytes at these descriptor slots are mostly zero, so many suboperations are inactive in the unmodified image. The code proves the operation sequence and masks; it does not identify the peripheral represented by each descriptor.

## 4. Low-level chipset mode helpers

### 8D09h
- Selects ALi index 03h.
- Reads ALi register 18h, sets bit 2, writes it back.
- Clears bit 2 in AH and writes through the same indexed helper sequence.
- Reads ALi register 23h, sets bit 1, writes it back.
- Writes AX=5503h (index 55h, data 03h).
- Returns CX=0.

### 8D39h
- Selects ALi index 03h.
- Reads ALi register 23h, clears bit 1, writes it back.
- Writes AX=5503h.
- Returns CX=0.

These two helpers are distinct chipset configuration sequences selected by the 8250h/8260h descriptor flags. Exact hardware feature labels for registers 18h, 23h and 55h are not assigned.

## 5. Related memory-path helpers

### 8D56h
- Selects ALi index 03h and reads register 18h.
- If bit 1 is clear, jumps to 2686h with DI=8D6Ch as the return continuation.
- Otherwise jumps to 2629h with DI=8D72h.
- The continuation at 8D72h sets bit 1 in ALi register 18h.
- Returns CX=FFFFh.

This is a chipset-state-dependent protected-mode memory-access path; the code alone does not identify the physical memory window.

### 8D83h
- Selects ALi index 03h and enters the indexed read/write continuation chain.
- Reads/updates ALi register 19h, setting low bits to 3.
- Enters 2686h through a continuation at 8DA5h.
- The continuation later clears low two bits of ALi register 19h, updates ALi register 18h bit 1, and returns CX=FFFFh.

This helper is used by the memory-test failure path and by other setup routines. Its observed register changes are recorded without assigning undocumented chipset semantics.

## 6. Interrupt/POST integration and current descriptor status

- 8B2Dh is a CLI-protected dispatcher. It compares AL with CS:[826Eh] and CS:[825Eh], then chooses one of two paired paths depending on bits 0–1 of [0017h].
- For the 826Eh match, it calls 8BE8h or 8B5Eh.
- For the 825Eh match, it calls 8C4Dh or 8BA3h.
- 8BE8h/8C4Dh are alternate wrappers around the same configuration descriptors, using cache-control continuations 8CCDh/8CB2h.
- The two fixed descriptor groups occupy 8250h–8265h; their mostly-zero stock contents explain why these paths may be dormant unless initialized or patched.
- The B51x Setup keys analyzed in Phases 20–21 are a separate record-lookup mechanism and must not be conflated with these fixed descriptor blocks.

## 7. Recognition accounting

The full-ROM mechanical decode remains 65,536/65,536 bytes (100%). Semantic coverage is still reported as unquantified: no complete byte-level ledger currently partitions the ROM into confirmed code, confirmed data, ambiguous/overlapping streams and unresolved bytes. Phase reports document selected semantic regions, not a complete percentage denominator. A numeric semantic percentage will only be published after generating and auditing that ledger.

## 8. Confidence

Confirmed directly from instructions: CR0 masks, WBINVD placement, 8042 port protocol, descriptor offsets, conditional I/O read-modify-write masks, and ALi indexed-register operations.

Unresolved: physical peripheral identity of the fixed descriptors, meaning of ALi registers 18h/23h/55h, provenance of any runtime descriptor population, and exact mapping of the memory windows used by 2686h/2629h.
