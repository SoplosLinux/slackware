Slackware 16 (-current)

Status: written against the packages of Slackware-current of 26 October 2026
(sysvinit-scripts 16.0-10, mkinitrd 1.4.11-81). The patches were checked to
apply to those exact files, and the installer was tested in a fake root. It
has not been run on a real Slackware 16 yet.

Contents

  patches/rc.S.patch, patches/rc.6.patch
      The Plymouth hooks as patches against the Slackware 16 init scripts.
      On Slackware 15 these files were replaced as a whole; on 16 they change
      too often (seedrng, kexec, zram, ...), so they are patched instead.
      If a later sysvinit-scripts update changes the surrounding lines, the
      installer refuses to patch and changes nothing.

  etc/geninitrd.d/post-install/grub-update.sh
      Slackware runs the executable *.sh scripts of this directory after
      geninitrd installs a kernel or an initrd (the lilo package uses it too).
      This one regenerates the GRUB menu, which Slackware does not do on its
      own.

  scripts/setup.plymouth.installer
      Installs the theme, the service script and the patches, adds
      "quiet splash" to the GRUB command line and installs the hook. Every
      file it changes is first saved as FILE.pre-plymouth.

Differences from Slackware 15

  - geninitrd removes /boot/initrd-tree after generating the initrd
    (AUTO_REMOVE_INITRD_TREE=true in /etc/default/geninitrd). The 15 method
    of keeping that directory with the Plymouth binaries does not survive a
    kernel update. The 16 patches do not depend on it: they start Plymouth
    from rc.S, as the 15 files do.

  - /etc/default/grub is edited, not replaced, because Slackware 16 ships its
    own defaults (GRUB 2.16, Spleen font, GRUB_GFXMODE=0x0).

  - /etc/mkinitrd.conf and load_kernel_modules are not touched. On 15 the
    installer overwrote load_kernel_modules with an empty template, which
    removes the module loading of the initrd.

Pending

  - Start Plymouth from the initrd so the splash appears earlier. The 16
    geninitrd can use dracut (GENERATOR=dracut in /etc/default/geninitrd), and
    dracut has a plymouth module. Not tested.
  - Test everything on a real Slackware 16 VM, with a snapshot first.
