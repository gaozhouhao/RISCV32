#ifndef __TRACE_H__
#define __TRACE_H__


#if CONFIG_PC_TRACE

void pc_trace_init();
void pc_trace_push(vaddr_t pc);
void pc_trace_close();

#endif

#if CONFIG_BRANCH_TRACE

void branch_trace_init();
void branch_trace_push(vaddr_t pc, vaddr_t target, bool taken);
void branch_trace_close();

#endif


#endif