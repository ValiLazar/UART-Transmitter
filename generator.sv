class generator;
  
  transaction_valid_ready trans, tr;
  int repeat_count;             // cate tranzactii random generam
  
  mailbox gen2driv;             // de aici plecam catre driver
  event ended;
  
  function new(mailbox gen2driv, event ended);
    this.gen2driv = gen2driv;
    this.ended    = ended;
  endfunction
  
  // genereaza repeat_count tranzactii random
  task main();
    int count_valid_1 = 0;
    int count_valid_0 = 0;
    
    repeat (repeat_count) begin
      trans = new();
      if (!trans.randomize()) $fatal("Gen:: trans randomization failed");
      
      // numaram pt debug
      if (trans.valid_i == 1) count_valid_1++;
      else count_valid_0++;
      
      tr = trans.do_copy();     // copie ca sa nu trimitem aceeasi referinta
      gen2driv.put(tr);
    end
    
    $display("[GEN] Distributie: valid=1 -> %0d, valid=0 -> %0d (total %0d)",
             count_valid_1, count_valid_0, repeat_count);
    -> ended;
  endtask

  // pt teste directed - trimite o data fixa
  task write_single_transaction_valid_ready(bit [3:0] data_param);
    trans = new();
    if (!trans.randomize() with {data == data_param; valid_i == 1;})
      $fatal("Gen:: trans randomization failed");
          
    tr = trans.do_copy();
    gen2driv.put(tr);
  endtask
  
endclass