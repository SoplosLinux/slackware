# Slackware by Soplos Linux

Plymouth boot splash, KDE Plasma splash, setup scripts and artwork for
Slackware. The repository keeps one folder per Slackware release, plus the
parts shared by both.

## Quick start: the menu

Download one file and run it as root. It opens a menu and fetches from GitHub
only what each option needs:

```sh
wget https://raw.githubusercontent.com/SoplosLinux/slackware/main/soplos-menu.sh
bash soplos-menu.sh
```

The menu has these entries; the first four open a submenu:

| Entry | What it does |
|---|---|
| Clean Plasma | Preview or run the debloat, with or without the optional sections |
| First steps | Runlevel 4, mirror and updates, user with sudo, language, screen resolution, Spanish user folders |
| Install software | sbopkg, Plymouth, open-vm-tools, Flatpak with Flathub, KDE Discover |
| GRUB | Regenerate the menu now, or install the hook that does it on kernel updates (Slackware 16) |
| Plymouth boot splash | Installer for Slackware 15 or 16, detected from `/etc/slackware-version` |
| Library scanner | Report of library packages nobody uses |
| Kernel 6.8.9 | The build from the video (Slackware 15) |
| Tutorial | The Plymouth tutorial, in your language |

The menu starts in English. Press `L` (Change the language) to switch it to
Spanish, and again to go back. The scripts it launches print in English.

Nothing is installed until you choose an option and confirm it.

Flatpak and Discover come from AlienBOB's ready-made packages
(`slackware.uk/people/alien/slackbuilds`), checked against their MD5 file.
Plymouth and open-vm-tools are built from SlackBuilds.org with sbopkg.

## Layout

| Folder | Contents |
|---|---|
| `15/` | Slackware 15.0: Plymouth files at their install paths, and its setup scripts (Plymouth installer, kernel 6.8.9, GRUB update) |
| `16/` | Slackware 16 (-current): patches for `rc.S` and `rc.6`, a geninitrd hook that regenerates the GRUB menu on kernel installs, and its Plymouth installer. See `16/README.txt` |
| `soplos-menu.sh` | The menu described above |
| `scripts/` | Scripts valid for both releases: `setup.debloat` (clean Plasma install), `setup.orphans` (read-only library scanner), `setup.firststeps` and `setup.software` |
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
make, bison, flex, m4, perl, python3, git, kernel headers, llvm, libtool).

It also removes Qt5 and the KDE 5 frameworks, which Plasma 6 does not use
(about 600 MB; only `pinentry-qt5`, `simplescreenrecorder` and a few demos stop
working), and hides the menu entries of demos and tools that live inside
libraries that cannot be removed (Qt Designer and Assistant, GTK Demo, Vulkan
Caps Viewer, Avahi browsers...). An upgrade of the package that owns an entry
puts it back; run the script again.

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

Slackware 15: run `15/scripts/setup.plymouth.installer` as root. It installs
sbopkg, Plymouth and Dracut, then copies the files from `15/plymouth/` and
rebuilds the initrd and the GRUB configuration. Each replaced file is backed
up with a `.back` suffix.

Slackware 16: install Plymouth first, then run
`./16/scripts/setup.plymouth.installer` from a clone of this repository.

The manual procedure is described in the tutorial, available in
[English](docs/plymouth-tutorial.en.txt) and
[Spanish](docs/plymouth-tutorial.es.txt).

## License

This project is licensed under the GNU General Public License v3.0. See
[LICENSE](LICENSE).
