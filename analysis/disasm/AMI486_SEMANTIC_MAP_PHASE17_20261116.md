# AMI486 semantic map — phase 17 (2026-11-16)

## Scope

This phase follows the POST 98h path through 1E9D into the ROM-window helpers 2420h/242Bh/2436h, cross-checks the same helpers' earlier caller at 1B60h, and examines the POST A1h path 1EC8h -> 2850h -> 26F9h.

Source: analysis/disasm/ami486_full_linear_16bit.disasm.txt, 16-bit linear decode of the verified 64-KiB ROM. All addresses below are ROM offsets. Linear decode is not treated as proof that adjacent bytes are all code; alternate entry points and embedded data remain possible.

## 1. POST 98h: three independently gated window operations

Caller at 1402h invokes 1E9Dh. The routine performs three separate tests/calls:

| Gate byte | Test/call | Target helper |
|---|---|---|
| CS:B51F | call 8300; conditional branch | 2420 |
| CS:B521 | call 8300; conditional branch | 242B |
| CS:B523 | call 8300; conditional branch | 2436 |

Each operation is independent; failure/skip of one does not prevent the following gate from being evaluated.

### Important hook behavior

The stock bytes at 8300h decode as:
- 8300: push bx
- 8301: call 8305
- 8305: ret
- 8304: pop bx
- 8305: ret

Thus the stock hook preserves BX and returns without modifying flags. The caller's conditional branch therefore observes flags preserved across this hook, rather than a Boolean result computed from AL. The three bytes at B51F/B521/B523 are passed in AL but the stock hook does not interpret them. Treat these as OEM/runtime patch hooks or patch-dependent dispatch points; do not label the B51F/B521/B523 values as ordinary Boolean presence flags on the evidence of this stock path alone.

The same hook pattern is used at other addresses, so its semantics must be assessed per call site and not assumed to be a generic AL-nonzero test.

## 2. Shared ROM-window helper family

Entry stubs:

| Entry | BX loaded | CX | DL mask | Common destination |
|---|---:|---:|---:|---|
| 240A | F000h | 8000h | C0h | 2457 |
| 2415 | C000h | 4000h | 01h | 2457 |
| 2420 | C800h | 4000h | 02h | 2457 |
| 242B | D000h | 4000h | 04h | 2457 |
| 2436 | D800h | 4000h | 08h | 2457 |
| 2441 | E000h | 4000h | 10h | 2457 |
| 244C | C800h | 4000h | 20h | 2457 |

The three POST-98h calls select the C8000h, D0000h and D8000h windows respectively.

### Common body 2457–2494

1. Saves ES and DS.
2. Reads ALi1429 index 13h via 8DCF, ORs in DL, and writes it back via 8DDC.
3. Reads ALi1429 index 14h; applies (old & FCh) | 02h; writes it back.
4. Loads DS=ES=BX, clears SI and DI, and executes REP MOVSW with CX words. For the three C800/D000/D800 entries this is 4000h words = 8000h bytes, beginning at offset zero of the selected segment.
5. Reads ALi1429 index 14h again, clears bit 1 and sets bit 0, then writes it back.
6. Restores DS/ES and returns.

The sequence is strong evidence of a chipset shadow-window initialization/copy operation: register 13h receives a per-window mask, register 14h is staged before the same-address read/write copy and finalized afterward. The self-addressed copy is consistent with reading the currently visible ROM mapping and writing the same addresses after the chipset has enabled its shadow destination. The precise electrical meaning of each register-14h bit is not established by this ROM alone.

### PCem cross-check and limits

The Project124 PCem ALi1429 model explicitly treats registers 13h/14h as the control pair for 32-KiB shadow windows from C0000h through FFFFFh. This is consistent with the helper's 8000h-byte copy length and register-13h masks. The ROM's individual entry masks (01/02/04/08/10/20/C0) are directly observed; do not infer a complete bit-to-address decode beyond the entries and PCem's modeled mapping.

## 3. Earlier caller at 1B60h

1B60h also selects extended index C503h and invokes the same three helpers under the same three hook sites:
- B51F -> 2420
- B521 -> 242B
- B523 -> 2436

Afterward it checks the word at C000:0000 for signature AA55h. If present, it returns. If absent, it iterates BX from E000h to below E800h in 800h increments and calls 1BB3h.

This confirms the helpers are not unique to POST 98h; they are reused by another initialization path. The later E000h loop is a distinct operation and is not part of the three shared 32-KiB copies.

## 4. POST A1h: 1EC8 -> 2850 -> 26F9

Caller 156Ah invokes 1EC8h.

### 4.1 Register preconditioning at 2850h

2850h selects extended index C503h and uses indexed read/modify/write helpers to:
- set bits 0–1 of ALi register 19h (OR 03h);
- set bits 0–1 of ALi register 18h (OR 03h);
- write value 18h to indexed register 43h;
- continue through helper 2686h;
- set bits 0–1 of register 19h again;
- clear bits 0–1 of register 19h;
- continue through 2686h.

The helper chain uses the common indexed I/O primitives at 8DCF/8DDC and indirect continuation callbacks. The ROM establishes the exact register/index writes; it does not name their chipset function.

### 4.2 1EC8h continuation

After 2850h returns, 1EC8 restores BP/ES/DS, clears bit 4 of BDA byte 0016h, then calls 26F9h.

It next reads CMOS B3h, outputs the value to POST/debug port 80h, and tests SMSW/CR0-related state. Depending on the saved mode bits, it selects one of two small word tables at 8E62h or 8E7Ah and writes the listed ALi indexed-register values. It then tests the hook at B519h; on one branch it sets BDA byte 0016h bit 4, while another branch invokes the 8CCD protected-mode/cache-state helper. Finally it restores the saved AL value and may set the same BDA bit 4.

The table ranges are only 8 bytes and 4 bytes respectively. Their raw bytes are data, not a reliable linear instruction stream. The table-selected writes are exact, but register meaning is not assigned here.

### 4.3 26F9h: gated memory/cache setup sequence

At entry, 26F9 disables interrupts and passes CS:B518 to the 8300 hook. If the preserved flags indicate the skip branch, it jumps directly to the return tail at 284Fh.

Otherwise it:
- saves DS/ES and the BIOS stack state from BDA words 0067h/0069h;
- switches SS to CS and uses continuation callbacks to modify ALi registers 19h and 18h;
- enters helper 2686h between register changes;
- sets up a test at segment 1000h using 32-bit operand/address prefixes;
- writes the pattern 55AA55AAh to memory and verifies the first dword at offset zero, with additional reads at offsets 4, 800h, 1000h, 1800h and 2000h;
- continues into the memory sizing/configuration path at 27BCh/29BBh, or an error/alternate path if the comparison fails;
- restores the saved stack and segment state in the common tail.

The exact visible comparison is against the first dword at DS:0000 after writing the pattern; the additional dword loads are not each individually compared in the shown loop. Do not describe this as a full exhaustive memory test of every read location.

The B518 gate is another use of the stock 8300 no-op flag-preserving hook. Its branch condition is therefore patch/context dependent in the unmodified ROM, not a direct test of the B518 byte's numeric value.

## 5. Conclusions and open points

Confirmed from instruction flow:
- POST 98h calls three independently gated 32-KiB window helpers.
- Each helper modifies ALi registers 13h and 14h and performs a 32-KiB same-address copy.
- The same helpers are reused by the earlier 1B60h initialization path.
- POST A1h has a separate ALi register preconditioning and memory sizing/test path through 2850h and 26F9h.
- Stock 8300h is a flag-preserving stub, not a conventional AL-nonzero predicate.

Strongly supported:
- The 240A–244C family implements ROM shadow-window enable/copy/finalize behavior, consistent with PCem's register-13h/14h shadow-window model.

Still unresolved:
- Runtime/OEM patch provenance for the 8300h hook and B51F/B521/B523/B518 gate sites.
- Exact semantics of ALi registers 18h, 19h, 43h and the individual bits written here.
- Full purpose of the 1BB3h E000h–E800h loop.
- Full semantics of helper 2686h and the mode-dependent data tables at 8E62h/8E7Ah.
- Whether every helper entry in 240A–244C is used in another caller or by an OEM patch path.
