class transaction_uart;
  
  bit [3:0] data;       // ce am citit de pe linia tx
  int delay;            // cate tacte de idle au fost inainte
 
  // afisare dupa randomize (aici nu randomizam, dar lasam pt consistenta)
  function void post_randomize();
    $display("--------- [Trans] post_randomize ------");
    $display("\t data = 0x%0h\t  delay = %0d", data, delay);
    $display("-----------------------------------------");
  endfunction
  
  // copie
  function transaction_uart do_copy();
    transaction_uart trans;
    trans = new();
    trans.data    = this.data;
    trans.delay   = this.delay;
    return trans;
  endfunction
endclass