class transaction_valid_ready;
  
  rand bit [3:0] data;          // ce trimitem pe linie
  rand int delay;               // cate tacte asteptam inainte
  rand bit valid_i;             // 1 = trimitem, 0 = idle
  
  rand int unsigned valid_weight;  // ajutator pt distributie
 
  // facem ca valid_i sa fie 1 in 80% din cazuri
  constraint valid_distribution {
    valid_weight inside {[0:99]};
    valid_i == (valid_weight < 80);
  }
 
  // delay-ul - vrem si pauze scurte si lungi
  constraint delay_c {
    delay dist {[1:10] := 40, [11:15] := 40, 0 := 20, [50:100] := 5};
  }
 
  // se cheama automat dupa randomize, doar afiseaza
  function void post_randomize();
    $display("--------- [Trans] post_randomize ------");
    $display("\t data = 0x%0h\t valid_i = %0b\t delay = %0d", data, valid_i, delay);
    $display("-----------------------------------------");
  endfunction
  
  // copie a tranzactiei (ca sa nu trimitem aceeasi referinta peste tot)
  function transaction_valid_ready do_copy();
    transaction_valid_ready trans;
    trans = new();
    trans.data    = this.data;
    trans.valid_i = this.valid_i;
    trans.delay   = this.delay;
    return trans;
  endfunction
 
  // afiseaza tranzactia (folosit de driver)
  function void display();
    $display("\t data = 0x%0h\t valid_i = %0b\t delay = %0d", data, valid_i, delay);
  endfunction
  
endclass