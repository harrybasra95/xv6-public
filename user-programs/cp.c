#include "user.h"
#include "fcntl.h"

int main(int argc, char *argv[]) {

  if (argc < 3) {
    printf(2, "Usage: cp <source> <destination>\n");
    exit();
  }

  int fd_src = open(argv[1], O_RDONLY);
  if (fd_src < 0) {
    printf(2, "cp: cannot open %s\n", argv[1]);
    exit();
  }

  int fd_dest = open(argv[2], O_CREATE | O_RDWR);
  if (fd_dest < 0) {
    printf(2, "cp: cannot create %s\n", argv[2]);
    exit();
  }

  char *fileContent = malloc(512);

  int n;
  while ((n = read(fd_src, fileContent, 512)) > 0) {
    write(fd_dest, fileContent, n);
  }

  if (n < 0) {
    printf(2, "cp: read error\n");
    exit();
  }

  free(fileContent);
  close(fd_src);
  close(fd_dest);

  exit();
}