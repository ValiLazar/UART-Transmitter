`ifndef __FIFO_STRESS_TEST
`define __FIFO_STRESS_TEST

`include "environment.sv"

// Test special pentru a stresa FIFO-ul (FIFO_DEPTH=8) si a detecta:
//   - BUG_FIFO_FULL    (ready ramane mereu 1 -> date suprascrise)
//   - BUG_FIFO_SMALLER (ultimele 2 elemente nu se populeaza)
//   - BUG_CORRPUTED_DATA (20% din date sunt modificate)
// Trimitem 16 valori distincte, fara delay -> umplem FIFO-ul de mai multe ori.

program test(vr_intf vr_if, uart_intf uart_if);
  
  environment env;
  
  initial begin
    $display("--- Start Test: FIFO Stress Test ---");
    $display("divider is %0d", `DIVIDER);
    env = new(vr_if, uart_if);

    env.gen.repeat_count = 0; // doar tranzactii directe
    
    // 16 valori distincte - toate cele 16 valori posibile pe 4 biti.
    // Cu trimitere rapida (delay=0), FIFO-ul se umple si trebuie sa-l golim.
    for (int i = 0; i < 16; i++) begin
      env.gen.write_single_transaction_valid_ready(i[3:0]);
    end
    
    env.run();
    
    $display("--- Test Terminat ---");
  end
  
endprogram

`endif