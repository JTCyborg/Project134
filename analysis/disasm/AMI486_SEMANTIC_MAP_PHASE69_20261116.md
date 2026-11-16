# AMI486 semantic map — phase 69 (2026-11-16)

## Scope and correction

Rechecked the configuration-byte hypothesis from phase 68 against the actual raw `ami486.bin` bytes, not just the linear listing. Image: 65,536 bytes; repository blob SHA `480c7520c93e6c7ed437cf3ad214da7503f82ec6`.

## 1. 8281h is a byte in the ROM image

At ROM offset 8280h the bytes are:

```
F000:8280  2F 00 E7 03 00 00 12 00
           ^^ ^^
           |  +-- byte at 8281h = 00h
           +----- byte at 8280h = 2Fh
```

The inspected code references use CS:8281h for the bit-6 tests (D657h, D724h, 8B11h, 8BEC/8C44/8C51/8CA9, 9153h, 91FEh, etc.). In the unmodified checked-in ROM, the tested byte is 00h, so bit 6 is statically clear. The F06Ah reference omits an explicit CS override; whether it aliases this ROM byte depends on DS at that point and should not be assumed without tracing the segment setup.

This is a correction to phase 68's wording: 8281h should not be described as a normal RAM configuration byte with an unknown producer. For the CS-qualified reads, the value is a ROM constant. A runtime modification would require a patch/overlay or a different mapping, neither of which is established by the ROM alone.

## 2. Consequences for known branches

With CS:8281h = 00h in the stock image:

- At D657h, `TEST [CS:8281h],40h` is zero, so the JNZ at D65Dh is not taken; execution falls through to D65Fh.
- At D724h, the JNZ at D72Ah is not taken; the subsequent SMSW/CR0-related sequence at D72Ch is executed.
- At 8B11h, the JNZ at 8B17h is not taken; the CMOS register 2Dh read at 8B19h–8B28h is executed.
- At 8BEC/8C44/8C51/8CA9 and 9153h/91FEh, the same constant-zero test selects the clear-bit paths, subject to those sites being reached.

This makes the bit-6-set branch from the F06Ah test to 8AD5h unreachable under the assumption DS resolves to the same F000 ROM mapping. That DS assumption is still to be verified; the CS-qualified tests above do not depend on it.

## 3. No BIOS writer required for the CS-qualified value

The previous search for a writer to 8281h was framed as if the byte were runtime state. For CS-qualified references, that premise was wrong: they read the ROM byte itself. The absence of a store is expected and is not evidence of an incomplete RAM initialization path.

The nearby 8280h region is a ROM data area with multiple words and callback pointers (including the 82D8h–82E6h table already examined). It must be treated as immutable image data unless an external ROM shadow/patch mechanism is independently demonstrated.

## 4. BP.13 and DA5Eh status

This correction does not identify BP.13's producer. It does, however, remove the stock-ROM bit-6-set branch through the 8281h CS tests as a plausible normal path into the reset handler. The 8AD5h–8AE6h code remains a terminal keyboard-controller reset path, not the explanation for DA5Eh/DA61h.

BP.13 provenance and a dynamic entry into DA5Eh/DA61h remain unresolved.

## Next target

Trace the segment state at F06Ah and establish whether its unprefixed `[8281h]` also resolves to F000 ROM. Then trace the stock clear-bit paths from D657h, D724h and 8B11h, and continue the independent search for BP.13 writes and indirect entries into DA5Eh/DA61h.
