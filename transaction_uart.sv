class transaction_uart;
   bit [3:0] data;     // DATA_WIDTH = 4
   int       delay;
 
  function void post_randomize();
    $display("--------- [Trans] post_randomize ------");
    $display("\t data = 0x%0h\t  delay = %0d", data, delay);
    $display("-----------------------------------------");
  endfunction
  
  function transaction_uart do_copy();
    transaction_uart trans;
    trans = new();
    trans.data    = this.data;
    trans.delay   = this.delay;
    return trans;
  endfunction
endclass
 