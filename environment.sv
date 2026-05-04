`ifndef __ENVIRONMENT
`define __ENVIRONMENT

// Macro-uri globale ale verification environment-ului.
`ifndef DIVIDER
  `define DIVIDER 7        // BIT_PERIOD = 62500000 >> (20+3) = 7 tacte/bit
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


`include "transaction_valid_ready.sv"
`include "transaction_uart.sv"
`include "generator.sv"
`include "driver_valid_ready.sv"
`include "coverage.sv"
`include "monitor_valid_ready.sv"
`include "monitor_uart.sv"
`include "scoreboard.sv"
 
class environment;
  
  generator            gen;
  driver               driv;
  monitor_valid_ready  mon_vr;
  monitor_uart         mon_uart;
  scoreboard           scb;
  
  mailbox gen2driv;
  mailbox mon_vr2scb;
  mailbox mon_uart2scb;
  
  event gen_ended;

  coverage colector_coverage;
  
  virtual vr_intf   vr_vif;
  virtual uart_intf uart_vif;
  
  function new(virtual vr_intf vr_vif, virtual uart_intf uart_vif);
    this.vr_vif   = vr_vif;
    this.uart_vif = uart_vif;
    
    gen2driv     = new();
    mon_vr2scb   = new();
    mon_uart2scb = new();
    
    colector_coverage = new();

    gen      = new(gen2driv, gen_ended);
    driv     = new(vr_vif, gen2driv);
    mon_vr   = new(vr_vif, mon_vr2scb, colector_coverage);
    mon_uart = new(vr_vif, uart_vif, mon_uart2scb, colector_coverage);
    scb      = new(mon_vr2scb, mon_uart2scb);
  endfunction
  
  task pre_test();
    driv.reset();
  endtask
  
  task test();
    fork 
      gen.main();
      driv.main();
      mon_vr.main();
      mon_uart.main();
      scb.main();      
    join_none
  endtask
  
  task post_test();
    // Asteptam pana cand coada e goala (toate datele au fost transmise pe UART)
    // SAU pana la timeout. Daca apare timeout cu coada nevida -> bug.
    fork
      begin : wait_queue_empty
        // Asteptam ca coada de scoreboard sa devina goala SI sa nu mai vina
        // tranzactii noi pe valid-ready (idle suficient timp).
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
      begin : timeout
        // Timeout maxim: 1ms = ar trebui sa ajunga pentru orice test rezonabil
        #10000000;
        $display("[ENV] Timeout in post_test (1ms) - coada inca nevida");
      end
    join_any
    disable fork;
    
    scb.final_check();
    colector_coverage.print_coverage();
  endtask 
  
  task run;
    pre_test();
    test();
    post_test();
    $finish;
  endtask
  
endclass

`endif