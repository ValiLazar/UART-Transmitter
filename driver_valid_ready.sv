`define DRIV_IF vr_vif.DRIVER.driver_cb

class driver;
  
  int no_transaction_valid_readys;   // contor
  virtual vr_intf vr_vif;
  mailbox gen2driv;
  
  function new(virtual vr_intf vr_vif, mailbox gen2driv);
    this.vr_vif   = vr_vif;
    this.gen2driv = gen2driv;
  endfunction
  
  // se ruleaza la inceput - asteapta resetul si curata semnalele
  task reset;
    wait(!vr_vif.rst_n);
    $display("--------- [DRIVER] Reset Started ---------");
    
    // direct pe vr_vif (nu prin CB) ca sa fie INSTANT, nu cu skew
    vr_vif.data_i  = 0; 
    vr_vif.valid_i = 0;       
    
    wait(vr_vif.rst_n);
    $display("--------- [DRIVER] Reset Ended ---------");
  endtask
  
  // ia O tranzactie din mailbox si o aplica pe interfata
  task drive;
    transaction_valid_ready trans;
    wait(vr_vif.rst_n);
    
    gen2driv.get(trans);        // blocheaza pana primim ceva
    
    // delay-ul cerut de tranzactie (cu valid_i jos)
    repeat(trans.delay) @(posedge vr_vif.DRIVER.clk);
    
    if (trans.valid_i) begin
      // punem datele si ridicam valid_i
      `DRIV_IF.data_i  <= trans.data;
      `DRIV_IF.valid_i <= 1'b1;
      
      // asteptam handshake (ready_o == 1)
      @(posedge vr_vif.DRIVER.clk iff `DRIV_IF.ready_o);
      
      $display("\tDATA = 0x%0h", trans.data);
      
      // tragem valid jos si curatam data
      `DRIV_IF.valid_i <= 1'b0;
      `DRIV_IF.data_i  <= '0;
      @(posedge vr_vif.DRIVER.clk);   // un ciclu pauza intre tranzactii
    end else begin
      // tranzactie idle, doar asiguram ca valid e jos
      `DRIV_IF.valid_i <= 1'b0;
    end
    
    $display("--------- [DRIVER-TRANSFER: transaction with index %0d ] ---------", no_transaction_valid_readys);
    trans.display();
    no_transaction_valid_readys++;
  endtask
  
  // bucla principala - robusta la reset
  task main;
    forever begin
      fork
        begin
          wait(!vr_vif.rst_n);    // detecteaza inceperea unui reset
        end
        begin
          wait(vr_vif.rst_n); 
          forever drive();        // ruleaza driverul normal
        end
      join_any
      disable fork;               // oprim ce ramane

      // daca am intrat in reset in mijlocul transmisiei, curatam semnalele
      if (!vr_vif.rst_n) begin
        $display("--------- [DRIVER] Reset aplicat in timpul transmisiei! ---------");
        vr_vif.data_i  = 0;
        vr_vif.valid_i = 0;
        wait(vr_vif.rst_n);
        $display("--------- [DRIVER] Reset terminat, reluam ---------");
      end
    end
  endtask
        
endclass