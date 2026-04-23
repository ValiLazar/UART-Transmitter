
module uart_tx
  #(
    parameter DATA_WIDTH  = 8,
    parameter FIFO_DEPTH  = 4,
    parameter DIVIDER     = 16, //cate tacte dureaza un bit transmis pe uart
    parameter HAS_PARITY  = 0
  )
  (
    input  wire                  clk,
    input  wire                  rst_n,
    
    input  wire [DATA_WIDTH-1:0] data_i,
    input  wire                  valid_i,
    output wire                  ready_o,
    
    output reg                   tx
  );

  reg [DATA_WIDTH-1:0] fifo [0:FIFO_DEPTH-1];
  reg [$clog2(FIFO_DEPTH):0] w_counter, r_counter, no_fifo_elements;
  
  wire fifo_full  = (no_fifo_elements == FIFO_DEPTH);
  wire fifo_empty = (no_fifo_elements == 0);
  
  assign ready_o = ~fifo_full;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      w_counter <= 0;
    end else if (valid_i && ready_o) begin
      fifo[w_counter[$clog2(FIFO_DEPTH)-1:0]] <= data_i;
      w_counter <= w_counter + 1;
    end
  end

  reg read_done;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      no_fifo_elements <= 0;
    else begin
      case ({(valid_i && ready_o), read_done})
        2'b10:   no_fifo_elements <= no_fifo_elements + 1;
        2'b01:   no_fifo_elements <= no_fifo_elements - 1;
        default: no_fifo_elements <= no_fifo_elements;
      endcase
    end
  end

  localparam WAIT_TRANSACTION = 3'd0;
  localparam START            = 3'd1;
  localparam DATA             = 3'd2;
  localparam PARITY           = 3'd3;
  localparam STOP             = 3'd4;

  reg [2:0]  current_state;
  reg [$clog2(DIVIDER)-1:0] baud_counter;
  reg [$clog2(DATA_WIDTH)-1:0] bit_cnt;
  reg [DATA_WIDTH-1:0] tx_shift_reg;
  wire baud_tick = (baud_counter == DIVIDER - 1);

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      baud_counter <= 0;
    else if (current_state == WAIT_TRANSACTION)
      baud_counter <= 0;
    else if (baud_tick)
      baud_counter <= 0;
    else
      baud_counter <= baud_counter + 1;
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      current_state <= WAIT_TRANSACTION;
      tx            <= 1'b1;
      bit_cnt       <= 0;
      r_counter     <= 0;
      read_done     <= 0;
      tx_shift_reg  <= 0;
    end else begin
      read_done <= 0;
      case (current_state)
        
        WAIT_TRANSACTION: begin
          tx <= 1'b1;
          if (!fifo_empty) begin
            tx_shift_reg  <= fifo[r_counter[$clog2(FIFO_DEPTH)-1:0]];
            current_state <= START;
          end
        end

        START: begin
          tx <= 1'b0; 
          if (baud_tick) begin
            bit_cnt       <= 0;
            current_state <= DATA;
          end
        end

        DATA: begin
          tx <= tx_shift_reg[bit_cnt];
          if (baud_tick) begin
            if (bit_cnt == DATA_WIDTH - 1) begin
              if (HAS_PARITY)
                current_state <= PARITY;
              else
                current_state <= STOP;
            end else begin
              bit_cnt <= bit_cnt + 1;
            end
          end
        end

        PARITY: begin
          tx <= ^tx_shift_reg; 
          if (baud_tick)
            current_state <= STOP;
        end

        STOP: begin
          tx <= 1'b1; 
          if (baud_tick) begin
            r_counter     <= r_counter + 1;
            read_done     <= 1;
            current_state <= WAIT_TRANSACTION;
          end
        end

        default: current_state <= WAIT_TRANSACTION;
      endcase
    end
  end

endmodule