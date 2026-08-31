
-include $(NPC_HOME)/include/config/auto.conf
-include $(NPC_HOME)/include/config/auto.conf.cmd

FILELIST_MK = $(shell find -L ./csrc -name "filelist.mk")
include $(FILELIST_MK)

ARCH ?= ysyxsoc

ifeq ($(ARCH),npc)
TOPNAME = ysyx_25120302
RESET_PC := 80000000
CXXFLAGS += -DARCH_NPC
VERILATOR_CFLAGS += -DARCH_NPC
else ifeq ($(ARCH),ysyxsoc)
TOPNAME = ysyxSoCFull
RESET_PC := 30000000
CXXFLAGS += -DARCH_YSYXSOC
VERILATOR_CFLAGS += -DARCH_YSYXSOC
NXDC_FILES = constr/top.nxdc
else
$(error Unsupported ARCH=$(ARCH))
endif


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
VERILATOR_CFLAGS += -DRESET_PC=32\'h$(RESET_PC)

ifeq ($(CONFIG_MTRACE),y)
VERILATOR_CFLAGS += -DCONFIG_MTRACE
endif

ifeq ($(CONFIG_GTKWAVE), y)
VERILATOR_CFLAGS += --trace-fst
endif

VERILATOR_CFLAGS += -I$(abspath ./vsrc)


BUILD_DIR = ./build
OBJ_DIR = $(BUILD_DIR)/obj_dir
BIN = $(BUILD_DIR)/$(TOPNAME)

default: $(BIN)

$(shell mkdir -p $(BUILD_DIR))

# project source
VSRCS = $(shell find $(abspath ./vsrc) -name "*.v" -or -name "*.sv")
# VSRCS := $(filter-out %Xbar.sv, $(VSRCS))
VSRCS := $(filter-out $(shell find $(abspath ./vsrc/wrapper) -name "*.v"), $(VSRCS))
VHDRS = $(shell find $(abspath ./vsrc) -name "*.vh")

CSRCS += $(shell find $(abspath ./csrc) -name "*.c" -or -name "*.cc" -or -name "*.cpp")
CSRCS := $(filter-out $(CSRCS-BLACKLIST-y), $(CSRCS))

LDFLAGS += -lreadline -lhistory

# rules for velilator
INCFLAGS = $(addprefix -I, $(INC_PATH))
CXXFLAGS += $(INCFLAGS) -DTOP_NAME="\"V$(TOPNAME)\""
CXXFLAGS += $(INCFLAGS) -DTOP_ROOT="\"V$(TOPNAME)___024root\""
CXXFLAGS += $(INCFLAGS) -DTOP_DPI="\"V$(TOPNAME)__Dpi\""
CXXFLAGS += -DRESET_PC=0x$(RESET_PC)
CXXFLAGS += -g


ifeq ($(ARCH),ysyxsoc)

# rules for NVBoard
include $(NVBOARD_HOME)/scripts/nvboard.mk

VERILATOR_CFLAGS += -I$(abspath ../ysyxSoC/perip/uart16550/rtl)
VERILATOR_CFLAGS += -I$(abspath ../ysyxSoC/perip/spi/rtl)

# constraint file
SRC_AUTO_BIND = $(abspath $(BUILD_DIR)/auto_bind.cpp)
$(SRC_AUTO_BIND): $(NXDC_FILES)
	python3 $(NVBOARD_HOME)/scripts/auto_pin_bind.py $^ $@

# project source
VSRCS += $(shell find $(abspath ../ysyxSoC/perip) -name "*.v")
VSRCS += $(abspath ../ysyxSoC/build/ysyxSoCFull.v)

CSRCS += $(SRC_AUTO_BIND)

endif


all:
	@echo "Write this Makefile by your self."

$(BIN): $(VSRCS) $(VHDRS) $(CSRCS) $(NVBOARD_ARCHIVE)
	@rm -rf $(OBJ_DIR)
	$(VERILATOR) $(VERILATOR_CFLAGS) \
		--top-module $(TOPNAME) $^ \
		$(addprefix -CFLAGS , $(CXXFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
		--Mdir $(OBJ_DIR) --Wno-UNOPTFLAT --public --exe --trace-fst -o $(abspath $(BIN)) $(CSRCS)

sim: $(BIN)
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	echo $(BIN) $(ARGS) $(IMG)
	@$(BIN) $(ARGS) $(IMG)
ifeq ($(CONFIG_GTKWAVE), y)
	gtkwave $(OBJ_DIR)/wave.fst
endif

RTL_FILES ?=
RTL_FILES := $(shell find $(NPC_HOME)/vsrc \
	-type f \( -name "*.v" -o -name "*.sv" -o -name "*.vh" \))

RTL_FILES := $(filter-out $(NPC_HOME)/vsrc/wrapper/%,$(RTL_FILES))
RTL_FILES := $(filter-out \
	$(NPC_HOME)/vsrc/MEM.sv \
	$(NPC_HOME)/vsrc/UART.sv \
	$(NPC_HOME)/vsrc/perf_pkg.sv, \
	$(RTL_FILES))
# RTL_FILES += $(NPC_HOME)/vsrc/wrapper/$(file)_TOP.v
# RTL_FILES += $(NPC_HOME)/vsrc/$(file).sv

sta:
	$(MAKE) -C $(HOME)/yosys-sta/ sta \
		DESIGN=ysyx_25120302 \
		SDC_FILE=$(NPC_HOME)/scripts/my.sdc \
		CLK_FREQ_MHZ=2000 \
		CLK_PORT_NAME=clock \
		O=$(NPC_HOME)/result \
		RTL_FILES="$(RTL_FILES)" 


submodule-sync:
	git submodule sync --recursive
	git submodule update --init --recursive --checkout

perf: submodule-sync
	$(MAKE) sim
	$(MAKE) sta


gdb: $(BIN)
	gdb -s $(BIN) --args $(BIN) $(ARGS) $(IMG)

clean:
	rm -rf $(BUILD_DIR)

.PHONY: submodule-sync perf gdb clean sta sim all


include $(NPC_HOME)/scripts/config.mk
include $(NPC_HOME)/scripts/native.mk
