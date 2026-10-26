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

The menu offers: a preview of the debloat, the debloat itself, the library
scanner, the Plymouth installer for Slackware 15 or 16 (detected from
`/etc/slackware-version`), the GRUB menu regeneration and its kernel-update
hook, the kernel 6.8.9 build and the Plymouth tutorial. Nothing is installed
until you choose an option and confirm it.

## Layout

| Folder | Contents |
|---|---|
| `15/` | Slackware 15.0: Plymouth files at their install paths, and its setup scripts (Plymouth installer, kernel 6.8.9, Discover with Flatpak, GRUB update) |
| `16/` | Slackware 16 (-current): patches for `rc.S` and `rc.6`, a geninitrd hook that regenerates the GRUB menu on kernel installs, and its Plymouth installer. See `16/README.txt` |
| `soplos-menu.sh` | The menu described above |
| `scripts/` | Scripts valid for both releases: `setup.debloat` (clean Plasma install) and `setup.orphans` (read-only library scanner) |
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

Optional sections (build tools, input methods, printing) are off by default;
see `./scripts/setup.debloat -l`.

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
