#include <stdlib.h>
#include <stdio.h>

int main(int argc, char* argv[]) {
  char passwd[] = ".bcvs/passwd";
  char file[] = ".bcvs//etc/passwd";

  FILE* src = fopen(passwd, "r");
  FILE* dst = fopen(file, "w");

  if (!src) {
    printf("Failed to open source file: %s\n", passwd);
  }
  if (!dst) {
    printf("Failed to open dest file %s\n", file);
  }
  return 0;
}
