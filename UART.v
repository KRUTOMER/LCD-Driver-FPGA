`timescale 1ns / 100ps

module UART_receiver
#(parameter FREQ = 24_000_000,
            BAUD_RATE = 9600)
(
    input wire clk, //reset,
    input wire DATA_serial,
    
//    output reg data_bit = 0, 
  //  output reg data_bit2 = 0,
   // output reg [2:0] STATE,
   // output reg [11:0] clk_counter,
 //   output reg [2:0] bit_index,
    
    output reg done_tick = 0,
    output wire [7:0] DATA_byte

    );
    
//signal declaration
reg [11:0] clk_counter = 0;
reg data_bit, data_bit2;
reg [2:0] bit_index = 0;
reg [7:0] byte_bit = 0;
reg [2:0] STATE = 0;

//dowble register body
always @(posedge clk)
  begin
    data_bit2 <= DATA_serial;
    data_bit <= data_bit2;
  end

    


//state declaration
localparam [2:0] IDLE = 3'b000,
                 START_BIT = 3'b001,
                 DATA_TRANSFER = 3'b010,
                 STOP_BIT = 3'b011,
                 CLEAN_UP = 3'b100;
                 
//------------FSM BODY---------------
always @(posedge clk)
  begin
    case (STATE) IDLE: begin
                       //waiting start_bit
                       done_tick <= 0;
                       clk_counter <= 0;
                       bit_index <= 0;
                         if (data_bit == 0) 
                           STATE <= START_BIT;
                         else
                           STATE <= IDLE;
                       end
                       
           START_BIT: begin
                      //check the midle of start_bit
                      done_tick <= 0;
                      clk_counter <= 0;
                      bit_index <= 0;
                        if (clk_counter == ((FREQ/2/BAUD_RATE)-1)) 
                          if (data_bit == 0) begin 
                            clk_counter <= 0; //midle of input_bit duration
                            STATE <= DATA_TRANSFER; end
                          else 
                            STATE <= IDLE; 
                        
                        else begin
                          clk_counter <= clk_counter + 1;
                          STATE <= START_BIT;
                        end
                      end
                      
       DATA_TRANSFER: begin
                      // receive 8 bit of data
                      done_tick <= 0;
                      //bit_index <= 0;
                        if (clk_counter < ((FREQ/BAUD_RATE)-1)) begin
                          clk_counter <= clk_counter + 1;  
                          STATE <= DATA_TRANSFER; end
                        else begin
                          clk_counter <= 0;
                          byte_bit[bit_index] <= data_bit;
                            if (bit_index < 7) begin
                              bit_index <= bit_index + 1;
                              STATE <= DATA_TRANSFER; end
                            else begin
                              bit_index <= 0;
                              STATE <= STOP_BIT; end
                        end
                     end
                     
           STOP_BIT: begin
                     // receive stop-bit
                       if (clk_counter < ((FREQ/BAUD_RATE)-1)) begin
                         clk_counter <= clk_counter + 1;
                         STATE <= STOP_BIT; end
                       else begin
                         done_tick <= 1;
                         clk_counter <= 0;
                         STATE <= CLEAN_UP; end
                     end
                     
           CLEAN_UP: begin
                     //waiting 1 clk cycle
                     done_tick <= 0;
                     STATE <= IDLE;
                     end
                     
             default: STATE <= IDLE;
  endcase
end
   
