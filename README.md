# Project134

BIOS-first development of a ZX Spectrum-compatible platform using the PCem AMI486 machine model as the starting platform reference.

Project134 is independent of Project133. Project133 will not be modified.

## Development plan

The authoritative staged plan, task checklist and phase exit criteria are maintained in [docs/PROJECT134_PLAN.md](docs/PROJECT134_PLAN.md).

Current order:

1. Establish the Project134 baseline and identify the working AMI486 BIOS.
2. Complete POST diagnostics and validate the inherited 486 hardware.
3. Define the target Spectrum model and hardware compatibility mapping.
4. Implement Spectrum support through the BIOS/platform firmware.
5. Verify software compatibility and first launch.
6. Expand hardware support and stabilize.

The project is BIOS/platform-firmware-first. Existing PCem functionality must be preserved; any necessary PCem-core change requires explicit review.
