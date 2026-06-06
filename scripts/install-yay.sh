#!/usr/bin/env bash
set -euo pipefail

TARGET_USER="${1:-}"
TARGET_HOME="${2:-}"

if [[ -z "$TARGET_USER" || -z "$TARGET_HOME" ]]; then
  echo "Usage: $0 <target_user> <target_home>" >&2
  exit 2
fi

if [[ "$(id -u)" -ne 0 ]]; then
  echo "This script must be run as root by Ansible because it installs packages with pacman." >&2
  exit 3
fi

if ! id "$TARGET_USER" >/dev/null 2>&1; then
  echo "Target user does not exist: $TARGET_USER" >&2
  exit 4
fi

if command -v yay >/dev/null 2>&1; then
  echo "yay is already installed at $(command -v yay)"
  exit 0
fi

echo "Installing dependencies required to build yay..."
pacman -S --needed --noconfirm base-devel git go

CACHE_DIR="$TARGET_HOME/.cache"
YAY_DIR="$CACHE_DIR/yay-build"

install -d -o "$TARGET_USER" -g "$TARGET_USER" -m 0755 "$CACHE_DIR"

if [[ -d "$YAY_DIR/.git" ]]; then
  echo "Updating existing yay AUR checkout..."
  runuser -u "$TARGET_USER" -- git -C "$YAY_DIR" pull --ff-only
else
  echo "Cloning yay from AUR..."
  rm -rf "$YAY_DIR"
  runuser -u "$TARGET_USER" -- git clone https://aur.archlinux.org/yay.git "$YAY_DIR"
fi

echo "Building yay as $TARGET_USER..."
runuser -u "$TARGET_USER" -- bash -lc "cd '$YAY_DIR' && makepkg -f --noconfirm"

YAY_PKG="$(find "$YAY_DIR" -maxdepth 1 -type f -name 'yay-*.pkg.tar.zst' ! -name 'yay-debug-*.pkg.tar.zst' -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -n 1 | cut -d' ' -f2- || true)"

if [[ -z "$YAY_PKG" ]]; then
  echo "Could not find built non-debug yay package in $YAY_DIR" >&2
  echo "Available built packages:" >&2
  find "$YAY_DIR" -maxdepth 1 -type f -name 'yay-*.pkg.tar.zst' -print >&2 || true
  exit 5
fi

echo "Installing built yay package: $YAY_PKG"
pacman -U --noconfirm "$YAY_PKG"

if ! command -v yay >/dev/null 2>&1; then
  echo "yay install completed, but yay is still not in PATH." >&2
  exit 6
fi

echo "yay installed successfully at $(command -v yay)"
