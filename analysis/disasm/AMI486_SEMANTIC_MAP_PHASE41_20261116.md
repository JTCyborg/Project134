# AMI486 semantic map — phase 41 (2026-11-16)

## Scope

This phase audits CMOS B3h write sites and the Setup/editor paths that expose B3h. It distinguishes direct writes from read-only consumers and records the limits of the available control-flow evidence.

## 1. Direct CMOS B3h writes found in the linear ROM listing

The direct immediate-index references to CMOS B3h are:

- 11C8h: read/modify/write. Clears bit 7, then sets it iff DS:0013h is strictly greater than 0200h. This is the automatic threshold-derived flag described in phase 40.
- 27E8h: read/modify/write. Sets bit 0 after the DS segment scan reaches the 9000h boundary. Other bits are preserved.
- 8914h: write in the continuation around 88D3h–8921h. Reads B3h at 8906h, ORs a mask held in AH into the existing byte at 8912h, then writes the merged byte at 8914h. The local mask-generation fragment at 88FAh–8904h sets AH to 02h only when (DL AND 30h) equals 30h; otherwise AH is zero. Thus this fragment can set B3h bit 1 and does not clear existing bits.
- 575Eh is not a CMOS write. It is a Setup/editor helper returning CMOS index B3h or BAh according to bit 1 of the UI state word E19Dh.

The B3h reads at 1A35h, 1A60h, 1AFBh, 1ED9h, 25C4h, 25EBh, 417Fh, 4197h, 41A5h, 8A2Eh are read-only in their immediate local sequences. The B3h value is consumed for display, mode/table selection or diagnostic text.

No other direct immediate-index write to B3h was found in the full linear listing. This is a static scan of the ROM image, not proof that an option ROM or runtime extension cannot write CMOS B3h.

## 2. Setup/editor exposure of CMOS B3h

The selector helper at 575Eh returns:

- B3h when bit 1 of word [E19Dh] is clear;
- BAh when bit 1 of [E19Dh] is set.

This is an index-selection helper, not itself a CMOS access. It shows that the Setup/editor framework has a path whose selected CMOS register is B3h, with BAh as the paired alternative under the UI state bit.

The nearby helpers at 5751h similarly select C4h or CDh using bit 0 of [E19Dh]. The family of helpers around 571Ch–576Ah is a table/editor abstraction: it derives register indices and option encodings from E19Dh. Do not label E19Dh bit 1 as a specific user-facing option without tracing the menu record and callback.

## 3. B3h write fragment around 88D3h

The local sequence is:

- 88D7h: SMSW AX.
- 88DAh: tests CR0.PE (AL bit 0); if set, branches away to 891Eh.
- 88DEh: tests AH, i.e. the high byte of the SMSW result, not CR0.PE.
- 88E2h: compares DH with 04h.
- 88FAh–8904h: derives AH=02h only if (DL AND 30h)==30h, otherwise AH=00h.
- 8906h: reads CMOS B3h.
- 8912h: ORs AH into the byte read from CMOS.
- 8914h: writes the merged byte back to CMOS B3h.

The fragment proves an OR-only update capable of setting B3h bit 1. It does not clear B3h bit 1. However, the code uses stack-adjusted continuations and intermediate jumps (88E8h–893Ch); without reconstructing the caller's stack contract and the alternate entry points, do not claim that every local branch is reachable from a single ordinary call or that DH/DL always originate from a particular Setup control. The safe conclusion is the local write semantics and the mask condition at 88FAh–8904h.

## 4. Additional B3h read in setup-dependent selection

At 8A20h–8A66h, the BIOS tests SI against 5, 9 and 0Ah. For those cases it reads CMOS B3h at 8A2Eh, then checks a byte at [BP+SI+0CA8h]. If the check passes, it carries the B3h value in DL into the table-selection fragment at 8A4Ah–8A60h:

- B3h bit 2 set: selects ten words beginning at 8E62h.
- B3h bit 2 clear: selects two words beginning at 8E7Ah.

This is a further consumer of bit 2 in a context indexed by SI; the exact meaning of the SI values depends on the calling Setup/POST state and remains unresolved here.

## Confirmed vs. unresolved

Confirmed:
- The two automatic B3h updates at 11C8h and 27E8h.
- The OR-based B3h write at 8914h and its local bit-1 mask generation.
- The Setup/editor helper at 575Eh returns B3h or BAh according to E19Dh bit 1.
- The 8A2Eh read path uses B3h bit 2 to choose between the same long and short ALi word lists.
- The other immediate B3h references enumerated above are local reads, not writes.

Unresolved:
- The full caller/stack contract that enters the 88D3h continuation family.
- The user-visible Setup label associated with E19Dh bit 1 and the B3h/BAh register pair.
- Whether any OEM/option-ROM code changes B3h through generic CMOS write helpers or hardware-level paths not visible as immediate B3h references.
- Intended names for B3h bits 0, 1, 2, 3 and 7 beyond the directly observed behavior.

## Reproducibility

Primary listing: `analysis/disasm/ami486_full_linear_16bit.disasm.txt`.
ROM SHA-256: `91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b`.
Key ranges: 571Ch–576Ah, 88D3h–893Ch, 8A20h–8A66h, 11C8h–11DCh, 27DEh–2800h.
