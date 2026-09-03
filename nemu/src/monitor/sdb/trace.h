#ifndef __TRACE_H__
#define __TRACE_H__


#if CONFIG_PC_TRACE



void pc_trace_init();
void pc_trace_push(vaddr_t pc);
void pc_trace_close();

#endif


#endif