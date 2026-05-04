`ifdef ___FIFO_FULL_RECOVERY_TEST_SV___
`define ___FIFO_FULL_RECOVERY_TEST_SV___

`include "environment.sv"

program fifo_full_recovery_test(vr_intf vr_if, uart_intf uart_if);
  environment env;
  initial begin
    env = new(vr_if, uart_if);
    env.gen.repeat_count = 0;
    
    // Umple FIFO (8 elemente back-to-back)
    for (int i = 0; i < 8; i++)
      env.gen.write_single_transaction_valid_ready(i[3:0]);
    
    // Apoi trimite cu delay mare ca FIFO să se mai golească parțial
    env.gen.write_single_transaction_valid_ready(4'hA);  // delay random
    env.gen.write_single_transaction_valid_ready(4'hB);
    env.gen.write_single_transaction_valid_ready(4'hC);
    
    env.run();
  end
endprogram

`endif