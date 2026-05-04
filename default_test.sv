`ifndef __DEFAULT_TEST
`define __DEFAULT_TEST

`include "environment.sv"

program default_test(vr_intf vr_if, uart_intf uart_if);
  
  environment env;
  
  initial begin
    $display("divider is %0d", `DIVIDER);
    env = new(vr_if, uart_if);
    env.gen.repeat_count = 5;
    
    env.run();
  end
  
endprogram

`endif