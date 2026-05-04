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
    // Folosim vr_vif direct pentru a ocoli delay-ul blocului de ceas!
    vr_vif.data_i  = 0; 
    vr_vif.valid_i = 0;       
    wait(vr_vif.rst_n);
    $display("--------- [DRIVER] Reset Ended ---------");
  endtask
  
task drive;
    transaction_valid_ready trans;
    wait(vr_vif.rst_n);
    
    gen2driv.get(trans);
    
    // 1. Așteptăm numărul exact de cicli de delay (dacă e 0, nu așteaptă deloc)
    repeat(trans.delay) @(posedge vr_vif.DRIVER.clk);
    
    if (trans.valid_i) begin
      // 2. Punem datele pe interfață IMEDIAT (fără @posedge suplimentar aici)
      `DRIV_IF.data_i  <= trans.data;
      `DRIV_IF.valid_i <= trans.valid_i;
      
      // 3. Așteptăm frontul de ceas în care READY este 1 (handshake valid-ready)
      // Folosim "iff" pentru a ne asigura că eșantionăm corect starea semnalului ready_o
      @(posedge vr_vif.DRIVER.clk iff `DRIV_IF.ready_o);
      
      // 4. Afișăm data și tragem valid în jos pentru a termina tranzacția
      $display("\tDATA = 0x%0h", trans.data);
      `DRIV_IF.valid_i <= 0;
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
          wait(vr_vif.rst_n); 
          forever drive();
        end
      join_any
      disable fork; 

      if (!vr_vif.rst_n) begin
        $display("--------- [DRIVER] Reset aplicat in timpul transmisiei! Curatam semnalele... ---------");
        
        // Folosim vr_vif direct, ca să oprim instantaneu semnalele
        vr_vif.data_i  = 0;
        vr_vif.valid_i = 0;
        
        wait(vr_vif.rst_n);
        $display("--------- [DRIVER] Resetul a luat sfarsit, reluam functionarea ---------");
      end
    end
  endtask
        
endclass