# AMI486 semantic map — phase 25 (2026-11-16)

## 1. B517h is an ordinal Setup-record selector

At 1E1Ch the BIOS executes `mov al, cs:[B517h]`, then calls 8300h. The stock byte at B517h is 0Fh. It is not a CMOS register number and not a direct feature bit.

8306h starts from the first Advanced CMOS Setup record at B7D0h. For a nonzero selector below the optional-extension threshold, it advances through the variable-length record sequence. Each step uses the record's +1Fh option-count byte, advances by 20h plus that count, and, when +1Eh bit 7 is set, skips the auxiliary NUL-terminated help strings. The selector is decremented once per record. Therefore selector 0Fh selects the fifteenth record in this sequence.

## 2. The fifteenth record is System Boot Up Sequence

Record base: BA0Bh.

Decoded fields:
- Label: `System Boot Up Sequence`.
- CMOS index/key at +1Ch: ADh.
- Mask/routing byte at +1Dh: 20h.
- Flags at +1Eh: 00h.
- Number of option codes at +1Fh: 02h.
- Option codes beginning at +20h: 10h and 0Fh.

This confirms that the stock B517h selector points to the System Boot Up Sequence Setup item. It does not mean that CMOS ADh contains 0Fh; 0Fh is the record ordinal used by the BIOS lookup routine.

## 3. POST decision and ALi1429 effects

At 1E1Ch:
1. AL=CS:[B517h] (0Fh).
2. 8300h/8306h decodes the selected Setup item using CMOS ADh, mask 20h, and the record's option-code mapping.
3. A nonzero decoded result calls 8BA3h; zero calls 8B5Eh.
4. The handler selects ALi index C503h and returns to the caller.

In the stock descriptor table, CS:[8250h]=01h and CS:[8260h]=01h, so these handlers perform their respective ALi sequences:
- 8BA3h -> 8D09h: pulse ALi register 18h bit 2, set ALi register 23h bit 1, write 03h to ALi register 55h.
- 8B5Eh -> 8D39h: clear ALi register 23h bit 1, write 03h to ALi register 55h.

The control flow proves that System Boot Up Sequence selects between these two chipset actions. The precise electrical/functional meaning of ALi register 23h bit 1 is not identified by the firmware disassembly alone.

## 4. Important separation from the keyboard hotkey path

The same 8BA3h/8B5Eh handlers are also selected by the INT 15h AH=4Fh intercept through scan codes 4Eh and 4Ah. That keyboard path is independent of the POST Setup lookup at 1E1Ch. The shared handlers therefore serve both a Setup-derived POST decision and a keyboard-intercept path.

## 5. Confidence

Confirmed directly from ROM bytes and control flow: B517h=0Fh; 8306h performs ordinal traversal; the fifteenth Advanced CMOS record is BA0Bh; the label, CMOS ADh, mask 20h and option codes 10h/0Fh; and the nonzero/zero dispatch at 1E23h–1E2Ch.

Still unresolved: which option code is represented as decoded zero versus nonzero in every CMOS validity mode; the user-visible meaning of the chipset register 23h bit; and whether the keyboard hotkey path is intended to override or synchronize this Setup choice.

## 6. Recognition accounting

Linear 16-bit decode remains 65,536/65,536 bytes (100%). Semantic percentage is not yet stated because a complete per-byte classification ledger is still required.