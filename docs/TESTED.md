# Testing record

## Original hardware verification

Verified in September 2026 on one Sunyao G02:

| Item | Observed |
| --- | --- |
| Firmware | `4.7-Nexus_devel_20260526095458` |
| Architecture | `OdroidGoAdvance.aarch64` |
| Kernel | Linux `5.10.160`, aarch64 |
| Device tree model | `Rockchip rk3326 evb lpddr3 v12 board for linux` |
| Ports execution | `uid=0(root)` |
| Root home | `/storage` |
| Authorized keys | `.ssh/authorized_keys` relative to root home |
| SSH result | Dedicated Ed25519 key accepted; interactive-command execution as root verified |
| Original root password | Unchanged |
| Firmware update | Not performed |

The successful prototype added a public key via an SD-card Ports script. This public package adds validation, guided setup, and removal behavior. Evidence for those additions is recorded below, separately from the prototype.

## Release checks

For v1.0.1:

- Eight automated tests passed, including execution under a caller that explicitly checks failures: install/repeat/remove, bad/private key rejection, pre-existing key preservation, conflicting managed key rejection, symlink rejection, initially missing authorized_keys, Windows CRLF public keys, and shell syntax.
- Both Windows helpers passed parsing in Windows PowerShell on the development workstation.
- Release ZIP integrity and the explicit file allowlist were checked; the ZIP contains no public/private keys or personal reports.
- The packaged scripts were not re-run on the real handheld before release: it became unreachable during that final check. The hardware result above establishes the prototype method, not a completed end-to-end test of every packaged feature.
- The Windows wizard has not yet been walked through end-to-end by a user. Automated CI parser checks do not establish that interaction.

Automated shell tests use temporary directories and temporary keys; they do not modify your actual SSH configuration.

Windows wizard interaction and every SD-card reader combination cannot be inferred from a shell test. No claim is made that other G02 revisions or related brands work.

## Reporting another device

Please include the exact device name, firmware version, whether Ports appears, whether the diagnostic reports root, and whether a **fresh** SSH connection succeeds. A script returning to the menu alone does not establish success.
