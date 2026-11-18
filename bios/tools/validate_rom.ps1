param(
    [Parameter(Mandatory = $true)]
    [string]$RomPath,
    [Parameter(Mandatory = $true)]
    [int]$ExpectedSize,
    [Parameter(Mandatory = $false)]
    [string]$ReferenceRomPath
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $RomPath -PathType Leaf)) {
    throw "BIOS output not found: $RomPath"
}

$bytes = [System.IO.File]::ReadAllBytes($RomPath)
if ($bytes.Length -ne $ExpectedSize -or $ExpectedSize -ne 65536) {
    throw ("Invalid BIOS size: {0}; expected 65536 bytes" -f $bytes.Length)
}

function Assert-Bytes {
    param([int]$Offset, [byte[]]$Expected, [string]$Description)
    for ($i = 0; $i -lt $Expected.Length; $i++) {
        if ($bytes[$Offset + $i] -ne $Expected[$i]) {
            throw ("{0}: mismatch at ROM offset 0x{1:X4}; got 0x{2:X2}, expected 0x{3:X2}" -f $Description, ($Offset + $i), $bytes[$Offset + $i], $Expected[$i])
        }
    }
}

# These checks validate the assembled instruction stream, not a reference ROM.
Assert-Bytes -Offset 0xFFF0 -Expected ([byte[]](0xEA, 0x5B, 0xE0, 0x00, 0xF0)) -Description "NASM reset far jump"
Assert-Bytes -Offset 0xE05B -Expected ([byte[]](0xE9, 0xA2, 0xF5)) -Description "NASM reset gateway"
Assert-Bytes -Offset 0xD604 -Expected ([byte[]](0xFA, 0xFC, 0xE4, 0x64, 0xA8, 0x04, 0x75, 0x03, 0xE9)) -Description "NASM POST entry"

Write-Host ("NASM BIOS structural validation PASS: {0} bytes; reset vector, gateway and POST instruction encoding verified. This does not validate POST completion or boot." -f $bytes.Length) -ForegroundColor Green
