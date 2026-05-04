interface vr_intf(input logic clk, rst_n);
  
  logic [3:0] data_i = 0;     // DATA_WIDTH = 4
  logic       valid_i = 0;
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
    
  // ============================================================
  //   ASERTII PROTOCOL VALID-READY
  // ============================================================

  // 1. Stabilitatea datelor: cat timp valid_i==1 si ready_o==0 (handshake nu s-a
  //    intamplat inca), data_i NU trebuie sa se schimbe.
  property data_stable_until_ready;
    @(posedge clk) disable iff (!rst_n)
    (valid_i && !ready_o) |=> (data_i == $past(data_i));
  endproperty

  asertia_data_stable: assert property (data_stable_until_ready)
    else $error("VR_INTF: data_i s-a schimbat in timp ce valid_i=1 si ready_o=0");

  // 2. Persistenta lui valid: daca valid_i==1 si ready_o==0, atunci in ciclul
  //    urmator valid_i trebuie sa ramana 1 (master-ul nu are voie sa retraga
  //    valid pana la handshake).
  property valid_persists_until_ready;
    @(posedge clk) disable iff (!rst_n)
    (valid_i && !ready_o) |=> valid_i;
  endproperty

  asertia_valid_persists: assert property (valid_persists_until_ready)
    else $error("VR_INTF: valid_i a fost retras inainte de handshake (ready_o=0)");

  // 3. Datele si valid trebuie sa nu fie X/Z atunci cand valid_i este activ.
  property valid_data_not_unknown;
    @(posedge clk) disable iff (!rst_n)
    valid_i |-> !$isunknown({valid_i, data_i});
  endproperty

  asertia_data_known: assert property (valid_data_not_unknown)
    else $error("VR_INTF: data_i sau valid_i sunt X/Z cand valid_i=1");

  // 4. Dupa reset, valid_i trebuie sa fie 0.
 property valid_low_after_reset;
    @(posedge clk) disable iff (!rst_n)
    $rose(rst_n) |-> ##1 (valid_i === 1'b0);
endproperty

  asertia_valid_low_reset: assert property (valid_low_after_reset)
    else $error("VR_INTF: valid_i nu este 0 imediat dupa reset");

endinterface