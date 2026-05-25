# Phase 1: Detailed User-Space & C Mastery Roadmap

## Sub-Phase 1A: Strings, Pointers, and Standard Input

**Core Concepts:** Pointer arithmetic, strings as null-terminated `char` arrays, parsing command-line arguments (`argc`/`argv`), reading from standard input (file descriptor 0).

### Program 1: `echo` (Enhanced)

- **Goal:** Learn how to iterate over `argv` arrays and manipulate string pointers.
- **Usage:** `echo [-n] [-r] [-u] [strings...]`
- **Flags:**
     - `-n`: Do not print the trailing newline.
     - `-r`: Reverse the entire output string before printing (requires manipulating pointers from the end of the string to the beginning).
     - `-u`: Convert all lowercase letters to uppercase (you must write the ASCII math yourself; no `toupper()` exists).

### Program 2: `calc`

- **Goal:** Learn to parse strings into integers using the provided `atoi` in `ulib.c`, and handle basic logic.
- **Usage:** `calc <num1> <operator> <num2>`
- **Operators:** `+`, `-`, `x` (use 'x' instead of '\*' to avoid shell expansion), `/`.
- **Constraint:** You must manually check if the user provided valid numbers and handle division by zero gracefully without crashing.

### Program 3: `censor`

- **Goal:** Master `read()` from standard input (fd 0), character-by-character or chunk-by-chunk processing, and string matching.
- **Usage:** `censor <word>`
- **Behavior:** Read text from standard input. Whenever the `<word>` appears, replace its characters with asterisks (`*`) and print the result to standard output (fd 1).
- **Constraint:** Do not assume the input fits in a single buffer. You must handle the case where the censored word is split perfectly across two `read()` buffer boundaries.

---

## Sub-Phase 1B: Basic File I/O and Buffers

**Core Concepts:** File descriptors, `open()`, `read()`, `write()`, `close()`, buffer management, handling read loops.

### Program 4: `cat` (Enhanced)

- **Goal:** Master reading from file descriptors into fixed-size buffers (`char buf[512]`) and writing to stdout.
- **Usage:** `cat [-n] [-e] [file...]`
- **Flags:**
     - `-n`: Number all output lines. (You will have to track newline characters `\n` in your buffer).
     - `-e`: Display a `$` character at the end of each line before the newline.

### Program 5: `cp` (Enhanced)

- **Goal:** Safely copy bytes from one file descriptor to another.
- **Usage:** `cp [-i] <source> <dest>`
- **Flags:**
     - `-i`: Interactive. If `<dest>` already exists, prompt the user on standard output (`Overwrite? (y/n)`) and read their response from standard input before proceeding.
- **Constraint:** You must use `fstat` to check if `<source>` is a directory. If it is, throw an error (do not copy directories yet).

### Program 6: `tee`

- **Goal:** Multiplexing output. Read from stdin, write to stdout AND a file simultaneously.
- **Usage:** `tee <file>`
- **Behavior:** Whatever is piped into `tee` should be printed to the screen and also saved to `<file>`. If `<file>` exists, overwrite it.

---

## Sub-Phase 1C: Advanced File Logic (Dynamic Memory & Pointers)

**Core Concepts:** Using `malloc()` and `free()` in user space, building dynamic data structures (like circular arrays or linked lists) to hold data of unknown sizes.

### Program 7: `wc` (Enhanced)

- **Goal:** State machines. Tracking state as you read through chunks of a file.
- **Usage:** `wc [-l] [-w] [-c] [files...]`
- **Flags:**
     - `-l`: Print line count.
     - `-w`: Print word count.
     - `-c`: Print byte count.
- **Constraint:** If multiple files are provided, print the stats for each file, and then print a "total" row at the very bottom.

### Program 8: `tail`

- **Goal:** Master dynamic memory. xv6 does **not** have an `lseek` system call to jump to the end of a file. You must read the file from start to finish.
- **Usage:** `tail [-n <lines>] <file>`
- **Flags:**
     - `-n <lines>`: Print the last N lines of the file. Default is 10.
- **Constraint:** Because files can be larger than available memory, you cannot load the whole file into a buffer. You must create an array of `N` pointers using `malloc`, updating them as a circular buffer as you read through the file. Don't forget to `free()`!

### Program 9: `grep` (Enhanced)

- **Goal:** Advanced string matching line-by-line.
- **Usage:** `grep [-v] [-i] [-n] <pattern> [files...]`
- **Flags:**
     - `-v`: Invert match (print lines that DO NOT match the pattern).
     - `-i`: Ignore case (treat 'A' and 'a' as identical).
     - `-n`: Prefix each matching line with its line number in the file.

---

## Sub-Phase 1D: File Systems, Inodes, and Structs

**Core Concepts:** The `stat` struct, `fstat`, the `dirent` struct, traversing directories, understanding how xv6 stores file metadata.

### Program 10: `ls` (Enhanced)

- **Goal:** Working with arrays of structs and implementing sorting algorithms in C.
- **Usage:** `ls [-l] [-s] [dir]`
- **Flags:**
     - `-l`: Long format. Print file type, inode number, and size (this is default in xv6, but you should format it cleanly).
     - `-s`: Sort the output by file size (largest to smallest) instead of directory order.
- **Constraint:** To sort, you will need to read all `dirent` structs into a dynamically allocated array, fetch their `stat` info, sort the array (using Bubble Sort or Insertion Sort, since xv6 has no `qsort`), and then print it.

### Program 11: `find` (Enhanced)

- **Goal:** Deep recursion and passing state through recursive function calls.
- **Usage:** `find <dir> [-name <string>] [-type d|f] [-size +<bytes>]`
- **Flags:**
     - `-name <string>`: Find files matching this exact name.
     - `-type d|f`: Filter results to only directories (`d`) or files (`f`).
     - `-size +<bytes>`: Find files strictly larger than `<bytes>`.
- **Constraint:** Be careful with the `.` and `..` directories, otherwise your recursion will cause a stack overflow and crash your xv6 session!

### Program 12: `tree`

- **Goal:** Visualizing recursion.
- **Usage:** `tree [-d] <dir>`
- **Flags:**
     - `-d`: List directories only.
- **Behavior:** Print the directory structure as an indented tree. You will need to pass an "indentation level" variable down through your recursive calls to print the correct number of spaces/pipes (`|--`).

---

## Sub-Phase 1E: The Final Bosses (Data Structures in C)

**Core Concepts:** Complex parsing, arrays of strings, line-by-line processing, heavy `malloc` and `free` usage.

### Program 13: `sort`

- **Goal:** Read an entire file into memory line-by-line, sort the lines alphabetically, and print them.
- **Usage:** `sort [-r] <file>`
- **Flags:**
     - `-r`: Reverse sort order.
- **Constraint:** You will need to build an array of `char*` (an array of pointers to strings). As you read the file, `malloc` exact amounts of space for each line, copy the string into it, and store the pointer in your array. Write a custom string comparison function.

### Program 14: `uniq`

- **Goal:** Detect and manipulate adjacent identical lines.
- **Usage:** `uniq [-c] [-d] <file>`
- **Flags:**
     - `-c`: Prefix each line with the number of times it occurred consecutively.
     - `-d`: Only print lines that are repeated (do not print unique lines).
- **Constraint:** You must maintain pointers to the "previous line" and "current line", comparing them as you iterate through the file.

### Program 15: `xargs` (Preparation for Phase 2)

- **Goal:** Understand how to build `argv` arrays dynamically.
- **Usage:** `xargs <command>`
- **Behavior:** Read lines from standard input. For every line read, execute `<command>` with the read line appended as an argument.
- _(Note: This requires the `fork()`, `exec()`, and `wait()` system calls. If you complete this, you are officially ready for Phase 2)._
