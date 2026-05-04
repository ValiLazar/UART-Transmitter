`ifndef __DEFAULT_BIG_TEST
`define __DEFAULT_BIG_TEST

`include "environment.sv"

program default_big_test(vr_intf vr_if, uart_intf uart_if);
  environment env;
  initial begin
    env = new(vr_if, uart_if);
    env.gen.repeat_count = 50;
    env.run();
    
    $display("[TEST] Tranzactii generate (cu valid=0 sau 1): %0d", env.gen.repeat_count);
    $display("[TEST] Tranzactii procesate de driver: %0d", env.driv.no_transaction_valid_readys);
    $display("[TEST] Tranzactii capturate de monitor VR: %0d", env.mon_vr.nr_tranazctii);
    $display("[TEST] Tranzactii in scoreboard: %0d", env.scb.no_vr_transactions);
  end
endprogram

`endif