`ifdef ___PARITY_TEST_SV___
`define ___PARITY_TEST_SV___

`include "environment.sv"

program parity_test(vr_intf vr_if, uart_intf uart_if);
  environment env;
  initial begin
    env = new(vr_if, uart_if);
    env.gen.repeat_count = 0;
    
    // Valori cu paritate IMPARĂ (^data == 1) — vor expune BUG_PARITY
    env.gen.write_single_transaction_valid_ready(4'h1);  // 0001, paritate=1
    env.gen.write_single_transaction_valid_ready(4'h2);  // 0010, paritate=1
    env.gen.write_single_transaction_valid_ready(4'h7);  // 0111, paritate=1
    env.gen.write_single_transaction_valid_ready(4'hE);  // 1110, paritate=1
    env.gen.write_single_transaction_valid_ready(4'hB);  // 1011, paritate=1
    
    // Si valori cu paritate PARĂ (^data == 0) — control
    env.gen.write_single_transaction_valid_ready(4'h0);  // 0000, paritate=0
    env.gen.write_single_transaction_valid_ready(4'h3);  // 0011, paritate=0
    env.gen.write_single_transaction_valid_ready(4'hF);  // 1111, paritate=0
    
    env.run();
  end
endprogram

`endif