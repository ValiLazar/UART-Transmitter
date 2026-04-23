
class generator;
  
  rand transaction_valid_ready trans, tr;
  int repeat_count;
  
  mailbox gen2driv;
  event ended;
  
  function new(mailbox gen2driv, event ended);
    this.gen2driv = gen2driv;
    this.ended    = ended;
  endfunction
  
  task main();
    repeat (repeat_count) begin
      trans = new();
      if (!trans.randomize()) $fatal("Gen:: trans randomization failed");
      
    tr = trans.do_copy();
     gen2driv.put(tr);
     // gen2driv.put(trans); //de incercat

    end
    -> ended;
  endtask

  
  task write_single_transaction_valid_ready(bit [9:0] data_param);
    trans = new();  // 2. Instanțiem 'trans' înainte să îl folosim

    if( !trans.randomize() with {data == data_param; valid_i == 1;})
          $fatal("Gen:: trans randomization failed");
          
    tr = trans.do_copy();
    gen2driv.put(tr);
endtask
  
endclass