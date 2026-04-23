`define DIVIDER 16
`define DATA_WIDTH 8
//`include "directed_test.sv"
//`include "default_test.sv"
//`include "default_big_test.sv"
`include "directed_test_long_delay.sv"
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
  
  test t1(vr_if, uart_if);
  
  uart_tx #(
    .DATA_WIDTH (8),
    .FIFO_DEPTH (4),
    .DIVIDER    (16),
    .HAS_PARITY (0)
  ) DUT (
    .clk     (clk),
    .rst_n   (rst_n),
    .data_i  (vr_if.data_i),
    .valid_i (vr_if.valid_i),
    .ready_o (vr_if.ready_o),
    .tx      (uart_if.tx)
  );
  
  initial begin 
    $dumpfile("dump.vcd");
    $dumpvars;
  end
  
endmodule
