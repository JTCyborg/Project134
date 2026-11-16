#!/usr/bin/env python3
"""Emit bounded Capstone decodes from raw-byte candidate offsets.

These are inspection windows, NOT confirmed function entries or a CFG.
Data ranges (e.g. A125h message and AD00h-AE5Fh key maps) are intentionally
excluded. Each stream is independently decoded to preserve alternate starts.
"""
from pathlib import Path
from capstone import Cs, CS_ARCH_X86, CS_MODE_16

ROOT = Path(__file__).resolve().parents[1]
ROM_PATH = ROOT / "ami486.bin"
OUT_PATH = ROOT / "analysis" / "disasm" / "ami486_candidate_windows_20261116.txt"
MANIFEST_PATH = ROOT / "analysis" / "disasm" / "ami486_candidate_windows_20261116.manifest.txt"
WINDOW = 0x80

SEEDS = [
    (0xA000, "code-dense raw window; entry not yet caller-verified"),
    (0xA18E, "byte-aligned short helper immediately after embedded prompt"),
    (0xA1A0, "code-dense raw window; entry not yet caller-verified"),
    (0xA200, "code-dense raw window"),
    (0xA300, "code-dense raw window"),
    (0xA400, "code-dense raw window"),
    (0xA500, "code-dense raw window"),
    (0xA600, "code-dense raw window"),
    (0xA700, "code-dense raw window"),
    (0xA800, "code-dense raw window"),
    (0xA900, "code-dense raw window"),
    (0xAA00, "code-dense raw window"),
    (0xAB00, "code-dense raw window"),
    (0xAC00, "code-dense raw window"),
    (0xAE60, "code resumes after keyboard translation table candidate"),
    (0xAF00, "code-dense raw window"),
    (0x2100, "5555h/AAAAh pattern-write and compare stream candidate"),
    (0x6800, "code-dense raw window without phase address token"),
    (0xD100, "FDC I/O code candidate; references ports 03F4h/03F7h"),
    (0xD200, "FDC I/O continuation candidate"),
    (0xD300, "FDC I/O continuation candidate"),
    (0xD400, "FDC I/O continuation candidate"),
    (0xD500, "FDC I/O continuation candidate"),
    (0xF900, "code-dense raw window; entry and indirect-call provenance unresolved"),
]

def main():
    rom = ROM_PATH.read_bytes()
    if len(rom) != 65536:
        raise SystemExit(f"Expected 65536 bytes, got {len(rom)}")
    md = Cs(CS_ARCH_X86, CS_MODE_16)
    lines = [
        "AMI486 RAW-BYTE CANDIDATE WINDOWS",
        "Decoder: Capstone x86 16-bit",
        "Window length: 0x80 bytes per seed, clipped at ROM end",
        "WARNING: independently seeded linear decodes; not a CFG and not proof of entry points.",
        "",
    ]
    for start, reason in SEEDS:
        end = min(start + WINDOW, len(rom))
        lines += [f"===== {start:04X}h-{end-1:04X}h =====", f"Reason: {reason}"]
        off = start
        while off < end:
            ins = next(md.disasm(rom[off:end], off, count=1), None)
            if ins is None or ins.size < 1:
                b = rom[off]
                lines.append(f"{off:04X}  {b:02X}              db 0x{b:02X}")
                off += 1
            else:
                raw = rom[off:off + ins.size]
                lines.append(f"{off:04X}  {raw.hex(' ').upper():<23} {ins.mnemonic} {ins.op_str}".rstrip())
                off += ins.size
        lines.append("")
    OUT_PATH.write_text("\n".join(lines) + "\n", encoding="utf-8")
    MANIFEST_PATH.write_text(
        "Target: ami486.bin\n"
        "ROM size: 65536 bytes\n"
        f"Candidate windows: {len(SEEDS)}\n"
        f"Window bytes: 0x{WINDOW:X} each (clipped at ROM end)\n"
        "Decoder: Capstone x86 16-bit\n"
        "Interpretation: independently seeded linear windows only; no CFG or entry-point proof.\n",
        encoding="utf-8",
    )
    print(f"Wrote {len(SEEDS)} candidate windows to {OUT_PATH}")

if __name__ == "__main__":
    main()
