`timescale 1ns / 100ps

module FIFO
#(parameter DATA_WIDTH=8, ADDR_WIDTH=2, DEPTH=(1<<ADDR_WIDTH))
    (input [DATA_WIDTH-1:0] data_in,
     input clk, reset, rd, wr,
     output empty, full,
     output reg [ADDR_WIDTH:0] fifo_cnt = 0,
     output reg [DATA_WIDTH-1:0] data_out
    );
    
reg [DATA_WIDTH-1:0] fifo_ram [0:DEPTH-1]; //memory array
reg [ADDR_WIDTH-1:0] rd_ptr, rd_ptr_next, wr_ptr, wr_ptr_next; //pointers for read and write operations
reg [ADDR_WIDTH-1:0] fifo_cnt_next;
reg [DATA_WIDTH-1:0] data_out_next;

//register body
always @(posedge clk)
  if (reset)
    begin
      rd_ptr <= 0;
      wr_ptr <= 0;
      fifo_cnt <=0;
      data_out <=0;
    end
  else
    begin
      rd_ptr <= rd_ptr_next;
      wr_ptr <= wr_ptr_next;
      fifo_cnt <= fifo_cnt_next;
      data_out <= data_out_next;
    end


//determine memory state
assign empty = (fifo_cnt_next==0); //memory empty
assign full = (fifo_cnt_next==DEPTH-1); //memory full

always @* //writing
  begin
    if (wr && !full) fifo_ram[wr_ptr] = data_in;
    else if (wr && rd) fifo_ram[wr_ptr] = data_in;
  end

always @* //reading
  begin
    data_out_next = data_out;
    if (rd && !empty) data_out_next = fifo_ram[rd_ptr];
    else if (rd && wr && empty) data_out_next = fifo_ram[rd_ptr];
  end
  
  
always @* //pointers
  begin
    wr_ptr_next = ((wr && !full)||(wr && rd)) ? wr_ptr + 1'b1 : wr_ptr;
    rd_ptr_next = ((wr && rd)||(rd && !empty)) ? rd_ptr + 1'b1 : rd_ptr;
  end
  
always @* // counting number of words in memory
  begin
   if (!wr && rd)
     fifo_cnt_next = (fifo_cnt == 1'b0) ? 1'b0 : fifo_cnt - 1'b1;
   else if (wr && !rd)
     fifo_cnt_next = (fifo_cnt == DEPTH - 1) ? (DEPTH - 1) : fifo_cnt + 1'b1;
   else
     fifo_cnt_next = fifo_cnt;
  end   
    
endmodule
