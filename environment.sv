`ifndef __ENVIRONMENT
`define __ENVIRONMENT


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
    join_any
  endtask
  
  task post_test();
    //wait(gen_ended.triggered);
  //  wait(gen.repeat_count == driv.no_transaction_valid_readys);
    //wait(scb.no_transactions == gen.repeat_count);
   // wait(scb.expected_queue.size() == 0);
    #4000;
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