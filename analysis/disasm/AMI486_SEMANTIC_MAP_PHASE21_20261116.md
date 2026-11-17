# AMI486 semantic map — phase 21 (2026-11-16)

## 1. POST handler 1DE8h–1E35h: conditional feature setup

Entry 1DD8h first checks the byte at CS:8256h. If zero, it skips the B51Bh/B517h option-dependent path.

When CS:8256h is nonzero:
- Loads the lookup key byte from CS:B51Bh and calls 8300h.
- If the decoded option is nonzero, sets bit 6 in the POST state byte at [0016h], calls F5D9h, then evaluates the returned AL/AH masks. It clears/sets bit 7 of [0016h] according to the AL/AH intersection and applies the AH mask to the result.
- Loads the key byte at CS:B517h and calls 8300h. A nonzero decoded option calls 8BA3h; zero calls 8B5Eh.
- Finally writes ALi index selector C503h and returns.

The exact feature names represented by B51Bh/B517h are not established. The code proves the dispatch and state-bit side effects, not the user-facing meaning of the options.

## 2. POST handler 1E78h: ALi register 14h bit 3

1E78h loads the key byte at CS:B513h and calls 8300h. If the decoded option is zero, it returns without changing the chipset. Otherwise it selects ALi register 14h, sets bit 3, writes the register and returns with AX forced nonzero.

This proves a CMOS-option-gated ALi register 14h bit-3 operation. Its hardware feature name remains unknown.

## 3. POST handler 1E9Dh and 2042h: five conditional ROM shadow windows

1E9Dh checks B51Fh, B521h and B523h through 8300h and conditionally calls:
- B51Fh -> 2420h: C800h window, register-13h mask 02h.
- B521h -> 242Bh: D000h window, mask 04h.
- B523h -> 2436h: D800h window, mask 08h.

2042h selects ALi index C503h, then checks:
- B525h -> 2441h: E000h window, mask 10h.
- B527h -> 244Ch: alternate C800h window, mask 20h.

The helpers themselves were decoded in Phase 19: they stage ALi registers 13h/14h and perform a 32-KiB same-segment read/write transfer consistent with shadow initialization. The callers prove independent CMOS-option gates. They do not prove the option labels or exact chipset physical mapping.

## 4. POST handler 1EC8h–1F46h: memory setup and mode-dependent dispatch

1EC8h saves DS/ES/BP, calls 2850h, restores registers, clears bit 4 of [0016h], and calls the gated memory-test path 26F9h. It then reads CMOS B3h and writes the value to port 80h as a POST checkpoint/output.

If SMSW indicates protected mode is not active, it tests bits 2/3 of the CMOS B3h value:
- When either bit is set, it selects one of two word tables at 8E62h–8E7Eh (selection depends on bit 2) and writes each table word through ALi indexed write helper 8DDCh.
- It then looks up the key byte at CS:B519h using 8300h.
- Nonzero result dispatches through 8CB2h with a local continuation at 1F29h; the continuation can set bit 4 of [0016h].
- Zero result dispatches through 8CCDh at 1F3Ah.
- The final path sets bit 4 of [0016h] if CMOS B3h bit 0 is set.

The table words and dispatch mechanics are established. The semantic names of the table modes and the B519h option are not.

## 5. POST A4 handler 1F47h–203Eh: additional ALi1429 configuration

1F47h selects ALi index C503h and calls 29EDh to choose AUTO/manual configuration.

AUTO branch:
- Calls 8F12h, 2588h and 25A6h, then joins the common tail at 1F90h.

Manual branch reads CMOS and performs indexed ALi1429 read-modify-write operations:
- CMOS 46h low nibble -> ALi 16h low nibble.
- CMOS 49h bits 5:6 -> ALi 19h bits 5:6.
- CMOS 49h bits 2:5 (mask 9Ch) -> ALi 19h bits 2:5 (destination mask 63h).
- CMOS 55h bits 4:5 -> ALi 25h bits 4:5.
- CMOS 42h bits 3:4 -> ALi 12h bits 3:4.
- CMOS 48h bits 3 and 7 -> ALi 18h bits 3 and 7.
- CMOS 4Ah bits 6:7 -> ALi 1Ah bits 6:7.
- CMOS 57h bits 3:5 -> ALi 27h bits 3:5.

Common tail at 1F90h–203Eh:
- Reapplies CMOS 49h bits 2:5 to ALi 19h bits 2:5 (mask 63h).
- Applies CMOS 55h bits 4:5 to ALi 25h bits 4:5.
- Applies CMOS 42h bits 3:4 to ALi 12h bits 3:4.
- Applies CMOS 48h bits 3 and 7 to ALi 18h bits 3 and 7.
- Applies CMOS 4Ah bits 6:7 to ALi 1Ah bits 6:7.
- Applies CMOS 57h bits 1,2,5,6 (mask C6h) to ALi 27h bits 0,3,4,5 (destination mask 39h).
- Reads ALi 1Ah, preserves its high nibble, and if CMOS 4Ah bit 0 is set, forces its low nibble to Fh.

The code-level source/destination masks are directly visible. Do not infer named timing or cache features from these bitfields without an authoritative ALi1429 register map.

## 6. B51x option-key limitation

The B51x operands are bytes loaded from CS-relative locations and passed to the 8300h lookup worker; they are not themselves CMOS indices unless the record lookup resolves them that way. Phase 20 established that 8300h returns a decoded option value using a built-in record walk or the optional extended record range at 82C6h.

The stock ROM has 82C6h=82C8h=0 and no static writers for those pointers. Consequently, keys whose lookup falls into the optional range cannot be assigned a stock user-visible option name from the current image alone. Their caller-side effects are now mapped, but their OEM/runtime record provenance remains unresolved.

## 7. ROM recognition progress — honest status

- Mechanical byte coverage: 65,536 / 65,536 bytes = 100% (complete 16-bit linear decode).
- Semantic recognition: not yet assigned a defensible percentage. The current work is a set of focused, overlapping control-flow and data-structure investigations, not a complete per-byte code/data/reachability ledger. Counting the 21 phase reports as a percentage of ROM bytes would be misleading.
- Current semantic milestone: major Setup/CMOS structures, ALi1429 access and configuration paths, ROM-shadow helpers, Option-ROM validation, and selected POST memory-test paths have been characterized. Remaining work includes whole-ROM control-flow reconciliation, code/data classification, unresolved dispatch targets, OEM extension provenance, and hardware-bit naming.

## 8. Confidence and open questions

Confirmed from instruction flow: the branch conditions, lookup call sites, ALi indexed-register read/modify/write masks, table traversal, and calls to ROM-window helpers.

Strongly supported: the 32-KiB helper family performs ROM-shadow initialization based on ALi 13h/14h behavior and the PCem model.

Unresolved: the exact B51x Setup labels in the stock image, the runtime/OEM source of the optional record table, the physical mapping of the ALi windows, and the hardware meanings of the affected register bits.


## Audit clarification — ROM-shadow copy lengths (2026-11-17)

The 32-KiB same-segment copy description in section 3 applies to the C000h–E000h option-gated helpers (2415h, 2420h, 242Bh, 2436h, 2441h, 244Ch), each of which sets CX=4000h words. A separate POST helper at 240Ah is called from 23ECh: it sets BX=F000h, CX=8000h words (64 KiB), DL=C0h, then enters the same common copy body at 2457h. The common body stages ALi registers 13h/14h, copies from DS:0000 to ES:0000 with REP MOVSW, then changes register 14h to the final state. The exact hardware mapping remains chipset-dependent. See `AMI486_ADDRESS_LEDGER_REGION_23CE_29F6_20261117.md`.
