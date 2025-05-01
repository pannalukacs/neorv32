# ========================================
# Project Paths and Config
# ========================================
SRC_DIR     := src
INC_DIR     := inc
TEST_DIR    := test
BUILD_DIR   := build
NATIVE_DIR  := build_native
TARGET      := montgomery_test

SRCS        := $(SRC_DIR)/kyber_reduce.c
TEST_SRCS   := $(TEST_DIR)/test_montgomery.c
INCLUDES    := -I$(INC_DIR)

# ========================================
# Native Build
# ========================================
CC_NATIVE     := gcc
CFLAGS_NATIVE := -Wall -Wextra -O2 $(INCLUDES) -DNATIVE
OBJS_NATIVE   := $(patsubst $(SRC_DIR)/%.c,$(NATIVE_DIR)/%.o,$(SRCS)) \
                 $(patsubst $(TEST_DIR)/%.c,$(NATIVE_DIR)/%.o,$(TEST_SRCS))

# ========================================
# NEORV32 Configuration
# Only enable if calling a NEORV32-related target
# ========================================
ifneq (,$(filter install sim elf exe image bin hex all clean clean_all info check gdb asm,$(MAKECMDGOALS)))

MARCH        := rv32i_zicsr_zifencei
EFFORT       := -Os

USER_FLAGS  += -ggdb -gdwarf-3
USER_FLAGS  += --specs=nano.specs
USER_FLAGS  += -Wl,--defsym,__neorv32_rom_size=16k
USER_FLAGS  += -Wl,--defsym,__neorv32_ram_size=8k
# USER_FLAGS  += -Wl,--defsym,__neorv32_heap_size=1k
USER_FLAGS  += -DUART0_SIM_MODE
USER_FLAGS  += -DNEORV32

APP_SRC     += $(SRCS) $(TEST_SRCS)
APP_INC     += $(INCLUDES)

NEORV32_HOME ?= ../..
GHDL_RUN_FLAGS += --stop-time=10000ms

include $(NEORV32_HOME)/sw/common/common.mk

endif

# ========================================
# Default Target: Show Help
# ========================================
all: project-help

project-help:
	@echo "========== Project Help =========="
	@echo "  make native        # Build for host"
	@echo "  make run           # Build and run on host"
	@echo "  make elf           # Build NEORV32 ELF"
	@echo "  make exe           # Build bootloader image for NEORV32"
	@echo "  make install       # Install bootloader image to VHDL"
	@echo "  make sim           # Simulate NEORV32 in console"
	@echo "  make clean         # Clean native build"
	@echo "  make clean_all     # Full NEORV32 clean (native too)"
	@echo "  make check info    # Check toolchain or project info"
	@echo "  make neorv32-help  # Show official NEORV32 Makefile help"

# ========================================
# Native Build Target
# ========================================
native: $(NATIVE_DIR) $(TARGET)

$(NATIVE_DIR):
	mkdir -p $(NATIVE_DIR)

$(NATIVE_DIR)/%.o: $(SRC_DIR)/%.c
	$(CC_NATIVE) $(CFLAGS_NATIVE) -c $< -o $@

$(NATIVE_DIR)/%.o: $(TEST_DIR)/%.c
	$(CC_NATIVE) $(CFLAGS_NATIVE) -c $< -o $@

$(TARGET): $(OBJS_NATIVE)
	$(CC_NATIVE) $(CFLAGS_NATIVE) $^ -o $@

# ========================================
# Run Native Test
# ========================================
run: native
	./$(TARGET)

# ========================================
# Clean Native
# (NEORV32 defines its own 'clean' and 'clean_all')
# ========================================
ifneq (,$(filter-out install sim elf exe image bin hex all clean clean_all info check gdb asm,$(MAKECMDGOALS)))
clean:
	rm -rf $(BUILD_DIR) $(NATIVE_DIR) $(TARGET)
endif

# ========================================
# Show NEORV32 Help Message (Explicit)
# ========================================
neorv32-help:
	@$(MAKE) --no-print-directory -f ../../sw/common/common.mk NEORV32_HOME=../.. help