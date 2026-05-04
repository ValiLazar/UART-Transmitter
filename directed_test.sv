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
    env.gen.write_single_transaction_valid_ready(15);  // max
    env.gen.write_single_transaction_valid_ready(0);   // min
    env.gen.write_single_transaction_valid_ready(7);   // jumatate
    env.gen.write_single_transaction_valid_ready(11);  // mediu-mare
    env.gen.write_single_transaction_valid_ready(3);   // mic
    
    env.run();
  end
  
endprogram

`endif
