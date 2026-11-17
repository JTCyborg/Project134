# AMI486 address ledger — Setup exit prompts and temporary INT 13h/IVT path (2F66h–3043h)

Date: 2026-11-17  
Repository: JTCyborg/Project134, branch main  
Source: ami486.bin, 65,536 bytes  
SHA-1: 480c7520c93e6c7ed437cf3ad214da7503f82ec6  
ROM SHA-256 recorded by the existing ledger: 91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b

## 1. Scope and boundaries

The previous uncovered interval 2F66h–3043h begins with the terminating NUL of the Setup exit-prompt strings. The actual code entries are:

| Range | Classification |
|---|---|
| 2F66h | Final NUL byte of the prompt-string data range |
| 2F67h–2F8Eh | Setup exit confirmation and saved-stack restoration |
| 2F8Fh–2FA2h | BDA/low-memory clear helper |
| 2FA3h–3043h | Temporary IVT/INT 13h Setup diagnostic path |
| 3044h onward | Next string block; begins with “ STANDARD CMOS SETUP” |

The prompt data range is 2F24h–2F66h inclusive. Its previous generator end excluded the final NUL at 2F66h; the data range now ends at 2F67h exclusive.

## 2. Setup exit confirmation — 2F67h–2F8Eh

Direct caller: 3D73h.

The handler presents two prompts through the existing text-display helper at 5959h:

1. String at 2F24h: “Write to CMOS and Exit (Y/N) ?”
2. If the answer is not Y, string at 2F43h: “Want to Quit Without Saving (Y/N) ?”

For the first prompt, Y calls 852Eh (the STI/RET helper) and proceeds to the saved-stack restoration path. For the second prompt, Y proceeds to the same restoration path. If the user answers N to both, the handler returns to the Setup menu at 2F8Eh.

The exit path at 2F80h:
- clears AX and sets DS=0000h;
- disables interrupts;
- restores SS from 0000:0469h and SP from 0000:0467h;
- re-enables interrupts and returns.

This is a saved Setup-stack exit path, not a direct jump to the reset vector.

## 3. BDA/low-memory clear helper — 2F8Fh–2FA2h

Direct callers: 2FD8h and 3023h.

With ES already set to segment 0000h, the helper clears:
- words at 0040:0442h, 0444h and 0446h, plus byte 0448h;
- word 0040:0474h plus byte 0476h;
- word 0040:048Ch plus byte 048Eh.

It uses STOSW/STOSB and returns at 2FA2h. The routine itself does not select ES; callers establish the destination segment before calling it.

## 4. Temporary IVT/INT 13h path — 2FA3h–3043h

Direct caller: 4A6Bh.

The routine saves SI, DI and DS, then copies four original IVT vectors from segment 0000h into the caller's data segment beginning at E429h. The saved vectors correspond to offsets 0100h, 004Ch, 0104h and 0118h.

It then sets ES=0000h, disables interrupts and temporarily:
- replaces the INT 13h vector at 0000:004Ch with offset A08Dh and the current CS;
- places the previous INT 13h vector at 0000:0100h;
- clears the BDA fields through 2F8Fh;
- selects one of the INT 41h/INT 46h vector slots (0000:0104h or 0000:0118h) according to byte E421h;
- writes the temporary vector 0100:E411h into the selected slot;
- increments the BDA hard-disk count byte at 0040:0075h, and increments DL for the alternate slot;
- enables interrupts and invokes INT 13h with AH=14h and DL initially 80h.

The INT 13h result controls the returned status path. On failure it assigns AL=02h; on the alternate helper failure path it assigns AL=03h. The path also calls helpers at AAA3h and 691Ch; their internal meanings are not redefined by this local map.

Before returning, the routine clears the low-memory BDA fields again, restores all four saved IVT vectors from E429h to their original locations, restores registers and returns at 3043h.

This establishes a temporary BIOS interrupt-vector substitution around an INT 13h AH=14h operation, followed by deterministic restoration of the original vectors. It does not by itself establish the user-visible Setup label for the 4A6Bh caller.

## 5. Cross-reference ledger

| Source | Target | Meaning |
|---:|---:|---|
| 3D73h | 2F67h | Setup exit prompt handler |
| 2F71h | 852Eh | STI/RET helper before saved-stack exit |
| 2FD8h | 2F8Fh | Clear BDA fields during temporary-vector setup |
| 3023h | 2F8Fh | Clear BDA fields before IVT restoration |
| 4A6Bh | 2FA3h | Setup diagnostic/temporary INT 13h path |

## 6. Generator integration

The candidate generator now:
- includes the terminating NUL at 2F66h in the prompt data range;
- seeds 2F67h with a 28h-byte window;
- seeds 2F8Fh with a 14h-byte helper window;
- seeds 2FA3h with an A1h-byte window ending immediately before the string at 3044h.

Generator update commit: fe81b16853fccc3a4befc7736982bd04fca58d1a.

The manifest has not yet been regenerated after the 0B2Dh, 84BEh and 2F66h boundary corrections. No new global coverage percentage or CI pass is claimed.

## 7. Remaining uncertainties

- The user-facing label and broader purpose of the 4A6Bh caller.
- The exact hardware/BIOS meaning of the INT 13h AH=14h result handling in this Setup path.
- The internal meanings of helpers AAA3h and 691Ch.
- Whether the temporary INT 41h/INT 46h vector selection reflects disk geometry or another board-specific configuration field.
