#!/bin/bash
chown root /etc/sudoers
chmod 440 /etc/sudoers

echo "Backing up sudoers file to /etc/sudoers.bak"
cp /etc/sudoers /etc/sudoers.bak
cat /etc/sudoers | sed '/^%student ALL=NOPASSWD: \/bin\/sh$/d' > /etc/temp_sudoers

mv /etc/temp_sudoers /etc/sudoers

echo "Check that the sudoers file is what you expect"
