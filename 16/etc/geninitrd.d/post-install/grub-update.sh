#!/bin/bash
# Regenerate the GRUB menu after geninitrd has installed a kernel or an initrd.
# Slackware runs the executable *.sh scripts of this directory after geninitrd
# (the lilo package uses the same mechanism). To disable this hook, make the
# file non-executable.
if [ -d /boot/grub ]; then
  if command -v grub-update > /dev/null 2>&1; then
    echo "Regenerating the GRUB menu:"
    grub-update
  elif command -v grub-mkconfig > /dev/null 2>&1; then
    echo "Regenerating the GRUB menu:"
    grub-mkconfig -o /boot/grub/grub.cfg
  fi
fi
