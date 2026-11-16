# AMI486 semantic map — phase 26 (2026-11-16)

## 1. B51Bh resolves to Fast Gate A20 Option

The byte table at B508h is an ordinal selector sequence: B517h=0Fh, B519h=11h, B51Bh=13h. The selector used by POST at 1DE3h is therefore 13h (decimal 19), not 12h.

Starting at B7D0h, the nineteenth Advanced CMOS Setup record is BA91h. Its label is `Fast Gate A20 Option`.

Record BA91h fields:
- +1Ch CMOS index/key: 2Dh.
- +1Dh mask: 02h.
- +1Eh flags/callback selector: 00h.
- +1Fh option count: 02h.
- option codes: 02h and 01h.

Thus B51Bh is the ordinal selector for the Fast Gate A20 Setup record. It is not a CMOS register address.

## 2. POST path 1DD8h–1E18h

1. Reads CS:[8256h]; zero skips the optional prelude and continues at 1E1Ch.
2. Loads selector byte CS:[B51Bh] (13h), calls 8300h to decode the selected Setup record, and preserves AX across the call.
3. If the decoded option is zero, skips the A20-controller probe and continues at 1E1Ch.
4. If nonzero, sets bit 6 in the BIOS state byte [0016h], calls F5D9h, and examines the returned AX bits to update bits 7 and other masked state in [0016h].

F5D9h drains a pending 8042 output byte when status port 64h bit 0 is set, then sends command C0h through F5BCh and returns the byte read from port 60h. Command C0h is the 8042 read-input-port command. This is consistent with the Fast Gate A20 feature and its A20 input-port control bit, though the exact board-level interpretation of every returned bit is not fully proven by this routine alone.

## 3. Distinct selector B519h: External Cache Memory

B519h contains 11h (decimal 17), selecting the seventeenth Advanced CMOS Setup record at BA4Fh, labelled `External Cache Memory`.

Callback selector 2 dispatches to 2EB4h. That routine reads selector CS:[B519h], calls 83AEh to obtain the selected record's CMOS key and mask, then updates the corresponding BIOS configuration-state bit(s) in the working Setup image, with different behavior depending on real/protected-mode context. This is a separate Setup callback path from the Fast Gate A20 POST path at 1DD8h.

## 4. Record order around the two selectors

- 15 (0Fh): BA0Bh — System Boot Up Sequence.
- 16 (10h): BA2Dh — System Boot Up CPU Speed.
- 17 (11h): BA4Fh — External Cache Memory.
- 18 (12h): BA71h — Internal Cache Memory.
- 19 (13h): BA91h — Fast Gate A20 Option.

This confirms the selector arithmetic and removes the earlier possible off-by-one ambiguity.

## 5. Confidence and remaining questions

Confirmed from ROM bytes/control flow: selector bytes B519h=11h and B51Bh=13h; record ordinal mapping; record labels and fields; POST's call to F5D9h; F5D9h's 8042 command C0h and port 60h read; separate callback 2EB4h for External Cache Memory.

Strongly supported interpretation: the POST path probes/configures the 8042 input-port state for Fast Gate A20. Still unresolved: exact board wiring and full meaning of the returned input-port bits and BIOS state-byte [0016h] bit transitions.

## 6. Recognition accounting

Linear 16-bit decode remains 65,536/65,536 bytes (100%). Semantic percentage is not reported until a complete byte-level classification ledger exists.