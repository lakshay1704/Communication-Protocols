//UART
//Universal Aynchronous Reciever Transmitter

module u_art(); //top module uart
	
	reg clk; //to the transmitter and reciever
	reg reset; //to the transmitter and reciever
	reg enable; //to the transmitter
	reg [7:0] tx_data; //to the transmitter
	wire tx; //from the transmitter
	wire busy; //from the transmitter
	wire [7:0] rx; //from the reciever
	wire parity_error; //from the reciever
	wire rx_done; //from the reciever

	u_art_tx transmitter(clk,reset,enable,tx_data,tx,busy); //instantiate transmitter
	u_art_rx reciever(tx,clk,reset,parity_error,rx,rx_done); //instantiate receiver

	initial 
	begin
		clk = 0;
	end
	always #10 clk = ~clk; //clock time period = 10 time units

	initial
	begin
		reset = 0;
		#20;
		reset = 1;
		#20;
		reset = 0;
		enable = 1;
		//tx_data = 8'b10110101;
		//tx_data = 8'b01101100;
		//tx_data = 8'b10110000;
		tx_data = 8'b01100111;
		#20;
		enable = 0; //comment this if not working
		#400;
		reset = 1;
		//enable = 0; //uncomment this if not working
		enable = 1;
		#20;
		reset = 0;
		enable = 0;
		//reset = 1;
		//$stop;
		
	end

endmodule : u_art

module u_art_tx(clk,reset,enable,tx_data,tx,busy);//uart trasmitter

	input clk,reset,enable;
	input [7:0] tx_data; //data to be transmitted
	output reg tx; //serial data to be trasmitted
	output reg busy; //high when transmitter sending data
		     //as soon as data transmission done this goes low
	
	//different states
	parameter idle = 3'b000, start = 3'b001, data = 3'b010, parity = 3'b011, stop = 3'b100;
	
	reg [2:0] state;
	reg [3:0] count;
	reg [7:0] temp;

	always @(posedge clk or posedge reset)
	begin
	
		if (reset) begin
			state <= idle;
			tx <= 1'b1; //delete this if not working added at night
		end
		else
		begin
			case (state)
				idle : begin
							if (enable)
								begin
									//busy <= 1'b1;
									count <= 4'b0000;
									temp <= tx_data;
									state <= start; //delete this if not working
									tx <= 1'b1; //delete this if not working added at night
								end
							else 
								begin
									//busy <= 1'b0;
									tx <= 1'b1;
									//state <= start;
								end	
						end

				start : begin
							tx <= 1'b0;
							busy <= 1'b1;
							state <= data;
						end

				data : begin
							if (count == 4'b1000)
								begin
									tx <= temp[7];
									state <= parity;
								end
							else 
								begin
									//tx <= temp[count];
									tx <= temp[7];
									temp <= temp << 1;
									count <= count + 1;
								end
						end

				parity : begin
							tx <= ^temp;
							state <= stop;
						end

				stop : begin
							tx <= 1'b1;
							temp <= 0;
							state <= idle;
						end
			endcase
		end
	end

endmodule : u_art_tx

module u_art_rx(tx,clk,reset,parity_error,rx,rx_done); //uart reciever

	input tx;
	input clk,reset;
	output reg parity_error;
	output reg [7:0] rx; //the data it recieved
	output reg rx_done;

	parameter 	idle =	2'b00, data = 2'b01, parity = 2'b10, stop =	2'b11;

	reg [1:0] state;
	reg [3:0] count;
	reg [7:0] temp = 0;

	reg parity_bit;

	always @(posedge clk or posedge reset)
		begin
			if (reset)
				begin
					state <= idle;
					rx_done <= 0;
					parity_error <= 1'bx;
					rx <= 0;
					count <= 0;
					rx_done <= 0;
				end
			else 
				begin
					case (state)
						idle : begin
									@(negedge tx);
									state <= data;
								end

						data : begin
									//temp[0] = tx;
									//count <= 0;
									if (count == 8)
										begin
											temp[0] <= tx;
											state <= parity;
										end
									else
										begin
											temp[0] = tx;
											//temp[7] <= tx;
											//temp = temp << 1; //make the shifting work
											//debug the tx
											//how data bits are comming out of tx
											//which bit first?
											temp = temp << 1;
											count = count + 1;
										end
								end
						parity : begin
									parity_bit = ^temp;
									if (tx == parity_bit)
										begin
											parity_error <= 1'b0;
											rx <= temp;
											state <= stop;
										end
									else 
										begin
											parity_error <= 1'b1;
											rx <= temp;
											state <= stop;
										end
								end

						stop : begin
									@(posedge tx)
									state <= idle;
									rx_done <= 1;
								end
					endcase
				end
		end

endmodule : u_art_rx
