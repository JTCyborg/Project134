param(
    [Parameter(Mandatory = $true)]
    [string]$RomPath,

    [Parameter(Mandatory = $true)]
    [int]$ExpectedSize
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $RomPath -PathType Leaf)) {
    throw "BIOS output not found: $RomPath"
}

$bytes = [System.IO.File]::ReadAllBytes($RomPath)
if ($bytes.Length -ne $ExpectedSize) {
    throw ("Invalid ROM size: {0} bytes; expected {1}" -f $bytes.Length, $ExpectedSize)
}
if ($ExpectedSize -ne 65536) {
    throw "The current AMI486 reconstruction layout requires a 64 KiB ROM."
}

function Assert-Bytes {
    param([int]$Offset, [byte[]]$Expected, [string]$Description)
    for ($i = 0; $i -lt $Expected.Length; $i++) {
        if ($bytes[$Offset + $i] -ne $Expected[$i]) {
            throw ("{0}: mismatch at ROM offset 0x{1:X4}; got 0x{2:X2}, expected 0x{3:X2}" -f $Description, ($Offset + $i), $bytes[$Offset + $i], $Expected[$i])
        }
    }
}

# Reference reset vector: EA 5B E0 00 F0 => F000:E05B.
Assert-Bytes -Offset 0xFFF0 -Expected ([byte[]](0xEA, 0x5B, 0xE0, 0x00, 0xF0)) -Description "Reset vector"
# Reference reset gateway at F000:E05B: E9 A6 F5 => near JMP D604.
Assert-Bytes -Offset 0xE05B -Expected ([byte[]](0xE9, 0xA6, 0xF5)) -Description "Reset gateway"
# First instructions at D604 are the verified CLI/CLD/8042 status probe.
Assert-Bytes -Offset 0xD604 -Expected ([byte[]](0xFA, 0xFC, 0xE4, 0x64, 0xA8, 0x04, 0x75, 0x06)) -Description "Early POST entry"

Write-Host ("BIOS ROM layout validation PASS: {0} bytes; FFFF:0000 -> F000:E05B -> D604h" -f $bytes.Length) -ForegroundColor Green
