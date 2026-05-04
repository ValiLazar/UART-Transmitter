// BUG_LSB_DATA
// BUG_FIFO_SMALLER
// BUG_FIFO_FULL
// BUG_CORRPUTED_DATA
// BUG_PARITY

`ifndef DATA_WIDTH_SIMULATION
`define DATA_WIDTH_SIMULATION 8
`endif

`ifndef FIFO_DEPTH_SIMULATION
`define FIFO_DEPTH_SIMULATION 6
`endif


`define WAIT_TRANSACTION 0
`define START 1
`define DATA 2
`define PARITY 3
`define STOP 4

module uart  #(
parameter DATA_WIDTH   = `DATA_WIDTH_SIMULATION,
parameter FIFO_DEPTH   = `FIFO_DEPTH_SIMULATION,
parameter BOUD_RATE    = 3,    // asta inseamna ca BOUD_RATE este 2^(20+3) ; se considera ca ceasul de intrare are o frecventa de 62.5MHz
parameter integer BIT_PERIOD = (62500000>>(20 + BOUD_RATE)),
parameter HAS_PARITY   = 1,
parameter NO_BITS_STOP = 2  // 0 = 1 bit de stop, 1 = 1,5 biti de stop si 2 = 2 biti de stop
)(
input                     clk      ,
input                     rst_n    ,

input [DATA_WIDTH-1:0]    data_i   ,
input                     valid    ,
output                    ready    ,

output reg                tx       
               
);
 

 
 
reg [DATA_WIDTH - 1:0] fifo [FIFO_DEPTH - 1:0];

wire fifo_full   ;
wire fifo_empty  ;


wire bit_overflow;
wire [DATA_WIDTH-1:0] bit_cnt     ;


reg [FIFO_DEPTH-1:0] r_counter;
reg [FIFO_DEPTH-1:0] w_counter;
reg [FIFO_DEPTH-1:0] no_fifo_elements;

      
reg   [3-1:0]        current_state; 
reg   [3-1:0]        next_state; 
wire  [6-1:0]        boud_rate_counter;
reg   [32-1:0]        data_i_cnt;

// configurare semnal ready si semnale ajutatoare
`ifndef BUG_FIFO_FULL // daca este introdus acest bug, semnalul ready va sta tot timpul in 1, iar datele se vor suprascrie in FIFO chiar daca nu au fost trimise pe linia tx pe interfata de iesire
assign ready = ~fifo_full;
`else
assign ready = 1;
`endif
                    

// configurare repere pentru fifo
assign fifo_empty = (no_fifo_elements == 0);
assign fifo_full  = ( no_fifo_elements == FIFO_DEPTH)? 1 : 0;




//counter pt elementele scrise in fifo
always @(posedge clk or negedge rst_n)
if (~rst_n)               w_counter <= 0                         ;else
`ifndef BUG_FIFO_SMALLER // daca se introduce acest bug, ultimele doua elemente din stiva nu se vor popula niciodata cu elemente
if (valid && ready )      w_counter <= (w_counter + 1)%FIFO_DEPTH;else
`else
if (valid && ready )      w_counter <= (w_counter + 1)%(FIFO_DEPTH-2);else
`endif
                          w_counter <= w_counter                 ;


//counter pt elementele citite din fifo
always @(posedge clk or negedge rst_n)
if (~rst_n)                                             r_counter <= 0                         ;else
if (boud_rate_counter==0 && (current_state== `STOP))    r_counter <= (r_counter + 1)%FIFO_DEPTH;


//cate elemente sunt in fifo: number of fifo elements
always @(posedge clk or negedge rst_n)
if (~rst_n)                                           no_fifo_elements <= 0                   ;else 
begin
if (valid && ready && no_fifo_elements<FIFO_DEPTH)    no_fifo_elements <= no_fifo_elements + 1;
if (boud_rate_counter==0 && (current_state==`STOP))   no_fifo_elements <= no_fifo_elements - 1;
end



//dau valori lui fifo, care apoi vor fi puse pe mosi
always @(posedge clk or negedge rst_n)
`ifndef BUG_CORRPUTED_DATA // daca acest bug este activat, 20% din datele care ajung la intrarea modulului vor fi modificate de DUT inainte de a se introduce in stiva
if(valid &&ready)      fifo[w_counter] <= data_i;
`else
if(valid &&ready)      fifo[w_counter] <= data_i+2*($urandom_range(1,10)/9);
`endif



always @(posedge clk or negedge rst_n)
if(~rst_n) current_state <= `WAIT_TRANSACTION; else
           current_state <= next_state;
           
           
           
always @(posedge clk or negedge rst_n)           
if(~rst_n)        tx <= 1; else
case (current_state) 
      `START:      tx <= 0;      
      `DATA:       tx <= fifo[r_counter][bit_cnt];
	  `ifndef BUG_PARITY // daca este introdus acest bug, bitul de paritate va fi transmis tot timpul cu valoarea '0'
      `PARITY:     tx <= ^(fifo[r_counter])      ; // sau exclusiv pe toti bitii, bitul de paritate daca e numar impar e 1 si daca e par e 0
	  `else
	  `PARITY:     tx <= 0;    
	  `endif
      default:     tx <= 1                       ; // deci cand e STOP sau transactie se pune in 1
endcase


        
always @(*) begin
    case (current_state)
        `WAIT_TRANSACTION: next_state = (~fifo_empty) ? `START : current_state;
        `START:            next_state = (~|boud_rate_counter) ? `DATA : current_state;
		`ifndef BUG_LSB_DATA // daca se introduce acest bug, nu se va mai trimite ultimul bit de date pe linia tx
        `DATA:             next_state = (~|bit_cnt && ~|boud_rate_counter) ? (HAS_PARITY) ? `PARITY : `STOP : current_state;
		`else
		`DATA:             next_state = (~|bit_cnt[DATA_WIDTH-1:1] && ~|boud_rate_counter) ? (HAS_PARITY) ? `PARITY : `STOP : current_state;
		`endif
                           //fiecare ? este un if si fiecare : este un else
                           // s-au transmis toti bitii ?, daca da intreaba daca are paritate ca sa stie unde sa mearga, sau isi pastreaza starea                           
        `PARITY:           next_state = (~|boud_rate_counter) ? `STOP : current_state;
        `STOP:             next_state = (~|boud_rate_counter) ? `WAIT_TRANSACTION : current_state;
        default:           next_state = (~fifo_empty) ? `START : current_state;
    endcase
end

 // valoarea lui data_i_cnt se va modifica diferit doar pentru bitul de stop
always@(current_state or boud_rate_counter)
if(NO_BITS_STOP == 0 && ((current_state == `PARITY && HAS_PARITY == 1) || (current_state == `DATA && HAS_PARITY == 0 && ~|bit_cnt)) && ~|boud_rate_counter) // 1 bit de stop
      data_i_cnt <= (62500000>>(20 + BOUD_RATE))-1      ; else
if(NO_BITS_STOP == 1 && ((current_state == `PARITY && HAS_PARITY == 1) || (current_state == `DATA && HAS_PARITY == 0 && ~|bit_cnt)) && ~|boud_rate_counter) // 1.5
      data_i_cnt <= (62500000>>(20 + BOUD_RATE)) + ((62500000)>>(20 + BOUD_RATE+1)) -1  ; else   //93750000 = 1.5 * 93750000
if(NO_BITS_STOP == 2 && ((current_state == `PARITY && HAS_PARITY == 1) || (current_state == `DATA && HAS_PARITY == 0 && ~|bit_cnt)) && ~|boud_rate_counter) // 2
      data_i_cnt <= ((2*62500000)>>(20 + BOUD_RATE))-1  ; else        
      data_i_cnt <= (62500000>>(20 + BOUD_RATE))-1      ;

  
//instantiere counter cate tacte ceas per bit
counter #(
  .WIDTH (6)
)i_counter_tacte_ceas_per_bit(
  .clk        (clk                               ),
  .rst_n      (rst_n                             ),
  .reset_value(data_i_cnt                        ),     //calculul de BOUD_RATE=> tacte de ceas/secunda, impartit cu BOUD_RATE, BOUD_RATE fiind biti/sec
  .enable_i   (current_state != `WAIT_TRANSACTION),
  .up_down_i  (1'b0                              ),
  .load_i     (~|boud_rate_counter               ),
  .data_i     (data_i_cnt                        ),
  .overflow   (boud_rate_overflow                ),
  .cnt_o      (boud_rate_counter                 )
);



//instantiere counter cati biti am
counter #(
  .WIDTH (DATA_WIDTH)
)i_counter_bit(
  .clk        (clk                                         ),
  .rst_n      (rst_n                                       ),
  .reset_value(DATA_WIDTH - 1                              ),
  .enable_i   (~|boud_rate_counter & current_state == `DATA),
  .up_down_i  (1'b0                                        ),
  .load_i     (~|bit_cnt && ~|boud_rate_counter            ), //(bit_cnt==0) && (boud_rate_counter=0)
  .data_i     (DATA_WIDTH - 1                              ),
  .overflow   (bit_overflow                                ),
  .cnt_o      (bit_cnt                                     )
);






endmodule 
