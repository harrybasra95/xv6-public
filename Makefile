# --- 1. Config and Tools
BUILD_DIR = build

TOOLPREFIX = i686-elf-

# Complier and Linker definitions
CC = $(TOOLPREFIX)gcc
AS = $(TOOLPREFIX)gas
LD = $(TOOLPREFIX)ld
OBJCOPY = $(TOOLPREFIX)objcopy
OBJDUMP = $(TOOLPREFIX)objdump

# CFLAGS: How C files are compiled
# -m32: Compile for 32-bit CPU (xv6 is 32-bit)
# -O2: Optimize the code
# -fno-pie -fno-pic: Disable position-independent code (kernel needs fixed addresses)
# -nostdinc: Don't use host computer's standard libs
# -I: where to look for header (.h) files
CFLAGS = -fno-pic -static -fno-builtin -fno-strict-aliasing -O2 -Wall -MD -ggdb -m32 -Werror -fno-omit-frame-pointer
CFLAGS += -Wno-array-bounds -Wno-infinite-recursion
CFLAGS += -Iboot -Ikernel-core -I. -Isync -Ifs -Idevices -Iheaders -Iuser-programs -Ibuild-tools

# ASFLAGS: How assembly files are compiled
ASFLAGS = -m32 -gdwarf-2 -Wa,-divide -Iboot -Ikernel-core -I. -Isync -Ifs -Idevices -Iheaders

# LDFLAGS: How files are linked together
LDFLAGS = -m elf_i386


# --- 2. KERNEL OBJECT FILES ---
# List of all C and Assembly files that make up the core OS
OBJS = \
	kernel-core/exec.o \
	kernel-core/kalloc.o \
	kernel-core/main.o \
	kernel-core/proc.o \
	kernel-core/syscall.o \
	kernel-core/sysproc.o \
	kernel-core/trap.o \
	kernel-core/vm.o \
	boot/swtch.o \
	boot/trapasm.o \
	fs/file.o \
	fs/fs.o \
	fs/ide.o \
	fs/log.o \
	fs/pipe.o \
	devices/console.o \
	devices/ioapic.o \
	devices/kbd.o \
	devices/lapic.o \
	devices/mp.o \
	devices/picirq.o \
	devices/uart.o \
	sync/sleeplock.o \
	sync/spinlock.o \
	headers/string.o \
	user-programs/bio.o \
	sysfile.o \
	vectors.o

# Magic trick: Prepend $(BUILD_DIR)/ to every object file
OBJS := $(addprefix $(BUILD_DIR)/, $(OBJS))


# --- 3. GENERIC COMPILATION RULES ---
# Tell Make not to delete these intermediate files
.PRECIOUS: $(BUILD_DIR)/%.o

# Rule: How to turn ANY .c file into a .o file in the build directory
$(BUILD_DIR)/%.o: %.c
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -c -o $@ $<

# Rule: How to turn ANY .S (Assembly) file into a .o file in the build directory
$(BUILD_DIR)/%.o: %.S
	@mkdir -p $(@D)
	$(CC) $(ASFLAGS) -c -o $@ $<

# Auto-generate vectors.S using the perl script
vectors.S: boot/vectors.pl
	perl boot/vectors.pl > vectors.S


# --- 4. BOOTLOADER & SPECIAL BINARIES ---
# Bootblock: The first 512 bytes of the disk
$(BUILD_DIR)/bootblock: boot/bootasm.S boot/bootmain.c
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -fno-pic -O -nostdinc -c boot/bootmain.c -o $(BUILD_DIR)/bootmain.o
	$(CC) $(CFLAGS) -fno-pic -nostdinc -c boot/bootasm.S -o $(BUILD_DIR)/bootasm.o
	$(LD) $(LDFLAGS) -N -e start -Ttext 0x7C00 -o $(BUILD_DIR)/bootblock.o $(BUILD_DIR)/bootasm.o $(BUILD_DIR)/bootmain.o
	$(OBJCOPY) -S -O binary -j .text $(BUILD_DIR)/bootblock.o $@
	./build-tools/sign.pl $@

# Entryother: Used to wake up secondary CPUs
$(BUILD_DIR)/entryother: boot/entryother.S
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -fno-pic -nostdinc -c $< -o $(BUILD_DIR)/entryother.o
	$(LD) $(LDFLAGS) -N -e start -Ttext 0x7000 -o $(BUILD_DIR)/bootblockother.o $(BUILD_DIR)/entryother.o
	$(OBJCOPY) -S -O binary -j .text $(BUILD_DIR)/bootblockother.o $@

# Initcode: The first user program embedded in the kernel
$(BUILD_DIR)/initcode: boot/initcode.S
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -nostdinc -c $< -o $(BUILD_DIR)/initcode.o
	$(LD) $(LDFLAGS) -N -e start -Ttext 0 -o $(BUILD_DIR)/initcode.out $(BUILD_DIR)/initcode.o
	$(OBJCOPY) -S -O binary $(BUILD_DIR)/initcode.out $@

# --- 5. THE KERNEL ---
$(BUILD_DIR)/kernel: $(OBJS) $(BUILD_DIR)/boot/entry.o $(BUILD_DIR)/entryother $(BUILD_DIR)/initcode boot/kernel.ld
	@cp $(BUILD_DIR)/initcode initcode
	@cp $(BUILD_DIR)/entryother entryother
	$(LD) $(LDFLAGS) -T boot/kernel.ld -o $@ $(BUILD_DIR)/boot/entry.o $(OBJS) -b binary initcode entryother
	@rm -f initcode entryother
	$(OBJDUMP) -S $@ > $(BUILD_DIR)/kernel.asm
	$(OBJDUMP) -t $@ | sed '1,/SYMBOL TABLE/d; s/ .* / /; /^$$/d' > $(BUILD_DIR)/kernel.sym


# --- 6. USER PROGRAMS & FILESYSTEM ---
# The User Library (functions user programs can call)
ULIB = $(BUILD_DIR)/headers/ulib.o $(BUILD_DIR)/boot/usys.o $(BUILD_DIR)/devices/printf.o $(BUILD_DIR)/headers/umalloc.o

# Rule: How to link a user program (e.g., cat)
$(BUILD_DIR)/user-programs/_%: $(BUILD_DIR)/user-programs/%.o $(ULIB)
	$(LD) $(LDFLAGS) -N -e main -Ttext 0 -o $@ $^
	$(OBJDUMP) -S $@ > $@.asm

# List of all user programs
UPROGS=\
	$(BUILD_DIR)/user-programs/_cat \
	$(BUILD_DIR)/user-programs/_echo \
	$(BUILD_DIR)/user-programs/_forktest \
	$(BUILD_DIR)/user-programs/_grep \
	$(BUILD_DIR)/user-programs/_init \
	$(BUILD_DIR)/user-programs/_kill \
	$(BUILD_DIR)/user-programs/_ln \
	$(BUILD_DIR)/user-programs/_ls \
	$(BUILD_DIR)/user-programs/_mkdir \
	$(BUILD_DIR)/user-programs/_rm \
	$(BUILD_DIR)/user-programs/_sh \
	$(BUILD_DIR)/user-programs/_stressfs \
	$(BUILD_DIR)/user-programs/_usertests \
	$(BUILD_DIR)/user-programs/_wc \
	$(BUILD_DIR)/user-programs/_zombie \
	$(BUILD_DIR)/user-programs/_hello \
	$(BUILD_DIR)/user-programs/_cp \
	$(BUILD_DIR)/user-programs/_head 

# Build the filesystem maker tool using the HOST computer's compiler
$(BUILD_DIR)/mkfs: fs/mkfs.c fs/fs.h
	@mkdir -p $(@D)
	gcc -Werror -Wall -o $@ fs/mkfs.c

# Format fs.img and pack user programs into it
fs.img: $(BUILD_DIR)/mkfs build-tools/README user-programs/hello.txt user-programs/new.txt $(UPROGS)
	$(BUILD_DIR)/mkfs fs.img build-tools/README user-programs/hello.txt user-programs/new.txt $(UPROGS)


# --- 7. FINAL DISK IMAGES & RUN TARGETS ---
xv6.img: $(BUILD_DIR)/bootblock $(BUILD_DIR)/kernel
	dd if=/dev/zero of=xv6.img count=10000
	dd if=$(BUILD_DIR)/bootblock of=xv6.img conv=notrunc
	dd if=$(BUILD_DIR)/kernel of=xv6.img seek=1 conv=notrunc

# QEMU emulator variables
QEMU = qemu-system-i386
CPUS = 2
QEMUOPTS = -drive file=fs.img,index=1,media=disk,format=raw -drive file=xv6.img,index=0,media=disk,format=raw -smp $(CPUS) -m 512

qemu-nox: fs.img xv6.img
	$(QEMU) -nographic $(QEMUOPTS)

clean: 
	rm -rf $(BUILD_DIR) xv6.img fs.img vectors.S