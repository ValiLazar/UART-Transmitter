interface vr_intf(input logic clk, rst_n);
  
  logic [7:0] data_i;
  logic       valid_i;
  logic       ready_o;
  
  clocking driver_cb @(posedge clk);
    default input #1 output #1;
    output data_i;
    output valid_i;
    input  ready_o;
  endclocking   
  
  clocking monitor_cb @(posedge clk);
    default input #1 output #1;
    input data_i;
    input valid_i;
    input ready_o;
  endclocking
  
  modport DRIVER  (clocking driver_cb, input clk, rst_n);
  modport MONITOR (clocking monitor_cb, input clk, rst_n);
    
  // Asertii
  property no_valid_when_not_ready;
    @(posedge clk) disable iff (rst_n == 0)
    (!ready_o) |-> (!valid_i);
  endproperty
  
  asertia_no_valid: assert property (no_valid_when_not_ready) 
    else $error("VR_INTF: a picat asertia no_valid_when_not_ready");
      
  property valid_i_pulse;
    @(posedge clk) disable iff (rst_n == 0)
    valid_i |=> !valid_i;
  endproperty
  
  asertia_valid_i_pulse: assert property (valid_i_pulse) 
    else $error("VR_INTF: a picat asertia valid_i_pulse");
      
endinterface