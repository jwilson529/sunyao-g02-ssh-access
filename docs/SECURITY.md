# What changes, and how to undo it

[← Back to the guide](../README.md)

## Your PC

Windows setup creates an Ed25519 key pair at `%USERPROFILE%\.ssh\sunyao-g02` and `sunyao-g02.pub`, unless one already exists. The private key is reusable access to root on your handheld. Anyone with an unencrypted copy can impersonate your PC. You may protect it with a passphrase during setup.

Only the public key is copied to `ports_scripts/g02-access/workstation.pub`. The connector uses ordinary OpenSSH host verification; it does not disable host checks or attempt password guesses.

The `.cmd` launchers use an execution-policy bypass for that PowerShell process only so the downloaded, unsigned helper can run. They do not change the system execution policy or request administrator access.

## Your handheld

**Check My Handheld:** reads identity, OS version, hardware, storage usage, and selected SSH settings. Writes `G02-DIAGNOSTIC.txt` beside the script.

**Enable SSH Access:** requires root, EmuELEC, root home `/storage`, and the expected key authentication configuration. It validates one Ed25519 public key, then:

- Preserves existing authorized keys and the root password.
- Backs up an existing `authorized_keys` to a uniquely named `authorized_keys.before-g02.*` file.
- Appends the public key with the `g02-access-managed` comment to `/storage/.ssh/authorized_keys`.
- Records that public key in `/storage/.ssh/g02-access-managed.pub` for removal.
- Sets the SSH directory to mode 700 and the key/state files to 600.
- Writes `G02-ENABLE-RESULT.txt` to the card, including current network addresses.

It does not restart SSH, alter `sshd_config`, flash firmware, reset passwords, modify game files, or install network services. SSH was already running on the tested handheld. The tool does not change the stock firmware's other security settings.

**Remove SSH Access:** removes the exact marked key recorded by this package, then deletes the ownership record. Other keys remain. It does not restore a backup over newer keys or disable SSH. Existing sessions remain open until disconnected.

If an identical key was already installed outside this tool, enable reports that it was left unchanged. The tool does not claim or remove it. Removing a public key from `authorized_keys` is what revokes it—not deleting the private key, the card scripts, or a backup file.

## Reports and sharing

Reports are stored on the game card, which may be readable by anyone with the card. Review them before posting: diagnostics contain device/build information, and enable reports contain local IP and network-interface details. No script reads password hashes or private keys.

Do not forward port 22 on your router. This project is intended for administration over your own local network. Keep the SD scripts out of reach of people who should not be able to authorize their own keys.

## Limitations

One device/firmware combination established the method. Preflight checks reduce mistakes but are not proof of compatibility on all hardware. A firmware reset may erase access. A future change to the launcher or SSH service can prevent it from working.

These scripts run as root when launched. Review updates before copying them to your card. Only obtain the package from this repository's releases.
