#include "types.h"
#include "fcntl.h"
#include "user.h"



int main(int argc, char *argv[]) {
  // wc [-l] [-w] [-c] [file...]
  int printLines = 0;
  int printWords = 0;
  int printChar = 0;
  int file_path_start_index = 0;

  for (int i = 1; i < argc; i++) {
    if (strcmp(argv[i], "-l") == 0) {
      printLines = 1;
      continue;
    }
    if (strcmp(argv[i], "-w") == 0) {
      printWords = 1;
      continue;
    }
    if (strcmp(argv[i], "-c") == 0) {
      printChar = 1;
      continue;
    }
    file_path_start_index = i;
  }
  if (printChar == 0 && printLines == 0 && printWords == 0) {
    printLines = 1;
    printWords = 1;
    printChar = 1;
  }
  int fd;
  int l = 0;
  int c = 0;
  int w = 0;
  int n;
  char buf[512];
  printf(1, "Filename L C W\n");
  while (file_path_start_index < argc) {
    if ((fd = open(argv[file_path_start_index], O_RDONLY)) < 0) {
      printf(2, "wc: file read error - %s\n", argv[file_path_start_index]);
      exit();
    }
    int word_start = 0;
    while ((n = read(fd, buf, 512)) > 0) {
      for (int i = 0; i < n; i++) {
        if (buf[i] == '\n') {
          l++;
          if (word_start == 1) {
            word_start = 0;
            w++;
          }
          continue;
        }
        if (buf[i] != ' ') {
          c++;
          word_start = 1;
          continue;
        }
        if (buf[i] == ' ' && word_start == 1) {
          word_start = 0;
          w++;
        }
      }
    }
    if (fd) {
      close(fd);
    }
    printf(1, "%s %d %d %d\n", argv[file_path_start_index], l, c, w);
    file_path_start_index++;
    l = c = w = 0;
  }
  exit();
}