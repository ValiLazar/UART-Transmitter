`ifndef __MONITOR_UART
`define __MONITOR_UART


`define MON_UART uart_vif.MONITOR.monitor_cb
`define DIVIDER 16
`define DATA_WIDTH 8
`define HAS_PARITY 0

class monitor_uart;

  virtual vr_intf   vr_vif;
  virtual uart_intf uart_vif;
  mailbox mon2scb;

  coverage colector_coverage;

  function new(virtual vr_intf vr_vif, virtual uart_intf uart_vif, mailbox mon2scb, coverage colector_coverage);
    this.vr_vif   = vr_vif;
    this.uart_vif = uart_vif;
    this.mon2scb  = mon2scb;
    this.colector_coverage = colector_coverage;
  endfunction

  task main;
    forever begin
      transaction_uart trans;
      trans = new();
        while( `MON_UART.tx)begin // se calculeaza intarzierea dintre doua tranzactii
          @(`MON_UART);
          trans.delay++;
        end
        if(trans.delay > 0) begin
          trans.delay--; // se scade 1 pentru ca s-a incrementat si pentru tranzactia curenta
        end

        repeat(`DIVIDER/2) @(posedge vr_vif.MONITOR.clk);//se asteapta pana la mijlocul bitului de start
         assert (`MON_UART.tx == 0) // Verificăm bitul de start
         else $error("Monitor UART: Start bit error detected!");
          repeat(`DIVIDER - `DIVIDER/2) @(posedge vr_vif.MONITOR.clk); //se astepata pana la finalul bitului de start
        for (int i = 0; i < `DATA_WIDTH; i++) begin // preluarea datelor
          repeat(`DIVIDER/2) @(posedge vr_vif.MONITOR.clk);//se asteapta pana la mijlocul bitului de date
          trans.data[i] = `MON_UART.tx;
          repeat(`DIVIDER - `DIVIDER/2) @(posedge vr_vif.MONITOR.clk);//se asteapta pana la finalul bitului de date
        end

        if (`HAS_PARITY) begin
          repeat(`DIVIDER/2) @(posedge vr_vif.MONITOR.clk);//se asteapta pana la mijlocul bitului de paritate
          assert (`MON_UART.tx == ^trans.data) // Verificăm bitul de paritate
            else $error("Monitor UART: Parity error detected!");
          repeat(`DIVIDER - `DIVIDER/2) @(posedge vr_vif.MONITOR.clk);
        end

        repeat(`DIVIDER/2) @(posedge vr_vif.MONITOR.clk);//se asteapta pana la mijlocul bitului de stop
        assert (`MON_UART.tx == 1) // Verificăm bitul de stop
          else $error("Monitor UART: Stop bit error detected!");
        repeat(`DIVIDER - `DIVIDER/2) @(posedge vr_vif.MONITOR.clk);

        $display("[MON_UART] Data capturata: 0x%0h", trans.data);
        mon2scb.put(trans);

  colector_coverage.sample_uart(trans);
      
    end
  endtask

endclass

`endif