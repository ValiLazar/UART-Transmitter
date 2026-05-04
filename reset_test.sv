`ifndef __RESET_TEST
`define __RESET_TEST

`include "environment.sv"


program reset_test(vr_intf vr_if, uart_intf uart_if);
  environment env;
  
  initial begin
    $display("--- Start Test: Reset During TX ---");
    env = new(vr_if, uart_if);
    env.gen.repeat_count = 0; 
    
    // 1. Trimitem o data ca sa incepem transmisia
    env.gen.write_single_transaction_valid_ready(4'ha);
    
    // 2. Asteptam putin ca UART-ul sa inceapa sa trimita (ex: asteptam 20 de tacte)
    repeat(20) @(posedge vr_if.clk);
    
    // 3. FORTAM RESETUL IN MIJLOCUL TRANSMISIEI
    $display("!!! APLICAM RESET IN TIMPUL TRANSMISIEI !!!");
    force vr_if.rst_n = 0;   // Forțează semnalul în 0, ignorând testbench-ul principal
    repeat(5) @(posedge vr_if.clk);
    release vr_if.rst_n;     // Eliberează semnalul, permițându-i să revină la starea naturală (1)
    
    // 4. Mai trimitem o data ca sa vedem daca isi revine dupa reset
    env.gen.write_single_transaction_valid_ready(4'h3);
    
    env.run();
    $display("--- Test Terminat ---");
  end
endprogram

`endif