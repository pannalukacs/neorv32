# CPU ISA
MARCH = rv32i_zicsr_zifencei

# Optimization effort
EFFORT = -Os

# Debugging symbols
USER_FLAGS += -ggdb -gdwarf-3

# Adjust memory size (IMEM/DMEM/HEAP)
USER_FLAGS += -Wl,--defsym,__neorv32_rom_size=128k
USER_FLAGS += -Wl,--defsym,__neorv32_ram_size=16k
USER_FLAGS += -Wl,--defsym,__neorv32_heap_size=8k

# Application source files
APP_SRC += main.c
APP_SRC += mlkem/kem.c mlkem/indcpa.c mlkem/poly.c mlkem/polyvec.c mlkem/ntt.c mlkem/reduce.c mlkem/symmetric-shake.c mlkem/verify.c mlkem/cbd.c
APP_SRC += common/fips202.c common/randombytes.c

# Application include folders
APP_INC += -I mlkem -I common

# Path to NEORV32 repo root
NEORV32_HOME ?= ../../..

# Include NEORV32 Makefile
include $(NEORV32_HOME)/sw/common/common.mk
