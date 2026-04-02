#include "fcntl.h"
#include "user.h"

int is_number(char *s) {
  if (*s == '\0')
    return 0;
  while (*s) {
    if (*s < '0' || *s > '9')
      return 0;
    s++;
  }
  return 1;
}

void head(int fd, int maxLines) {
  char buf[512];
  int n;
  int lines = 0;
  while ((n = read(fd, buf, 512)) > 0 && lines <= 10) {

    for (int i = 0; i < n; i++) {
      if (buf[i] == '\n') {
        lines++;
        if (lines == maxLines) {
          if (write(1, buf, i + 1) != i + 1) {
            printf(2, "head: writing error\n");
          }
          return;
        }
      }
    }
    if (write(1, buf, n) != n) {
      printf(2, "head: write error\n");
      return;
    }
  }
}

int main(int argc, char *argv[]) {
  char *filename = 0;
  int maxLines = 10;
  int fd;

  for (int i = 1; i < argc; i++) {
    if (strcmp(argv[i], "-h") == 0) {
      printf(2, "Usage: head -n <number of lines> <file>\n");
      exit();
    }
    if (strcmp(argv[i], "-n") == 0) {
      if (i + 1 >= argc || is_number(argv[i + 1]) == 0) {
        printf(2, "Invalid value for -n argument\n");
        exit();
      }
      maxLines = atoi(argv[i + 1]);
      i++;
      continue;
    }
    if (filename == 0) {
      filename = argv[i];
    } else {
      printf(2, "Usage: head [-n lines] [file]\n");
      exit();
    }
  }

  if (filename == 0) {
    fd = 0;
  } else {
    if ((fd = open(filename, O_RDONLY)) < 0) {
      printf(2, "head: cannot open %s\n", filename);
      exit();
    }
  }

  head(fd, maxLines);

  if (fd > 0) {
    close(fd);
  }

  exit();
}