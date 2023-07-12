`timescale 1ns/1ps

module testbench(); 

	//parameters for setting cycles for the shiftController   
	parameter integer rx_cycle = 4; 
	parameter integer tx_cycle = 2;	
	 
	//control signals from the testbench  
   reg reset_n, CPOL, feederEnable, scEnable, CLOCK_50, scltrig, ldData; 
	
	//nets for internal connections 
   wire MOSI, MISO, shift_rx, shift_tx, SCLK; 
	
	//data lines 
	wire [2:0] cycle_counter;
	wire [7:0] rx_buffer; 
	reg  [7:0] tx_data; 

	
	initial 
		begin
		CPOL = 1'b1; //assuming CPOL = 1 CPHA = 0 
	
		//idle state 
		reset_n = 1'b1;
		feederEnable = 1'b0; 
		scEnable = 1'b0; 
		scltrig = 1'b0; 
		ldData = 1'b0;		
		#100ns;
		
		//reset ON  
		reset_n = 1'b1; 
		#100ns;
		 
      //reset OFF
	   reset_n = 1'b0; 
		#100ns;

		//reset ON with other signals ON 
		reset_n = 1'b0; 		
		feederEnable = 1'b1; 
		scEnable = 1'b1; 
		scltrig = 1'b1; 
		ldData = 1'b1;	
		#100ns;
		
		//idle again
		reset_n = 1'b1;
		feederEnable = 1'b0; 
		scEnable = 1'b0; 
		scltrig = 1'b0; 
		ldData = 1'b0;		
		#100ns;
		
		//data line
		tx_data = 8'b11011010; 
		#20ns; 
		
		//ld data
		ldData = 1'b1; 
		#20ns; 
		
		//transmit and receive state 
		feederEnable = 1'b1; 
		scEnable = 1'b1; 
		scltrig = 1'b1; 
		ldData = 1'b0; 
		#280ns
		
		scltrig = 1'b0;
		end 
		
	 always
	   begin 
			CLOCK_50 = 1'b1; 
			#10ns;
			CLOCK_50 = 1'b0; 
			#10ns;
		end 
	
   
	sclkLogic SCL1 (.sclk_trig(scltrig), .clk_ext(CLOCK_50), .CPOL(CPOL), .SCLK(SCLK), .reset_n(reset_n));  
	
	wire [2:0] counter; 
	rxBuffer  RXB1 (.MISO(MISO), .shift(shift_rx), .reset_n(reset_n), .SCLK(SCLK), .rx_buffer(rx_buffer)); 	
	
	rxFeeder  RXF1 (.enable(feederEnable), .reset_n(reset_n), .SCLK(SCLK), .MISO(MISO), .counter(counter));
	
	txBuffer  TXB1 (.ldData(ldData), .shift(shift_tx), .data(tx_data), .reset_n(reset_n), .SCLK(SCLK), .MOSI(MOSI));

	shiftController #(.rx_cycle(rx_cycle), .tx_cycle(tx_cycle)) SC1 (.sclk_trig(scltrig), .SCLK(SCLK), .enable(scEnable), .reset_n(reset_n), .shift_tx(shift_tx), .shift_rx(shift_rx), .cycle_counter(cycle_counter)); 
	
endmodule 

module rxFeeder(
    input enable, 
	 input reset_n, 
	 input SCLK, 
	 output reg MISO, 
	 output reg [2:0] counter 
); 

	//reg [3:0] counter; 
	
	always @ (negedge SCLK or negedge reset_n) begin		
		if(!reset_n)  
			counter <= 4'b0; 
		else if(enable)
			counter <= counter + 1'b1;	
	end 
	
	always @ (posedge SCLK) begin 
		if(enable) begin 
			case(counter) 
			 4'd1: MISO <= 1'b1; 
			 4'd2: MISO <= 1'b0;
			 4'd3: MISO <= 1'b1;
		    4'd4: MISO <= 1'b1;
			 4'd5: MISO <= 1'b0;
			 4'd6: MISO <= 1'b1;
		    4'd7: MISO <= 1'b0;
			 4'd8: MISO <= 1'b1; 
			 default: MISO <= 1'b0; 
		    endcase;
		end 
	end 
	
endmodule

 