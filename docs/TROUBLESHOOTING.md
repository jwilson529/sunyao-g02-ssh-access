# Troubleshooting

[← Back to the guide](../README.md)

## Ports is missing

Ports belongs beside your **game-system categories**, not in Settings. This distinction caught us during the original setup.

Check the card on your PC: the path must be `X:\ports_scripts\02 - Enable SSH Access.sh`, where `X` is your card's letter. It must not be nested inside another downloaded folder. Keep the `g02-access` folder alongside the three scripts.

Shut down before moving the card; reboot with it inserted. If Ports still does not appear, your firmware may hide or ignore this category. Do not try random reset or update actions. Report your exact model and firmware.

## The script flashed and disappeared

It may have finished normally. After shutting down the handheld, put the card in your PC and open:

- `ports_scripts/G02-DIAGNOSTIC.txt`
- `ports_scripts/G02-ENABLE-RESULT.txt`
- `ports_scripts/G02-REMOVE-RESULT.txt` (only after removal)

A successful enable report says **SUCCESS: Your public key is installed**. A blank/missing report does not prove success. If you see `ERROR`, include that message in your issue. Return the card to the handheld and boot it before trying SSH.

## Connection timed out / unreachable

Check the handheld is on, awake, and connected to Wi-Fi. Read its **current** IP; it can change after reboot. Both devices must be on networks that allow them to reach each other. Guest Wi-Fi or client isolation can prevent this.

A timeout happens before SSH authentication. It does not mean the key is wrong.

## Permission denied

Open the enable result file and check for `SUCCESS` or `ERROR`. Use the **same PC and Windows account** that ran setup. The connector expects `%USERPROFILE%\.ssh\sunyao-g02`.

The scripts deliberately stop if root's home or the SSH configuration differs from the tested device. Share that error rather than editing firmware blindly. The old default `root / emuelec` did not work on our G02.

## Windows says OpenSSH Client is missing

In Windows Settings, search **Optional features**, choose **View features / Add a feature**, search for **OpenSSH Client**, and install it. You need the client, not the server. Your Windows administrator may need to approve installation.

Microsoft's [OpenSSH installation guide](https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse) covers differences between Windows versions.

## The setup window says STOP

The message explains why. Setup will not overwrite a previous set of package files. If updating/retrying, move the three named scripts and `g02-access` folder to a backup folder **on your PC**, then run setup again. Leave unrelated Ports files alone. The existing PC key is reused.

If copying was interrupted, follow the same procedure. This does not revoke a key already installed on the handheld.

If the private key exists but `.pub` is missing, recover the public half in PowerShell:

```powershell
ssh-keygen -y -f "$env:USERPROFILE\.ssh\sunyao-g02" | Set-Content -Encoding ascii "$env:USERPROFILE\.ssh\sunyao-g02.pub"
```

Never rename the private key to `.pub` or copy it to the card.

## SSH warns that the host identification changed

Do not automatically dismiss this warning. Check the handheld's current IP and whether the device was reflashed; another device may now have its old address. Only remove an old host-key record after you have established why the identity changed.

## I lost the original PC key

If you still have the card's scripts, **Remove SSH Access** uses the ownership record on the handheld; it does not need the old private key. Run removal, then prepare access from your new PC. A second, different key cannot silently replace an existing managed key.

## Can I now install 4.8?

Not on the evidence in this project. The G02 runs a manufacturer-customized build. The generic update notification does not verify display, controls, bootloader, partition size, or firmware compatibility. This package does not download or trigger updates.
