#!/bin/sh
# Shared functions. Arguments are explicit so tests never touch system paths.
fail() { printf 'ERROR: %s\n' "$*" >&2; return 1; }
validate_key() {
  [ -f "$1" ] && [ ! -L "$1" ] || { fail 'Public key file is missing or is a symlink.'; return 1; }
  [ "$(wc -c < "$1")" -le 1024 ] || { fail 'Public key file is too large.'; return 1; }
  awk 'NF {n++; if ($1 != "ssh-ed25519" || $2 !~ /^[A-Za-z0-9+\/=]+$/) bad=1} END {exit (n != 1 || bad)}' "$1" || {
    fail 'Expected exactly one Ed25519 PUBLIC key, not a private key.'; return 1;
  }
  ssh-keygen -l -f "$1" >/dev/null 2>&1 || { fail 'SSH rejected this public key.'; return 1; }
}
check_dir() {
  [ -d "$1" ] && [ ! -L "$1" ] || { fail 'SSH directory is missing or a symlink.'; return 1; }
  for path in "$1/authorized_keys" "$1/g02-access-managed.pub"; do
    if [ -L "$path" ] || { [ -e "$path" ] && [ ! -f "$path" ]; }; then
      fail 'Refusing an unexpected SSH file type.'; return 1
    fi
  done
}
install_key() (
  set -eu
  auth_dir=$1
  pub=$2
  validate_key "$pub"
  check_dir "$auth_dir"
  key=$(awk 'NF {print $1 " " $2}' "$pub")
  blob=$(printf '%s\n' "$key" | awk '{print $2}')
  auth="$auth_dir/authorized_keys"
  state="$auth_dir/g02-access-managed.pub"
  if [ -f "$state" ]; then
    validate_key "$state"
    old=$(awk 'NF {print $1 " " $2}' "$state")
    [ "$old" = "$key" ] || { fail 'A different key is already managed. Run Remove SSH Access using the original installation first.'; exit 1; }
  fi
  if [ -f "$auth" ] && awk -v k="$blob" '$1=="ssh-ed25519" && $2==k {found=1} END {exit !found}' "$auth"; then
    if [ -f "$state" ]; then
      echo 'SUCCESS: This key is already installed.'
    else
      echo 'This key was already present. Left unchanged; this tool does not claim or remove pre-existing access.'
    fi
    exit 0
  fi
  umask 077
  tmp=$(mktemp "$auth_dir/.g02-auth.XXXXXX")
  trap 'rm -f "$tmp"' EXIT HUP INT TERM
  if [ -f "$auth" ]; then
    cp -p "$auth" "$tmp"
    backup=$(mktemp "$auth_dir/authorized_keys.before-g02.XXXXXX")
    cp -p "$auth" "$backup"
    chmod 600 "$backup"
  fi
  printf '\n%s g02-access-managed\n' "$key" >> "$tmp"
  chmod 600 "$tmp"
  # Record ownership before installing, allowing removal after interrupted setup.
  printf '%s\n' "$key" > "$state"
  chmod 600 "$state"
  chmod 700 "$auth_dir"
  mv "$tmp" "$auth"
  sync
  echo 'SUCCESS: Your public key is installed. Password and other keys are unchanged.'
)
remove_key() (
  set -eu
  auth_dir=$1
  check_dir "$auth_dir"
  auth="$auth_dir/authorized_keys"
  state="$auth_dir/g02-access-managed.pub"
  if [ ! -f "$state" ]; then echo 'Nothing to remove: no key managed by this tool.'; exit 0; fi
  validate_key "$state"
  blob=$(awk 'NF {print $2}' "$state")
  if [ -f "$auth" ]; then
    umask 077
    tmp=$(mktemp "$auth_dir/.g02-auth.XXXXXX")
    trap 'rm -f "$tmp"' EXIT HUP INT TERM
    awk -v k="$blob" '!($1=="ssh-ed25519" && $2==k && $3=="g02-access-managed")' "$auth" > "$tmp"
    chmod 600 "$tmp"
    mv "$tmp" "$auth"
  fi
  rm "$state"
  sync
  echo 'SUCCESS: The key installed by this tool was removed. Other keys and passwords are unchanged.'
  echo 'Existing SSH sessions stay open; new connections using this key should fail.'
)
