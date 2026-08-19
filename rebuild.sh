#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ln -sfn "$DIR" "$HOME/.dotfiles"

OPERATING_SYSTEM="$(uname -s)"
case "$OPERATING_SYSTEM" in
  Darwin)
    exec sudo darwin-rebuild switch --flake "$HOME/.dotfiles#mac"
    ;;
  Linux)
    exec nix run "$DIR/linux#home-manager" -- \
      switch --flake "$HOME/.dotfiles/linux#framework"
    ;;
  *)
    echo "Unsupported operating system: $OPERATING_SYSTEM" >&2
    exit 1
    ;;
esac
