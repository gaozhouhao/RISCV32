#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <Vtop.h>
#include <Vtop___024root.h>
#include <verilated.h>
#include <verilated_fst_c.h>
#include <nvboard.h>

const std::unique_ptr<VerilatedContext> contextp{new VerilatedContext};    
const std::unique_ptr<Vtop> top{new Vtop{contextp.get(), "TOP"}};
uint32_t pmem_read(uint32_t pc);
void nvboard_bind_all_pins(TOP_NAME* top);

static void single_cycle() {
    top->clk = 0; top->eval();
    top->clk = 1; top->eval();
    top->eval();
}

static void reset(int n) {
    //dut.rst = 1;
    while (n -- > 0) single_cycle();
    //dut.rst = 0;
}

int main(int argc, char** argv){
    //nvboard_bind_all_pins(top.get());
    //nvboard_init();

    //reset(10);
    Verilated::mkdir("logs");
    //std::unique_ptr<VerilatedFstC> tfp{new VerilatedFstC};
    VerilatedFstC* tfp = new VerilatedFstC;
    contextp->traceEverOn(true);
    top->trace(tfp, 99);
    tfp->open("./build/obj_dir/wave.fst");
    
    //while(1){
    while (contextp->time() < 16) {
        top->inst = pmem_read(top->pc/4);
        tfp->dump(contextp->time());
        contextp->timeInc(1);       
        top->eval();
        printf("PC:%d\n", top->pc);
        printf("INST:%X\n", top->inst);
        //for(int i = 0; i < 4; i ++){
        //    printf("%X\n", dut.rootp->top__DOT__ram__DOT__register[i]);
        //}
        //printf("---------\n");
        //printf("opcode:%x\n", dut.rootp->top__DOT__rom__DOT__q);
        //nvboard_update();
        single_cycle();
    }

    tfp->close();
}
