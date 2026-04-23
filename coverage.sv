`ifndef __COVERAGE
`define __COVERAGE

class coverage;
  
  transaction_valid_ready trans_vr_covered;
  transaction_uart trans_uart_covered;
  
  covergroup vr_transaction_cg;
    option.per_instance = 1;
    
    valid_cp: coverpoint trans_vr_covered.valid_i;
    
    write_data_cp: coverpoint trans_vr_covered.data {
      bins big_values = {[191:254]};
      bins medium_values = {[127:190]};
      bins low_values = {[1:126]};
      bins lowest_value = {0};
      bins highest_value = {255};
    }
    
    delay_cp: coverpoint trans_vr_covered.delay {
      bins no_delay = {0};
      bins short_delay = {[1:10]};
      bins long_delay = {[11:15]};
    }
  endgroup
  
  covergroup uart_transaction_cg;
    option.per_instance = 1;
    
    uart_data_cp: coverpoint trans_uart_covered.data {
      bins big_values = {[191:254]};
      bins medium_values = {[127:190]};
      bins low_values = {[1:126]};
      bins lowest_value = {0};
      bins highest_value = {255};
    }

    delay_no_cp: coverpoint trans_uart_covered.delay {
      bins no_delay = {0};
    }

    delay_short_cp: coverpoint trans_uart_covered.delay {
      bins short_delay = {[1:10]};
    }

    delay_long_cp: coverpoint trans_uart_covered.delay {
      bins long_delay = {[11:15]};
    }

     delay_cp: coverpoint trans_uart_covered.delay {
      bins no_delay = {0};
      bins short_delay = {[1:10]};
      bins long_delay = {[11:15]};
    }
  endgroup
  
  function new();
    vr_transaction_cg = new();
    uart_transaction_cg = new();
  endfunction
  
  task sample_vr(transaction_valid_ready trans);
    this.trans_vr_covered = trans;
    vr_transaction_cg.sample();
  endtask
  
  task sample_uart(transaction_uart trans);
    this.trans_uart_covered = trans;
    uart_transaction_cg.sample();
  endtask
  
  function void print_coverage();
  // Valid ready coverage
    // $display("VR Write data coverage = %.2f%%", vr_transaction_cg.write_data_cp.get_coverage());
    // $display("VR Delay coverage = %.2f%%", vr_transaction_cg.delay_cp.get_coverage());
    //   $display("VR Delay coverage = %.2f%%", vr_transaction_cg.delay_cp.get_coverage());
    // $display("VR Overall coverage = %.2f%%", vr_transaction_cg.get_coverage());

    $display("--------- [Valid ready coverage] ---------");
    $display("Valid signal coverage = %.2f%%", vr_transaction_cg.valid_cp.get_coverage());
    $display("Write data coverage = %.2f%%", vr_transaction_cg.write_data_cp.get_coverage());
    $display("Delay coverage pentru valid-ready = %.2f%%", vr_transaction_cg.delay_cp.get_coverage());
    $display("Valid ready overall coverage = %.2f%%", vr_transaction_cg.get_coverage());
    $display("-----------------------------------------");
    $display("Overall coverage = %.2f%%", vr_transaction_cg.get_coverage());
    $display("-----------------------------------------");
    $display("--------- [UART coverage] ---------");
    $display("UART data coverage = %.2f%%", uart_transaction_cg.uart_data_cp.get_coverage());
    $display("Delay coverage pentru iesire = %.2f%%", uart_transaction_cg.delay_cp.get_coverage());
    $display("Overall coverage = %.2f%%", uart_transaction_cg.get_coverage());
    $display("-----------------------------------------");
    $display("UART transaction coverage = %.2f%%", uart_transaction_cg.uart_data_cp.get_coverage());
    $display("UART overall coverage = %.2f%%", uart_transaction_cg.get_coverage());
    $display("--------------------------Debug------------------------");
    $display("Delay_no_cp = %.2f%%", uart_transaction_cg.delay_no_cp.get_coverage());
    $display("Delay_short_cp = %.2f%%", uart_transaction_cg.delay_short_cp.get_coverage());
    $display("Delay_long_cp = %.2f%%", uart_transaction_cg.delay_long_cp.get_coverage());

    // $display("UART data coverage = %.2f%%", uart_transaction_cg.uart_data_cp.get_coverage());
    // $display("VR Overall coverage = %.2f%%", vr_transaction_cg.get_coverage());
    // $display("UART Overall coverage = %.2f%%", uart_transaction_cg.get_coverage());
  endfunction
  
endclass: coverage

`endif