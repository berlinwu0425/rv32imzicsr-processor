#include "Vcpu_tb.h"
#include "verilated.h"
#include "verilated_timing.h"
#include "verilated_vcd_c.h"

int main(int argc, char** argv)
{
    VerilatedContext* contextp = new VerilatedContext;
    contextp->commandArgs(argc, argv);

    Verilated::traceEverOn(true);

    Vcpu_tb* top = new Vcpu_tb{contextp};
    while (!contextp->gotFinish()) {
        top->eval();
        contextp->timeInc(1);
    }
    top->final();
    delete top;
    delete contextp;
    return 0;
}
