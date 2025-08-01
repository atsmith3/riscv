#include "Vcore_top.h"
#include "verilated_vcd_c.h"
#include <cstdlib>
#include <iostream>
#include <memory>
#include <stdlib.h>
#include <verilated.h>

#define MAX_SIM_TIME 100
#define SIM_START_TIME 10
uint64_t simulation_time = 0;
uint64_t clock_count = 0;

void reset_dut(Vcore_top *core_top, uint64_t sim_time) {
  core_top->rst_n = 1;
  if (sim_time >= 3 && sim_time < 6) {
    core_top->rst_n = 0;
    core_top->mem_rdata = 0;
    core_top->mem_resp = 0;
  }
}

int main(int argc, char **argv, char **env) {
  srand(time(nullptr));
  Verilated::commandArgs(argc, argv);
  Vcore_top *core_top = new Vcore_top();

  Verilated::traceEverOn(true);
  VerilatedVcdC *m_trace = new VerilatedVcdC();
  core_top->trace(m_trace, 99);
  Verilated::mkdir("trace");
  m_trace->open("trace/waveform.vcd");

  while (simulation_time < MAX_SIM_TIME) {
    reset_dut(core_top, simulation_time);
    core_top->clk ^= 1;
    core_top->eval();

    if (core_top->clk == 1) {
      if (simulation_time >= SIM_START_TIME) {
      }
    }
    m_trace->dump(simulation_time);
    simulation_time++;
  }

  m_trace->close();
  // Verilated::mkdir("logs");
  // core_top->coveragep()->write("logs/coverage.dat");

  if (core_top)
    delete core_top;
  if (m_trace)
    delete m_trace;
  return 0;
}
