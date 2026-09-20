#!/bin/sh
DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd) || exit 1
umask 077
exec > "$DIR/G02-ENABLE-RESULT.txt" 2>&1
printf 'G02 SSH access: enable\n'
date -u
[ "$(id -u)" = 0 ] || { echo 'ERROR: This firmware does not run Ports as root.'; exit 1; }
[ -r "$DIR/g02-access/common.sh" ] || { echo 'ERROR: Copy the entire ports_scripts folder, including g02-access.'; exit 1; }
. "$DIR/g02-access/common.sh"
[ -f /etc/os-release ] && grep -q '^ID="*emuelec"*$' /etc/os-release || {
  echo 'ERROR: Expected EmuELEC. This package is not for ArkOS or Android.'; exit 1;
}
[ "$(awk -F: '$1=="root" {print $6}' /etc/passwd)" = /storage ] || {
  echo 'ERROR: Unexpected root home. No SSH access changes made.'; exit 1;
}
[ -d /storage/.ssh ] && [ ! -L /storage/.ssh ] || {
  echo 'ERROR: Expected /storage/.ssh directory. No changes made.'; exit 1;
}

settings=$(/usr/sbin/sshd -T 2>/dev/null) || { echo 'ERROR: Cannot read SSH settings.'; exit 1; }
printf '%s\n' "$settings" | grep -qx 'pubkeyauthentication yes' || { echo 'ERROR: Public-key authentication is disabled.'; exit 1; }
printf '%s\n' "$settings" | grep -Eq '^permitrootlogin (yes|prohibit-password|without-password)$' || { echo 'ERROR: SSH root key login is disabled.'; exit 1; }
printf '%s\n' "$settings" | grep -Eq '^authorizedkeysfile (\.ssh/authorized_keys|/storage/\.ssh/authorized_keys)( |$)' || { echo 'ERROR: Unexpected authorized_keys path.'; exit 1; }
install_key /storage/.ssh "$DIR/g02-access/workstation.pub" || exit 1
printf '\nIPv4 addresses (look for wlan0):\n'
ip -4 addr show 2>/dev/null
