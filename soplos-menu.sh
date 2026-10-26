#!/bin/bash
#BLURB="Soplos Linux menu for Slackware"
#
# Script: soplos-menu.sh
# Description: One file to download. It opens a menu with every tool of this
#              repository and fetches from GitHub what each option needs.
# Author: [SoplosLinux]
# Version: 2.0
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
REL=

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

use_dialog() {
  command -v dialog > /dev/null 2>&1 && [ -t 1 ]
}

pause() {
  echo
  read -r -p "Press Enter to return to the menu. " _ <"$TTY"
}

say() {
  if use_dialog; then
    dialog --clear --msgbox "$1" 12 70
  else
    echo; echo -e "$1"; pause
  fi
}

confirm() {
  local answer
  if use_dialog; then
    dialog --clear --yesno "$1" 14 70
    return $?
  fi
  echo; echo -e "$1"
  read -r -p "Continue? [y/N] " answer <"$TTY"
  [ "$answer" = "y" ]
}

# choose TITLE TEXT TAG DESCRIPTION [TAG DESCRIPTION ...]  prints the chosen tag
choose() {
  local title=$1 text=$2 choice i
  shift 2
  local items=("$@")
  if use_dialog; then
    choice=$(dialog --clear --no-cancel --title "$title" --menu "$text" 22 78 12 "${items[@]}" 3>&1 1>&2 2>&3) || choice=0
    echo "$choice"
  else
    {
      echo
      echo "$title - $text"
      for ((i = 0; i < ${#items[@]}; i += 2)); do
        printf '  %s) %s\n' "${items[i]}" "${items[i+1]}"
      done
    } >&2
    read -r -p "Option: " choice <"$TTY"
    echo "$choice"
  fi
}

# run SCRIPT [ARGS...]  runs a script of the repository and waits
run() {
  local script=$1
  shift
  clear
  bash "$REPO/$script" "$@"
  pause
}

# ------------------------------------------------------------------ submenus

menu_clean() {
  local c
  while true; do
    c=$(choose "Clean Plasma" "Remove what a normal Plasma desktop does not need" \
      1 "Preview what would be removed" \
      2 "Preview, including the optional sections" \
      3 "Remove the unneeded packages" \
      4 "Remove them, including the optional sections" \
      5 "List the sections" \
      0 "Back")
    clear
    case "$c" in
      1) bash "$REPO/scripts/setup.debloat" -n -v | ${PAGER:-less}; pause ;;
      2) bash "$REPO/scripts/setup.debloat" -n -v -a | ${PAGER:-less}; pause ;;
      3) run scripts/setup.debloat ;;
      4) run scripts/setup.debloat -a ;;
      5) bash "$REPO/scripts/setup.debloat" -l | ${PAGER:-less}; pause ;;
      0|"") return ;;
    esac
  done
}

menu_firststeps() {
  local c
  while true; do
    c=$(choose "First steps" "Usual steps after installing Slackware" \
      1 "Boot into the graphical login (runlevel 4)" \
      2 "Set a mirror and update the system" \
      3 "Create a user with sudo" \
      4 "Set the system language" \
      5 "Force a screen resolution for X11" \
      6 "Rename the user folders to Spanish" \
      0 "Back")
    clear
    case "$c" in
      1) run scripts/setup.firststeps runlevel4 ;;
      2) confirm "Update the system with slackpkg?\n\nIt runs update gpg, update and upgrade-all, and may download a lot." && run scripts/setup.firststeps updates ;;
      3) run scripts/setup.firststeps user ;;
      4) run scripts/setup.firststeps lang ;;
      5) run scripts/setup.firststeps resolution ;;
      6) run scripts/setup.firststeps userdirs ;;
      0|"") return ;;
    esac
  done
}

menu_software() {
  local c
  while true; do
    c=$(choose "Install software" "Things Slackware does not ship" \
      1 "sbopkg (SlackBuilds.org installer)" \
      2 "Plymouth (build the package, then use the Plymouth option)" \
      3 "open-vm-tools (VMware guest: clipboard, resize)" \
      4 "Flatpak and the Flathub repository" \
      5 "KDE Discover (installs Flatpak too)" \
      0 "Back")
    clear
    case "$c" in
      1) run scripts/setup.software sbopkg ;;
      2) confirm "Build and install Plymouth from SlackBuilds.org?\n\nIt compiles the package and can take several minutes." && run scripts/setup.software plymouth ;;
      3) confirm "Build and install open-vm-tools from SlackBuilds.org?" && run scripts/setup.software open-vm-tools ;;
      4) confirm "Install Flatpak from AlienBOB's packages and add Flathub?" && run scripts/setup.software flatpak ;;
      5) confirm "Install KDE Discover and Flatpak from AlienBOB's packages?\n\nThey were built in May and June 2026 and may not match a newer -current." && run scripts/setup.software discover ;;
      0|"") return ;;
    esac
  done
}

menu_grub() {
  local c
  while true; do
    c=$(choose "GRUB" "Boot menu" \
      1 "Regenerate the GRUB menu now" \
      2 "Install the hook that regenerates it on kernel updates (Slackware 16)" \
      0 "Back")
    clear
    case "$c" in
      1) run 16/etc/geninitrd.d/post-install/grub-update.sh ;;
      2)
        if [ ! -d /etc/geninitrd.d ]; then
          say "This system has no /etc/geninitrd.d, which only Slackware 16 provides. Use the first option after installing a kernel."
        elif confirm "Install /etc/geninitrd.d/post-install/grub-update.sh?\n\nIt regenerates the GRUB menu every time a kernel is installed."; then
          mkdir -p /etc/geninitrd.d/post-install
          cp "$REPO/16/etc/geninitrd.d/post-install/grub-update.sh" /etc/geninitrd.d/post-install/grub-update.sh
          chmod 755 /etc/geninitrd.d/post-install/grub-update.sh
          say "Hook installed."
        fi
        ;;
      0|"") return ;;
    esac
  done
}

run_plymouth() {
  case "$REL" in
    15|16) ;;
    *) say "Could not detect the Slackware version from /etc/slackware-version. This installer exists for Slackware 15 and 16."; return ;;
  esac
  confirm "Install the Plymouth splash for Slackware $REL?\n\nIt replaces or patches /etc/rc.d/rc.S and rc.6 and edits the GRUB configuration. Take a snapshot or a backup first." || return
  run "$REL/scripts/setup.plymouth.installer"
}

main() {
  fetch_repo
  REL=$(release)
  local c
  while true; do
    c=$(choose "Soplos Linux" "Slackware ${REL:-unknown}" \
      1 "Clean Plasma: remove what is not needed" \
      2 "First steps: runlevel, updates, user, language" \
      3 "Install software: sbopkg, Plymouth, VMware tools, Flatpak, Discover" \
      4 "Plymouth boot splash" \
      5 "GRUB menu and kernel-update hook" \
      6 "Find library packages nobody uses (report only)" \
      7 "Build kernel 6.8.9 (Slackware 15)" \
      8 "Read the Plymouth tutorial" \
      9 "Download the latest scripts again" \
      0 "Quit")
    clear
    case "$c" in
      1) menu_clean ;;
      2) menu_firststeps ;;
      3) menu_software ;;
      4) run_plymouth ;;
      5) menu_grub ;;
      6) bash "$REPO/scripts/setup.orphans" -o /root/orphans.txt; echo "Open /root/orphans.txt to read the report."; pause ;;
      7) confirm "This builds kernel 6.8.9 from kernel.org. It takes a long time, opens make menuconfig and uses /dev/sda3 as the root device.\n\nThe script was written for Slackware 15." && run 15/scripts/setup.update.kernel-6.8.9s ;;
      8)
        case "${LANG:-}" in
          es*) ${PAGER:-less} "$REPO/docs/plymouth-tutorial.es.txt" ;;
          *)   ${PAGER:-less} "$REPO/docs/plymouth-tutorial.en.txt" ;;
        esac
        ;;
      9) fetch_repo refresh; say "Scripts downloaded again." ;;
      0|"") break ;;
      *) echo "Unknown option: $c" ;;
    esac
  done
  clear
}

main
