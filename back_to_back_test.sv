`ifdef ___LSB_DATA_TEST_SV___
`define ___LSB_DATA_TEST_SV___

`include "environment.sv"

program back_to_back_test(vr_intf vr_if, uart_intf uart_if);
  environment env;
  initial begin
    env = new(vr_if, uart_if);
    env.gen.repeat_count = 0;
    
    // 4 tranzacții back-to-back (sub FIFO_DEPTH=8)
    // delay=0 forțat
    for (int i = 0; i < 4; i++) begin
      env.gen.trans = new();
      assert(env.gen.trans.randomize() with {
        valid_i == 1;
        delay   == 0;
      });
      env.gen.gen2driv.put(env.gen.trans.do_copy());
    end
    
    env.run();
  end
endprogram

`endif