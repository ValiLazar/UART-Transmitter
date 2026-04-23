`define DRIV_IF vr_vif.DRIVER.driver_cb

class driver;
  
  int no_transaction_valid_readys;
  virtual vr_intf vr_vif;
  mailbox gen2driv;
  
  function new(virtual vr_intf vr_vif, mailbox gen2driv);
    this.vr_vif   = vr_vif;
    this.gen2driv = gen2driv;
  endfunction
  
  task reset;
    wait(!vr_vif.rst_n);
    $display("--------- [DRIVER] Reset Started ---------");
    `DRIV_IF.data_i  <= 0;
    `DRIV_IF.valid_i <= 0;       
    wait(vr_vif.rst_n);
    $display("--------- [DRIVER] Reset Ended ---------");
  endtask
  
  task drive;
    transaction_valid_ready trans;
    wait(vr_vif.rst_n);
    
    gen2driv.get(trans);
    
    repeat(trans.delay) @(posedge vr_vif.DRIVER.clk);
    
    if (trans.valid_i) begin
      @(posedge vr_vif.DRIVER.clk);
      wait(`DRIV_IF.ready_o);
      `DRIV_IF.data_i  <= trans.data;
      `DRIV_IF.valid_i <= trans.valid_i;
      if(trans.valid_i) begin
      $display("\tDATA = 0x%0h", trans.data);
      @(posedge vr_vif.DRIVER.clk iff `DRIV_IF.ready_o);
      `DRIV_IF.valid_i <= 0;
      end
    end
    $display("--------- [DRIVER-TRANSFER: transaction with index %0d and with following data was transferred ] ---------", no_transaction_valid_readys);
    trans.display();
    $display("-----------------------------------------");
    no_transaction_valid_readys++;
  endtask
  
  task main;
    forever begin
      fork
        begin
          wait(!vr_vif.rst_n);
        end
        begin
          forever drive();
        end
      join_any
      disable fork;
    end
  endtask
        
endclass