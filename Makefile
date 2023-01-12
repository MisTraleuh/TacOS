SRC				= ./src
CONFIG			= ./config
BIN				= ./bin
ISO				= ./iso

# Main folders path
ENTRY			= $(SRC)/entry
UTILS			= $(SRC)/utils
BOOT			= $(SRC)/boot_sector
INTERRUPTS		= $(SRC)/interrupts
DRIVERS			= $(SRC)/drivers

# Kernel needed file(s)
KERNEL_BIN		= $(BIN)/kernel.bin
KERNEL_BUILD	= $(BIN)/kernelfull.o
OS_BIN			= $(ISO)/epi-os.img

# Compilation tools (compiler, linker, etc..)
NASM			= nasm
CC				= i686-elf-gcc
LD				= i686-elf-ld

# Boot sector
BOOT_SRC		= $(BOOT)/boot_sector.asm
BOOT_BIN		= $(BIN)/boot.bin
BOOT_FLAGS		= -f bin

# Includes
INCLUDES		= -I $(SRC) -I $(UTILS)

# Flags
ASM_FLAGS		= -f elf32
CFLAGS			= -g -ffreestanding $(INCLUDES) -W -Wall -Wextra
LDFLAGS			= -Ttext 0x1000 --oformat binary

# Sources
ASM_SRC			= $(ENTRY)/entry_point.asm \
				$(DRIVERS)/idt/interrupts.asm
C_SRC			= $(ENTRY)/kernel_entry.c \
				  $(UTILS)/VGA/clear.c \
				  $(UTILS)/VGA/print.c \
				  $(UTILS)/string/revstr.c \
				  $(UTILS)/string/itoa.c \
				  $(UTILS)/string/strlen.c \
				  $(UTILS)/memory/memset.c \
				  $(UTILS)/memory/memcpy.c \
				  $(DRIVERS)/idt/idt.c \
				  $(DRIVERS)/idt/init.c \
				  $(DRIVERS)/idt/handler.c \
				  $(DRIVERS)/pic/remap.c \
				  $(DRIVERS)/pic/io.c \
				  $(DRIVERS)/keyboard/init.c \
				  $(DRIVERS)/keyboard/handler.c \
				  $(DRIVERS)/vesa/init.c \
				  $(DRIVERS)/gdt/gdt.c \
				  $(DRIVERS)/bios/32/interrupts.c \
				  $(DRIVERS)/bios/32/init.c	

# Objects
C_OBJ			= $(C_SRC:.c=.o)
ASM_OBJ			= $(ASM_SRC:.asm=.o)
KERNEL_OBJS		= $(ASM_OBJ) $(C_OBJ)


# Targets
all: build

build: boot_bin kernel_bin
	dd if=/dev/zero of=$(OS_BIN) bs=1M count=32
	dd if=$(BOOT_BIN) 					>> $(KERNEL_BUILD)
	dd if=$(KERNEL_BIN) 				>> $(KERNEL_BUILD)
	dd if=$(KERNEL_BUILD) of=$(OS_BIN) 	conv=notrunc

# Compile and launch QEMU
run:
	qemu-system-x86_64 -d int -no-reboot $(OS_BIN)

run_bochs:
	$(RM) $(OS_BIN).lock
	bochs -q -f bochsrc

build_and_run: build run

boot_bin:
	$(NASM) $(BOOT_FLAGS) $(BOOT_SRC) -o $(BOOT_BIN)

kernel_bin: $(KERNEL_OBJS)
	$(LD) $(LDFLAGS) $(KERNEL_OBJS) -o $(KERNEL_BIN)

clean:
	$(RM) $(C_OBJ)
	$(RM) $(ASM_OBJ)
	$(RM) $(KERNEL_BIN)
	$(RM) $(BOOT_BIN)
	$(RM) $(KERNEL_BUILD)

fclean: clean
	$(RM) $(OS_BIN)

re: fclean all

# Compilations rules
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

%.o: %.asm
	$(NASM) $(ASM_FLAGS) $< -o $@

.PHONY: build run build_and_run boot_bin kernel_bin clean fclean re
