# AMI486 semantic map — phase 18 (2026-11-16)

## Scope

This phase resolves the E0000h–E7FFFh scan reached from 1B60h, the separate C0000h window path at 1BF6h, and the protected-mode helper 2686h used by multiple chipset/cache setup callbacks.

Source is the full 64-KiB linear listing in this repository. Alternate entry points are considered separately from the linear instruction stream.

## 1. 1BB3h is an option-ROM validator and executor

Caller 1B60h invokes 1BB3h while BX advances from E000h to below E800h in 800h increments.

At each candidate segment, 1BB3h:
1. Disables interrupts, clears direction flag, saves DS, and sets DS=BX.
2. Requires the word at DS:0000 to equal AA55h (the option-ROM signature).
3. Reads the size byte at DS:0002. Since the successful signature comparison leaves AH=0, CX receives the size byte.
4. Computes the candidate ROM length as size * 512 bytes. BX is advanced by size * 32 paragraphs, i.e. the same byte length expressed in paragraphs.
5. Sums the size*512 bytes from the candidate image, beginning at offset 0002h, using the high byte accumulator. A nonzero checksum rejects the image.
6. On a valid image, restores interrupt state and constructs a far-call-like stack frame, transferring control to offset 0003h in the original candidate segment. It arranges a return address at 1BE7h and preserves/restores ES, BX, BP and DS around the call.
7. On invalid signature/checksum, advances BX by 0080h paragraphs (800h bytes) and returns so the caller can continue its scan.

The far transfer is therefore to the standard option-ROM entry point at segment:0003, not to a BIOS routine. The candidate scan covers E0000h–E7FFFh in 2-KiB steps, with the ROM size byte determining the next segment after a valid image.

This corrects the earlier phase-17 note that described the E000h loop only as a separate operation: it is specifically a scan/dispatch loop for option ROMs.

## 2. C0000h shadow-window path at 1BF6h

The caller at POST offset 5E20h invokes 1BF6h after the 1B60h initialization/option-ROM path.

1BF6h loads CS:B51D into AL, calls the stock 8300h hook, and conditionally calls 2415h. Entry 2415h selects BX=C000h, CX=4000h words and DL=01h, then joins the common body at 2457h.

Thus the C0000h window helper is used through a separate hook site from the three 98h/1B60h paths:
- B51D -> 8300h hook -> 2415h (C0000h window, mask 01h).
- B51F/B521/B523 -> 8300h hook -> 2420h/242Bh/2436h (C8000h/D0000h/D8000h windows).

As established in phase 17, stock 8300h preserves flags and does not interpret AL. The B51D branch is consequently patch/context dependent in the stock image; it is not proven to be a direct Boolean test of B51D.

## 3. Helper 2686h: protected-mode flat-segment read sweep

2686h is a real alternate entry point in the code region, not a table.

Its sequence:
1. Loads ECX=00040000h and ESI=00100000h.
2. Loads a GDT descriptor from CS:264Eh. The six-byte pseudo-descriptor is limit 0040h, base 000F2646h (physical F2646h).
3. Reads CR0, sets PE (bit 0), writes CR0, and executes a short jump to serialize the mode transition.
4. Loads ES=0038h, clears DF, and executes a 32-bit REP LODSD with ES override. It reads 00040000h dwords = 1 MiB, beginning at linear address 00100000h and ending immediately below 00200000h.
5. Loads ES=0010h, clears CR0.PE, writes CR0, executes a short jump, then jumps through DI to the caller-supplied continuation.

The GDT entry selected by selector 0038h is the descriptor at GDT base + 7*8 = F2647Eh. Its bytes are FF FF 00 00 00 93 8F 00: a present ring-0 writable data segment, base zero, 4-GiB limit with 4-KiB granularity. Selector 0010h selects a 64-KiB real-mode-compatible data descriptor used before clearing PE.

The observed operation is a protected-mode flat-address read sweep of physical 1–2 MiB. It does not write or compare the scanned words. This may serve as a cache/memory conditioning delay or sweep, but the ROM alone does not prove a specific cache-control effect. Do not call it a destructive memory test.

## 4. Call-site interpretation for 2686h

The helper is reached through indirect continuation stubs, including jumps from 274Bh, 281Bh, 287Bh and the indexed-register callback sequences at 8D69h/8DA2h. These callers set up chipset register values and place a continuation address in DI before entering 2686h.

This establishes 2686h as a shared transition/sweep primitive used by multiple setup sequences, rather than a one-off routine belonging only to POST A1h. The exact semantics of the surrounding ALi1429 register bits remain unresolved.

## 5. Findings

Confirmed:
- 1BB3h validates option-ROM signature, size and checksum, then far-calls the image at segment:0003.
- 1B60h scans E0000h–E7FFFh in 2-KiB candidate steps.
- 1BF6h conditionally invokes the C0000h shadow-window entry 2415h through the B51D/8300h hook.
- 2686h briefly enters protected mode with a flat 4-GiB data selector, reads 1 MiB at physical 00100000h–001FFFFFh, returns to real mode, and resumes via DI.

Unresolved:
- Whether the 2686h read sweep is specifically intended to evict/condition CPU cache, impose a delay, or satisfy another chipset timing requirement.
- Runtime/OEM patch source for the 8300h hook and the B51D/B51F/B521/B523 call-site conditions.
- Exact functional names for ALi1429 registers 18h/19h/43h and the related mode-dependent setup tables.
