#!/bin/sh
DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd) || exit 1
umask 077
{
  echo 'G02 diagnostic report — no system settings changed'
  date -u
  printf '\n=== Access level ===\n'
  id
  printf '\n=== Firmware ===\n'
  cat /etc/os-release 2>/dev/null
  uname -a
  printf '\n=== Hardware ===\n'
  for f in /proc/device-tree/model /proc/device-tree/compatible; do
    [ -r "$f" ] && tr '\000' '\n' < "$f"
  done
  printf '\n=== Storage ===\n'
  df -h /flash /storage /storage/roms 2>/dev/null
  printf '\n=== SSH settings ===\n'
  /usr/sbin/sshd -T 2>/dev/null | grep -E '^(authorizedkeysfile|pubkeyauthentication|permitrootlogin) '
  printf '\n=== End ===\n'
} > "$DIR/G02-DIAGNOSTIC.txt" 2>&1
sync
