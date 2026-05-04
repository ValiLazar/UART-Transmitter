program mid_transmission_reset_test(vr_intf vr_if, uart_intf uart_if);
  environment env;
  initial begin
    env = new(vr_if, uart_if);
    env.gen.repeat_count = 0;
    
    // Test 1: reset în timpul start bit (după ~3 cicli)
    env.gen.write_single_transaction_valid_ready(4'hA);
    repeat(10) @(posedge vr_if.clk);
    force vr_if.rst_n = 0;
    repeat(5) @(posedge vr_if.clk);
    release vr_if.rst_n;
    repeat(20) @(posedge vr_if.clk);
    
    // Test 2: reset în timpul data bits (după ~25 cicli din start)
    env.gen.write_single_transaction_valid_ready(4'h5);
    repeat(25) @(posedge vr_if.clk);
    force vr_if.rst_n = 0;
    repeat(5) @(posedge vr_if.clk);
    release vr_if.rst_n;
    repeat(20) @(posedge vr_if.clk);
    
    // Test 3: reset în timpul parity (după ~50 cicli)
    env.gen.write_single_transaction_valid_ready(4'hF);
    repeat(50) @(posedge vr_if.clk);
    force vr_if.rst_n = 0;
    repeat(5) @(posedge vr_if.clk);
    release vr_if.rst_n;
    repeat(20) @(posedge vr_if.clk);
    
    // După toate reset-urile, trimite o tranzacție normală
    env.gen.write_single_transaction_valid_ready(4'h7);
    
    env.run();
  end
endprogram