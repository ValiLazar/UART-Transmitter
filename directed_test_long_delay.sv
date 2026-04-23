`ifndef __DIRECTED_TEST_LONG_DELAY
`define __DIRECTED_TEST_LONG_DELAY

`include "environment.sv"

program test(vr_intf vr_if, uart_intf uart_if);
  
  environment env;
  
  initial begin
    env = new(vr_if, uart_if);
    env.gen.repeat_count = 0;  
    env.gen.write_single_transaction_valid_ready(8'hAA);
    env.gen.write_single_transaction_valid_ready(8'h55);
    env.gen.write_single_transaction_valid_ready(8'hFF);
    env.gen.write_single_transaction_valid_ready(8'h00);
    env.gen.write_single_transaction_valid_ready(8'h80);
    
    env.run();
  end
  
endprogram

`endif