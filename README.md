# Slackware by Soplos Linux

Plymouth boot splash, KDE Plasma splash, setup scripts and artwork for
Slackware. The repository keeps one folder per Slackware release, plus the
parts shared by both.

## Quick start: the menu

Download one file and run it as root. It opens a menu and fetches from GitHub
only what each option needs:

```sh
wget https://github.com/SoplosLinux/slackware/raw/main/soplos-menu.sh
chmod +x soplos-menu.sh
./soplos-menu.sh
```

The first run installs it for good: the scripts go to
`/usr/local/share/soplos-slackware`, the command `soplos-menu` goes to
`/usr/local/bin` and an entry called "Soplos Slackware Tools" appears in the
application launcher (it asks for the root password in a terminal). The file you
downloaded is not needed any more: running it again opens the menu already
installed. Key `R` of the menu fetches the latest scripts from GitHub, and
`soplos-menu --uninstall` removes all of it.

The menu reads top to bottom as a recipe for a new install: entries 1 to 6 are
the usual order, the rest are tools for later. Entries with a list of steps open a
submenu.

| Key | Entry | What it does |
|---|---|---|
| 1 | First steps | Runlevel 4, language, keyboard layout (Console, Wayland and X11), screen resolution, Spanish user folders, reset of the keyboard shortcuts |
| 2 | Packages (slackpkg) | Each step on its own: choose the mirror (the official redirector, or any of the mirrors slackpkg knows, by country, or an address you type), update (lists only), upgrade-all, install-new |
| 3 | Clean Plasma | Preview or run the debloat, with or without the optional sections |
| 4 | Install software | sbopkg, Plymouth, open-vm-tools, Flatpak with Flathub, KDE Discover |
| 5 | Plymouth boot splash | Installer for Slackware 15 or 16, detected from `/etc/slackware-version` |
| 6 | GRUB | Regenerate the menu now, or install the hook that does it on kernel updates (Slackware 16) |
| 7 | Users | List, create, give or take sudo, delete a user (refuses root, system users, logged-in users and the only regular user) |
| 8 | Library scanner | Report of library packages nobody uses |
| 9 | Diagnose Plasma | Missing libraries and QML modules |
| V | Slackware version | Switch target branch between Slackware 15.0 and 16.0 / -current |
| K | Kernel 6.8.9 | The build from the video (shown on Slackware 15 only) |
| T | Tutorial | The Plymouth tutorial, in your language |
| R | Download again | The latest scripts from GitHub |
| L | Language | English or Spanish |

The menu starts in English. Press `L` (Change the language) to switch it to
Spanish, and again to go back. The scripts it launches print in English.

Nothing is installed until you choose an option and confirm it.

Flatpak and Discover come from AlienBOB's ready-made packages
(`slackware.uk/people/alien/slackbuilds`), checked against their MD5 file.
Plymouth and open-vm-tools are built from SlackBuilds.org with sbopkg; open-vm-tools
first builds its two dependencies, libmspack and libdnet, because sbopkg does not
resolve them by itself.

## Layout

| Folder | Contents |
|---|---|
| `15/` | Slackware 15.0: the Plymouth theme and `rc.plymouth` (shared by both releases), the patches for `rc.S` and `rc.6`, and the older setup scripts (kernel 6.8.9, GRUB update) |
| `16/` | Slackware 16 (-current): patches for `rc.S` and `rc.6` and a geninitrd hook that regenerates the GRUB menu on kernel installs. See `16/README.txt` |
| `soplos-menu.sh` | The menu described above |
| `scripts/` | Scripts valid for both releases: `setup.debloat` (clean Plasma install), `setup.orphans` (read-only library scanner), `setup.firststeps`, `setup.software` and `setup.plymouth.installer` |
| `data/` | `deps.tsv`, the map of which Slackware package needs which, used by the debloat |
| `tools/` | `gen-deps.py`, which rebuilds `data/deps.tsv` from a Slackware mirror |
| `plasma-splash/` | KDE Plasma look-and-feel splash screen (Qt5, not tested on Plasma 6) |
| `docs/` | Plymouth tutorial in English and Spanish, first steps, kernel build, SDDM |
| `artwork/` | Wallpapers (JPG), logos and a Plymouth screenshot |

## Clean Plasma install

Install Slackware normally, leaving the series E, F, K, T, TCL, XFCE and Y
unchecked, then run, as root:

```sh
./scripts/setup.debloat -n    # show what would be removed
./scripts/setup.debloat       # remove it, asking once
```

Optional sections (input methods, printing, documentation tools) are off by
default; see `./scripts/setup.debloat -l`. The development section removes
every package of the `d` series except the basic toolchain (gcc, g++, binutils,
make, bison, flex, m4, perl, python3, git, kernel headers, llvm, libtool) and
autoconf, automake and gettext-tools (27 MB), which the SlackBuilds built later
by the menu need (open-vm-tools runs `autoreconf`). cmake and meson are
removed.

It also removes Qt5 and the KDE 5 frameworks, which Plasma 6 does not use
(about 600 MB; only `pinentry-qt5`, `simplescreenrecorder` and a few demos stop
working), and hides the menu entries of demos and tools that live inside
libraries that cannot be removed (Qt Designer and Assistant, GTK Demo, Vulkan
Caps Viewer, Avahi browsers...). An upgrade of the package that owns an entry
puts it back; run the script again.

Run it, then log out of Plasma and back in. If Super or Alt+Tab do nothing
afterwards, use First steps, Reset keyboard shortcuts in the menu. This
happened once on a real system after the debloat ran inside a live Plasma
session: `kglobalshortcutsrc` had almost every shortcut set to `none`, and
moving it and `kwinrc` aside fixed it. The cause is not proven.

Everything it removes is written to `/var/log/setup.debloat.log`, and it can be
brought back by section: `setup.debloat -u qt5` (or `-u all`, add `-n` to
preview) reinstalls what that section removed with slackpkg, which only needs
`update` and `install`, never `upgrade-all`. The menu has the same option.

Slackware does not track dependencies, so the script does it itself. It reads
`data/deps.tsv` and keeps any package that an installed package that stays
still needs: for example `guile` because `make` links to it, or `gcc-gfortran`
because `openblas` does. The list of what was kept is printed before anything
is removed. The map does not see libraries loaded by name at run time, Python
modules or QML modules, so take a snapshot first. To rebuild the map for a newer
-current: `python3 tools/gen-deps.py` (downloads about 5 GB, streams, writes
nothing else to disk).

## Plymouth

Install Plymouth first (menu: Install software, Plymouth), then run
`./scripts/setup.plymouth.installer` as root from the repository, or use the
Plymouth entry of the menu. One installer serves both releases: it reads
`/etc/slackware-version` and applies the patches of `15/patches` or
`16/patches` to `rc.S` and `rc.6`. Nothing is replaced: the init scripts are
patched, `/etc/default/grub` gets `quiet splash` added, and on Slackware 15 the
initrd tree is kept (`CLEAR_TREE="0"` in `mkinitrd.conf`) and rebuilt with the
Plymouth binaries. If a patch no longer matches the installed script, the
installer stops before changing anything. Each file it changes is first saved
as `FILE.pre-plymouth`.

The manual procedure is described in the tutorial, available in
[English](docs/plymouth-tutorial.en.txt) and
[Spanish](docs/plymouth-tutorial.es.txt).

## License

This project is licensed under the GNU General Public License v3.0. See
[LICENSE](LICENSE).
