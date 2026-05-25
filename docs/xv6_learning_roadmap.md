# From Beginner to Kernel Hacker: xv6 Systems Engineering Roadmap

This roadmap is designed to take you from a beginner learning C to an expert who understands how a multi-core operating system works at the hardware level. It uses xv6 as the learning vehicle.

---

## Phase 1: User-Space Comfort & C Fundamentals (Your Current Phase)

**Goal:** Learn C syntax, pointers, memory allocation, and how to use basic system calls.
**Where you are working:** `user-programs/`, `headers/user.h`, `headers/ulib.c`

- **Step 1.1: Master Pointers and Arrays**
     - _Concept:_ Understand memory addresses, dereferencing (`*`), address-of (`&`), and pointer arithmetic.
     - _Project:_ Write a program that reverses a string in place using only pointers (no array indexing like `buf[i]`).
- **Step 1.2: File I/O System Calls**
     - _Concept:_ File descriptors (`fd`), `open`, `read`, `write`, `close`.
     - _Project:_ Finish `cp`, `wc`, and `head` (which you are already doing). Then write a `tail` program (harder because you don't know the file size in advance).
- **Step 1.3: Structs and Directory Traversal**
     - _Concept:_ Structs, the `stat` system call, the `dirent` struct.
     - _Project:_ Finish `find`. Then write `tree`, a program that prints the directory structure recursively in a visual tree format.

## Phase 2: Process Control & Inter-Process Communication (IPC)

**Goal:** Understand how the OS creates and manages programs.
**Where you are working:** `user-programs/`, `user-programs/sh.c`

- **Step 2.1: The Fork/Exec/Wait Pattern**
     - _Concept:_ How `fork` clones a process, how `exec` replaces the memory image, and how `wait` reaps zombies.
     - _Project:_ Write a program `xargs` (like the UNIX utility).
- **Step 2.2: Pipes and Redirection**
     - _Concept:_ How `pipe` creates a bounded buffer in the kernel, and how `dup` duplicates file descriptors to redirect standard input/output (fd 0, 1, 2).
     - _Project:_ Write a program `pingpong` that passes a byte back and forth between a parent and child using two pipes.
- **Step 2.3: Shell Mechanics**
     - _Project:_ Read `sh.c` very carefully. Understand how it parses commands and executes them. Add a new built-in command to the shell (e.g., `history`).

## Phase 3: Crossing the Boundary (Syscalls & Traps)

**Goal:** Understand exactly how a user program asks the kernel for hardware access.
**Where you are working:** `boot/usys.S`, `kernel-core/syscall.c`, `kernel-core/trap.c`, `kernel-core/sysproc.c`

- **Step 3.1: The Journey of a Syscall**
     - _Concept:_ Understand the `INT` assembly instruction. Trace a system call (like `read`) from `usys.S` -> `vector` -> `alltraps` (in `trapasm.S`) -> `trap.c` -> `syscall.c` -> `sys_read`.
     - _Project:_ Add a new system call `trace(mask)` that prints out a trace of every system call the current process makes. (This is a classic MIT 6.828 lab).
- **Step 3.2: Trap Frames**
     - _Concept:_ When the CPU jumps to the kernel, where do the user's registers go? Study the `trapframe` struct in `mmu.h`/`x86.h`.
     - _Project:_ Write a system call `getregs` that fills a user-provided struct with the current values of the CPU registers.

## Phase 4: CPU Scheduling and Context Switching

**Goal:** Understand how one CPU runs multiple programs seemingly at the same time.
**Where you are working:** `kernel-core/proc.c`, `boot/swtch.S`

- **Step 4.1: The Process Table**
     - _Concept:_ The `ptable` and process states (`RUNNING`, `RUNNABLE`, `SLEEPING`, `ZOMBIE`).
     - _Project:_ Write a user program `ps` that prints all running processes. You will need to add a system call to read the kernel's `ptable`.
- **Step 4.2: Context Switching (Assembly Level)**
     - _Concept:_ Read `swtch.S`. Understand how the kernel saves its _own_ registers to switch from a user thread to the scheduler thread, and then to another user thread.
- **Step 4.3: Custom Schedulers**
     - _Concept:_ The default xv6 scheduler is a simple Round-Robin.
     - _Project:_ Implement a **Lottery Scheduler** or a **Priority Scheduler**. Add a system call `setpriority(pid, priority)`, and modify `scheduler()` in `proc.c` to pick the highest priority `RUNNABLE` process.

## Phase 5: Memory Management (The Hardest Phase)

**Goal:** Demystify RAM. Understand Virtual vs. Physical memory.
**Where you are working:** `kernel-core/vm.c`, `kernel-core/kalloc.c`, `boot/mmu.h`

- **Step 5.1: Physical Memory Allocation**
     - _Concept:_ How the kernel keeps track of free RAM (`kalloc.c`).
     - _Project:_ Modify `kalloc.c` to keep a count of free pages. Add a syscall `freemem()` that returns the amount of free RAM.
- **Step 5.2: Paging and Page Tables**
     - _Concept:_ The CR3 register, Page Directories, and Page Table Entries (PTEs). Understand how `vm.c` maps a virtual address to a physical address.
     - _Project:_ Implement a `NULL` pointer dereference protection. (In default xv6, address `0x0` is mapped. Unmap the first page of memory so dereferencing `NULL` causes a page fault).
- **Step 5.3: Lazy Allocation**
     - _Concept:_ When a user calls `sbrk()`, xv6 allocates physical memory immediately. Modern OSes lie: they just update the page table but don't give physical memory until the program actually touches it (causing a page fault).
     - _Project:_ Implement Lazy Allocation. Modify `sys_sbrk` to just increase `proc->sz`. Then modify `trap.c` to catch `T_PGFLT` (page faults), allocate the physical page, map it, and resume the program.

## Phase 6: Concurrency and Locking

**Goal:** Understand multi-core processing and how to prevent data corruption.
**Where you are working:** `sync/spinlock.c`, `sync/sleeplock.c`

- **Step 6.1: Spinlocks**
     - _Concept:_ The `xchg` atomic hardware instruction. Why we must disable interrupts (`cli`) before grabbing a spinlock.
     - _Project:_ Intentionally remove a lock in `kalloc.c` or `proc.c`. Run the `stressfs` user program and watch the kernel panic to see race conditions in action.
- **Step 6.2: Sleep and Wakeup**
     - _Concept:_ How `sleep` releases a lock and puts a process to sleep, and how `wakeup` finds it. The "Lost Wakeup" problem.

## Phase 7: The File System & Storage

**Goal:** Understand how data persists on a hard drive.
**Where you are working:** `fs/fs.c`, `fs/bio.c`, `fs/log.c`, `fs/file.c`, `fs/ide.c`

- **Step 7.1: The Buffer Cache**
     - _Concept:_ How `bio.c` caches disk blocks in RAM.
- **Step 7.2: Logging and Crash Recovery**
     - _Concept:_ Why xv6 uses a log (`log.c`) to ensure file system consistency if the power cuts out mid-write.
- **Step 7.3: Inodes and Indirect Blocks**
     - _Concept:_ How files are represented by inodes (`dinode` struct).
     - _Project:_ Currently, xv6 files have a maximum size (12 direct blocks + 1 singly-indirect block = 140 blocks = 71KB). **Implement doubly-indirect blocks** to allow xv6 to support massive files (up to several megabytes).

## Phase 8: Booting the Hardware (The Absolute Bottom)

**Goal:** Understand what happens the moment you press the power button.
**Where you are working:** `boot/bootasm.S`, `boot/bootmain.c`, `kernel-core/main.c`

- **Step 8.1: Real Mode to Protected Mode**
     - _Concept:_ How the BIOS loads sector 0 (`bootblock`), which runs in 16-bit real mode, enables the A20 line, loads the Global Descriptor Table (GDT), and switches to 32-bit protected mode.
- **Step 8.2: Kernel Initialization**
     - _Concept:_ Read `main.c`. Trace how the kernel sets up the page tables, initializes the multi-core processors (`mp.c`, `lapic.c`), and finally drops into user space via `userinit()`.
