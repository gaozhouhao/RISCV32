
#ifndef __NPC_MEMORY_H__
#define __NPC_MEMORY_H__

#include <npc_common.h>

extern uint32_t memory[];

#ifdef __cplusplus
extern "C"{
#endif
unsigned int pmem_read(unsigned int raddr);
#ifdef __cplusplus
}
#endif

#endif
