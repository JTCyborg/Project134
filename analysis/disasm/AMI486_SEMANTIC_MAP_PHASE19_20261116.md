# AMI486 semantic map — phase 19 (2026-11-16)

## Scope

Reconciled the ROM-window setup path, the stock hook at 8300h, the POST caller at 5E05h, and the Option-ROM scan/dispatch routine at 1BB3h. This report uses the byte-complete linear listing as a byte source; alternate entry points are interpreted from their actual call targets.

## 1. 8300h is a wrapper; 8306h is the stock table walker

The bytes at 82FFh onward are:

- 82FF: 00
- 8300: 53                 PUSH BX
- 8301: E8 02 00            CALL 8306
- 8304: 5B                  POP BX
- 8305: C3                  RET

Therefore callers entering at 8300h preserve BX and invoke 8306h. The earlier Phase 17 wording that called 8300h a flag-preserving/no-op stub is incorrect and is superseded here.

At 8306h the code begins with BX=B7D0h and tests AL. It then distinguishes built-in keys from the extended record range, consults CS:[82C6] for the optional runtime Setup-record base, walks variable-length records using +1Eh/+1Fh and optional help strings, and ultimately reaches the CMOS-index handling path at 834Fh onward. This is consistent with the previously documented Setup-record walker, not a generic Boolean test.

Consequences for callers:
- 1B60 calls 8300 with AL loaded from CS:B51F, B521, and B523. These are keys/selectors passed to the record walker, not proven Boolean feature-presence bytes.
- 1BF6 calls 8300 with AL from CS:B51D before optionally calling 2415.
- 26F9 calls 8300 with AL from CS:B518 and branches on the resulting flags.
- 1F18 calls 8300 with AL from CS:B519.
The exact meaning of these selectors depends on the matching stock/extended record data and the state of CS:[82C6]. Do not label them Boolean gates without decoding the returned flags and the relevant record set.

## 2. ROM-window helpers 2415h–244Ch

The helper entry points are small parameter stubs feeding a common body at 2457h:

| Entry | Segment base | CX | DL mask |
|---|---:|---:|---:|
| 2415h | C000h | 4000h words | 01h |
| 2420h | C800h | 4000h words | 02h |
| 242Bh | D000h | 4000h words | 04h |
| 2436h | D800h | 4000h words | 08h |
| 2441h | E000h | 4000h words | 10h |
| 244Ch | C800h | 4000h words | 20h |

Common body 2457h:
1. Saves ES and DS.
2. Reads ALi1429 register 13h; ORs in DL and writes the result back.
3. Reads register 14h; clears low two bits and sets bit 1, then writes it.
4. Loads DS=ES=the selected segment and executes REP MOVSW with CX=4000h. This is 4000h words = 8000h bytes = 32 KiB, with source and destination both at offset 0000h.
5. Reads register 14h again; clears bit 1 and sets bit 0, writes it back.
6. Restores DS/ES and returns.

Because the source and destination segment:offset are identical, this is not an ordinary RAM-to-RAM copy. The meaningful operation is the same-address read/write while the chipset window is configured; it is strongly consistent with copying the currently visible ROM contents into the corresponding shadow RAM. The exact electrical/read-vs-write mapping and individual register bit semantics are not proven by the BIOS alone.

The extra 2441h and 244Ch entries were missed by the earlier narrow trace. 2441h adds a distinct E000h window mask 10h; 244Ch uses C800h with mask 20h. These entries must be included in any complete map of this helper family.

## 3. Callers and scan flow

### 1B60h

- Writes ALi extended index C503h.
- Calls 2420h if the 8300h lookup for key B51Fh returns nonzero.
- Calls 242Bh if lookup for key B521h returns nonzero.
- Calls 2436h if lookup for key B523h returns nonzero.
- Then checks the word at C000:0000 for AA55h.
- If absent, scans candidate segments beginning at E000h and below E800h, calling 1BB3h. An invalid candidate advances BX by 0080h (2 KiB); a valid image advances BX by its declared image length (size byte × 512 bytes, expressed as paragraphs), so the scan is not unconditionally a fixed 2-KiB stride.
- Returns with ZF reflecting whether the C000h signature test succeeded (the code uses OR SP,SP / CMP SP,SP idioms to set flags).

The calls to 2420h/242Bh/2436h are therefore conditional on the record-walker result, not direct tests of raw Boolean bytes.

### 1BF6h

- Loads AL from CS:B51D and calls 8300h.
- If the result is nonzero, calls 2415h (C000h window, mask 01h).
- This is the C000h shadow-window path used by POST 5E20h.

### POST 5E05h

- Calls 1B60h.
- If its ZF result indicates the C000h signature was not found, proceeds to a separate scan loop beginning at C000h and advancing BX toward C800h through helper F6D9h.
- Then disables interrupts, clears direction flag, and calls 1BF6h.
- Continues with CMOS index 8Dh and the following POST work.

This establishes a distinct C000h shadow setup after the Option-ROM/C000h scan stage.

## 4. Option-ROM validator/executor at 1BB3h

At entry BX is a candidate 16-bit segment:
- Saves DS, sets DS=BX, SI=0.
- Reads the first word and compares it with AA55h.
- Reads the size byte at offset 2. The code converts that count to bytes by multiplying by 512 (size << 9).
- Advances BX by the corresponding 512-byte paragraph count to retain the end/candidate progression.
- Iterates over the image bytes, accumulating an 8-bit checksum in AH; nonzero result rejects the image.
- On success, restores the required state and performs a far call to candidate segment:0003, then restores registers/segments and returns.

The far-call construction is visible at 1BDC–1BE6: it pushes a return CS:IP frame and executes RETF to transfer control to segment:0003. This is an Option-ROM initialization call, not a near call into the BIOS.

Caution: this routine is invoked by the scan loop for candidate segments; the existence of a valid signature/checksum does not prove the option ROM will successfully initialize or remain resident.

## 5. POST A1h: protected-mode memory sweep details

The earlier Phase 18 identification of the 2686h sweep as a read-only pass needs qualification after tracing its caller at 26F9h.

At 26F9h:
- A lookup for key B518h is performed through 8300h; a zero result skips the test and returns.
- Otherwise the routine temporarily switches to a stack in the BIOS segment, configures ALi registers 19h and 18h, and enters the protected-mode test path.
- At 2761h it sets DS=1000h, ESI=0, and EAX=55AA55AAh.
- It reads a dword from [ESI] into EBX, writes the pattern to [ESI], and later reads additional offsets (+4, +800h, +1000h, +1800h, +2000h).
- It compares EAX against [ESI] and advances ESI by four for two loop iterations. Thus there is a write/read-compare at the base address, plus extra reads at other offsets; those extra reads are not individually compared in this loop.
- The continuation at 27BCh–284Fh performs memory sizing/configuration and restores the prior stack/segments.

Accordingly, this is not a pure read-only sweep. It contains at least a destructive pattern write and comparison at physical 00100000h (DS=1000h, offset 0), followed by additional reads and a memory-sizing continuation. The routine's broader purpose and safety assumptions remain to be established.

## 6. Corrections to previous phase summaries

1. Supersedes Phase 17's statement that 8300h is a stock no-op/flag-preserving stub. 8300h is a PUSH BX / CALL 8306h / POP BX / RET wrapper.
2. Supersedes Phase 18's description of the 2686h path as read-only: its caller/test body writes 55AA55AAh at the base of the test region and compares it.
3. Extends the Phase 17 helper list with 2441h and 244Ch.
4. B51F/B521/B523/B51D/B518 are lookup keys passed into the record walker. Their raw values are not sufficient to infer Boolean enablement.

## 7. Remaining work

- Reconstruct the exact Setup/extension records referenced by keys B518h/B519h/B51Dh/B51Fh/B521h/B523h, including stock table boundaries and runtime pointer initialization.
- Decode the complete 2415h–244Ch caller graph and establish whether all six window entries are reachable in the stock image.
- Trace F6D9h and the C000h scan to determine the exact source of candidate data and the behavior when the signature is absent.
- Continue the POST A1h path beyond 284Fh and identify which memory ranges are written, read, or merely sized.
- Do not assign chipset register bit names without an ALi1429 register specification or emulator implementation that defines them.
