#include "stat.h"
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
    close(fd_src);
    exit();
  }

  struct stat st;

  if ((fstat(fd_src, &st)) < 0) {
    printf(2, "cp: cannot stat %s\n", argv[1]);
    close(fd_src);
    exit();
  }

  if (st.type == T_DIR) {
    printf(2, "cp: %s is not a file\n", argv[1]);
    close(fd_src);
    exit();
  }

  int fd_dest = open(argv[2], O_WRONLY);
  if (fd_dest < 0) {
    printf(2, "cp: cannot create %s\n", argv[2]);
    exit();
  }

  char fileContent[512];

  int n;
  while ((n = read(fd_src, fileContent, 512)) > 0) {
    write(fd_dest, fileContent, n);
  }

  if (n < 0) {
    printf(2, "cp: read error\n");
    exit();
  }

  close(fd_src);
  close(fd_dest);

  exit();
}