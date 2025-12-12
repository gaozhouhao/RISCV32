#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <Vtop.h>
#include <Vtop___024root.h>
#include <verilated.h>
#include <verilated_fst_c.h>
#include <nvboard.h>

static TOP_NAME dut;

uint32_t pmem_read(uint32_t pc);
void nvboard_bind_all_pins(TOP_NAME* top);

static void single_cycle() {
    dut.clk = 0; dut.eval();
    dut.clk = 1; dut.eval();
    dut.eval();
}

static void reset(int n) {
    //dut.rst = 1;
    while (n -- > 0) single_cycle();
    //dut.rst = 0;
}

int main(int argc, char** argv){
    nvboard_bind_all_pins(&dut);
    nvboard_init();

    //reset(10);

    //Verilated::mkdir("logs");
    
    //VerilatedFstC* tfp = new VerilatedFstC;
    std::unique_ptr<VerilatedFstC> tfp{new VerilatedFstC};
    const std::unique_ptr<VerilatedContext> contextp{new VerilatedContext};    
    const std::unique_ptr<Vtop> top{new Vtop{contextp.get(), "TOP"}};
    
    //contextp->traceEverOn(true);
    //top->trace(tfp.get(), 99);
    //tfp->open("./build/obj_dir/wave.fst");
    
    //while(1){
    while (contextp->time() < 10) {
        top->inst = pmem_read(top->pc);
        printf("PC:%d\n", top->pc);
        printf("INST:%X\n", top->inst);
        printf("IDU->INST:%X\n", dut.rootp->top__DOT__idu__DOT__inst);
        printf("TOP->INST:%X\n", dut.rootp->top__DOT__inst);
        //for(int i = 0; i < 4; i ++){
        //    printf("%X\n", dut.rootp->top__DOT__ram__DOT__register[i]);
        //}
        //printf("---------\n");
        //printf("opcode:%x\n", dut.rootp->top__DOT__rom__DOT__q);
        
        nvboard_update();
        single_cycle();
        
        contextp->timeInc(1);
        //int a = rand() & 1;
        //int b = rand() & 1;
        //top->a = a;
        //top->b = b;
        //top->eval();
        //tfp->dump(contextp->time());
        //printf("a = %d, b = %d, f = %d\n", a, b, top->f);
        //assert(top->f == (a ^ b));
    }
    //tfp->close();
}
