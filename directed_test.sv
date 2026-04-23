`ifndef __DIRECTED_TEST
`define __DIRECTED_TEST

`include "environment.sv"

program test(vr_intf vr_if, uart_intf uart_if);
  
  environment env;
  
  initial begin
    $display("divider is %0d", `DIVIDER);
    env = new(vr_if, uart_if);
    env.gen.repeat_count = 5;

    env.gen.write_single_transaction_valid_ready(255);
    env.gen.write_single_transaction_valid_ready(0);
    env.gen.write_single_transaction_valid_ready(127);
    env.gen.write_single_transaction_valid_ready(191);
    env.gen.write_single_transaction_valid_ready(63);
    
    env.run();
  end
  
endprogram

`endif