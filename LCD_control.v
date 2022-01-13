`timescale 1ns / 100ps


module LCD_control(
       input wire clk, reset, start,
       input wire [7:0] DATA_in,
       input wire [1:0] operation,
       
       output reg [2:0] STATE = 0,
       output reg [1:0] SUBSTATE = 0,
       output reg [19:0] count_timer = 0,
       
       output reg [3:0] DATA_out,
       output reg LCD_RS, LCD_RW, LCD_E, ready  
        

    );
    

/*###############NOTES################
The normal clocking regime for this module is 24 MHz (one period ~ 41,6 ns)
When LCD_RS change wait 1 clock cycle
To send data or instruction you should set up E = 1 and wait 6 clock cycles or more
While E=1 send data or instruction; When E=1 -> 0, hold data for 10 ns minimum
#####################################*/

// Define timing parameters
localparam [19:0] t_40ns = 1; // 40ns, 1 clk cycle
localparam [19:0] t_250ns = 6; // 250ns, 6 clk cycles
localparam [19:0] t_42us = 1008; // 42us, 1008 clk cycles
localparam [19:0] t_100us = 2400; // 100us, 2400 clk cycles
localparam [19:0] t_1640us = 39360; // 1.64ms, 39360 clk cycles
localparam [19:0] t_4100us = 98400; // 4,1ms, 98400 clk cycles
localparam [19:0] t_15000us = 36000; // 15ms, 36000 clk cycles

// Define basic command list
localparam [7:0] INITIAL = 8'b0011_0000, //NOT A COMMAND, initial set after LCD power up
                                         //wait 15 ms after turn on
                                         //send this command 1st time and wait 15 ms
                                         //send this command 2nd time and wait 1,64 ms
                                         //send this command 3rd time and wait 1,64 ms;  begin setting of LCD
                 SETUP = 8'b0010_1000, //4-bit mode, 2 lines, 5x8 dots resolution
                                       // execution time = 42 ns
                 RETURN_HOME = 8'b0000_0010, //Return cursor at the beginning
                                             //execution time = 1,64 ms
                  DISPLAY_ON = 8'b0000_1100, //Display ON, cursor OFF, cursor's blink OFF
                                             //execution time = 42 us
                 ALL_ON = 8'b0000_1111, //Display ON, cursor ON, cursor's blink ON
                                        //execution time = 42 us
                 ALL_OFF = 8'b0000_1000, //Display OFF, cursor OFF, cursor's blink OFF
                                         //execution time = 42 us
                 CLEAR = 8'b0000_0001, //Clear datas on display and return cursor to home
                                       //execution time = 1,64 ms
                 ENTRY_N = 8'b0000_0110, //Normal entry mode: cursor moves right, DDRAM adress +, display shift OFF
                                         //execution time = 42 us                                             
                 CURSOR_SHIFT_L = 8'b0001_0000, //Shift cursor to the left one position
                                                //execution time = 42 us                                                                                          
                 CURSOR_SHIFT_R = 8'b0001_0100, //Shift cursor to the right one position
                                                //execution time = 42 us                                                                                          
                 DISPLAY_SHIFT_L = 8'b0001_1000, //Shift all display to the left
                                                //execution time = 42 us
                 DISPLAY_SHIFT_R = 8'b0001_1100; //Shift all display to the right
                                                 //execution time = 42 us

//Counter body
//reg [19:0] count_timer = 0; //39360 clks, used to formig delays between states and command executions
reg flag_250ns = 0, flag_42us = 0, flag_100us = 0, flag_1640us = 0, flag_4100us = 0, flag_15000us = 0;
reg flag_reset = 1; //When flag is 1 counting not started

always @(posedge clk)
  if (flag_reset)
    begin
      count_timer <= 0;
      flag_250ns <= 0;
      flag_42us <= 0;
      flag_100us <= 0;
      flag_1640us <= 0;
      flag_4100us <= 0;
      flag_15000us <= 0;
    end
  else
    begin
      if (count_timer >= t_250ns) flag_250ns <= 1;
      else flag_250ns <= 0;
      
      if (count_timer >= t_42us) flag_42us <= 1;
      else flag_42us <= 0;

      if (count_timer >= t_100us) flag_100us <= 1;
      else flag_100us <= 0;
    
      if (count_timer >= t_1640us) flag_1640us <= 1;
      else flag_1640us <= 0;    
      
      if (count_timer >= t_4100us) flag_4100us <= 1;
      else flag_4100us <= 0;     

      if (count_timer >= t_15000us) flag_15000us <= 1;
      else flag_15000us <= 0;     
    
      count_timer <= count_timer + 1;
      
    end
    
//--------------FSM's BODY----------------------------------
//reg [2:0] STATE = 0;
//reg [1:0] SUBSTATE = 0;

always @(posedge clk)
  begin
    LCD_RW <= 0;
    LCD_E <= LCD_E;
    DATA_out <= DATA_out;
    SUBSTATE <= SUBSTATE;
    flag_reset <= flag_reset;
    flag_250ns <= flag_250ns;
      case (STATE) 
           0: begin
           //------------------Inital procedure (3 in 1)---------------
             LCD_RS <= 1'b0;
         
             //LCD_E <= 0;
         
             DATA_out <= 0;
             ready <= 0;
             STATE <= STATE;
             SUBSTATE <= 0;
             
             
             if (SUBSTATE == 0) begin
             if (flag_15000us) begin
               SUBSTATE <= SUBSTATE + 1;
               flag_reset <= 1; end
             else begin
                SUBSTATE <= SUBSTATE;
                flag_reset <= 0; end
            end
                
                 if (SUBSTATE == 1) begin
                 LCD_E <= 1;
                 DATA_out <= INITIAL [7:4];  
                 STATE <= STATE;
                 flag_reset <= 0;
                   if (flag_250ns == 1) begin
                      LCD_E <=0;
                      SUBSTATE <= SUBSTATE;
                      flag_reset <= 0; end
                  else if (flag_4100us == 1) begin
                      LCD_E <= 0;
                      SUBSTATE <= SUBSTATE + 1;
                      flag_reset <= 1; end
                   else begin
                     LCD_E <= 0;
                     SUBSTATE <= SUBSTATE;
                     flag_reset <= 0; end
                 end
                     
                   if (SUBSTATE == 2) begin
                     LCD_E <= 1;
                     DATA_out <= INITIAL [7:4];  
                     STATE <= STATE;
                     flag_reset <= 0;
                      if (flag_250ns == 1) begin
                          LCD_E <=0;
                          SUBSTATE <= SUBSTATE;
                          flag_reset <= 0; end
                       else if (flag_100us == 1) begin
                          LCD_E <= 0;
                          SUBSTATE <= SUBSTATE + 1;
                          flag_reset <= 1; end
                       else begin
                         LCD_E <= 0;
                         SUBSTATE <= SUBSTATE;
                         flag_reset <= 0; end 
                     end
                     
                     if (SUBSTATE == 3) begin
                       LCD_E <= 1;
                       DATA_out <= INITIAL [7:4];  
                       STATE <= STATE;
                       flag_reset <= 0;
                        if (flag_250ns == 1) begin
                            LCD_E <= 0;
                            SUBSTATE <= SUBSTATE;
                            flag_reset <= 0; end 
                         if (flag_42us == 1) begin
                            LCD_E <= 0;
                            SUBSTATE <= 0;
                            STATE <= STATE + 1;
                            flag_reset <= 1; end
                         else begin
                           LCD_E <= 0;
                           STATE <= STATE;
                           SUBSTATE <= SUBSTATE;
                           flag_reset <= 0; end 
                       end
                     end
                      
             
           1: begin
           //------------Set 4-bit mode,  2 lines, 5x8 resolution----------------------------
              LCD_RS = 0;
       
             // LCD_E <= 0;
              
              DATA_out = DATA_out;
       
              ready = 0;
              STATE = STATE;
              
              if (SUBSTATE == 0) begin
                LCD_E <= 1;
                DATA_out <= SETUP [7:4];
                STATE <= STATE;
                if (flag_250ns == 1) begin
                  LCD_E <= 0;
                  flag_reset <= 1;
                  SUBSTATE <= SUBSTATE + 1; end
                else begin
                  LCD_E <= 1;
                  flag_reset <= 0;
                  SUBSTATE <= SUBSTATE; end
              end              
              
              if (SUBSTATE == 1) begin
                 LCD_E <= 1;
                 DATA_out <= SETUP [3:0];
                 STATE <= STATE;
                  if (flag_250ns == 1) begin
                    LCD_E <= 0;
                    flag_reset <= 1;
                    SUBSTATE <= SUBSTATE + 1; end
                  else begin
                    LCD_E <= 1;
                    flag_reset <= 0;
                    SUBSTATE <= SUBSTATE; end
              end
                    
               if (SUBSTATE == 2) begin
                 LCD_E <= 0;
                 DATA_out <= DATA_out;
                   if (flag_100us == 1) begin
                     flag_reset <= 1;
                     SUBSTATE <= 0;
                     STATE <= STATE + 1;
                      end
                   else begin
                     SUBSTATE <= SUBSTATE;
                     STATE <= STATE;
                     flag_reset <= 0; end
              end
           end
              
           2: begin
           //--------------------DISPLAY SETTING---------------------
                LCD_RS <= 0;
                
                //flag_reset = 1;
                
                //LCD_E <= 0;
                
                DATA_out <= DATA_out;
                
                ready <= 0;
                STATE <= STATE;
                
                if (SUBSTATE == 0) begin
                  LCD_E <= 1;
                  DATA_out <= DISPLAY_ON [7:4];
                  if (flag_250ns == 1) begin
                    LCD_E <= 0;
                    flag_reset <= 1;
                    SUBSTATE <= SUBSTATE + 1; end
                  else begin
                    LCD_E <= 1;
                    flag_reset <= 0;
                    SUBSTATE <= SUBSTATE; end
                end
                
                if (SUBSTATE == 1) begin
                  LCD_E <= 1;
                  DATA_out <= DISPLAY_ON [3:0];
                  if (flag_250ns == 1) begin
                    LCD_E <= 0;
                    flag_reset <= 1;
                    SUBSTATE <= SUBSTATE + 1; end
                  else begin
                    LCD_E <= 1;
                    flag_reset <= 0;
                    SUBSTATE <= SUBSTATE; end
                end
                
                if (SUBSTATE == 2) begin
                  LCD_E <= 0;
                  DATA_out <= DATA_out;
                  if (flag_100us) begin
                    flag_reset <= 1;
                    SUBSTATE <= 0;
                    STATE <= STATE + 1; end
                  else begin
                    flag_reset <= 0;
                    SUBSTATE <= SUBSTATE;
                    STATE <= STATE; end
                end
           
             end
             
           3: begin
           //------------------------------SET NORMAL ENTRY MODE----------------------------------------
              LCD_RS <= 0;
              
              //LCD_E = 0;
              
              DATA_out <= DATA_out;
              
              ready <= 0;
              STATE <= STATE;
              
              if (SUBSTATE == 0) begin
                LCD_E <= 1;
                DATA_out <= ENTRY_N [7:4];
                  if(flag_250ns == 1) begin
                    LCD_E <= 0;
                    flag_reset <= 1;
                    SUBSTATE <= SUBSTATE + 1; end
                  else begin
                    LCD_E <= 1;
                    flag_reset <= 0;
                    SUBSTATE <= SUBSTATE; end
              end
              
              if (SUBSTATE == 1) begin
                LCD_E <= 1;
                DATA_out <= ENTRY_N [3:0];
                  if (flag_250ns == 1) begin
                    LCD_E <= 0;
                    flag_reset <= 1;
                    SUBSTATE <= SUBSTATE + 1; end
                  else begin
                    LCD_E <= 1;
                    flag_reset <= 0;
                    SUBSTATE <= SUBSTATE; end
              end
              
              if (SUBSTATE == 2) begin
                LCD_E <= 0;
                DATA_out <= DATA_out;
                STATE <= STATE;
                  if (flag_100us == 1) begin
                    flag_reset <= 1;
                    STATE <= STATE + 1;
                    SUBSTATE <= 0; end
                  else begin
                    flag_reset <= 0;
                    STATE <= STATE;
                    SUBSTATE <= SUBSTATE; end
              end
           end
              
            4: begin
            //--------------------CLEAR DISPLAY-------------------------------
               LCD_RS <= 0;
               
               ready <= 0;
               
               DATA_out <= DATA_out;
               
               //LCD_E = 0;
               
               STATE <= STATE;
               
               if (SUBSTATE == 0) begin
                 LCD_E <= 1;
                 DATA_out <= CLEAR [7:4];
                   if (flag_250ns == 1) begin
                     flag_reset <= 1;
                     SUBSTATE <= SUBSTATE + 1;end
                   else begin
                     flag_reset <= 0;
                     SUBSTATE <= SUBSTATE; end
               end
               
               if (SUBSTATE == 1) begin
                 LCD_E <= 1;
                 DATA_out <= CLEAR [3:0];
                   if (flag_250ns == 1) begin
                     flag_reset <= 1;
                     SUBSTATE <= SUBSTATE + 1; end
                   else begin
                     flag_reset <= 0;
                     SUBSTATE <= SUBSTATE; end
               end
               
               if (SUBSTATE == 2) begin
                 LCD_E <= 0;
                 DATA_out <= DATA_out;
                 STATE <= STATE;
                   if (flag_1640us == 1) begin
                     flag_reset <= 1;
                     SUBSTATE <= 0;
                     STATE <= 7; end
                   else begin
                     flag_reset <= 0;
                     SUBSTATE <= SUBSTATE;
                     STATE <= STATE; end
               end
           end
               
            5: begin
            //-------------------------WRITE INSTRUCTION-------------------------
               LCD_RS <= 0;
               ready <= 0;
               STATE <= STATE;
               //LCD_E <= 0;
               
               if (SUBSTATE == 0) begin
                 LCD_E <= 1;
                 DATA_out <= DATA_in [7:4];
                   if (flag_250ns == 1) begin
                     flag_reset <= 1;
                     SUBSTATE <= SUBSTATE + 1; end
                   else begin
                     flag_reset <= 0;
                     SUBSTATE <= SUBSTATE; end
               end
               
               if (SUBSTATE == 1) begin
                 LCD_E <= 1;
                 DATA_out <= DATA_in [3:0];
                   if (flag_250ns == 1) begin
                     flag_reset <= 1;
                     SUBSTATE <= SUBSTATE + 1; end
                   else begin
                     flag_reset <= 0;
                     SUBSTATE <= SUBSTATE; end
               end
               
               if (SUBSTATE == 2) begin
                 LCD_E <= 0;
                 DATA_out <= DATA_out;
                 STATE <= STATE;
                   if (flag_100us) begin
                     flag_reset <= 1;
                     SUBSTATE <= 0;
                     STATE <= 7; end
                   else begin
                     flag_reset <= 0;
                     SUBSTATE <= SUBSTATE;
                     STATE <= STATE; end
               end
            end
            
           6: begin
           //-----------------------WRITE DATA-------------------------
              LCD_RS <= 1;
              ready <= 0;
              //LCD_E = 0;
              STATE <= STATE;
                if (SUBSTATE == 0) begin
                  LCD_E <= 1;
                  DATA_out <= DATA_in [7:4];
                    if (flag_250ns) begin
                      flag_reset <= 1;
                      LCD_E <= 0;
                      SUBSTATE <= SUBSTATE + 1; end
                    else begin
                      flag_reset <= 0;
                      LCD_E <= 1;
                      SUBSTATE <= SUBSTATE; end
              end
              
              if (SUBSTATE == 1) begin
                LCD_E <= 1;
                DATA_out <= DATA_in [3:0];
                  if (flag_250ns) begin
                    flag_reset <= 1;
                    LCD_E <= 0;
                    SUBSTATE <= SUBSTATE + 1; end
                  else begin
                    flag_reset <= 0;
                    LCD_E <= 1;
                    SUBSTATE <= SUBSTATE; end
              end
              
              if (SUBSTATE == 2) begin
                LCD_E <= 0;
                DATA_out <= DATA_out;
                STATE <= STATE;
                  if (flag_4100us) begin
                    flag_reset <= 1;
                    SUBSTATE <= 0;
                    STATE <= 7; end
                  else begin
                    flag_reset <= 0;
                    SUBSTATE <= SUBSTATE;
                    STATE <= STATE; end
              end
           end
           
     default: begin //------------WAIT FOR DATA OR INSTRUCTION-----------------
              LCD_RS <= LCD_RS;
              DATA_out <= DATA_out;
              LCD_E <= 0;
              ready <= 1; 
                if (start == 1 && reset == 0) begin
                  case (operation) 00: STATE <= STATE;
                                   01: STATE <= 6; //write data (character)
                                   10: STATE <= 5; //write instruction
                                   11: STATE <= 4; // clear display
                                   default: STATE <= STATE;
                  endcase
                end
                else if (reset == 1)
                   STATE <= 0;
     end
  endcase            
end           
               
    
endmodule
