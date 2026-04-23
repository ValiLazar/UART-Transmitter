
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
    forever begin
      transaction_valid_ready trans;
        trans = new();

        $display("%0t inainte de a se face valid 1", $time);
      while (`MON_VR.valid_i ==0) begin
      @(posedge vr_vif.clk);
      trans.delay++;
      end
        $display("%0t dupa ce s-a facut valid 1", $time);

      wait( `MON_VR.ready_o == 1);
     /* if (nr_tranazctii ==2) 
      
      $stop;*/
        $display("%0t dupa ce s-a facut ready 1", $time);
        trans.data    = `MON_VR.data_i;
        trans.valid_i = `MON_VR.valid_i;
        $display("[MON_VR] Data capturata: 0x%0h", trans.data);
        mon2scb.put(trans);
        colector_coverage.sample_vr(trans);
         @(posedge vr_vif.clk);
        nr_tranazctii++;
      end
  endtask

endclass