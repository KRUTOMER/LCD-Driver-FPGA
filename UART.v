`timescale 1ns / 100ps

module UART_receiver
#(parameter FREQ = 24_000_000,
            BAUD_RATE = 9600)
(
    input wire clk, //reset,
    input wire DATA_serial,
    
   // output reg data_bit = 0, 
   // output reg data_bit2 = 0,
    //output reg [2:0] STATE_reg = 0,
   //output reg [11:0] clk_counter_reg = 0,
   //output reg [2:0] bit_index_reg = 0,
    
    output reg done_tick = 0,
    output wire [7:0] DATA_byte

    );
    
//signal declaration
reg [11:0] clk_counter_reg = 0;
reg [11:0] clk_counter_next;
reg data_bit, data_bit2;
reg [2:0] bit_index_reg = 0;
reg [2:0] bit_index_next;
reg [7:0] byte_bit = 0;
reg [2:0] STATE_reg = 0;
reg [2:0] STATE_next;

//dowble register body
always @(posedge clk)
  begin
    data_bit2 <= DATA_serial;
    data_bit <= data_bit2;
    STATE_reg <= STATE_next;
    clk_counter_reg <= clk_counter_next;
    bit_index_reg <= bit_index_next;
  end

//state declaration
localparam [2:0] IDLE = 3'b000,
                 START_BIT = 3'b001,
                 DATA_TRANSFER = 3'b010,
                 STOP_BIT = 3'b011,
                 DONE = 3'b100;
                 
//------------FSM BODY---------------
always @*
  begin
    done_tick = 0;
    clk_counter_next = clk_counter_reg;
    bit_index_next = bit_index_reg;
    STATE_next = STATE_reg;
  
  
      case (STATE_reg) IDLE: begin
                           //waiting start_bit
                               if (data_bit == 0) 
                                 STATE_next = START_BIT;
                               else
                                 STATE_next = IDLE;
                             end
                       
           START_BIT: begin
                      //check the midle of start_bit
                        if (clk_counter_next == ((FREQ/2/BAUD_RATE)-1)) 
                          if (data_bit == 0) begin 
                            clk_counter_next = 0; //midle of input_bit duration
                            STATE_next = DATA_TRANSFER; end
                          else 
                            STATE_next = IDLE; 
                        else begin
                          clk_counter_next = clk_counter_reg + 1;
                          STATE_next = START_BIT;
                        end
                      end
                      
       DATA_TRANSFER: begin
                      // receive 8 bit of data
                        if (clk_counter_next < ((FREQ/BAUD_RATE)-1)) begin
                          clk_counter_next = clk_counter_reg + 1;  
                          STATE_next = DATA_TRANSFER; end
                        else begin
                          clk_counter_next = 0;
                          byte_bit[bit_index_next] = data_bit;
                            if (bit_index_next < 7) begin
                              bit_index_next = bit_index_reg + 1;
                              STATE_next = DATA_TRANSFER; end
                            else begin
                              bit_index_next = 0;
                              STATE_next = STOP_BIT; end
                        end
                     end
                     
           STOP_BIT: begin
                     // receive stop-bit
                       if (clk_counter_next < ((FREQ/BAUD_RATE)-1)) begin
                         clk_counter_next = clk_counter_reg + 1;
                         STATE_next = STOP_BIT; end
                       else begin
                        // done_tick = 1;
                         clk_counter_next = 0;
                         STATE_next = DONE; end
                     end
                     
           DONE: begin
                     //waiting 1 clk cycle
                     done_tick = 1;
                     STATE_next = IDLE;
                     end
                     
             default: STATE_next = IDLE;
  endcase
end
   
   
assign DATA_byte = byte_bit;   
                                            
    
endmodule
