`ifndef __SCOREBOARD
`define __SCOREBOARD

class scoreboard;
  
  mailbox mon_vr2scb;          // primim de la monitor_vr
  mailbox mon_uart2scb;        // primim de la monitor_uart
  
  int no_transactions;         // cate au iesit corect pe uart
  int no_vr_transactions;      // cate au intrat pe valid-ready
  int no_errors;               // cate erori
  
  bit [3:0] expected_queue[$]; // FIFO cu valorile asteptate
  
  function new(mailbox mon_vr2scb, mailbox mon_uart2scb);
    this.mon_vr2scb   = mon_vr2scb;
    this.mon_uart2scb = mon_uart2scb;
  endfunction

  // ce intra pe valid-ready bagam in coada
  task collect_vr;
    transaction_valid_ready trans;
    forever begin
      mon_vr2scb.get(trans);
      expected_queue.push_back(trans.data);
      no_vr_transactions++;
      $display("[SCB] Data adaugata in coada: 0x%0h (dimensiune coada: %0d)", 
               trans.data, expected_queue.size());
    end
  endtask
  
  // ce iese pe uart comparam cu prima valoare din coada
  task collect_uart;
    transaction_uart trans;
    forever begin
      mon_uart2scb.get(trans);
      
      if (expected_queue.size() > 0) begin
        bit [3:0] expected_data;
        expected_data = expected_queue.pop_front();
        
        if (expected_data != trans.data) begin
          $error("[SCB-FAIL] Data :: Expected = 0x%0h Actual = 0x%0h", 
                 expected_data, trans.data);
          no_errors++;
        end else begin
          $display("[SCB-PASS] Data :: Expected = 0x%0h Actual = 0x%0h", 
                   expected_data, trans.data);
        end
      end else begin
        // a venit ceva pe uart dar nimic in coada -> ciudat
        $error("[SCB-FAIL] Date receptionate pe UART fara date asteptate in coada! Data = 0x%0h", 
               trans.data);
        no_errors++;
      end
      
      no_transactions++;
    end
  endtask
  
  // pornim ambele in paralel
  task main;
    fork
      collect_vr();
      collect_uart();
    join_any
  endtask

  // raport final
  function void final_check();
    $display("=========================================");
    $display("[SCB] Final check:");
    $display("[SCB]   Tranzactii primite pe valid-ready: %0d", no_vr_transactions);
    $display("[SCB]   Tranzactii primite pe UART       : %0d", no_transactions);
    $display("[SCB]   Tranzactii ramase in coada       : %0d", expected_queue.size());
    $display("[SCB]   Erori detectate                  : %0d", no_errors);
    
    // daca au ramas date in coada, DUT-ul le-a inghitit
    if (expected_queue.size() != 0) begin
      $error("[SCB-FAIL] %0d date trimise pe valid-ready dar nereceptionate pe UART!", 
             expected_queue.size());
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