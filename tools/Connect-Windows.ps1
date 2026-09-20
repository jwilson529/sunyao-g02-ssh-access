$ErrorActionPreference = 'Stop'
try {
    $key = Join-Path $env:USERPROFILE '.ssh\sunyao-g02'
    if (-not (Test-Path $key)) { throw 'Run Setup Windows.cmd on this PC first.' }
    if (-not (Get-Command ssh.exe -ErrorAction SilentlyContinue)) { throw 'Install the Windows OpenSSH Client. See docs.' }
    $address = (Read-Host 'IP shown on the handheld right now (example: 192.168.1.50)').Trim()
    $parsed = $null
    if ($address -notmatch '^\d{1,3}(\.\d{1,3}){3}$' -or -not [Net.IPAddress]::TryParse($address,[ref]$parsed)) { throw 'Enter an IPv4 address, not a command or URL.' }
    Write-Host 'At the first connection, SSH asks whether to trust this device. Check the IP, then type yes.'
    Write-Host 'If asked for root password, stop: the key was not accepted. Read troubleshooting.'
    Write-Host 'A working connection opens a root shell. Type exit to disconnect.'
    & ssh.exe -i $key -o IdentitiesOnly=yes -o PasswordAuthentication=no -o KbdInteractiveAuthentication=no -o ConnectTimeout=10 "root@$address"
    exit $LASTEXITCODE
} catch { Write-Host $_.Exception.Message -ForegroundColor Red; exit 1 }
