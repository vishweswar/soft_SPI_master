`timescale 1ns/1ps

module spimaster (
	input CLOCK_50, 
	input enable,
	input reset_n, 
	input edge_signal,
   inout [35:0] GPIO_0,
	input [9:0] SW,	
	input scltrig,
	input ldData,
	input shift,
	output timing_met 
); 


	parameter integer count_cyc = 20; //set to  n - 1 for edge_signal to be pulled high on the nth cycle 
	parameter integer pos_or_neg = 0; 	
	timingCounter  #(.count_cyc(count_cyc), .pos_or_neg(pos_or_neg)) TC1 (.edge_signal(edge_signal), .enable(enable), .reset_n(reset_n), .clk(CLOCK_50), .timing_met(timing_met)); 

	
	wire CPOL; 
	wire SCLK; 	
	assign CPOL = 1'b1; 
	
	sclkLogic SCL1 (.sclk_trig(scltrig), .clk_ext(CLOCK_50), .CPOL(CPOL), .SCLK(SCLK));  
	
	wire [7:0] data; 
	assign data = 8'b11001110; 
	wire MOSI; 
	txBuffer TXB1 (.ldData(ldData), .shift(shift), .data(data), .reset_n(reset_n), .SCLK(SCLK), .MOSI(MOSI)); 
	
	wire [7:0] rx_buffer; 
	rxBuffer RXB1 (.MISO(), .shift(shift), .reset_n(reset_n), .SCLK(SCLK), .rx_buffer(rx_buffer)); 
	
endmodule 

module clockBox(
	input CLOCK_50, 
	input reset_n, 
	output clk_system, 
	output clk_ext	
); 

	////////////////////////////////////////PLL UNIT\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\	
	wire reset; 	
	assign reset = !reset_n; 	
	wire locked; 		
	pll PLL1 (.refclk(CLOCK_50), .rst(reset), .outclk_0(clk_system), .locked(locked));	
  	//clk_ext is SPI Frequency dependent and can be obtained either through a PLL or a Prescaler  
	
endmodule

module FSM(
	
); 

  localparam no_talk = 3'b000, idle_or_reset = 3'b001, press_wait = 3'b010, talk = 3'b011, display = 3'b100, result_wait = 3'b101;  

 //state table 
 always @ (*) begin 
	case(current_state) 
		

	endcase 
 end 
 
 always @ (*) begin 
    case(current_state) 
	 
	 endcase 
	 
	 if(current_state == no_talk) begin 
	   if(talk_switch == 1'b1) 
			next_state <= idle_or_reset; 
		else 
			next_state <= no_talk;
	 end
	 else if(current_state == idle_or_reset) begin 
	   if(talk_key == 1'b0) 
			next_state <= press_wait; 
		else 
			next_state <= idle_or_reset;
	 end
	 else if(current_state == press_wait) begin 
	   if(talk_key == 1'b1) 
			next_state <= talk; 
		else 
			next_state <= press_wait;
	 end
	 else if(current_state == talk) begin 
	   if(talk_key == 1'b1) 
			next_state <= talk; 
		else 
			next_state <= press_wait;
	 end
	 
	 
 end
 
endmodule 


module sclkLogic(	
	input  sclk_trig,
	input  reset_n, 
	input  clk_ext,
	input  CPOL, 
	output SCLK
); //asynchronous logic to drive SCLK
   assign SCLK = (sclk_trig == 1'b1 && reset_n)? clk_ext : CPOL; 
endmodule 

module shiftController #(parameter integer rx_cycle = 2, parameter integer tx_cycle = 2)(
	input sclk_trig, 
	input SCLK, 
	input enable, 
	input reset_n,
   output shift_tx,
	output shift_rx,
	output reg [2:0] cycle_counter //8 bit SCLK cycle counter
); 
//control signals for TX and RX buffer 

 
  
	always @ (negedge SCLK or negedge reset_n or negedge sclk_trig) begin //posedge SCLK when CPOL = 0
		if(sclk_trig && enable && reset_n) 
			cycle_counter <= cycle_counter + 1'b1;		
		else
			cycle_counter <= 3'b0; 
	end 
	
	assign shift_tx = (enable == 1'b1 && cycle_counter >= tx_cycle)? 1'b1:1'b0;	
	assign shift_rx = (enable == 1'b1 && cycle_counter >= rx_cycle)? 1'b1:1'b0; 
	
endmodule 

module csnLogic(
	input toggle, 
	output cs_n 
); 
	//toggles CS_N when toggle is on
	assign cs_n = (toggle == 1'b1)? 1'b0 : 1'b1; 
endmodule 

module txBuffer(
	input ldData,
	input shift,
	input [7:0] data, //adjust according to bit size 
	input reset_n,
	input SCLK,
	output reg MOSI
); 
 	
	reg [7:0] tx_buffer; 
	
	always @ (posedge SCLK or posedge ldData) begin //posedge when CPOL = 0 CPHA = 1 and 1,0 | negedge otherwise 
		if(!reset_n) 
			tx_buffer <= 8'b0; 
		else if(ldData) 
			tx_buffer <= data; 
		else if(shift) begin 
		   MOSI <= tx_buffer[7]; //MSB 
			tx_buffer <= {tx_buffer[6:0], 1'b0}; //shift_operation 
		end 
	end 
	
endmodule


module rxBuffer(
	input MISO, 
	input shift, 
	input reset_n,
	input SCLK, 
	output reg [7:0] rx_buffer	
); 
	always @ (negedge SCLK) begin //posedge when CPOL = 0 CPHA = 1 and 1,0 negedge otherwise
		if(!reset_n) 
			rx_buffer <= 8'b0; 
		else if(shift) begin 
			rx_buffer <= {rx_buffer[6:0], MISO}; //shift_operation 
		end 
	end 
endmodule 


module halfCounter( 
	input clk,
	input enable,
   input	reset_n,
	output reg [3:0] count	
); 

	always @ (posedge clk or negedge clk) begin
		if(!reset_n || !enable)
			count <= 6'b0; 
		else if(enable)
			count <= count + 1'b1; 
		end 
		
endmodule 


module timingCounter #(parameter integer count_cyc = 50, parameter integer pos_or_neg = 0)( 

	//this counter helps meet the timing requirements	
	input edge_signal, //pos_or_neg 1 posegde 0 negedge 
	input enable, 
	input reset_n, 
	input clk, 
	
	output reg timing_met //signal is pulled high until reset when the count_cyc value is counted 
); 

  //input clk frequency of 100 MHz gives a resolution of 10 ns 
  //the counter has a high time  
  
  reg [5:0] count_cycles; //count_cyc < 64
  reg pos_trig_count; 
  reg neg_trig_count;
  
  always @ (posedge edge_signal) begin
		if(!reset_n || !enable)
			pos_trig_count <= 1'b0; 
		else if(pos_or_neg == 1)
			pos_trig_count <= 1'b1; 
  end 
  
   always @ (negedge edge_signal) begin
		if(!reset_n || !enable)
			neg_trig_count <= 1'b0; 
		else if(pos_or_neg == 0)
			neg_trig_count <= 1'b1; 
  end 
    
  always @ (posedge clk) begin   
    if(!reset_n || !enable) begin 		
		timing_met <= 1'b0; 
		count_cycles <= 6'b0; 			
	 end 		
	 else if (enable) begin 
		if(count_cycles == count_cyc) begin 
			timing_met <= 1'b1; 
			count_cycles <= 6'b0; 
		end 
		else if(neg_trig_count | pos_trig_count)
			count_cycles <= count_cycles + 1'b1;  
	 end 
	 
  end 
endmodule 
