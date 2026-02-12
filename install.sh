#!/usr/bin/env bash
# Dev-Dash CLI installer
# Usage: curl -fsSL https://raw.githubusercontent.com/jasonmassey/devdash-cli/main/install.sh | bash
set -euo pipefail

REPO="jasonmassey/devdash-cli"
INSTALL_DIR="${DEVDASH_INSTALL_DIR:-${HOME}/.local/bin}"

echo "Installing devdash CLI..."
echo ""

# Check prerequisites
missing=()
for cmd in curl jq openssl python3 git; do
  if ! command -v "$cmd" &>/dev/null; then
    missing+=("$cmd")
  fi
done

if [ ${#missing[@]} -gt 0 ]; then
  echo "Missing required dependencies: ${missing[*]}"
  echo "Please install them and retry."
  exit 1
fi

# Prefer npm if available
if command -v npm &>/dev/null; then
  echo "npm detected — installing via npm (recommended)..."
  npm install -g devdash-cli
  echo ""
  echo "Installed: $(devdash --version)"
  exit 0
fi

# Fallback: direct download
echo "npm not found — installing from GitHub..."

mkdir -p "$INSTALL_DIR"

# Download latest bin/devdash from main branch
curl -fsSL "https://raw.githubusercontent.com/${REPO}/main/bin/devdash" -o "${INSTALL_DIR}/devdash"
chmod +x "${INSTALL_DIR}/devdash"

echo ""
echo "Installed devdash to ${INSTALL_DIR}/devdash"

# Check if INSTALL_DIR is in PATH
if ! echo "$PATH" | tr ':' '\n' | grep -q "^${INSTALL_DIR}$"; then
  echo ""
  echo "⚠  ${INSTALL_DIR} is not in your PATH."
  shell_name=$(basename "${SHELL:-/bin/bash}")
  case "$shell_name" in
    zsh)  rc="${HOME}/.zshrc" ;;
    bash) rc="${HOME}/.bashrc" ;;
    fish) rc="${HOME}/.config/fish/config.fish" ;;
    *)    rc="${HOME}/.${shell_name}rc" ;;
  esac
  echo "Add this to ${rc}:"
  if [ "$shell_name" = "fish" ]; then
    echo "  fish_add_path ${INSTALL_DIR}"
  else
    echo "  export PATH=\"${INSTALL_DIR}:\$PATH\""
  fi
fi

# Offer alias setup
echo ""
if [ -t 0 ]; then
  printf "Add 'alias dd=devdash' to your shell config? [Y/n] "
  read -r answer
  answer="${answer:-y}"
  if [[ "$answer" =~ ^[Yy] ]]; then
    "${INSTALL_DIR}/devdash" alias-setup
  fi
else
  echo "Run 'devdash alias-setup' to add a 'dd' shortcut."
fi

echo ""
echo "Done! Run 'devdash help' to get started."
