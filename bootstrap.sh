#!/usr/bin/env bash
# Takes a fresh Mac or Omarchy machine from nothing to an applied Nix config.
# Run this once. After it finishes, use ./rebuild.sh for every later change.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
OPERATING_SYSTEM="$(uname -s)"

case "$OPERATING_SYSTEM" in
  Darwin | Linux) ;;
  *)
    echo "Unsupported operating system: $OPERATING_SYSTEM" >&2
    exit 1
    ;;
esac

echo "==> Step 1: Determinate Nix"
if command -v nix >/dev/null 2>&1; then
  echo "    nix already installed, skipping"
else
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
    | sh -s -- install --no-confirm
  # shellcheck disable=SC1091
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

echo "==> Step 2: symlink this repo to ~/.dotfiles"
# linux/home.nix resolves its mkOutOfStoreSymlink paths through ~/.dotfiles, so this
# has to exist before the first switch or the build will fail to find them.
ln -sfn "$DIR" ~/.dotfiles

echo "==> Step 3: personalize the configured username"
REAL_USER="$(whoami)"
MAC_FLAKE_USER="$(sed -nE 's/^[[:space:]]*user = "([^"]+)";.*/\1/p' "$DIR/flake.nix" | head -n1)"
LINUX_FLAKE_USER="$(sed -nE 's/^[[:space:]]*user = "([^"]+)";.*/\1/p' "$DIR/linux/flake.nix" | head -n1)"
if [ -z "$MAC_FLAKE_USER" ] || [ -z "$LINUX_FLAKE_USER" ]; then
  echo "    Could not find the \"user = \" line in both flake files."
  echo "    Edit flake.nix and linux/flake.nix yourself before continuing."
  exit 1
elif [ "$MAC_FLAKE_USER" != "$REAL_USER" ] || [ "$LINUX_FLAKE_USER" != "$REAL_USER" ]; then
  echo "    The flakes are configured for \"$MAC_FLAKE_USER\" and \"$LINUX_FLAKE_USER\", but you are \"$REAL_USER\"."
  read -r -p "    Rewrite both \"user = \" lines to \"$REAL_USER\"? [y/N] " REPLY
  if [ "$REPLY" = "y" ] || [ "$REPLY" = "Y" ]; then
    for FLAKE_FILE in "$DIR/flake.nix" "$DIR/linux/flake.nix"; do
      TEMP_FILE="$(mktemp "${TMPDIR:-/tmp}/dotfiles-user.XXXXXX")"
      sed -E "s/^([[:space:]]*user = \")[^\"]+(\";.*)/\1${REAL_USER}\2/" \
        "$FLAKE_FILE" >"$TEMP_FILE"
      cp "$TEMP_FILE" "$FLAKE_FILE"
      rm "$TEMP_FILE"
    done
    echo "    Updated. Review the change with: git diff -- flake.nix linux/flake.nix"
  else
    echo "    Skipped. Edit both \"user = \" lines yourself before continuing."
    exit 1
  fi
else
  echo "    Both flakes already match \"$REAL_USER\", nothing to do."
fi

NIX_BIN="$(command -v nix)"
if [ "$OPERATING_SYSTEM" = "Darwin" ]; then
  echo "==> Step 4: first darwin-rebuild switch (pinned to nix-darwin-26.05)"
  # sudo resets PATH, so invoke the absolute Nix path on the first switch.
  sudo "$NIX_BIN" run github:nix-darwin/nix-darwin/nix-darwin-26.05#darwin-rebuild -- \
    switch --flake "$HOME/.dotfiles#mac"
else
  echo "==> Step 4: first Home Manager switch for Framework Desktop"
  # -b adopts Omarchy's existing files without discarding them.
  "$NIX_BIN" run "$DIR/linux#home-manager" -- \
    switch --flake "$HOME/.dotfiles/linux#framework" -b hm-backup
fi

echo "==> Done. Use ./rebuild.sh for future changes."
