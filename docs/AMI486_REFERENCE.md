# AMI486 Reference Baseline

## Status

Research in progress. This document records only facts confirmed from the upstream PCem source inspected on 2026-11-16. It is not a substitute for inspecting the exact Project133 source revision or the user's ROM image.

## Confirmed model registration

Reference source: [sarah-walker-pcem/pcem, src/models/model.c, dev](https://github.com/sarah-walker-pcem/pcem/blob/dev/src/models/model.c).

The `m_ami486` model is registered with:

- Display name: `[486] AMI 486 clone`
- ROM identifier: `ROM_AMI486`
- Machine configuration name: `ami486`
- CPU families: Intel i486, AMD Am486, Cyrix Cx486
- Model flags: `MODEL_GFX_NONE | MODEL_AT | MODEL_HAS_IDE`
- RAM configuration fields in this source revision: minimum 1, maximum 256, step 1
- Machine initialization callback: `at_ali1429_init`

The callback calls `at_init()` followed by `ali1429_init()`. This establishes that the AMI486 machine profile is built on the AT platform initialization and the ALi 1429 chipset model in this source revision.

## What this establishes

1. The AMI486 profile is not a complete motherboard implementation contained in the BIOS ROM; it depends on PCem's AT platform and ALi 1429 chipset/device emulation.
2. The model registration advertises no built-in graphics adapter (`MODEL_GFX_NONE`); video is supplied by a separately configured adapter.
3. IDE is part of the machine profile.
4. The CPU family and RAM limits above are properties of the inspected upstream source revision, not yet verified against the exact Project133 checkout used by the user.

## Not yet verified

- Exact PCem source repository, branch, commit and local modifications used by Project133.
- Exact ROM-set 46 machine/profile configuration.
- Actual `ami486.bin` bytes, size, checksum, disassembly and POST flow.
- ALi 1429 register defaults and all devices initialized by `ali1429_init()`.
- BIOS reset-vector mapping and execution trace in the user's build.
- Memory map, shadow RAM, cache and chipset register behavior as observed at runtime.

## Required evidence to continue

Please attach the exact `ami486.bin` file again in this Project134 conversation. The binary is not currently available in the working files, so its checksum, disassembly and POST call graph cannot be independently reproduced yet.

Also capture or provide the exact Project133 source commit (or `git rev-parse HEAD`) and the AMI486 configuration used for the successful ROM-set 46 launch. Project133 remains read-only; this information is used only as the reference baseline.
