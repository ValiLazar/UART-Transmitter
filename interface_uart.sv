interface uart_intf(input logic clk, rst_n);
  
  logic tx;

  clocking driver_cb @(posedge clk);
    default input #1 output #1;
    output tx;
  endclocking
  
  clocking monitor_cb @(posedge clk);
    default input #1 output #1;
    input tx;
  endclocking
  
  modport DRIVER  (clocking driver_cb, input clk, rst_n);
  modport MONITOR (clocking monitor_cb, input clk, rst_n);

  // dupa reset, tx trebuie sa fie 1 (idle)
  property tx_idle_after_reset;
    @(posedge clk) $rose(rst_n) |-> ##[1:3] (tx == 1'b1);
  endproperty
  asertia_tx_idle: assert property (tx_idle_after_reset) 
    else $error("UART_INTF: tx nu este idle (1) dupa reset");

  // tx nu are voie sa fie X sau Z
  property tx_not_unknown;
    @(posedge clk) disable iff (!rst_n)
    !$isunknown(tx);
  endproperty
  asertia_tx_known: assert property (tx_not_unknown)
    else $error("UART_INTF: tx este X/Z");

  // daca tx cade in 0, trebuie sa revina in 1 in maxim 60 cicluri
  // (start + 4 data + parity + stop = 7 biti × 7 tacte = 49 tacte)
  property tx_returns_to_idle;
    @(posedge clk) disable iff (!rst_n)
    $fell(tx) |-> ##[1:60] (tx == 1'b1);
  endproperty
  asertia_tx_returns: assert property (tx_returns_to_idle)
    else $error("UART_INTF: tx a ramas la 0 mai mult de 60 cicluri");

endinterface