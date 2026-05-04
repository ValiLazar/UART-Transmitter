`define MON_VR vr_vif.MONITOR.monitor_cb

class monitor_valid_ready;

  virtual vr_intf vr_vif;
  mailbox mon2scb;            // catre scoreboard
  coverage colector_coverage;
  int nr_tranazctii;

  function new(virtual vr_intf vr_vif, mailbox mon2scb, coverage colector_coverage);
    this.vr_vif  = vr_vif;
    this.mon2scb = mon2scb;
    this.colector_coverage = colector_coverage;
  endfunction

  // detecteaza handshake-uri si le raporteaza
  task main;
    transaction_valid_ready trans;
    int delay_count;
    
    @(`MON_VR);                 // un ciclu sa treaca dupa reset
    delay_count = 0;
    
    forever begin
      // pe fiecare ciclu, verificam daca e handshake
      if (`MON_VR.valid_i && `MON_VR.ready_o) begin
        trans = new();
        trans.data    = `MON_VR.data_i;
        trans.valid_i = `MON_VR.valid_i;
        trans.delay   = delay_count;
        
        $display("[MON_VR] %0t Handshake: data=0x%0h delay=%0d", 
                 $time, trans.data, delay_count);
        
        mon2scb.put(trans);
        colector_coverage.sample_vr(trans);
        nr_tranazctii++;
        delay_count = 0;
      end else begin
        delay_count++;          // numaram cate cicluri de idle
      end
      
      @(`MON_VR);               // avansam un ciclu
    end
  endtask

endclass