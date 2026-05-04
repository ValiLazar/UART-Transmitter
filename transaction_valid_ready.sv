class transaction_valid_ready;
  rand bit [3:0] data;     // DATA_WIDTH = 4
  rand int delay;
  rand bit       valid_i;
 
  constraint data_c {
    valid_i dist {1 := 80, 0 := 20};
  }
 
  constraint delay_c {
    delay dist {[1:10] := 40, [11:15] := 40, 0 := 20, [50:100] := 5};
  }
 
  function void post_randomize();
    $display("--------- [Trans] post_randomize ------");
    $display("\t data = 0x%0h\t valid_i = %0b\t delay = %0d", data, valid_i, delay);
    $display("-----------------------------------------");
  endfunction
  
  function transaction_valid_ready do_copy();
    transaction_valid_ready trans;
    trans = new();
    trans.data    = this.data;
    trans.valid_i = this.valid_i;
    trans.delay   = this.delay;
    return trans;
  endfunction
 
  function void display();
    $display("\t data = 0x%0h\t valid_i = %0b\t delay = %0d", data, valid_i, delay);
  endfunction
  
endclass
 