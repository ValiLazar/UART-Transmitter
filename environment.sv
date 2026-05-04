`ifndef __ENVIRONMENT
`define __ENVIRONMENT

// macro-uri globale - daca nu sunt definite altundeva, pune valorile astea
`ifndef DIVIDER
  `define DIVIDER 7
`endif
`ifndef DATA_WIDTH
  `define DATA_WIDTH 4
`endif
`ifndef HAS_PARITY
  `define HAS_PARITY 1
`endif
`ifndef NO_BITS_STOP
  `define NO_BITS_STOP 2
`endif

// includem toate componentele in ordinea dependentelor
`include "transaction_valid_ready.sv"
`include "transaction_uart.sv"
`include "generator.sv"
`include "driver_valid_ready.sv"
`include "coverage.sv"
`include "monitor_valid_ready.sv"
`include "monitor_uart.sv"
`include "scoreboard.sv"

class environment;
  
  // componentele
  generator            gen;
  driver               driv;
  monitor_valid_ready  mon_vr;
  monitor_uart         mon_uart;
  scoreboard           scb;
  
  // mailbox-urile care leaga componentele
  mailbox gen2driv;
  mailbox mon_vr2scb;
  mailbox mon_uart2scb;
  
  event gen_ended;
  
  coverage colector_coverage;
  
  // handles catre interfete
  virtual vr_intf   vr_vif;
  virtual uart_intf uart_vif;
  
  // creeaza si conecteaza tot
  function new(virtual vr_intf vr_vif, virtual uart_intf uart_vif);
    this.vr_vif   = vr_vif;
    this.uart_vif = uart_vif;
    
    gen2driv     = new();
    mon_vr2scb   = new();
    mon_uart2scb = new();
    
    colector_coverage = new();    // important: inainte de monitoare

    gen      = new(gen2driv, gen_ended);
    driv     = new(vr_vif, gen2driv);
    mon_vr   = new(vr_vif, mon_vr2scb, colector_coverage);
    mon_uart = new(vr_vif, uart_vif, mon_uart2scb, colector_coverage);
    scb      = new(mon_vr2scb, mon_uart2scb);
  endfunction
  
  // pregatire (resetul)
  task pre_test();
    driv.reset();
  endtask
  
  // pornim toate componentele in paralel
  task test();
    fork 
      gen.main();
      driv.main();
      mon_vr.main();
      mon_uart.main();
      scb.main();      
    join_none
  endtask
  
  // asteptam ca tot ce e in DUT sa iasa
  task post_test();
    fork
      // asteptam coada goala 200 cicluri consecutive
      begin : wait_queue_empty
        int idle_count;
        idle_count = 0;
        while (idle_count < 200) begin
          @(posedge vr_vif.clk);
          if (scb.expected_queue.size() == 0)
            idle_count++;
          else
            idle_count = 0;
        end
      end
      // siguranta - max 1ms
      begin : timeout
        #10000000;
        $display("[ENV] Timeout in post_test (1ms) - coada inca nevida");
      end
    join_any
    disable fork;
    
    scb.final_check();
    colector_coverage.print_coverage();
  endtask 
  
  // ruleaza in ordine
  task run;
    pre_test();
    test();
    post_test();
    $display("[ENV] Sumar: gen=%0d, driv=%0d, mon_vr=%0d, scb=%0d, mon_uart=%0d",
             gen.repeat_count, 
             driv.no_transaction_valid_readys,
             mon_vr.nr_tranazctii,
             scb.no_vr_transactions,
             scb.no_transactions);
    $finish;
  endtask
  
endclass

`endif