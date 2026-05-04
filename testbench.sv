// Macro-urile (DIVIDER, DATA_WIDTH, HAS_PARITY, NO_BITS_STOP) sunt definite
// in environment.sv care e inclus de fiecare test. Nu trebuie sa le definim aici.

`include "counter.v"
`include "uart.v"

//`include "directed_test.sv"
//`include "default_test.sv"
//`include "default_big_test.sv"
//`include "directed_test_long_delay.sv"
//`include "single_transaction_test.sv"
//`include "fifo_stress_test.sv"

module testbench;

  bit clk;
  bit rst_n;

  always #5 clk = ~clk;

  initial begin
    rst_n = 0;
    #20 rst_n = 1;
  end

  vr_intf   vr_if(clk, rst_n);
  uart_intf uart_if(clk, rst_n);

  //test t1(vr_if, uart_if);
  
  default_big_test t1(vr_if, uart_if);
  //directed_test_long_delay(vr_if,uart_if);

  // DUT-ul nou: modulul "uart" 
  uart #(
    .DATA_WIDTH  (4),
    .FIFO_DEPTH  (8),
    .BOUD_RATE   (3),    // -> BIT_PERIOD = 7 tacte
    .HAS_PARITY  (1),
    .NO_BITS_STOP(2)
  ) DUT (
    .clk     (clk),
    .rst_n   (rst_n),
    .data_i  (vr_if.data_i),
    .valid   (vr_if.valid_i),    // mapare: valid_i (interfata) -> valid (DUT)
    .ready   (vr_if.ready_o),    // mapare: ready_o (interfata) -> ready (DUT)
    .tx      (uart_if.tx)
  );

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end

endmodule