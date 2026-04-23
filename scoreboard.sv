`ifndef __SCOREBOARD
`define __SCOREBOARD


class scoreboard;
  
  mailbox mon_vr2scb;
  mailbox mon_uart2scb;
  
  int no_transactions;
  
  bit [7:0] expected_queue[$];
  

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
      $display("[SCB] Data adaugata in coada: 0x%0h (dimensiune coada: %0d)", trans.data, expected_queue.size());
    end
  endtask
  

  task collect_uart;
    transaction_uart trans;
    forever begin
      mon_uart2scb.get(trans);
      colector_coverage.sample_uart(trans);
      
      if (expected_queue.size() > 0) begin
        bit [7:0] expected_data;
        expected_data = expected_queue.pop_front();
        
        if (expected_data != trans.data)
          $error("[SCB-FAIL] Data :: Expected = 0x%0h Actual = 0x%0h", expected_data, trans.data);
        else
          $display("[SCB-PASS] Data :: Expected = 0x%0h Actual = 0x%0h", expected_data, trans.data);
      end else begin
        $error("[SCB-FAIL] Date receptionate pe UART fara date asteptate in coada! Data = 0x%0h", trans.data);
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
  
endclass: scoreboard

`endif