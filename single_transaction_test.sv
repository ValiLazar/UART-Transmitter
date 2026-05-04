`ifndef __SINGLE_TRANSACTION_TEST
`define __SINGLE_TRANSACTION_TEST

`include "environment.sv"

program test(vr_intf vr_if, uart_intf uart_if);
  
  environment env;
  
  initial begin
    $display("--- Start Test: Single Transaction (Sanity Check) ---");
    $display("divider is %0d", `DIVIDER);
    
    env = new(vr_if, uart_if);
    
    // Setam numarul de tranzactii random la 0 (doar tranzactia directa)
    env.gen.repeat_count = 0; 
    $display("Adaug in coada un singur byte: 0x5");
      
    // Trimitem o singura valoare catre generator (4 biti: 0..15)
    env.gen.write_single_transaction_valid_ready(4'h5);
    
    // Rulam mediul pentru a procesa acea unica tranzactie
    env.run();
    
    $display("--- Test Terminat ---");
  end
  
endprogram

`endif