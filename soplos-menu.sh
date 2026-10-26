#!/bin/bash
#BLURB="Soplos Linux menu for Slackware"
#
# Script: soplos-menu.sh
# Description: One file to download. It opens a menu with every tool of this
#              repository and fetches from GitHub what each option needs.
# Author: [SoplosLinux]
# Version: 1.0
#
# Usage (as root):
#   wget https://raw.githubusercontent.com/SoplosLinux/slackware/main/soplos-menu.sh
#   bash soplos-menu.sh
#
# What it downloads: the repository archive from GitHub, once, into
# /tmp/soplos-slackware. Everything is fetched over HTTPS and nothing is
# installed until you pick an option and confirm it. Read the scripts in the
# repository before running them as root.
#
# Environment (all optional):
#   SOPLOS_REF    branch or tag to download (default: main)
#   SOPLOS_URL    full URL of the archive, replaces the GitHub address
#   SOPLOS_LOCAL  path of a local clone to use instead of downloading
#   SOPLOS_WORK   download directory (default: /tmp/soplos-slackware)

OWNER_REPO=SoplosLinux/slackware
REF=${SOPLOS_REF:-main}
URL=${SOPLOS_URL:-https://github.com/$OWNER_REPO/archive/refs/heads/$REF.tar.gz}
WORK=${SOPLOS_WORK:-/tmp/soplos-slackware}
LOCAL=${SOPLOS_LOCAL:-}
TTY=${SOPLOS_TTY:-/dev/tty}
REPO=

die() { echo "Error: $*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || die "run this menu as root."

download() {
  if command -v curl > /dev/null 2>&1; then
    curl -fsSL -o "$2" "$1"
  elif command -v wget > /dev/null 2>&1; then
    wget -q -O "$2" "$1"
  else
    die "neither curl nor wget is installed."
  fi
}

# Fetch the repository once; "refresh" downloads it again
fetch_repo() {
  if [ -n "$LOCAL" ]; then
    REPO=$LOCAL
  else
    REPO=$WORK/repo
    if [ "${1:-}" = "refresh" ] || [ ! -f "$REPO/scripts/setup.debloat" ]; then
      echo "Downloading the scripts from GitHub..."
      rm -rf "$WORK"
      mkdir -p "$REPO"
      download "$URL" "$WORK/repo.tar.gz" || die "could not download $URL"
      tar -xzf "$WORK/repo.tar.gz" -C "$REPO" --strip-components=1 || die "could not unpack the archive."
    fi
  fi
  [ -f "$REPO/scripts/setup.debloat" ] || die "the downloaded archive does not look like the Soplos repository."
}

# Slackware major version: 15, 16, or empty if it cannot be told
release() {
  sed -n 's/^Slackware \([0-9][0-9]*\)\..*/\1/p' /etc/slackware-version 2> /dev/null | head -n 1
}

pause() {
  echo
  read -r -p "Press Enter to return to the menu. " _ <"$TTY"
}

say() {
  if command -v dialog > /dev/null 2>&1 && [ -t 1 ]; then
    dialog --clear --msgbox "$1" 12 70
  else
    echo; echo "$1"; pause
  fi
}

confirm() {
  local answer
  if command -v dialog > /dev/null 2>&1 && [ -t 1 ]; then
    dialog --clear --yesno "$1" 14 70
    return $?
  fi
  echo; echo "$1"
  read -r -p "Continue? [y/N] " answer <"$TTY"
  [ "$answer" = "y" ]
}

# Show the menu and print the chosen tag
show_menu() {
  local rel=$1 choice
  local items=(
    1 "Clean Plasma: preview what would be removed"
    2 "Clean Plasma: remove the unneeded packages"
    3 "Find library packages nobody uses (report only)"
    4 "Plymouth boot splash"
    5 "GRUB: regenerate the menu now"
    6 "GRUB: hook that regenerates it on kernel updates (16)"
    7 "Build kernel 6.8.9 (Slackware 15)"
    8 "Read the Plymouth tutorial"
    9 "Download the latest scripts again"
    0 "Quit"
  )
  if command -v dialog > /dev/null 2>&1 && [ -t 1 ]; then
    choice=$(dialog --clear --no-cancel --title "Soplos Linux" \
      --menu "Slackware ${rel:-unknown}" 21 74 10 "${items[@]}" 3>&1 1>&2 2>&3) || choice=0
    echo "$choice"
  else
    {
      echo
      echo "Soplos Linux - Slackware ${rel:-unknown}"
      local i
      for ((i = 0; i < ${#items[@]}; i += 2)); do
        printf '  %s) %s\n' "${items[i]}" "${items[i+1]}"
      done
    } >&2
    read -r -p "Option: " choice <"$TTY"
    echo "$choice"
  fi
}

run_plymouth() {
  local rel=$1
  case "$rel" in
    15|16) ;;
    *) say "Could not detect the Slackware version from /etc/slackware-version. This installer exists for Slackware 15 and 16."; return ;;
  esac
  confirm "Install the Plymouth splash for Slackware $rel?\n\nIt replaces or patches /etc/rc.d/rc.S and rc.6 and edits the GRUB configuration. Take a snapshot or a backup first." || return
  clear
  bash "$REPO/$rel/scripts/setup.plymouth.installer"
  pause
}

main() {
  fetch_repo
  local rel choice
  rel=$(release)
  while true; do
    choice=$(show_menu "$rel")
    clear
    case "$choice" in
      1) bash "$REPO/scripts/setup.debloat" -n -v | ${PAGER:-less}; pause ;;
      2) bash "$REPO/scripts/setup.debloat"; pause ;;
      3) bash "$REPO/scripts/setup.orphans" -o /root/orphans.txt; echo "Open /root/orphans.txt to read the report."; pause ;;
      4) run_plymouth "$rel" ;;
      5) bash "$REPO/16/etc/geninitrd.d/post-install/grub-update.sh"; pause ;;
      6)
        if [ ! -d /etc/geninitrd.d ]; then
          say "This system has no /etc/geninitrd.d, which only Slackware 16 provides. Use option 5 after installing a kernel."
        elif confirm "Install /etc/geninitrd.d/post-install/grub-update.sh?\n\nIt regenerates the GRUB menu every time a kernel is installed."; then
          mkdir -p /etc/geninitrd.d/post-install
          cp "$REPO/16/etc/geninitrd.d/post-install/grub-update.sh" /etc/geninitrd.d/post-install/grub-update.sh
          chmod 755 /etc/geninitrd.d/post-install/grub-update.sh
          say "Hook installed."
        fi
        ;;
      7)
        confirm "This builds kernel 6.8.9 from kernel.org. It takes a long time, opens make menuconfig and uses /dev/sda3 as the root device.\n\nThe script was written for Slackware 15." && { bash "$REPO/15/scripts/setup.update.kernel-6.8.9s"; pause; }
        ;;
      8)
        case "${LANG:-}" in
          es*) ${PAGER:-less} "$REPO/docs/plymouth-tutorial.es.txt" ;;
          *)   ${PAGER:-less} "$REPO/docs/plymouth-tutorial.en.txt" ;;
        esac
        ;;
      9) fetch_repo refresh; say "Scripts downloaded again." ;;
      0|"") break ;;
      *) echo "Unknown option: $choice" ;;
    esac
  done
  clear
}

main
