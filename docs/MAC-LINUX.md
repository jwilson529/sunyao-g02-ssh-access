# Mac and Linux: manual setup

[← Back to the guide](../README.md)

The on-device method was validated from Linux. These manual instructions use standard OpenSSH; macOS itself has not been tested.

1. Download and extract the release ZIP.
2. Create a dedicated key **on your computer** (stop if this filename already exists; reuse your existing key instead of overwriting it):

   ```sh
   ssh-keygen -t ed25519 -f "$HOME/.ssh/sunyao-g02" -C g02-access
   ```

   Choose a passphrase or press Enter twice. Never copy `sunyao-g02` to the card: that is the private key.

3. Using your file manager, copy the contents of **SD Card/ports_scripts** into **ports_scripts** at the root of your handheld card. Preserve unrelated files; do not replace an existing package installation without reviewing it.
4. Copy **`sunyao-g02.pub`** from your computer's `.ssh` folder into the card's **ports_scripts/g02-access** folder and rename that copy to **`workstation.pub`**. Hidden-file display may be necessary to see `.ssh`.
5. Safely eject the card; insert it into the powered-off handheld. Boot and run **Ports → 01 - Check My Handheld**, then **02 - Enable SSH Access**.
6. Leave the handheld awake on Wi-Fi. Replace the example IP below with its current address:

   ```sh
   ssh -i "$HOME/.ssh/sunyao-g02" -o IdentitiesOnly=yes root@192.168.1.50
   ```

7. Verify with `id`; expect `uid=0(root)`. Type `exit` to disconnect.

See [troubleshooting](TROUBLESHOOTING.md) and [removal](../README.md#undo-access).
