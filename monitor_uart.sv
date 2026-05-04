`ifndef __MONITOR_UART
`define __MONITOR_UART

`define MON_UART uart_vif.MONITOR.monitor_cb

class monitor_uart;

  // parametrii hardcodati ai DUT-ului
  parameter int DIVIDER       = 7;   // 7 tacte per bit
  parameter int DATA_WIDTH    = 4;
  parameter int HAS_PARITY    = 1;

  virtual vr_intf   vr_vif;
  virtual uart_intf uart_vif;
  mailbox mon2scb;
  coverage colector_coverage;

  function new(virtual vr_intf vr_vif, virtual uart_intf uart_vif, 
               mailbox mon2scb, coverage colector_coverage);
    this.vr_vif   = vr_vif;
    this.uart_vif = uart_vif;
    this.mon2scb  = mon2scb;
    this.colector_coverage = colector_coverage;
  endfunction

  // decodifica linia tx in tranzactii uart
  task main;
    forever begin
      transaction_uart trans;
      trans = new();

      // IDLE - asteptam pana cade tx (= start bit)
      while (`MON_UART.tx) begin
        @(`MON_UART);
        trans.delay++;
      end
      if (trans.delay > 0) trans.delay--;   // ultima iteratie nu conteaza

      // START BIT - esantionam la mijloc, verificam ca e 0
      repeat(DIVIDER/2) @(`MON_UART);
      assert (`MON_UART.tx == 0)
        else $error("Monitor UART: Start bit error!");
      repeat(DIVIDER - DIVIDER/2) @(`MON_UART);

      // DATA BITS - DUT-ul trimite MSB primul (data[3], data[2], ...)
      for (int i = DATA_WIDTH - 1; i >= 0; i--) begin
        repeat(DIVIDER/2) @(`MON_UART);
        trans.data[i] = `MON_UART.tx;
        repeat(DIVIDER - DIVIDER/2) @(`MON_UART);
      end

      // PARITY - tx trebuie sa fie XOR pe data
      if (HAS_PARITY) begin
        repeat(DIVIDER/2) @(`MON_UART);
        assert (`MON_UART.tx == ^trans.data)
          else $error("Monitor UART: Parity error! tx=%0b, expected=%0b, data=0x%0h",
                      `MON_UART.tx, ^trans.data, trans.data);
        repeat(DIVIDER - DIVIDER/2) @(`MON_UART);
      end

      // STOP BIT - tx trebuie sa fie 1
      repeat(DIVIDER/2) @(`MON_UART);
      assert (`MON_UART.tx == 1)
        else $error("Monitor UART: Stop bit error!");
      repeat(DIVIDER - DIVIDER/2) @(`MON_UART);

      $display("[MON_UART] Data capturata: 0x%0h, delay=%0d", trans.data, trans.delay);
      mon2scb.put(trans);
      colector_coverage.sample_uart(trans);
    end
  endtask

endclass

`endif