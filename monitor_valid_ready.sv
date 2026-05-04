`define MON_VR vr_vif.MONITOR.monitor_cb

class monitor_valid_ready;

  virtual vr_intf vr_vif;
  mailbox mon2scb;
  coverage colector_coverage;
  int nr_tranazctii;

  function new(virtual vr_intf vr_vif, mailbox mon2scb, coverage colector_coverage);
    this.vr_vif  = vr_vif;
    this.mon2scb = mon2scb;
    this.colector_coverage = colector_coverage;
  endfunction

  task main;
    transaction_valid_ready trans;
    int delay_count;
    
    // Asteptam un ciclu initial dupa reset
    @(`MON_VR);
    delay_count = 0;
    
    forever begin
      // Asteptam pana e handshake (valid && ready) PE ACELASI ciclu de ceas
      // Folosim @(`MON_VR iff ...) - asta avanseaza UN ciclu si verifica.
      // Daca conditia e indeplinita imediat, nu functioneaza corect, deci
      // facem manual:
      
      if (`MON_VR.valid_i && `MON_VR.ready_o) begin
        // Handshake detectat in ciclul curent -> capturam
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
        // Nu e handshake -> contorizam delay
        delay_count++;
      end
      
      // Avansam un ciclu si reluam
      @(`MON_VR);
    end
  endtask

endclass