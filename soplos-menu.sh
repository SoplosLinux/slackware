#!/bin/bash
#BLURB="Soplos Linux menu for Slackware"
#
# Script: soplos-menu.sh
# Description: One file to download. It opens a menu, in English or Spanish,
#              with every tool of this repository and fetches from GitHub what
#              each option needs.
# Author: [SoplosLinux]
# Version: 2.1
#
# Usage (as root):
#   wget https://raw.githubusercontent.com/SoplosLinux/slackware/main/soplos-menu.sh
#   bash soplos-menu.sh
#
# What it does the first time: it downloads the repository archive from GitHub
# into /usr/local/share/soplos-slackware, creates the command soplos-menu in
# /usr/local/bin and a menu entry in the application launcher. After that the
# downloaded file is not needed any more: start it from the launcher or run
# "soplos-menu" as root. Everything is fetched over HTTPS and nothing is
# installed until you pick an option and confirm it. Read the scripts in the
# repository before running them as root.
#
# To remove it all: soplos-menu --uninstall
#
# Environment (all optional):
#   SOPLOS_LANG   menu language, en or es (default: en; change it from the menu)
#   SOPLOS_REF    branch or tag to download (default: main)
#   SOPLOS_URL    full URL of the archive, replaces the GitHub address
#   SOPLOS_LOCAL  path of a local clone to use instead of downloading
#   SOPLOS_WORK   download directory (default: /usr/local/share/soplos-slackware)
#   SOPLOS_BIN    path of the command (default: /usr/local/bin/soplos-menu)
#   SOPLOS_DESKTOP path of the menu entry (default: /usr/share/applications/soplos-slackware.desktop)
#
# The menu texts exist in English and Spanish. The scripts the menu launches
# print their messages in English.

OWNER_REPO=SoplosLinux/slackware
REF=${SOPLOS_REF:-main}
URL=${SOPLOS_URL:-https://github.com/$OWNER_REPO/archive/refs/heads/$REF.tar.gz}
WORK=${SOPLOS_WORK:-/usr/local/share/soplos-slackware}
BIN=${SOPLOS_BIN:-/usr/local/bin/soplos-menu}
DESKTOP=${SOPLOS_DESKTOP:-/usr/share/applications/soplos-slackware.desktop}
LOCAL=${SOPLOS_LOCAL:-}
TTY=${SOPLOS_TTY:-/dev/tty}
REPO=
REL=
LC_MENU=${SOPLOS_LANG:-}

# ---------------------------------------------------------------- texts
# T_en and T_es hold the same keys.
declare -A T_en T_es
tr_add() { T_en[$1]=$2; T_es[$1]=$3; }

# t KEY  prints the text in the chosen language; \n becomes a line break
t() {
  if [ "$LC_MENU" = "es" ]; then echo -e "${T_es[$1]:-${T_en[$1]}}"; else echo -e "${T_en[$1]}"; fi
}

tr_add err_root "run this menu as root." "ejecuta este menú como root."
tr_add err_tool "neither curl nor wget is installed." "no hay ni curl ni wget instalado."
tr_add err_dl "could not download" "no se pudo descargar"
tr_add err_unpack "could not unpack the archive." "no se pudo descomprimir el archivo."
tr_add err_repo "the downloaded archive does not look like the Soplos repository." "el archivo descargado no parece el repositorio de Soplos."
tr_add downloading "Downloading the scripts from GitHub..." "Descargando los scripts de GitHub..."
tr_add press_enter "Press Enter to return to the menu. " "Pulsa Intro para volver al menú. "
tr_add continue_q "Continue? [y/N] " "¿Continuar? [s/N] "
tr_add option_q "Option: " "Opción: "
tr_add yes "Yes" "Sí"
tr_add no "No" "No"
tr_add ok "OK" "Aceptar"
tr_add back "Back" "Atrás"
tr_add unknown "unknown" "desconocida"
tr_add unknown_opt "Unknown option:" "Opción desconocida:"

tr_add m_text "Slackware" "Slackware"
tr_add m_hint "on a new install, go from 1 to 6" "en una instalación nueva, de la 1 a la 6"
tr_add m1 "Clean Plasma: remove what is not needed" "Limpiar Plasma: quitar lo que no hace falta"
tr_add m2 "First steps: runlevel, language, resolution, shortcuts" "Primeros pasos: nivel de arranque, idioma, resolución, atajos"
tr_add mP "Packages (slackpkg): mirror, update, upgrade, install-new" "Paquetes (slackpkg): mirror, update, upgrade, install-new"
tr_add mU "Users: list, create, sudo, delete" "Usuarios: listar, crear, sudo, borrar"
tr_add m3 "Install software: sbopkg, Plymouth, VMware tools, Flatpak, Discover" "Instalar software: sbopkg, Plymouth, VMware tools, Flatpak, Discover"
tr_add m4 "Plymouth boot splash" "Splash de arranque Plymouth"
tr_add m5 "GRUB menu and kernel-update hook" "Menú de GRUB y hook de actualización del kernel"
tr_add m6 "Find library packages nobody uses (report only)" "Buscar paquetes de librerías que nadie usa (solo informe)"
tr_add m7 "Build kernel 6.8.9 (Slackware 15)" "Compilar el kernel 6.8.9 (Slackware 15)"
tr_add m8 "Read the Plymouth tutorial" "Leer el tutorial de Plymouth"
tr_add m9 "Download the latest scripts again" "Descargar de nuevo los últimos scripts"
tr_add mD "Diagnose Plasma: missing libraries and QML modules" "Diagnosticar Plasma: librerías y módulos QML que faltan"
tr_add mV "Change Slackware version (15 / 16)" "Cambiar versión de Slackware (15 / 16)"
tr_add mL "Change the language" "Cambiar el idioma"
tr_add mq "Quit" "Salir"

tr_add v_title "Slackware version" "Versión de Slackware"
tr_add v_text "Select the Slackware branch to target for mirrors and packages:" "Selecciona la rama de Slackware para los mirrors y paquetes:"
tr_add v1 "Slackware 16.0 / -current (modern, Wayland)" "Slackware 16.0 / -current (moderna, Wayland)"
tr_add v2 "Slackware 15.0 (stable)" "Slackware 15.0 (estable)"
tr_add v_set16 "Slackware version set to 16 (-current)." "Versión de Slackware establecida a 16 (-current)."
tr_add v_set15 "Slackware version set to 15.0 (stable)." "Versión de Slackware establecida a 15.0 (estable)."

tr_add c_title "Clean Plasma" "Limpiar Plasma"
tr_add c_text "Remove what a normal Plasma desktop does not need" "Quitar lo que un escritorio Plasma normal no necesita"
tr_add c1 "Preview what would be removed" "Ver qué se quitaría (simulación)"
tr_add c2 "Preview, including the optional sections" "Ver qué se quitaría, con las secciones opcionales"
tr_add c3 "Remove the unneeded packages" "Quitar los paquetes sobrantes"
tr_add c4 "Remove them, including the optional sections" "Quitarlos, con las secciones opcionales"
tr_add c5 "List the sections" "Listar las secciones"
tr_add c6 "Undo: bring back what a section removed" "Deshacer: recuperar lo que quitó una sección"
tr_add c6_ask "Section to bring back (names below, or all): " "Sección que recuperar (nombres abajo, o all): "

tr_add f_title "First steps" "Primeros pasos"
tr_add f_text "Usual steps after installing Slackware" "Pasos habituales tras instalar Slackware"
tr_add f1 "Boot into the graphical login (runlevel 4)" "Arrancar en el login gráfico (nivel 4)"
tr_add f4 "Set the system language" "Establecer el idioma del sistema"
tr_add f8 "Set keyboard layout (Console and Wayland/X11)" "Establecer distribución del teclado (Consola y Wayland/X11)"
tr_add f5 "Force a screen resolution for X11" "Forzar una resolución de pantalla en X11"
tr_add f6 "Rename the user folders to Spanish" "Renombrar las carpetas de usuario al español"
tr_add f7 "Reset keyboard shortcuts (if Super or Alt+Tab do nothing)" "Restablecer los atajos de teclado (si Super o Alt+Tab no hacen nada)"
tr_add p_title "Packages (slackpkg)" "Paquetes (slackpkg)"
tr_add p_text "Each step is separate. The usual order is 1, 2, 3, 4." "Cada paso es independiente. El orden habitual es 1, 2, 3, 4."
tr_add p1 "Choose the mirror (changes nothing else)" "Elegir el mirror (no cambia nada más)"
tr_add p2 "Update: refresh the package lists (upgrades nothing)" "Update: actualizar las listas de paquetes (no actualiza nada)"
tr_add p3 "Upgrade: upgrade all installed packages (slow)" "Upgrade: actualizar todos los paquetes instalados (lento)"
tr_add p4 "Install-new: install packages added to Slackware" "Install-new: instalar los paquetes nuevos de Slackware"
tr_add p5 "Show the mirror in use" "Mostrar el mirror en uso"
tr_add p3_confirm "Upgrade every installed package with slackpkg?\n\nThis is the slow one: it can download several GB and take hours. It does not bring back packages you removed." "¿Actualizar todos los paquetes instalados con slackpkg?\n\nEs la parte lenta: puede descargar varios GB y tardar horas. No recupera los paquetes que hayas quitado."
tr_add p4_confirm "Install the packages added to Slackware since the last update?\n\nPackages removed by the debloat can come back if Slackware lists them as new. Preview with the Clean Plasma option afterwards." "¿Instalar los paquetes añadidos a Slackware desde la última actualización?\n\nLos paquetes que quitó el debloat pueden volver si Slackware los marca como nuevos. Después puedes volver a pasar Limpiar Plasma."
tr_add u_title "Users" "Usuarios"
tr_add u_text "Manage the users of this system" "Gestionar los usuarios de este sistema"
tr_add u1 "List the users" "Listar los usuarios"
tr_add u2 "Create a user" "Crear un usuario"
tr_add u3 "Give sudo to a user (group, sudoers, PATH)" "Dar sudo a un usuario (grupo, sudoers, PATH)"
tr_add u4 "Take sudo from a user" "Quitar el sudo a un usuario"
tr_add u5 "Delete a user" "Borrar un usuario"
tr_add u5_confirm "Delete a user?\n\nYou will be asked which one and to type the name again. root, system users, a logged-in user and the only regular user are refused. The home folder is deleted only if you say so." "¿Borrar un usuario?\n\nSe te preguntará cuál y tendrás que escribir el nombre otra vez. Se rechaza root, los usuarios del sistema, uno con sesión abierta y el único usuario normal. La carpeta personal solo se borra si lo dices."
tr_add mir_title "Slackpkg mirror" "Mirror de slackpkg"
tr_add mir_text "Choose the mirror. Then run Update (option 2) to read its package lists." "Elige el mirror. Después ejecuta Update (opción 2) para leer sus listas de paquetes."
tr_add mir_keep "Keep the mirror already set" "Mantener el mirror que ya hay"
tr_add mir_official "Official (mirrors.slackware.com), finds a nearby mirror: recommended" "Oficial (mirrors.slackware.com), busca un mirror cercano: recomendado"
tr_add mir_country "Pick a mirror by country (all the ones slackpkg knows)" "Elegir un mirror por país (todos los que conoce slackpkg)"
tr_add mir_custom "Type an address" "Escribir una dirección"
tr_add mir_country_text "Country" "País"
tr_add mir_pick_text "Mirrors in" "Mirrors en"
tr_add mir_url_ask "Address of the mirror (https://...): " "Dirección del mirror (https://...): "
tr_add mir_nolist "No list of mirrors was found on this system. Use the official one or type an address." "No se encontró ninguna lista de mirrors en este sistema. Usa el oficial o escribe una dirección."
tr_add m7_only15 "This build is only for Slackware 15." "Esta compilación es solo para Slackware 15."
tr_add s_title "Install software" "Instalar software"
tr_add s_text "Things Slackware does not ship" "Lo que Slackware no incluye"
tr_add s1 "sbopkg (SlackBuilds.org installer)" "sbopkg (instalador de SlackBuilds.org)"
tr_add s2 "Plymouth (build the package, then use the Plymouth option)" "Plymouth (compila el paquete; luego usa la opción de Plymouth)"
tr_add s3 "open-vm-tools (VMware guest: clipboard, resize)" "open-vm-tools (invitado VMware: portapapeles, redimensionado)"
tr_add s4 "Flatpak and the Flathub repository" "Flatpak y el repositorio Flathub"
tr_add s5 "KDE Discover (installs Flatpak too)" "KDE Discover (instala también Flatpak)"
tr_add s2_confirm "Build and install Plymouth from SlackBuilds.org?\n\nIt compiles the package and can take several minutes." "¿Compilar e instalar Plymouth desde SlackBuilds.org?\n\nCompila el paquete y puede tardar varios minutos."
tr_add s3_confirm "Build and install open-vm-tools from SlackBuilds.org?" "¿Compilar e instalar open-vm-tools desde SlackBuilds.org?"
tr_add s4_confirm "Install Flatpak from AlienBOB's packages and add Flathub?" "¿Instalar Flatpak desde los paquetes de AlienBOB y añadir Flathub?"
tr_add s5_confirm "Install KDE Discover and Flatpak from AlienBOB's packages?\n\nThey were built in May and June 2026 and may not match a newer -current." "¿Instalar KDE Discover y Flatpak desde los paquetes de AlienBOB?\n\nSe compilaron en mayo y junio de 2026 y pueden no encajar con un -current más nuevo."

tr_add g_title "GRUB" "GRUB"
tr_add g_text "Boot menu" "Menú de arranque"
tr_add g1 "Regenerate the GRUB menu now" "Regenerar el menú de GRUB ahora"
tr_add g2 "Install the hook that regenerates it on kernel updates (Slackware 16)" "Instalar el hook que lo regenera al actualizar el kernel (Slackware 16)"
tr_add g_nohook "This system has no /etc/geninitrd.d, which only Slackware 16 provides. Use the first option after installing a kernel." "Este sistema no tiene /etc/geninitrd.d, que solo existe en Slackware 16. Usa la primera opción después de instalar un kernel."
tr_add g_confirm "Install /etc/geninitrd.d/post-install/grub-update.sh?\n\nIt regenerates the GRUB menu every time a kernel is installed." "¿Instalar /etc/geninitrd.d/post-install/grub-update.sh?\n\nRegenera el menú de GRUB cada vez que se instala un kernel."
tr_add g_done "Hook installed." "Hook instalado."

tr_add p_noversion "Could not detect the Slackware version from /etc/slackware-version. This installer exists for Slackware 15 and 16." "No se pudo detectar la versión de Slackware en /etc/slackware-version. Este instalador existe para Slackware 15 y 16."
tr_add p_confirm "Install the Plymouth splash for Slackware %s?\n\nIt patches /etc/rc.d/rc.S and rc.6 and edits the GRUB configuration. Each file is saved as FILE.pre-plymouth. Take a snapshot or a backup first." "¿Instalar el splash de Plymouth para Slackware %s?\n\nParchea /etc/rc.d/rc.S y rc.6 y edita la configuración de GRUB. Cada archivo se guarda como ARCHIVO.pre-plymouth. Haz antes una instantánea o una copia de seguridad."
tr_add orphans_done "Open /root/orphans.txt to read the report." "Abre /root/orphans.txt para leer el informe."
tr_add k_confirm "This builds kernel 6.8.9 from kernel.org. It takes a long time, opens make menuconfig and uses /dev/sda3 as the root device.\n\nThe script was written for Slackware 15." "Esto compila el kernel 6.8.9 desde kernel.org. Tarda mucho, abre make menuconfig y usa /dev/sda3 como dispositivo raíz.\n\nEl script se escribió para Slackware 15."
tr_add refreshed "Scripts downloaded again." "Scripts descargados de nuevo."

# ---------------------------------------------------------------- helpers

die() { echo "Error: $*" >&2; exit 1; }

# Worked out once at start: asking [ -t 1 ] each time is false inside $(...),
# where the menus run, and the lists would never use dialog.
HAVE_DIALOG=0
command -v dialog > /dev/null 2>&1 && [ -t 0 ] && [ -t 2 ] && HAVE_DIALOG=1
use_dialog() {
  [ "$HAVE_DIALOG" -eq 1 ]
}

pick_language() {
  local c
  if use_dialog; then
    c=$(dialog --clear --no-cancel --title "Language / Idioma" --menu "" 12 50 2 en "English" es "Español" 3>&1 1>&2 2>&3) || c=en
  else
    {
      echo
      echo "Language / Idioma"
      echo "  1) English"
      echo "  2) Español"
    } >&2
    read -r -p "1/2: " c <"$TTY"
    case "$c" in 2|es|ES) c=es ;; *) c=en ;; esac
  fi
  LC_MENU=$c
}

download() {
  if command -v curl > /dev/null 2>&1; then
    curl -fsSL -o "$2" "$1"
  elif command -v wget > /dev/null 2>&1; then
    wget -q -O "$2" "$1"
  else
    die "$(t err_tool)"
  fi
}

# Fetch the repository once; "refresh" downloads it again
fetch_repo() {
  if [ -n "$LOCAL" ]; then
    REPO=$LOCAL
  else
    REPO=$WORK/repo
    if [ "${1:-}" = "refresh" ] || [ ! -f "$REPO/scripts/setup.debloat" ]; then
      t downloading
      # only ever delete a folder that is ours
      case "$WORK" in
        */soplos-slackware) ;;
        *) die "refusing to delete $WORK: its name must end in /soplos-slackware" ;;
      esac
      # Download and unpack beside the current copy and swap at the end, so a
      # failed download (no network) leaves the working copy untouched.
      local fresh
      mkdir -p "$WORK"
      fresh=$(mktemp -d "$WORK/fresh.XXXXXX") || die "mktemp failed."
      mkdir -p "$fresh/repo"
      download "$URL" "$fresh/repo.tar.gz" || { rm -rf "$fresh"; die "$(t err_dl) $URL"; }
      # -m: keep the current time, the clock of a VM is often behind the archive
      tar -xzmf "$fresh/repo.tar.gz" -C "$fresh/repo" --strip-components=1 --no-same-owner || { rm -rf "$fresh"; die "$(t err_unpack)"; }
      [ -f "$fresh/repo/scripts/setup.debloat" ] || { rm -rf "$fresh"; die "$(t err_repo)"; }
      rm -rf "$REPO"
      mv "$fresh/repo" "$REPO"
      rm -rf "$fresh"
    fi
  fi
  [ -f "$REPO/scripts/setup.debloat" ] || die "$(t err_repo)"
}

# Slackware major version: 15, 16, or empty if it cannot be told
release() {
  if [ -n "${SOPLOS_SLACK_VERSION:-}" ]; then
    echo "$SOPLOS_SLACK_VERSION"
    return
  fi
  local ver
  ver=$(cat /etc/slackware-version 2> /dev/null || true)
  if echo "$ver" | grep -Eq '(\+|current)'; then
    echo 16
    return
  fi
  echo "$ver" | sed -n 's/^Slackware \([0-9][0-9]*\)\..*/\1/p' | head -n 1
}

pick_slackware_version() {
  local c
  c=$(choose "$(t v_title)" "$(t v_text)" \
    1 "$(t v1)" \
    2 "$(t v2)" \
    0 "$(t back)")
  clear
  case "$c" in
    1)
      REL=16
      export SOPLOS_SLACK_VERSION=16
      say v_set16
      ;;
    2)
      REL=15
      export SOPLOS_SLACK_VERSION=15
      say v_set15
      ;;
    *) return ;;
  esac
}

pause() {
  echo
  read -r -p "$(t press_enter)" _ <"$TTY"
}

say() {
  if use_dialog; then
    dialog --clear --ok-label "$(t ok)" --msgbox "$(t "$1")" 12 70
  else
    echo; t "$1"; pause
  fi
}

# confirm KEY [ARG]  asks the question stored under KEY, with %s replaced by ARG
confirm() {
  local text answer
  text=$(t "$1")
  text=${text//%s/${2:-}}
  if use_dialog; then
    dialog --clear --yes-label "$(t yes)" --no-label "$(t no)" --yesno "$text" 14 70
    return $?
  fi
  echo; echo "$text"
  read -r -p "$(t continue_q)" answer <"$TTY"
  case "$answer" in y|Y|s|S) return 0 ;; *) return 1 ;; esac
}

# choose TITLE TEXT TAG DESCRIPTION [TAG DESCRIPTION ...]  prints the chosen tag
choose() {
  local title=$1 text=$2 choice i
  shift 2
  local items=("$@")
  if use_dialog; then
    choice=$(dialog --clear --no-cancel --ok-label "$(t ok)" --title "$title" --menu "$text" 0 0 0 "${items[@]}" 3>&1 1>&2 2>&3)
    if [ $? -eq 0 ] && [ -n "$choice" ]; then
      echo "$choice"
      return
    fi
  fi
  {
    echo
    echo "$title - $text"
    for ((i = 0; i < ${#items[@]}; i += 2)); do
      printf '  %s) %s\n' "${items[i]}" "${items[i+1]}"
    done
  } >&2
  read -r -p "$(t option_q)" choice <"$TTY"
  echo "$choice"
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
    c=$(choose "$(t c_title)" "$(t c_text)" \
      1 "$(t c1)" 2 "$(t c2)" 3 "$(t c3)" 4 "$(t c4)" 5 "$(t c5)" 6 "$(t c6)" 0 "$(t back)")
    clear
    case "$c" in
      6)
        echo "  $(grep -ho '^\[[a-z0-9-]*\]' /var/log/setup.debloat.log 2> /dev/null | tr -d '[]' | sort -u | tr '\n' ' ')"
        read -r -p "$(t c6_ask)" sec <"$TTY"
        [ -n "$sec" ] && run scripts/setup.debloat -u "$sec" ;;
      1) bash "$REPO/scripts/setup.debloat" -n -v | ${PAGER:-less}; pause ;;
      2) bash "$REPO/scripts/setup.debloat" -n -v -a | ${PAGER:-less}; pause ;;
      3) run scripts/setup.debloat ;;
      4) run scripts/setup.debloat -a ;;
      5) bash "$REPO/scripts/setup.debloat" -l | ${PAGER:-less}; pause ;;
      0|"") return ;;
    esac
  done
}

# Asks for a country and then for one of its mirrors, both read from the list
# that slackpkg ships (setup.firststeps mirrorlist). Leaves the address in
# PICKED, empty if the user goes back. It is not called inside $(...) because
# clear and the dialog boxes must reach the screen.
PICKED=

# Which tree the mirrors below are for, the same one setup.firststeps uses
mirror_tree() {
  if [ "$REL" = "15" ]; then
    echo "Slackware 15.0 (slackware64-15.0)"
  else
    echo "Slackware ${REL:-current} (slackware64-current)"
  fi
}

pick_mirror_by_country() {
  local line i c urls=() items=() names=() counts=() n
  PICKED=
  while IFS=$'\t' read -r c n; do
    [ -n "$c" ] || continue
    names+=("$c"); counts+=("$n")
  done < <(bash "$REPO/scripts/setup.firststeps" mirrorlist 2> /dev/null)
  if [ "${#names[@]}" -eq 0 ]; then
    say mir_nolist
    return
  fi
  for ((i = 0; i < ${#names[@]}; i++)); do
    items+=("$((i + 1))" "${names[i]} [${counts[i]}]")
  done
  c=$(choose "$(t mir_title) - $(mirror_tree)" "$(t mir_country_text)" "${items[@]}" 0 "$(t back)")
  clear
  case "$c" in
    ''|0|*[!0-9]*) return ;;
  esac
  [ "$c" -le "${#names[@]}" ] || return
  c=${names[c - 1]}
  while IFS= read -r line; do
    [ -n "$line" ] && urls+=("$line")
  done < <(bash "$REPO/scripts/setup.firststeps" mirrorlist "$c" 2> /dev/null)
  items=()
  for ((i = 0; i < ${#urls[@]}; i++)); do
    items+=("$((i + 1))" "${urls[i]}")
  done
  c=$(choose "$(t mir_title) - $(mirror_tree)" "$(t mir_pick_text) $c" "${items[@]}" 0 "$(t back)")
  clear
  case "$c" in
    ''|0|*[!0-9]*) return ;;
  esac
  [ "$c" -le "${#urls[@]}" ] || return
  PICKED=${urls[c - 1]}
}

# Asks which slackpkg mirror to use and sets it
choose_mirror() {
  local m base
  m=$(choose "$(t mir_title) - $(mirror_tree)" "$(t mir_text)" \
    1 "$(t mir_official)" \
    2 "$(t mir_country)" \
    3 "$(t mir_custom)" \
    4 "$(t mir_keep)" \
    0 "$(t back)")
  clear
  case "$m" in
    1) base=https://mirrors.slackware.com/slackware ;;
    2) pick_mirror_by_country; base=$PICKED; [ -n "$base" ] || return ;;
    3) read -r -p "$(t mir_url_ask)" base <"$TTY"; [ -n "$base" ] || return ;;
    4) base= ;;
    *) return ;;
  esac
  run scripts/setup.firststeps mirror $base
}

menu_firststeps() {
  local c
  while true; do
    c=$(choose "$(t f_title)" "$(t f_text)" \
      1 "$(t f1)" 2 "$(t f4)" 3 "$(t f8)" 4 "$(t f5)" 5 "$(t f6)" 6 "$(t f7)" 0 "$(t back)")
    clear
    case "$c" in
      1) run scripts/setup.firststeps runlevel4 ;;
      2) run scripts/setup.firststeps lang ;;
      3) run scripts/setup.firststeps keyboard ;;
      4) run scripts/setup.firststeps resolution ;;
      5) run scripts/setup.firststeps userdirs ;;
      6) run scripts/setup.firststeps shortcuts ;;
      0|"") return ;;
    esac
  done
}

menu_packages() {
  local c
  while true; do
    c=$(choose "$(t p_title)" "$(t p_text)" \
      1 "$(t p1)" 2 "$(t p2)" 3 "$(t p3)" 4 "$(t p4)" 5 "$(t p5)" 0 "$(t back)")
    clear
    case "$c" in
      1) choose_mirror ;;
      2) run scripts/setup.firststeps update ;;
      3) confirm p3_confirm && run scripts/setup.firststeps upgrade ;;
      4) confirm p4_confirm && run scripts/setup.firststeps installnew ;;
      5) run scripts/setup.firststeps mirror ;;
      0|"") return ;;
    esac
  done
}

menu_users() {
  local c
  while true; do
    c=$(choose "$(t u_title)" "$(t u_text)" \
      1 "$(t u1)" 2 "$(t u2)" 3 "$(t u3)" 4 "$(t u4)" 5 "$(t u5)" 0 "$(t back)")
    clear
    case "$c" in
      1) run scripts/setup.firststeps users ;;
      2) run scripts/setup.firststeps adduser ;;
      3) run scripts/setup.firststeps sudo ;;
      4) run scripts/setup.firststeps unsudo ;;
      5) confirm u5_confirm && run scripts/setup.firststeps deluser ;;
      0|"") return ;;
    esac
  done
}

menu_software() {
  local c
  while true; do
    c=$(choose "$(t s_title)" "$(t s_text)" \
      1 "$(t s1)" 2 "$(t s2)" 3 "$(t s3)" 4 "$(t s4)" 5 "$(t s5)" 0 "$(t back)")
    clear
    case "$c" in
      1) run scripts/setup.software sbopkg ;;
      2) confirm s2_confirm && run scripts/setup.software plymouth ;;
      3) confirm s3_confirm && run scripts/setup.software open-vm-tools ;;
      4) confirm s4_confirm && run scripts/setup.software flatpak ;;
      5) confirm s5_confirm && run scripts/setup.software discover ;;
      0|"") return ;;
    esac
  done
}

menu_grub() {
  local c
  while true; do
    c=$(choose "$(t g_title)" "$(t g_text)" 1 "$(t g1)" 2 "$(t g2)" 0 "$(t back)")
    clear
    case "$c" in
      1) run 16/etc/geninitrd.d/post-install/grub-update.sh ;;
      2)
        if [ ! -d /etc/geninitrd.d ]; then
          say g_nohook
        elif confirm g_confirm; then
          mkdir -p /etc/geninitrd.d/post-install
          cp "$REPO/16/etc/geninitrd.d/post-install/grub-update.sh" /etc/geninitrd.d/post-install/grub-update.sh
          chmod 755 /etc/geninitrd.d/post-install/grub-update.sh
          say g_done
        fi
        ;;
      0|"") return ;;
    esac
  done
}

run_plymouth() {
  case "$REL" in
    15|16) ;;
    *) say p_noversion; return ;;
  esac
  confirm p_confirm "$REL" || return
  run scripts/setup.plymouth.installer
}

# Creates the command and the menu entry that start the downloaded menu, and
# says what it did. Nothing is printed when both are already up to date.
install_launcher() {
  [ -n "$LOCAL" ] && return
  local wrapper entry
  wrapper=$(printf '#!/bin/sh\nexec bash "%s/repo/soplos-menu.sh" "$@"\n' "$WORK")
  entry=$(cat << EOF
[Desktop Entry]
Type=Application
Name=Soplos Slackware Tools
Name[es]=Herramientas Soplos para Slackware
Comment=Clean Plasma, first steps, Plymouth, Flatpak and more
Comment[es]=Limpiar Plasma, primeros pasos, Plymouth, Flatpak y más
Exec=su -l -c $BIN
Icon=preferences-system
Terminal=true
Categories=System;
EOF
)
  local changed=0
  if [ "$(cat "$BIN" 2> /dev/null)" != "$wrapper" ]; then
    mkdir -p "$(dirname "$BIN")" && printf '%s\n' "$wrapper" > "$BIN" && chmod 755 "$BIN" || { echo "Error: could not create $BIN" >&2; return 1; }
    changed=1
  fi
  if [ "$(cat "$DESKTOP" 2> /dev/null)" != "$entry" ]; then
    mkdir -p "$(dirname "$DESKTOP")" && printf '%s\n' "$entry" > "$DESKTOP" && chmod 644 "$DESKTOP" || { echo "Error: could not create $DESKTOP" >&2; return 1; }
    changed=1
  fi
  if [ "$changed" -eq 1 ]; then
    echo
    echo "Installed:"
    echo "  command:    $BIN"
    echo "  menu entry: $DESKTOP"
    echo "  scripts:    $WORK"
    echo "Open the application launcher and search for \"Soplos\", or run soplos-menu as root."
    echo "If the entry does not show up yet, run kbuildsycoca6 as your user, or log in again."
    echo
    read -r -p "Press Enter to continue. " _ <"$TTY"
  fi
}

# Removes the command, the menu entry and the downloaded copy
uninstall() {
  case "$WORK" in
    */soplos-slackware) ;;
    *) die "refusing to delete $WORK: its name must end in /soplos-slackware" ;;
  esac
  rm -f "$BIN" "$DESKTOP"
  rm -rf "$WORK"
  echo "Removed $BIN, $DESKTOP and $WORK"
  exit 0
}

# Start again from the downloaded copy of this menu
restart_from_repo() {
  exec env SOPLOS_REEXEC=1 SOPLOS_WORK="$WORK" SOPLOS_LANG="$LC_MENU" SOPLOS_SLACK_VERSION="$REL" bash "$REPO/soplos-menu.sh"
}

main() {
  [ "${1:-}" = "--uninstall" ] && uninstall
  fetch_repo
  # An old launcher, for example one saved in Downloads, runs the newest menu
  if [ -z "$LOCAL" ] && [ -z "${SOPLOS_REEXEC:-}" ] && [ -f "$REPO/soplos-menu.sh" ] \
    && ! cmp -s "$REPO/soplos-menu.sh" "$0"; then
    restart_from_repo
  fi
  install_launcher
  REL=$(release)
  local c rel_text kernel_item=()
  # Entries 1 to 6 follow the order of a fresh install; the rest are tools
  # for later, so the menu reads top to bottom as a recipe.
  while true; do
    export SOPLOS_SLACK_VERSION="$REL"
    kernel_item=()
    # The kernel 6.8.9 build was written for Slackware 15: offered only there
    [ "$REL" = "15" ] && kernel_item=(K "$(t m7)")
    rel_text="$(t m_text) ${REL:-$(t unknown)} - $(t m_hint)"
    c=$(choose "Soplos Linux" "$rel_text" \
      1 "$(t m2)" 2 "$(t mP)" 3 "$(t m1)" 4 "$(t m3)" 5 "$(t m4)" 6 "$(t m5)" \
      7 "$(t mU)" 8 "$(t m6)" 9 "$(t mD)" \
      "${kernel_item[@]}" V "$(t mV)" T "$(t m8)" R "$(t m9)" L "$(t mL)" 0 "$(t mq)")
    clear
    case "$c" in
      1) menu_firststeps ;;
      2) menu_packages ;;
      3) menu_clean ;;
      4) menu_software ;;
      5) run_plymouth ;;
      6) menu_grub ;;
      7) menu_users ;;
      8) bash "$REPO/scripts/setup.orphans" -o /root/orphans.txt; t orphans_done; pause ;;
      9) run scripts/setup.diagnose ;;
      V|v) pick_slackware_version ;;
      K|k)
        if [ "$REL" != "15" ]; then say m7_only15
        elif confirm k_confirm; then run 15/scripts/setup.update.kernel-6.8.9s; fi
        ;;
      T|t)
        if [ "$LC_MENU" = "es" ]; then ${PAGER:-less} "$REPO/docs/plymouth-tutorial.es.txt"
        else ${PAGER:-less} "$REPO/docs/plymouth-tutorial.en.txt"; fi
        ;;
      R|r) fetch_repo refresh; say refreshed; [ -z "$LOCAL" ] && restart_from_repo ;;
      L|l) pick_language ;;
      0|"") break ;;
      *) echo "$(t unknown_opt) $c" ;;
    esac
  done
  clear
}

[ "$LC_MENU" = "es" ] || LC_MENU=en
[ "$(id -u)" -eq 0 ] || die "$(t err_root)"
# su without a dash leaves the sbin folders out of PATH; the scripts inherit this
export PATH=$PATH:/usr/local/sbin:/usr/sbin:/sbin
export SOPLOS_LANG=$LC_MENU
[ -n "${REL:-}" ] && export SOPLOS_SLACK_VERSION="$REL"
main "$@"
