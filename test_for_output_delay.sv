`ifndef __DIRECTED_TEST
`define __DIRECTED_TEST

`include "environment.sv"

program test(vr_intf vr_if, uart_intf uart_if);
  
  environment env;
  
  initial begin
    $display("divider is %0d", `DIVIDER);
    env = new(vr_if, uart_if);
    env.gen.repeat_count = 5;

    // Valori pe 4 biti (0..15)
    env.gen.write_single_transaction_valid_ready(15);
    @(vr_if.clk);
    env.gen.write_single_transaction_valid_ready(0);
    repeat(30) @(vr_if.clk);
    env.gen.write_single_transaction_valid_ready(7);
    env.gen.write_single_transaction_valid_ready(11);
    env.gen.write_single_transaction_valid_ready(3);
    
    env.run();
  end
  
endprogram

`endif
