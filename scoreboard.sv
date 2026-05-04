`ifndef __SCOREBOARD
`define __SCOREBOARD


class scoreboard;
  
  mailbox mon_vr2scb;
  mailbox mon_uart2scb;
  
  int no_transactions;       // tranzactii validate cu succes pe UART
  int no_vr_transactions;    // tranzactii intrate in valid-ready
  int no_errors;             // numar erori detectate
  
  bit [3:0] expected_queue[$];
  

  coverage colector_coverage;
  
  function new(mailbox mon_vr2scb, mailbox mon_uart2scb);
    this.mon_vr2scb   = mon_vr2scb;
    this.mon_uart2scb = mon_uart2scb;
    colector_coverage  = new();
  endfunction

  task collect_vr;
    transaction_valid_ready trans;
    forever begin
      mon_vr2scb.get(trans);
      expected_queue.push_back(trans.data);
      colector_coverage.sample_vr(trans);
      no_vr_transactions++;
      $display("[SCB] Data adaugata in coada: 0x%0h (dimensiune coada: %0d)", trans.data, expected_queue.size());
    end
  endtask
  

  task collect_uart;
    transaction_uart trans;
    forever begin
      mon_uart2scb.get(trans);
      colector_coverage.sample_uart(trans);
      
      if (expected_queue.size() > 0) begin
        bit [3:0] expected_data;
        expected_data = expected_queue.pop_front();
        
        if (expected_data != trans.data) begin
          $error("[SCB-FAIL] Data :: Expected = 0x%0h Actual = 0x%0h", expected_data, trans.data);
          no_errors++;
        end else begin
          $display("[SCB-PASS] Data :: Expected = 0x%0h Actual = 0x%0h", expected_data, trans.data);
        end
      end else begin
        $error("[SCB-FAIL] Date receptionate pe UART fara date asteptate in coada! Data = 0x%0h", trans.data);
        no_errors++;
      end
      
      no_transactions++;
    end
  endtask
  
  task main;
    fork
      collect_vr();
      collect_uart();
    join_any
  endtask

  // ============================================================
  //   VERIFICARE FINALA - se apeleaza din environment.post_test
  // ============================================================
  function void final_check();
    $display("=========================================");
    $display("[SCB] Final check:");
    $display("[SCB]   Tranzactii primite pe valid-ready: %0d", no_vr_transactions);
    $display("[SCB]   Tranzactii primite pe UART       : %0d", no_transactions);
    $display("[SCB]   Tranzactii ramase in coada       : %0d", expected_queue.size());
    $display("[SCB]   Erori detectate                  : %0d", no_errors);
    
    // Daca au ramas date in coada, inseamna ca au fost trimise pe valid-ready
    // dar nu au iesit pe UART => BUG_FIFO_FULL sau BUG_FIFO_SMALLER (date pierdute)
    if (expected_queue.size() != 0) begin
      $error("[SCB-FAIL] %0d date trimise pe valid-ready dar nereceptionate pe UART! Posibil BUG_FIFO_FULL sau BUG_FIFO_SMALLER", expected_queue.size());
      foreach (expected_queue[i])
        $display("[SCB]   coada[%0d] = 0x%0h", i, expected_queue[i]);
    end
    
    if (no_errors == 0 && expected_queue.size() == 0)
      $display("[SCB-PASS-FINAL] *** TOATE TRANZACTIILE AU FOST VERIFICATE CU SUCCES ***");
    else
      $display("[SCB-FAIL-FINAL] *** AU EXISTAT ERORI! ***");
    $display("=========================================");
  endfunction
  
endclass: scoreboard

`endif