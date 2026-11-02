IMAGE = branchsim

BATCH_MODE ?= 0

OFFSET_WIDTH ?= 2
INDEX_WIDTH  ?= 5
SET_WIDTH    ?= 5

CPPSRCS = $(wildcard *.c)
CPPSRCS += $(wildcard *.cpp)

CPPFLAGS = -g -O0 -std=c++11 -DOFFSET_WIDTH=$(OFFSET_WIDTH) -DINDEX_WIDTH=$(INDEX_WIDTH) -DSET_WIDTH=$(SET_WIDTH)

ifeq ($(BATCH_MODE), 1)
  CPPFLAGS += -DBATCH_MODE
endif

run:
	gcc $(CPPSRCS) $(CPPFLAGS) -o $(IMAGE)
	./$(IMAGE)

clean:
	rm -f $(IMAGE) 

.PHONY : run








