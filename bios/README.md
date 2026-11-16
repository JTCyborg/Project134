# BIOS workspace

This directory is reserved for Project134 BIOS research and implementation.

## Reference ROM

The original AMI486 BIOS dump (`ami486.bin`) is a reference binary only. It is not source code and will not be modified or redistributed as an implementation source.

The dump is not currently present in the Project134 working files. Add it here after the user reattaches the exact file and confirms it is the intended reference:

- `reference/ami486.bin` — original reference ROM (retain byte-for-byte)
- `reference/ami486.sha256` — checksum and provenance
- `src/` — independently written Project134 BIOS source
- `build/` — generated BIOS images (not hand-edited)

The new BIOS implementation must be developed independently. Do not copy proprietary AMIBIOS code into Project134.
