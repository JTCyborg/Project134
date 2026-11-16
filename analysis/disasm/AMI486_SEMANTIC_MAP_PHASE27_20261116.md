# AMI486 semantic map — phase 27 (2026-11-16)

## 1. 8042 command/data transport primitives

The ROM contains a layered 8042 interface around F5BCh–F690h:

- F659h waits for the 8042 input-buffer-full bit (status port 64h bit 1) to clear. It uses CX=0 with LOOPNE, giving a bounded 16-bit wraparound wait; this is not an infinite wait.
- F635h sends a command byte to port 64h: wait via F659h, OUT 64h, wait again. If the first wait expires, the OUT is skipped.
- F644h sends a data byte to port 60h using the same wait discipline.
- F622h sends command AL to port 64h, then data AH to port 60h.
- F62Dh wraps F622h with command D1h, so AH is written to the 8042 output port.
- F651h wraps F622h with command 60h, so AH is written as the 8042 command byte.

Response helpers:
- F5FFh waits for output-buffer-full (status port 64h bit 0) using nested 16-bit LOOPNE retry counters.
- F5F9h calls F5FFh and reads port 60h.
- F60Fh is a second bounded output-buffer wait/read helper with an outer 12-attempt counter.
- F5BCh sends command AL and compares the returned byte against AH; F5C9h does the equivalent for a data byte.

## 2. Input-port and output-port access

- F5D9h first drains a pending output byte if status bit 0 is set, then sends command C0h and returns the byte read from port 60h. This is the 8042 read-input-port operation.
- F5E9h similarly sends command D0h; F5F5h dispatches through F5BCh and F5F9h reads the response. D0h is the 8042 read-output-port operation.
- F62Dh sends D1h followed by a data byte, writing the 8042 output port.

Important distinction: the POST code at 1DD8h calls F5D9h (C0h/input-port read) to inspect controller input state. That routine itself does not write the A20 gate. Output-port writes are handled separately by D1h paths.

## 3. Direct A20 output-port control

F66Ah and F66Eh are the decisive routines:

- F66Ah loads AH=DFh and falls into the common D1h output-port writer at F670h.
- F66Eh loads AH=DDh and falls into the same writer.
- F670h waits for input-buffer availability, sends command D1h to port 64h, waits again, writes AH to port 60h, waits for completion, and returns.

DFh and DDh differ in bit 1: DFh has bit 1 set, DDh has bit 1 clear. For the standard AT 8042 output-port assignment, output-port bit 1 is the A20 gate. Thus F66Ah enables A20 and F66Eh disables A20. Both preserve the other output-port bits as fixed constants rather than read-modify-writing the current output-port value.

Convenience entries at 8ACFh and 8AD2h are direct jumps to F66Ah and F66Eh respectively. The callers include 90F3h (enable path), 528Eh, 9191h, 91D9h and 920Eh (disable path), plus the direct call sites at 933Ch (enable) and 9211h / F47Eh (disable).

## 4. Other observed 8042 uses

- 1115h–1136h sends FAh and checks for AAh, then sends ABh and compares the returned result. This is a controller/keyboard-interface diagnostic sequence; the code sets POST status bits in BP depending on the result.
- 5CCAh–5CF6h sends controller command 21h, reads a response, transforms it, and writes it back through F622h; this is a command-byte/8042 configuration path. On success it records state in BP and later sends command 30h through F651h in one branch.
- 5D52h reads the 8042 input port via F5D9h and stores the returned byte at [0012h]; it tests bit 5 before proceeding into the following initialization branch.
- 9821h sends command D4h and tests the response for FEh, then expects AAh and zero from subsequent reads. This is a separate auxiliary-controller/device initialization test; do not conflate it with A20 output-port switching.
- E819h sends command CAh and checks a one-byte response; E803h/F622h is used for command/data exchange and restores the controller with command FFh on the success path.
- F47Eh disables A20 via F66Eh after the displayed diagnostic/error text path.

## 5. Corrected interpretation of Phase 26

Phase 26 correctly identified F5D9h as an 8042 input-port read and the POST feature as Fast Gate A20. The stronger statement is now supported by the separate D1h output-port code: F66Ah writes DFh (A20 bit set), and F66Eh writes DDh (A20 bit clear). The input-port probe at 1DD8h is a detection/state-read step; it is not the actual A20 gate write.

## 6. Limits

The direct A20 bit interpretation relies on the standard AT 8042 output-port bit assignment. The exact board wiring and whether all target boards implement the same controller behavior are not derivable from this ROM alone. Wait loops are bounded by 16-bit counter wraparound; they do not report a rich error code, and callers often inspect only ZF/CF or the returned byte.

## 7. Recognition accounting

Linear 16-bit decode remains 65,536/65,536 bytes (100%). Semantic percentage is not reported until a complete byte-level classification ledger exists.