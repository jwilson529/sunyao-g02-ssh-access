$ErrorActionPreference = 'Stop'
try {
    Write-Host "`nSUNYAO G02 | SSH ACCESS" -ForegroundColor Cyan
    Write-Host 'This copies three small Ports tools to your SD card. It does not format it.'
    Write-Host 'When you run Enable SSH Access on the handheld, this PC gains root access.'
    Write-Host 'Your private key stays in your Windows user profile. Never share it.'
    if (-not (Get-Command ssh-keygen.exe -ErrorAction SilentlyContinue)) {
        throw 'OpenSSH Client is missing. See the Windows troubleshooting guide in docs.'
    }
    Get-Volume | Where-Object DriveLetter | Select-Object DriveLetter, FileSystemLabel,
        @{Name='SizeGB';Expression={[math]::Round($_.Size/1GB,1)}} | Format-Table
    $drive = (Read-Host 'Which drive is the HANDHELD SD card? Type one letter, e.g. E').Trim().TrimEnd(':').ToUpper()
    if ($drive -notmatch '^[A-Z]$') { throw 'Enter a single drive letter.' }
    if ($drive -eq $env:SystemDrive.TrimEnd(':')) { throw 'The Windows system drive cannot be used.' }
    $volume = Get-Volume -DriveLetter $drive
    Write-Host "Selected $drive`:  Label: $($volume.FileSystemLabel)  Size: $([math]::Round($volume.Size/1GB,1)) GB"
    if ((Read-Host 'Confirm this is your handheld card by typing COPY') -cne 'COPY') { throw 'Cancelled. No files copied.' }
    $root = Split-Path $PSScriptRoot -Parent
    $source = Join-Path $root 'SD Card\ports_scripts'
    $destination = "$drive`:\ports_scripts"
    $names = @('01 - Check My Handheld.sh','02 - Enable SSH Access.sh','03 - Remove SSH Access.sh','g02-access')
    foreach ($name in $names) {
        if (Test-Path (Join-Path $destination $name)) { throw "Already exists: $name. Keep your existing setup; see docs for reinstall instructions." }
    }
    $keyDir = Join-Path $env:USERPROFILE '.ssh'
    $key = Join-Path $keyDir 'sunyao-g02'
    New-Item -ItemType Directory -Path $keyDir -Force | Out-Null
    if (-not (Test-Path $key)) {
        Write-Host "`nCreating your personal key. At both passphrase prompts, press Enter for simple setup."
        Write-Host 'You can choose a passphrase instead; SSH will ask for it when connecting.'
        & ssh-keygen.exe -t ed25519 -f $key -C 'g02-access'
        if ($LASTEXITCODE -ne 0) { throw 'Key creation failed. Nothing copied to the card.' }
    }
    if (-not (Test-Path "$key.pub")) { throw "Missing $key.pub. Do not copy the private key. See troubleshooting." }
    # Derive the public key from the private key; fail before copying if they differ.
    $derived = & ssh-keygen.exe -y -f $key
    if ($LASTEXITCODE -ne 0) { throw 'Could not read the private key.' }
    $public = (Get-Content -Raw "$key.pub").Trim()
    $parts = $public -split '\s+'
    $derivedParts = ($derived -join '').Trim() -split '\s+'
    if ($parts.Count -lt 2 -or $parts[0] -ne 'ssh-ed25519' -or $derivedParts.Count -lt 2 -or $parts[1] -ne $derivedParts[1]) {
        throw 'The public/private keys do not match, or are not Ed25519. Nothing copied.'
    }
    New-Item -ItemType Directory -Path $destination -Force | Out-Null
    foreach ($name in $names) { Copy-Item -LiteralPath (Join-Path $source $name) -Destination $destination -Recurse }
    # Normalize to plain ASCII and LF. No private key is ever copied.
    [IO.File]::WriteAllText((Join-Path $destination 'g02-access\workstation.pub'), "$($parts[0]) $($parts[1]) g02-access`n", [Text.Encoding]::ASCII)
    foreach ($file in Get-ChildItem -LiteralPath $source -File -Recurse) {
        $relative = $file.FullName.Substring($source.Length).TrimStart('\')
        if ((Get-FileHash $file.FullName).Hash -ne (Get-FileHash (Join-Path $destination $relative)).Hash) { throw "Copy verification failed: $relative" }
    }
    Write-Host "`nREADY - files copied and verified." -ForegroundColor Green
    Write-Host '1. Safely eject the card. Insert it into the powered-off handheld.'
    Write-Host '2. Turn it on. Find PORTS alongside the console/game categories, not Settings.'
    Write-Host '3. Run 01 - Check My Handheld. Then run 02 - Enable SSH Access.'
    Write-Host '4. Leave it awake on Wi-Fi. Find its current IP in Network Settings.'
    Write-Host '5. On this PC, double-click Connect Windows.cmd.'
    Write-Host 'If Ports is missing or access fails, follow README troubleshooting. Do not force an update.'
} catch {
    Write-Host "`nSTOP: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
