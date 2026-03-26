#include "user.h"
#include "fcntl.h"

int main(int argc, char *argv[]) {

  if (argc < 3) {
    printf(1, "Usage: cp <source> <destination>\n");
    exit();
  }

  int fd_src = open(argv[1], O_RDONLY);
  if (fd_src < 0) {
    printf(1, "Incorrect file path\n");
    exit();
  }

  int fd_dest = open(argv[2], O_CREATE | O_RDWR);
  if (fd_dest < 0) {
    printf(1, "Incorrect destination file path\n");
    exit();
  }

  char *fileContent = malloc(512);

  read(fd_src, fileContent, 512);
  write(fd_dest, fileContent, 512);

  free(fileContent);
  close(fd_src);
  close(fd_dest);

  exit();
}