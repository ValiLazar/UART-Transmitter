`ifdef ___LSB_DATA_TEST_SV___
`define ___LSB_DATA_TEST_SV___

`include "environment.sv"

program lsb_data_test(vr_intf vr_if, uart_intf uart_if);
  environment env;
  initial begin
    env = new(vr_if, uart_if);
    env.gen.repeat_count = 0;
    
    // Perechi care diferă doar prin LSB
    env.gen.write_single_transaction_valid_ready(4'b0000); // 0
    env.gen.write_single_transaction_valid_ready(4'b0001); // 1 — diferă de 0 doar la LSB
    env.gen.write_single_transaction_valid_ready(4'b1110); // E
    env.gen.write_single_transaction_valid_ready(4'b1111); // F — diferă de E doar la LSB
    env.gen.write_single_transaction_valid_ready(4'b0110); // 6
    env.gen.write_single_transaction_valid_ready(4'b0111); // 7
    
    env.run();
  end
endprogram

`endif