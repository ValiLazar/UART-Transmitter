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

  property tx_idle_after_reset;
    @(posedge clk) $rose(rst_n) |-> ##[1:3] (tx == 1'b1);
endproperty
  
  asertia_tx_idle: assert property (tx_idle_after_reset) 
    else $error("UART_INTF: tx nu este idle (1) dupa reset");

endinterface