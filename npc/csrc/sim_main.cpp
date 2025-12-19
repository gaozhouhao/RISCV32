#include <assert.h>
#include <Vtop.h>
#include <Vtop___024root.h>
#include <verilated.h>
#include <verilated_fst_c.h>
#include <nvboard.h>

#include "svdpi.h"
#include "Vtop__Dpi.h"

const std::unique_ptr<VerilatedContext> contextp{new VerilatedContext};    
const std::unique_ptr<Vtop> top{new Vtop{contextp.get(), "TOP"}};
uint32_t pmem_read(uint32_t pc);
void nvboard_bind_all_pins(TOP_NAME* top);

static void single_cycle() {
    top->clk = 0; top->eval(); contextp->timeInc(1);
    top->clk = 1; top->eval(); contextp->timeInc(1);
    top->eval();
}

static void reset(int n) {
    //dut.rst = 1;
    while (n -- > 0) single_cycle();
    //dut.rst = 0;
}

extern uint32_t memory[1<<18];

int flag = 0;
void ebreak(svBit is_ebreak){ flag = is_ebreak; }

int main(int argc, char** argv){
    int ret = 0;
    FILE *fp = NULL; 
    top->clk = 0;
    if(argc == 1) fp = fopen("./csrc/sum.bin", "rb");
    if(argc == 2) fp = fopen(argv[1], "rb");
    if(fp == NULL) printf("File Open Failure!\n\n");
    size_t n = fread(memory, 1, sizeof(memory), fp);
    fclose(fp);
    if(argc == 1) memory[0x228/4] = 0x00100073;
    //nvboard_bind_all_pins(top.get());
    //nvboard_init();

    //reset(10);
    Verilated::mkdir("logs");
    VerilatedFstC* tfp = new VerilatedFstC;
    contextp->traceEverOn(true);
    top->trace(tfp, 99);
    tfp->open("./build/obj_dir/wave.fst");
    int cnt = 0;
    while (contextp->time() < 50000) {
        cnt ++;
        //top->inst = pmem_read(top->pc);
        top->clk = 1;
        top->eval();
        contextp->timeInc(1);
        top->clk = 0;
        top->eval();
        contextp->timeInc(1);
        //printf("----%x\n", top->inst);
        //top->eval();
        //nvboard_update();
        //single_cycle();
        tfp->dump(contextp->time());
        if(flag) {
            ret = 1;
            //for(int i = 0; i < 32; i ++){
            //    printf("x%d: %08x\n", i, top->rootp->top__DOT__regfile__DOT__rf[i]);
            //}
            tfp->close();
            break;
        }
    }
    if(ret) printf("\n---------HIT GOOD TRAP------------\n");
    else printf("\n---------HIT BAD TRAP------------\n");
    tfp->close();
}
