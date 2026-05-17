
-include $(NPC_HOME)/include/config/auto.conf
-include $(NPC_HOME)/include/config/auto.conf.cmd

TOPNAME = ysyxSoCFull
NXDC_FILES = constr/top.nxdc
INC_PATH ?=
INC_PATH += $(NPC_HOME)/include
INC_PATH += $(abspath ./include)

VERILATOR = verilator
VERILATOR_CFLAGS += -MMD --build -cc -Wall\
					-O3 --x-assign fast --x-initial fast --noassert
VERILATOR_CFLAGS += -j 8
VERILATOR_CFLAGS += --timescale "1ns/1ns"
VERILATOR_CFLAGS += --no-timing
VERILATOR_CFLAGS += -Wno-PINCONNECTEMPTY \
  					-Wno-DECLFILENAME \
  					-Wno-SYNCASYNCNET \
  					-Wno-UNUSEDPARAM \
  					-Wno-DEFPARAM \
  					-Wno-ASSIGNDLY \
					-Wno-PROCASSINIT \
					--autoflush
ifeq ($(CONFIG_GTKWAVE), y)
VERILATOR_CFLAGS += --trace-fst
endif
VERILATOR_CFLAGS += -I$(abspath ./vsrc)
VERILATOR_CFLAGS += -I$(abspath ../ysyxSoC/perip/uart16550/rtl)
VERILATOR_CFLAGS += -I$(abspath ../ysyxSoC/perip/spi/rtl)

BUILD_DIR = ./build
OBJ_DIR = $(BUILD_DIR)/obj_dir
BIN = $(BUILD_DIR)/$(TOPNAME)

default: $(BIN)

$(shell mkdir -p $(BUILD_DIR))

# constraint file
SRC_AUTO_BIND = $(abspath $(BUILD_DIR)/auto_bind.cpp)
$(SRC_AUTO_BIND): $(NXDC_FILES)
	python3 $(NVBOARD_HOME)/scripts/auto_pin_bind.py $^ $@

# project source
VSRCS = $(shell find $(abspath ./vsrc) -name "*.v" -or -name "*.sv")
VSRCS := $(filter-out %Xbar.sv, $(VSRCS))
VHDRS = $(shell find $(abspath ./vsrc) -name "*.vh")
VSRCS += $(shell find $(abspath ../ysyxSoC/perip) -name "*.v")
VSRCS += $(abspath ../ysyxSoC/build/ysyxSoCFull.v)

CSRCS = $(shell find $(abspath ./csrc) -name "*.c" -or -name "*.cc" -or -name "*.cpp")
CSRCS += $(SRC_AUTO_BIND)


LDFLAGS += -lreadline -lhistory

# rules for NVBoard
include $(NVBOARD_HOME)/scripts/nvboard.mk

# rules for velilator
INCFLAGS = $(addprefix -I, $(INC_PATH))
CXXFLAGS += $(INCFLAGS) -DTOP_NAME="\"V$(TOPNAME)\""
CXXFLAGS += $(INCFLAGS) -DTOP_ROOT="\"V$(TOPNAME)___024root\""
CXXFLAGS += $(INCFLAGS) -DTOP_DPI="\"V$(TOPNAME)__Dpi\""
CXXFLAGS += -g

//DIFFTEST ?= 0
DIFF_REF_PATH = $(NEMU_HOME)/build
DIFF_REF_SO = $(DIFF_REF_PATH)/riscv32-nemu-interpreter-so

ARGS ?= 
ifeq ($(CONFIG_DIFFTEST), y)
override	ARGS += --diff=$(DIFF_REF_SO)
endif

all:
	@echo "Write this Makefile by your self."

$(BIN): $(VSRCS) $(VHDRS) $(CSRCS) $(NVBOARD_ARCHIVE)
	@rm -rf $(OBJ_DIR)
	$(VERILATOR) $(VERILATOR_CFLAGS) \
		--top-module $(TOPNAME) $(VSRCS) \
		$(addprefix -CFLAGS , $(CXXFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
		--Mdir $(OBJ_DIR) --Wno-UNOPTFLAT --public --exe --trace-fst -o $(abspath $(BIN)) $(CSRCS)

sim: $(BIN)
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	echo $(BIN) $(ARGS) $(IMG)
	@$(BIN) $(ARGS) $(IMG)
ifeq ($(CONFIG_GTKWAVE), y)
	gtkwave $(OBJ_DIR)/wave.fst
endif

gdb: $(BIN)
	gdb -s $(BIN) --args $(BIN) $(ARGS) $(IMG)

clean:
	rm -rf $(BUILD_DIR)

include ../Makefile

include $(NPC_HOME)/scripts/config.mk
