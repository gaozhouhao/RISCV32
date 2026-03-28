#ifndef __NPC_COMMON_H__
#define __NPC_COMMON_H__

#include <stdint.h>
#include <inttypes.h>
#include <stdbool.h>
#include <string.h>

#include <generated/autoconf.h>
#include <macro.h>

#include <assert.h>
#include <stdlib.h>
#include <stdio.h>


typedef MUXDEF(CONFIG_ISA64, uint64_t, uint32_t) word_t;
typedef int32_t sword_t;
#define FMT_WORD MUXDEF(CONFIG_ISA64, "0x%016" PRIx64, "0x%08" PRIx32)

typedef word_t vaddr_t;
typedef uint32_t paddr_t;


#include <debug.h>

#endif
