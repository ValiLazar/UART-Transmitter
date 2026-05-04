`ifndef __DIRECTED_TEST_LONG_DELAY
`define __DIRECTED_TEST_LONG_DELAY

`include "environment.sv"

program directed_test_long_delay(vr_intf vr_if, uart_intf uart_if);
  
  environment env;
  
  initial begin
    env = new(vr_if, uart_if);
    env.gen.repeat_count = 0;  

    // Valori pe 4 biti (0..15) - alternand pattern-uri de biti
    env.gen.write_single_transaction_valid_ready(4'hA);  // 1010
    env.gen.write_single_transaction_valid_ready(4'h5);  // 0101
    env.gen.write_single_transaction_valid_ready(4'hF);  // 1111
    env.gen.write_single_transaction_valid_ready(4'h0);  // 0000
    env.gen.write_single_transaction_valid_ready(4'h8);  // 1000
    
    env.run();
  end
  
endprogram

`endif
