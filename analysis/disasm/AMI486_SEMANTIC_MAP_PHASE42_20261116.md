# AMI486 semantic map — phase 42 (2026-11-16)

## Scope

This phase follows the Setup/editor display helpers around 571Ch–588Fh and reclassifies the CMOS B3h write continuation at 88D3h–893Ch using actual control-flow references. The key result is that the 575Eh selector belongs to the Setup/editor renderer, but the 88D3h writer is not called by that renderer and must not be described as its Setup save path.

ROM basis: ami486.bin, 64 KiB, SHA-256 91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b. Addresses below refer to the existing complete linear 16-bit listing. Because this is a linear decode, data/code overlap and indirect control flow remain possible.

## 1. Setup/editor rendering chain: 571Ch–588Fh

### 571Ch: extract a three-bit field from the UI state word

571Ch reads E19Dh, shifts right by CL, and masks AL with 07h. It then branches by the selector value:

- value 4 returns through 5751h;
- values greater than 4 return through 575Eh;
- values 0–3 use a translation table based at 55A8h, with a second selector derived from E19Dh bits 0–1.

The 5751h helper returns CMOS index C4h or CDh depending on E19Dh bit 0. The 575Eh helper returns CMOS index B3h or BAh depending on E19Dh bit 1. These are *index selectors*, not the values stored in CMOS and not proof that the Setup row is labelled "CPU speed" or any other particular name.

### 584Ah / 5862h / 587Ah: render a multi-column field

584Ah stores BX into E19Dh, calls the display-coordinate helper at 5702h and 56F1h, sets CL=0Ah, and calls 571Ch to obtain a translated display byte. It then derives a repeat count from DL.

5862h wraps 584Ah and fills the remaining cells with the index returned by 5751h, then calls 571Ch with CL=0Dh for the final display byte.

587Ah wraps 584Ah and, when its count is nonzero, repeatedly obtains the index from 575Eh and writes it at a fixed 00A0h stride. It then proceeds to the 586Fh continuation. Thus 575Eh is demonstrably consumed by this screen-rendering path, and its B3h/BAh choice is controlled by E19Dh bit 1.

The 5862h routine has callers in the BIOS Setup/menu code at 0CA Fh, 0CBAh, 0FE9h, 3CB0h, 3E7Ah, 4717h, 48DDh, 4C20h, 4D1Ah and 4F09h (linear listing addresses; see raw call sites). 587Ah is called at 0CD8h. 578Dh is a generic rectangle/fill renderer with numerous callers; it is not a CMOS writer.

### What remains unknown

The renderer proves that B3h is selected as one of the CMOS-index fields represented by the UI state word. It does not by itself identify the exact visible label, the editor's value encoding, or which caller corresponds to a specific Setup page. No unique human-readable Setup label is established from these routines alone.

## 2. The 88D3h continuation is not the Setup renderer's save path

The direct-reference scan of the complete listing finds:

- no CALL/JMP reference to 88D3h;
- no direct caller of 8914h;
- 88D3h is reached by fall-through after the 0100h-count delay loop at 88CEh–88D1h;
- the only direct jump into 88CEh found is at D60Ch.

This separates the B3h write at 8914h from the Setup/editor drawing path described above. It may still be reached through the wider D60Ch execution path, but the available static listing does not justify assigning it to a Setup Save action.

### Local semantics of the B3h write

At 88D3h the code:

1. loads CS into SS;
2. executes SMSW AX;
3. tests CR0 bit 0 (PE) via AL bit 0;
4. if PE is set, branches to 891Eh;
5. otherwise tests AH (the high byte returned by SMSW), and compares DH with 4;
6. for the special DH=4 / AH=0 path, it selects a continuation at 88EEh; otherwise it reaches the local DL test at 88FAh.

At 88FAh, DL is ANDed with 30h and compared with 30h. If both bits 4 and 5 are set, AH becomes 02h; otherwise AH becomes 00h. At 8906h, AL is set to B3h and control is transferred to the CMOS read helper EE94h through the explicit stack continuation at 890Eh. At 8912h, AH is ORed with the old CMOS byte in AL. At 8914h, AL is again set to B3h and control is transferred to CMOS write helper EE9Dh through the continuation at 891Ch.

Therefore, on this local path the operation is strictly OR-only: it can set B3h bit 1 when (DL AND 30h)=30h, and it does not clear existing B3h bits. The special DH=4 branch has a different stack continuation and is not safely reducible to the same local DL-mask condition without recovering its caller/register contract.

### 8931h continuation

8931h clears CL, loads AX=C2C2h, and transfers through the indexed ALi read helper at 8DC Fh using a stack continuation at 893Ch. This is a separate chipset-read continuation, not a direct CMOS B3h operation. The surrounding continuation bytes are intentionally not treated as ordinary sequential instructions because the code changes SP to land on embedded return/continuation sequences.

## 3. Confirmed versus unresolved

Confirmed:
- E19Dh is consumed as a packed UI/editor state word by 571Ch and its adjacent helpers.
- E19Dh bit 1 selects CMOS index B3h versus BAh at 575Eh.
- 587Ah uses that selector when rendering repeated cells; the renderer is called from Setup/menu code.
- 88D3h is not directly called by the Setup renderer; it is reached after the delay loop at 88CEh.
- The local 88FAh–8919h path reads B3h, ORs a condition-derived mask into it, and writes it back; the mask is 02h only when DL bits 4 and 5 are both set.
- 8931h uses the indexed ALi read helper with index C2h.

Unresolved:
- Exact Setup row label and user-facing meaning of the B3h/BAh field.
- The complete caller/register contract entering D60Ch/88CEh, including the special DH=4 continuation.
- Whether the B3h bit-1 update is exercised on a particular chipset/POST path at runtime.
- Hardware meaning of ALi register C2h.

## 4. Correction to the previous phase's open question

Phase 41 left open whether 88D3h–893Ch belonged to a Setup save path. The new reference audit rejects that assignment: the Setup evidence is the 571Ch/575Eh/587Ah renderer chain, while 88D3h is a separate fall-through continuation reached from the D60Ch path. The CMOS write semantics at 8914h remain valid, but its UI trigger must not be inferred from the Setup selector.

