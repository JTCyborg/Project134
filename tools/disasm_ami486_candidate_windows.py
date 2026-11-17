#!/usr/bin/env python3
"""Emit bounded Capstone decodes from raw-byte candidate offsets.

These are inspection windows, NOT confirmed function entries or a CFG.
Known tables/strings are emitted as data and excluded from code windows.
"""
from pathlib import Path
from capstone import Cs, CS_ARCH_X86, CS_MODE_16
from capstone.x86_const import X86_OP_IMM

ROOT = Path(__file__).resolve().parents[1]
ROM_PATH = ROOT / "ami486.bin"
OUT_PATH = ROOT / "analysis" / "disasm" / "ami486_candidate_windows_20261116.txt"
MANIFEST_PATH = ROOT / "analysis" / "disasm" / "ami486_candidate_windows_20261116.manifest.txt"
WINDOW = 0x80
LIMITS = {0x2D11: 0xE4, 0xE00: 0x1A, 0xE19: 0x63, 0xE47: 0x35, 0xE7C: 0x66, 0xEE2: 0x1FD, 0xC7D: 0x83, 0xCFE: 0x80, 0xD03: 0x7D, 0xD08: 0x78, 0xD84: 0x7C, 0x60BB: 0x60, 0x3F4A: 0xD, 0x3F7B: 0x1C7, 0x4142: 0xA2, 0x41C0: 0x24, 0x41E4: 0x3A, 0x421E: 0x13, 0x427D: 0x6, 0x431B: 0x5, 0xA08D: 0x64, 0xA0A0: 0x51, 0xA0BD: 0x34, 0xE845: 0x20, 0x2238: 0xA, 0x2244: 0xB, 0x2250: 0x3, 0xF8E7: 0x43, 0xD46D: 0x2D, 0x131F: 0x46, 0x578D: 0x80, 0x57FD: 0x80, 0x5862: 0x80, 0x58AF: 0x20, 0x58BE: 0x30, 0x58D3: 0x20, 0x58EE: 0x20, 0x5902: 0x60, 0x592A: 0x40, 0x5FE9: 0x40, 0x6008: 0x40, 0x6115: 0x40, 0x6122: 0x40, 0x6137: 0x40, 0x614D: 0x17, 0x56F1: 0x40, 0x5702: 0x40, 0x5711: 0x20, 0x571C: 0x30, 0x5729: 0x30, 0x5751: 0x20, 0x575E: 0x20, 0x576B: 0x20, 0x57E7: 0x20, 0x584A: 0x20, 0x587A: 0x20, 0x5891: 0x20, 0x58A1: 0x20, 0x58C6: 0x20, 0x591A: 0x20, 0x5FE4: 0x20, 0x6024: 0x20, 0x603F: 0x40, 0x6066: 0x40, 0x6092: 0x40}

DATA_RANGES = [
    (0x3044, 0x318C, "Complete Setup main-menu caption strings, ending at the final NUL", "ascii"),
    (0x318C, 0x31A4, "Setup main-menu caption pointer table (12 words)", "words"),
    (0x31A4, 0x342E, "Setup menu descriptions and help strings", "ascii"),
    (0x342E, 0x3444, "11-entry Setup long-description pointer table", "words"),
    (0x3444, 0x3446, "Separate pointer to the Do Not Write exit string", "words"),
    (0x3446, 0x345C, "11-entry Setup main-menu handler pointer table", "words"),
    (0x345C, 0x3473, "AMI BIOS Setup Utilities title string", "ascii"),
    (0x3473, 0x3474, "Setup title-to-key-legend control prefix", "hexascii"),
    (0x3474, 0x34AB, "Setup keyboard navigation legend", "hexascii"),
    (0x34AB, 0x3501, "No-CMOS warning and Setup warning text", "ascii"),
    (0x3501, 0x3601, "Setup entry/help instructions", "ascii"),
    (0x3601, 0x3624, "AMI BIOS Setup Program title", "ascii"),
    (0x36AB, 0x37C3, "Available-options and hard-disk help strings", "ascii"),
    (0x381C, 0x3873, "Hard-disk format menu labels", "ascii"),
    (0x3874, 0x3900, "Hard-disk format menu title and labels", "ascii"),
    (0x4231, 0x427D, "POST summary double-line top border graphics (C9h/CDh)", "hexascii"),
    (0x427D, 0x4283, "AMIBIOS banner right-corner and vertical-border prefix", "hexascii"),
    (0x4283, 0x42CC, "AMIBIOS System Configuration copyright banner", "ascii"),
    (0x42CC, 0x42D0, "AMIBIOS banner terminator/control bytes", "hexascii"),
    (0x42D0, 0x431B, "POST summary double-line separator/border graphics", "hexascii"),
    (0x431B, 0x4320, "POST summary left/right border and CR/LF control bytes", "hexascii"),
    (0x4320, 0x45D8, "POST summary field labels, CPU names and device-value strings", "hexascii"),
    (0x45D8, 0x4600, "POST summary bottom box-drawing border graphics", "hexascii"),
    (0xA0F1, 0xA125, "INT 13h AH function table", "words"),
    (0xA125, 0xA18E, "Format / BootSector Write / Possible VIRUS prompt", "ascii"),
    (0xAD00, 0xAE60, "Keyboard translation data candidates", "hexascii"),
    (0xF92A, 0xF936, "F9xx indirect-handler offset table", "words"),
    (0xE401, 0xE481, "First eight 16-byte fixed-disk parameter records", "hexascii"),
    (0xC5FA, 0xC610, "Legacy floppy INT 13h AH dispatch table", "words"),
    (0x2AB3, 0x2AC3, "Seven Setup clock-label strings plus callback offset 5756h", "words"),
    (0x2B0B, 0x2B13, "Four Setup speed-label string pointers", "words"),
    (0x2B8D, 0x2B91, "Two Setup wait-state label string pointers", "words"),
    (0x2C15, 0x2C1D, "Four Setup mode-label string pointers", "words"),
    (0x2CAF, 0x2CCF, "Sixteen Setup timing-label string pointers", "words"),
    (0xB55F, 0xB7B1, "Setup option labels: clock, speed, cache, wait states and timing", "ascii"),
    (0x55A8, 0x55E8, "8x8 CP437 box-drawing glyph lookup table used by E19Dh border-state decoder", "hexascii"),
    (0x55E8, 0x55EC, "Video text segment B800h and UI attribute constants", "hexascii"),
    (0x6164, 0x6176, "18-byte Setup viewport/calendar layout lookup table; role unresolved", "hexascii"),
    (0x6176, 0x6194, "Setup calendar/header box-drawing pattern", "hexascii"),
    (0x6194, 0x61B2, "Weekday names and vertical-border separators", "hexascii"),
    (0x188E, 0x18E5, "Four POST resource-conflict messages (parallel, serial, floppy and hard disk)", "ascii"),
    (0x19B0, 0x19CA, "POST cache/CPU timing threshold lookup bytes preceding the display labels", "hexascii"),
    (0x19CA, 0x19F8, "POST cache-memory and CPU-clock display strings", "ascii"),
    (0x2F24, 0x2F66, "Setup exit confirmation prompts: write CMOS or quit without saving", "ascii"),
    (0x3624, 0x36A4, "Setup secondary keyboard legend and F-key option captions with control bytes", "hexascii"),
    (0x37C3, 0x3806, "Setup option-page legends, control prefixes and border fill bytes", "hexascii"),
    (0x3806, 0x381C, "Setup menu border fill, terminator and disk-utility exit legend", "hexascii"),
    (0x3900, 0x3C5C, "Hard-disk utility strings and embedded menu/error pointer tables", "hexascii"),
    (0x59C0, 0x59C6, "Three-word pointer table for Setup load-value confirmation prompts", "words"),
    (0x59C6, 0x5A4C, "Setup load-original/default-values confirmation prompts", "ascii"),
    (0x7145, 0x714E, "Inline POST memory-throughput unit label (not NUL terminated)", "ascii"),
    (0x732B, 0x737F, "POST summary navigation legend, box-drawing fill and CR/LF control bytes", "hexascii"),
    (0x7380, 0x78B6, "POST summary, device labels, Setup help, calendar names and adjacent pointer tables", "hexascii"),
    (0x78B6, 0x7CE9, "POST error messages, boot/password prompts and keyboard-controller warning strings", "ascii"),
    (0x8000, 0x81EE, "AMI BIOS identification, OEM ID/configuration strings and padded banner data", "hexascii"),
    (0xB528, 0xB55F, "ASCII character/glyph lookup bytes preceding Setup option labels", "hexascii"),
]

SEEDS = [
    (0x56F1, "text-mode cell-offset helper: DI=(row*80+column)*2"),
    (0x5702, "video-mode helper: OUT 3D8h,21h and load ES from [55E8h]"),
    (0x5711, "video-mode helper: OUT 3D8h,29h"),
    (0x571C, "decode E19Dh packed border field and select glyph helper"),
    (0x5729, "lookup CP437 border glyph from the 55A8h table using E19D fields"),
    (0x5751, "horizontal border glyph selector: C4h/CDh via E19D bit 0"),
    (0x575E, "vertical border glyph selector: B3h/BAh via E19D bit 1"),
    (0x576B, "draw horizontal text-cell row using E199/E19F state"),
    (0x57E7, "compute rectangle dimensions and text-cell origin"),
    (0x584A, "initialize line-drawing state from BX and E19Dh"),
    (0x587A, "draw vertical border line"),
    (0x5891, "save current text attribute and merge mask [55EAh]"),
    (0x58A1, "temporary highlight-attribute wrapper around centered text output"),
    (0x58C6, "compute centered X coordinate from NUL string length"),
    (0x591A, "keyboard ASCII case-normalization helper"),
    (0x5FE4, "reset absolute selected-record index E18Ch to zero"),
    (0x6024, "advance variable-length Setup record and skip auxiliary NUL strings"),
    (0x603F, "decode current option value through the E000h configuration shadow and record mask"),
    (0x6066, "write transformed option value back to the E000h configuration shadow"),
    (0x6092, "dispatch the record-specific option callback from the E195h pointer table"),

    (0x578D, "Setup panel border renderer using the CP437 glyph table"),
    (0x57FD, "fill rectangular text area with space cells"),
    (0x5862, "direct CALL target from Setup/menu renderers; phase-42 caller cross-reference"),
    (0x58AF, "render NUL-terminated text with normal/alternate attribute"),
    (0x58BE, "render centered NUL-terminated text and restore attribute"),
    (0x58D3, "render NUL-terminated string at text-screen coordinate"),
    (0x58EE, "render one character at text-screen coordinate"),
    (0x5902, "Setup input/event read helper; direct callers 0D3Dh and 10D6h"),
    (0x592A, "NUL-terminated string length helper used by option-list renderer"),
    (0x5FE9, "Setup list reset/position helper; direct callers 0D03h and 0D34h"),
    (0x6008, "advance to next visible Setup record; wrap at E193h"),
    (0x6115, "resolve current option code to its NUL-terminated display string"),
    (0x6122, "alternate entry into 6115h string-list skip tail; AL is number of NUL strings to skip"),
    (0x6137, "map E185h viewport index to B800h text-screen offset"),
    (0x614D, "count visible Setup records by following 6008h links"),

    (0x0C7D, "direct CALL target at 0C79h; Setup item-list initializer prologue"),
    (0x0CFE, "aligned MOV state initialization immediately before Setup item loop"),
    (0x0D03, "fall-through continuation after E1xx state initialization"),
    (0x0D08, "loop body directly targeted by 0D21h; draws Setup menu items"),
    (0x0D84, "aligned selector dispatcher and branch context before E1xx routines"),
    (0x0E00, "short branch/call fragment; not assumed to be a function entry"),
    (0x0E19, "byte-aligned state-update helper; entry begins with CMP byte ptr [E18C],0"),
    (0x0E47, "direct CALL target; increment/wrap state-update helper"),
    (0x0E7C, "stack-frame routine following E1xx state-update helper"),
    (0x0EE2, "second stack-frame routine in E1xx state/menu rendering cluster"),
    (0x60BB, "direct CALL site and caller context for E1xx state/menu helper at 0E7Ch"),
    (0x3F4A, "direct CALL wrapper for POST summary frame renderer; prints bottom border on return"),
    (0x3F7B, "POST summary frame and hardware-field renderer; continues through 4141h"),
    (0x4142, "direct CALL target from POST summary; CPU-identification and processor-label selection"),
    (0x41C0, "POST processor-identification display block; incoming entry unresolved"),
    (0x41E4, "direct CALL target; POST numeric-processor presence display"),
    (0x421E, "direct CALL target; equipment-word/Weitek display selector"),
    (0x427D, "mixed banner prefix before AMIBIOS system-configuration text"),
    (0x431B, "structured display-record prefix before POST summary field labels"),
    (0xA000, "code-dense raw window; entry not yet caller-verified"),
    (0xA080, "continuation candidate after initial A000h helper group"),
    (0xA08D, "INT 13h hard-disk handler entry; forwards DL<80h to INT 40h"),
    (0xA0A0, "INT 13h AH-function dispatcher prologue"),
    (0xA0BD, "indirect CALL through CS-relative 26-entry function table"),
    (0xA18E, "byte-aligned short helper immediately after embedded prompt"),
    (0xA197, "branch target from A19Ah; likely routine entry"),
    (0xA1A4, "independent routine entry"),
    (0xA1B3, "branch target from A19Ch; ATA controller initialization path"),
    (0xA20B, "status-return helper after A20Ah RET"),
    (0xA216, "routine entry after A215h RET"),
    (0xA226, "routine entry after A225h RET"),
    (0xA23E, "routine entry after A23Dh RET"),
    (0xA25F, "routine entry after A25Eh RET"),
    (0xA2F1, "direct CALL target; ATA geometry/parameter helper"),
    (0xA300, "geometry/parameter conversion candidate"),
    (0xA337, "direct CALL target"),
    (0xA372, "direct dispatch target"),
    (0xA406, "direct jump target; ATA data transfer path"),
    (0xA474, "routine entry after A473h RET"),
    (0xA501, "direct CALL target; ATA command path"),
    (0xA5A9, "direct CALL target; ATA parameter helper"),
    (0xA5B6, "direct CALL target; ATA geometry helper"),
    (0xA5CA, "direct CALL target; ATA readiness/helper"),
    (0xA52B, "routine entry after A52Ah RET"),
    (0xA552, "direct CALL target"),
    (0xA57B, "routine entry after A57Ah RET"),
    (0xA610, "continuation near ATA status helper"),
    (0xA619, "routine entry after A618h RET"),
    (0xA621, "direct CALL target; ATA feature/error register write"),
    (0xA62D, "direct CALL target; ATA status polling"),
    (0xA655, "direct CALL target; ATA drive/status check"),
    (0xA694, "direct CALL target; ATA wait helper"),
    (0xA6BB, "direct CALL target; ATA transfer/status helper"),
    (0xA6DC, "direct CALL target; ATA status completion helper"),
    (0xA703, "ATA error/status decode candidate"),
    (0xA73E, "direct CALL target; ATA command register write"),
    (0xA76C, "direct CALL target; ES:BX buffer normalization"),
    (0xA798, "direct CALL target; ATA transfer setup"),
    (0xA7BA, "direct CALL target; ATA transfer helper"),
    (0xA808, "direct CALL target; mode/compatibility check"),
    (0xA80F, "direct CALL target; prompt decision path"),
    (0xA847, "direct CALL target; BIOS display/input prompt"),
    (0xA8C7, "prompt continuation / input decision candidate"),
    (0xA95E, "candidate INT 13h IVT hook installation stream"),
    (0xAA00, "INT 13h disk-service path candidate"),
    (0xAA6F, "direct CALL target; INT 13h drive parameter query"),
    (0xAB34, "routine entry after AB33h RET; disk metadata path"),
    (0xAC00, "ATA identify/read transfer path candidate"),
    (0xAE60, "INT 15h keyboard-intercept wrapper candidate after translation tables"),
    (0xAEE3, "keyboard-intercept branch target / common continuation"),
    (0xAF06, "keyboard event handler continuation"),
    (0xB1E9, "keyboard-intercept common exit target"),
    (0xB242, "keyboard event classifier direct CALL target"),
    (0xB253, "keyboard event state helper direct CALL target"),
    (0xB25F, "keyboard event state helper direct CALL target"),
    (0xB273, "keyboard-intercept helper direct CALL target"),
    (0xB296, "keyboard-intercept helper direct CALL target"),
    (0xB315, "keyboard event state helper direct CALL target"),
    (0xB327, "keyboard event state helper direct CALL target"),
    (0xB3D2, "keyboard event state helper direct CALL target"),
    (0xB3E2, "BIOS INT 16h keyboard-service handler entry candidate"),
    (0xB3DE, "keyboard interrupt/event continuation"),
    (0xB399, "BIOS keyboard ring-buffer pointer helper"),
    (0xB3A6, "keyboard controller status/command helper"),
    (0xB36A, "8042 keyboard command-byte sender with retry"),
    (0xB413, "INT 16h keyboard-buffer status path"),
    (0xB431, "INT 16h typematic-rate setup path"),
    (0xB473, "INT 16h keyboard read path candidate"),
    (0xB478, "INT 16h keyboard status path candidate"),
    (0xB480, "INT 16h keyboard service continuation"),
    (0xB48A, "INT 16h keyboard service continuation"),
    (0xB3D8, "keyboard event state helper direct CALL target"),
    (0xAF00, "keyboard/BIOS event handling code candidate"),
    (0x2100, "5555h/AAAAh pattern-write and compare stream candidate"),
    (0x2A00, "Setup chipset-option helper region; entry alignment to verify"),
    (0x2A04, "Setup chipset-option helper aligned code entry"),
    (0x5756, "callback target in final entry of 2AB3h clock selector table"),
    (0x2A80, "Setup chipset-option helper continuation"),
    (0x2AC2, "Setup clock-label selector; reads pointer table at 2AB3h"),
    (0x2B00, "Setup option selector continuation"),
    (0x2B13, "Setup speed-label selector; reads pointer table at 2B0Bh"),
    (0x2B4C, "Second Setup speed-label selector"),
    (0x2B80, "Setup wait-state selector continuation"),
    (0x2B91, "Setup wait-state label selector; reads pointer table at 2B8Dh"),
    (0x2BD3, "Second Setup wait-state label selector"),
    (0x2C00, "Setup option selector continuation"),
    (0x2C1D, "Setup mode-label selector; reads pointer table at 2C15h"),
    (0x2C69, "Setup enabled/disabled label selector"),
    (0x2C80, "Setup timing-label selector continuation"),
    (0x2CCF, "Setup timing-label selector; reads pointer table at 2CAFh"),
    (0x2D11, "stack-threaded memory/timing benchmark candidate; entry precondition unresolved"),
    (0x2DF5, "PIT channel-2 timing measurement helper"),
    (0x2E58, "timer measurement continuation"),
    (0x2187, "64-MiB memory-alias probe continuation"),
    (0x222D, "memory-alias result path that launches a stack-threaded chipset I/O sequence"),
    (0x2238, "return-to-stack code: read-modify-write chipset register 16h"),
    (0x2244, "return-to-stack code: write chipset register 11h"),
    (0x2250, "return-to-stack code continuation"),
    (0x2381, "second memory-alias result path; chipset register 10h write trampoline"),
    (0x2396, "return-to-stack code: mask and write chipset register 10h"),
    (0x23AA, "return-to-stack code: chipset register 11h update"),
    (0x23B6, "return-to-stack code: CR0 transition sequence"),
    (0x23CE, "return-to-stack continuation after CR0 transition"),
    (0x8DCF, "indexed chipset-register read helper using ports 22h/23h"),
    (0x8DDC, "indexed chipset-register write helper using ports 22h/23h"),
    (0x2253, "second memory-pattern probe stream"),
    (0x22DB, "64-MiB memory-alias probe continuation and chipset update"),
    (0x6700, "callers of the numeric text-rendering helper at 6805h"),
    (0x6708, "direct CALL site for numeric renderer 6805h"),
    (0x6716, "direct CALL site for numeric renderer 6805h"),
    (0x6721, "direct CALL site for numeric renderer 6805h"),
    (0x67AE, "BIOS INT1A clock/time display helper candidate"),
    (0x6774, "BIOS INT1A date read and display path"),
    (0x67D8, "numeric formatting helper"),
    (0x6800, "code-dense raw window without phase address token"),
    (0x6805, "numeric text-rendering loop"),
    (0x6841, "recursive decimal conversion helper"),
    (0x6860, "BIOS INT10 character/attribute output helper"),
    (0x68B0, "hexadecimal byte display helper"),
    (0x68C8, "BIOS INT10 character output helper"),
    (0x68E2, "numeric/date formatting helper"),
    (0xD100, "FDC I/O code candidate; references ports 03F4h/03F7h"),
    (0xD104, "FDC media/drive-state helper candidate"),
    (0xD156, "direct DMA programming helper"),
    (0xC610, "legacy floppy INT 13h handler entry; saved into INT 40h by A95Eh"),
    (0xC648, "shared FDC/INT13 status epilogue"),
    (0xC6BC, "FDC sense-interrupt status call bridge"),
    (0xC700, "diskette BIOS dispatch continuation"),
    (0xC780, "diskette BIOS dispatch continuation"),
    (0xC8B0, "diskette DMA transfer dispatch path"),
    (0xC8BB, "direct caller of DMA channel-2 setup D156h"),
    (0xC913, "diskette FDC DMA/result sequence"),
    (0xC936, "direct caller of DMA channel-2 setup D156h"),
    (0xC996, "diskette BIOS status/return continuation"),
    (0xD1C0, "direct FDC state/reset helper"),
    (0xD200, "FDC I/O continuation candidate"),
    (0xD216, "FDC/DMA transaction coordinator"),
    (0xD243, "FDC FIFO command-byte writer"),
    (0xD270, "FDC result-byte collection loop"),
    (0xD300, "FDC I/O continuation candidate"),
    (0xD2BD, "FDC status-byte to BIOS error mapper"),
    (0xD2FD, "FDC reset/status path"),
    (0xD348, "FDC digital-output-register reset sequence"),
    (0xD3A3, "FDC controller state helper"),
    (0xD3A5, "FDC controller state helper"),
    (0xD3B5, "FDC drive-state helper"),
    (0xD3ED, "FDC command sequence entry candidate"),
    (0xD3FA, "FDC command sequence common path"),
    (0xD46D, "FDC alternate CMOS-configuration rate-probe path"),
    (0x131F, "POST caller that invokes the INT13/INT40 hook installer at A95Eh"),
    (0xD400, "FDC I/O continuation candidate"),
    (0xD499, "FDC FIFO command helper"),
    (0xD500, "FDC I/O continuation candidate"),
    (0xD520, "FDC multi-byte result validation"),
    (0xD517, "FDC configuration-control register writer"),
    (0xD294, "direct CALL target; FDC result/data read helper"),
    (0xD580, "FDC command completion continuation"),
    (0xD5DB, "FDC routine continuation / return path"),
    (0xE845, "INT 76h / IRQ14 handler installed by A95Eh"),
    (0xF8E7, "guarded six-service INT 14h serial dispatcher candidate; F92Ah handler table follows after IRET"),
    (0xF936, "target listed in F92Ah dispatch table"),
    (0xF977, "target listed in F92Ah dispatch table"),
    (0xF986, "target listed in F92Ah dispatch table"),
    (0xF999, "target listed in F92Ah dispatch table"),
    (0xF9C4, "target listed in F92Ah dispatch table"),
    (0xF9D3, "target listed in F92Ah dispatch table"),
]

def main():
    rom = ROM_PATH.read_bytes()
    if len(rom) != 65536:
        raise SystemExit(f"Expected 65536 bytes, got {len(rom)}")
    md = Cs(CS_ARCH_X86, CS_MODE_16)
    md.detail = True
    lines = [
        "AMI486 RAW-BYTE CANDIDATE WINDOWS",
        "Decoder: Capstone x86 16-bit",
        "Window length: 0x80 bytes by default; selected handler windows stop at known data boundaries",
        "WARNING: independently seeded linear decodes; not a CFG and not proof of entry points.",
        "Relative near-branch targets are normalized to 16-bit IP wraparound.",
        "",
    ]
    for start, end, label, kind in DATA_RANGES:
        raw = rom[start:end]
        lines += [f"===== DATA {start:04X}h-{end-1:04X}h =====", f"Reason: {label}"]
        if kind == "words":
            words = [int.from_bytes(raw[i:i+2], "little") for i in range(0, len(raw), 2)]
            lines.append("Words: " + ", ".join(f"{w:04X}" for w in words))
        elif kind == "ascii":
            lines.append("ASCII: " + repr(raw.decode("ascii", errors="replace")))
        else:
            for pos in range(0, len(raw), 16):
                chunk = raw[pos:pos+16]
                asc = "".join(chr(b) if 32 <= b < 127 else "." for b in chunk)
                lines.append(f"{start+pos:04X}  {chunk.hex(' ').upper():<47} {asc}")
        lines.append("")
    seen = set()
    for start, reason in SEEDS:
        if start in seen:
            continue
        seen.add(start)
        end = min(start + LIMITS.get(start, WINDOW), len(rom))
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
                op_str = ins.op_str
                b = ins.bytes
                relative = (
                    b[0] in (0xE8, 0xE9, 0xEB)
                    or 0x70 <= b[0] <= 0x7F
                    or 0xE0 <= b[0] <= 0xE3
                    or (len(b) >= 2 and b[0] == 0x0F and 0x80 <= b[1] <= 0x8F)
                )
                if relative and ins.operands and ins.operands[0].type == X86_OP_IMM:
                    op_str = f"0x{ins.operands[0].imm & 0xFFFF:x}"
                lines.append(f"{off:04X}  {raw.hex(' ').upper():<23} {ins.mnemonic} {op_str}".rstrip())
                off += ins.size
        lines.append("")
    OUT_PATH.write_text("\n".join(lines) + "\n", encoding="utf-8")
    MANIFEST_PATH.write_text(
        "Target: ami486.bin\n"
        "ROM size: 65536 bytes\n"
        f"Candidate windows: {len(seen)}\n"
        f"Data ranges: {len(DATA_RANGES)}\n"
        f"Window bytes: 0x{WINDOW:X} default; selected handler windows clipped at known data boundaries\n"
        "Decoder: Capstone x86 16-bit\n"
        "Relative near-branch targets normalized to 16-bit IP.\n"
        "Known tables and strings are emitted separately as data.\n"
        "Interpretation: independently seeded linear windows only; no CFG or entry-point proof.\n",
        encoding="utf-8",
    )
    print(f"Wrote {len(seen)} candidate windows to {OUT_PATH}")

if __name__ == "__main__":
    main()
