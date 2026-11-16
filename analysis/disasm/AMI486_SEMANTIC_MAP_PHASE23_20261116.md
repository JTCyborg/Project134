# AMI486 semantic map — phase 23 (2026-11-16)

## 1. Third fixed I/O descriptor group: 8268h–826Dh

8BE8h is the descriptor executor for the third group:
- It preserves DX and, unless CS:[8281h].6 is set, saves EAX and invokes 8CCDh with DI=8BFAh as continuation.
- The continuation restores DI and derives CH from the condition flags returned by the cache-control helper.
- If CS:[8268h] is nonzero, calls 8D83h; the returned AH/CH state is folded into CH.
- If CS:[8269h] is nonzero, sends that byte to the 8042 command port through 8CEAh.
- If CS:[826Ah] is a nonzero I/O port, reads the port, computes (value AND CS:[826Dh]) OR CS:[826Ch], and writes it back.
- If any descriptor operation marks CH nonzero, clears bit 4 of [0016h].
- It restores EAX when the CS:[8281h].6 bypass is not active.

This is structurally parallel to 8BA3h/8B5Eh, but has its own ALi helper and state-bit polarity. The actual peripheral is not identified by the code alone.

## 2. Fourth fixed I/O descriptor group: 8258h–825Dh

8C4Dh executes the fourth group:
- Unless CS:[8281h].6 is set, saves EAX and invokes 8CB2h with DI=8C5Fh as continuation.
- If CS:[8258h] is nonzero, calls 8D56h.
- If CS:[8259h] is nonzero, sends it to the 8042 through 8CEAh.
- If CS:[825Ah] is a nonzero I/O port, reads it, applies (value AND CS:[825Dh]) OR CS:[825Ch], and writes it back.
- If any operation marks CH nonzero, sets bit 4 of [0016h].
- Restores EAX unless the CS:[8281h].6 bypass is active.

The 8258h–825Dh group is therefore paired with the 8268h–826Dh group but uses the opposite cache-control continuation and opposite [0016h].4 state update.

## 3. The CS:[8281h].6 global bypass

Static xrefs show the bit is tested by several unrelated control paths:
- 8B11h, 8BE8h, 8C41h, 8C4Eh, 8CA6h
- 9150h, 91FBh
- D657h, D724h, F06Ah
- F43Dh tests bit 7 separately.

For the descriptor wrappers, bit 6 suppresses the EAX save/cache transition wrapper while leaving the descriptor operations themselves reachable. It is not a per-device enable bit.

No static write to CS:[8281h] was found in the linear decode. Its runtime initialization or patch provenance remains open. Do not assign it a named Setup option without further evidence.

## 4. 8042 transaction path at 9400h–949Fh

9400h is a controller configuration/recovery path gated by:
- CS:[8256h] nonzero,
- [0016h].6 set,
- low three bits of [0016h] equal 7.

It checks status at ports 20h and A0h through helper EAE0h, then uses 8042 command/status helpers:
- 949Fh writes AL to command port 64h.
- 94A1h waits for output-buffer-full (status bit 0) to clear, while also checking input-buffer-full (bit 1); returns with CX zero on the bounded-wait exhaustion path.
- 94B3h waits for output-buffer-full to become set and reads port 60h when ready.
- The caller sends command bytes AFh, C0h and 20h; it reads responses and then sends command 60h followed by a modified command byte (original value OR 30h).
- It finishes by selecting one of the 8BA3h/8B5Eh descriptor groups based on the sign flag returned by 94A1h, then restores the 8042 command byte through command 60h.

This is definitively an 8042 command-byte/controller transaction, but the exact board-level purpose of the AFh/C0h sequence is not named here. The code also performs PIC status checks, so it should not be simplified to a generic keyboard reset.

## 5. 8042 BIOS interrupt helper at 8B2Dh

8B2Dh is invoked from 8AF F (the interrupt path at 8AFF) and B026h. It disables interrupts, compares AL against CS:[826Eh] and CS:[825Eh], and conditionally dispatches:
- 826Eh match: when [0017h] bits 0–1 are nonzero, calls 8BE8h; otherwise 8B5Eh.
- 825Eh match: when [0017h] bits 0–1 are nonzero, calls 8C4Dh; otherwise 8BA3h.
- It restores interrupts before returning.

The two selector bytes are fixed firmware dispatch values. Their meanings are not proven merely by the values or the nearby controller code.

## 6. INT 15h / keyboard hook context at 9400h

9400h is not itself the generic BIOS keyboard interrupt handler. It is a conditional controller-maintenance sequence that ends by selecting one of two descriptor groups. Its use of [0016h] state and CS:[8256h] makes it dependent on earlier POST/configuration state. The full caller chain and the exact origin of [0016h].6 remain to be traced.

## 7. Corrections and confidence notes

- The descriptor families are now four distinct blocks: 8250h–8255h, 8258h–825Dh, 8260h–8265h, and 8268h–826Dh. Their operation patterns are similar but not interchangeable.
- 8BE8h uses the 8CCDh cache-disable continuation; 8C4Dh uses the 8CB2h cache-enable continuation.
- 8BA3h sets [0016h].5 when any descriptor action occurs; 8B5Eh clears it. 8BE8h clears [0016h].4; 8C4Dh sets it.
- 8CEA uses bounded polling loops. On exhaustion it does not return a dedicated timeout code; callers must interpret the returned data/status and subsequent flags.
- Confirmed directly: descriptor offsets, branch conditions, port addresses, masks, helper calls and state-bit effects.
- Unresolved: hardware identities of all four descriptor blocks, initialization source of CS:[8281h], meanings of selector bytes 825Eh/826Eh, and exact board-specific intent of the 8042 AFh/C0h/20h sequence.

## 8. Recognition accounting

Mechanical linear decode: 65,536/65,536 bytes (100%). Semantic percentage remains unreported pending an audited byte-classification and control-flow ledger. The new phase adds further confirmed code regions but does not provide a valid whole-ROM percentage by itself.
