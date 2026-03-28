#ifndef __NPC_CPU_H__
#define __NPC_CPU_H__

#include <npc_common.h>

void cpu_exec(uint64_t n);

void set_npc_state(int state, uint32_t pc, int halt_ret);
//void invalid_inst(vaddr_t thispc);


#endif

