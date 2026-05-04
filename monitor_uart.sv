`ifndef __MONITOR_UART
`define __MONITOR_UART


`define MON_UART uart_vif.MONITOR.monitor_cb

class monitor_uart;

  // Parametri hardcodati ai DUT-ului (pentru BOUD_RATE=3, DATA_WIDTH=4, HAS_PARITY=1)
  // BIT_PERIOD = 62500000 >> (20 + 3) = 7
  parameter int DIVIDER       = 7;
  parameter int DATA_WIDTH    = 4;
  parameter int HAS_PARITY    = 1;

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

      // -------- IDLE / DELAY --------
      while (`MON_UART.tx) begin
        @(`MON_UART);
        trans.delay++;
      end
      if (trans.delay > 0) begin
        trans.delay--;
      end

      // -------- START BIT --------
      repeat(DIVIDER/2) @(posedge vr_vif.MONITOR.clk);
      assert (`MON_UART.tx == 0)
        else $error("Monitor UART: Start bit error detected!");
      repeat(DIVIDER - DIVIDER/2) @(posedge vr_vif.MONITOR.clk);

      // -------- DATA BITS (MSB first) --------
      // DUT-ul transmite biții incepand cu data[DATA_WIDTH-1] (MSB) catre data[0] (LSB).
      // Vezi uart.v: counter-ul bit_cnt porneste de la DATA_WIDTH-1 si decrementeaza.
      for (int i = DATA_WIDTH - 1; i >= 0; i--) begin
        repeat(DIVIDER/2) @(posedge vr_vif.MONITOR.clk);
        trans.data[i] = `MON_UART.tx;
        repeat(DIVIDER - DIVIDER/2) @(posedge vr_vif.MONITOR.clk);
      end

      // -------- PARITY BIT --------
      if (HAS_PARITY) begin
        repeat(DIVIDER/2) @(posedge vr_vif.MONITOR.clk);
        assert (`MON_UART.tx == ^trans.data)
          else $error("Monitor UART: Parity error! tx=%0b, expected=%0b, data=0x%0h",
                      `MON_UART.tx, ^trans.data, trans.data);
        repeat(DIVIDER - DIVIDER/2) @(posedge vr_vif.MONITOR.clk);
      end

      // -------- STOP BIT (primul) --------
      repeat(DIVIDER/2) @(posedge vr_vif.MONITOR.clk);
      assert (`MON_UART.tx == 1)
        else $error("Monitor UART: Stop bit error detected!");
      repeat(DIVIDER - DIVIDER/2) @(posedge vr_vif.MONITOR.clk);

      // Pentru NO_BITS_STOP=2, al doilea bit de stop va fi numarat ca delay in iteratia urmatoare.

      $display("[MON_UART] Data capturata: 0x%0h, delay=%0d", trans.data, trans.delay);
      mon2scb.put(trans);

      colector_coverage.sample_uart(trans);
    end
  endtask

endclass

`endif