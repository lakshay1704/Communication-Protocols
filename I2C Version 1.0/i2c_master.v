//I2C master module
//master generates the clock (SCL) for the slaves
//input is the clock on the fpga

//1. start bit
//2. slave address
//3. ack from slave
//4. data
//5. ack from slave
//6. stop bit
//why no parity bit?
	//because of the ack from the slave after 8 bit data transferred from master to slave

module i2c_master(clk,data_in,reset,address,sda,enable);

	//inputs to the master
	input clk,enable; //fpga clock
	//input r_wb; //for write should be 0
	input [7:0] data_in;
	input reset;
	input [6:0] address;
	//output scl = 0; //by default pulled high
	inout sda; //by default pulled high 

	//assign sda = 1'b1;

	parameter idle = 3'b000; //idle state
	parameter start_bit = 3'b001; //sending start bit
	parameter address_bits = 3'b010; //sending address bits
	parameter ack_ad = 3'b011; //ack for address recieved from the reciever
	parameter send_data = 3'b100; //send data
	parameter ack_sd = 3'b101; //ack for data recieved from the reciever
	parameter stop_bit = 3'b110; //sending stop bit

	reg [2:0] state;
	reg [3:0] count_data_bit;
	reg [2:0] count_address_bit; //this might be increase by 1 bit
	reg [7:0] temp_data;
	reg [6:0] temp_addr;

	reg enable_to_send = 1; // high for sending and low for high impedance
	wire ValFromSlave; //will recieve value from slave through sda when enable_to_send is 0
	reg ValToSlave = 0; //will be connected to the sda via tri state buffer when enable_to_send is 1
	//wire ValToSlave;
	
	//assign sda = enable_sda ? ValToSlave : 1'hz;
	always @(posedge clk or posedge reset)
	begin
		if (reset)
		begin
			state <= idle;
			//enable_to_send <= 0; //default high impedance should be pull up to high via TB
			count_address_bit = 0;
			count_data_bit = 0;
			temp_data <= 0;
			temp_addr <= 0;
			//sda <= 1;
		end

		else 
		begin
			case (state)
				idle : begin
					if (enable)
					begin
						state <= start_bit;
						//enable_to_send <= 1;
						temp_data <= data_in; //try doing it in data sending state
						temp_addr <= address; //try doing it in address sending state
					end

					else begin
						state <= idle;
					end
				end

				start_bit : begin
					enable_to_send <= 1;
					ValToSlave <= 0;
					state <= address_bits;
				end

				address_bits : begin
					enable_to_send <= 1;
					//temp_addr <= address; already done in idle state
					//use shifting
					if (count_address_bit == 7) begin
						//enable_sda <= 1;
						ValToSlave <= temp_addr[6];
						state <= ack_ad; //ack for slave address
					end

					else begin
						//enable_sda <= 1;
						ValToSlave <= temp_addr[6];
						temp_addr <= temp_addr << 1;
						count_address_bit <= count_address_bit + 1;
					end
				end

				ack_ad : begin
					enable_to_send <= 0;
					//ValFromSlave <= sda;
					//@(posedge sda);
					//if (ValFromSlave == 1)
					//begin
					//	state <= send_data;
					//end
					//else 
					//	state <= ack_ad;
						//state <= idle;
					state <= send_data;
				end

				send_data : begin
					enable_to_send <= 1;
					//temp_data <= data_in;
					if (count_data_bit == 8) begin
						//enable_sda <= 1;
						ValToSlave <= temp_data[7];
						state <= ack_sd; //ack for slave data
					end

					else begin
						ValToSlave <= temp_data[7];
						temp_data <= temp_data << 1;
						count_data_bit <= count_data_bit + 1;
					end
				end

				ack_sd : begin
					enable_to_send <= 0;
					//ValFromSlave <= sda;
					//@(posedge sda);
					//if (ValFromSlave == 1)
					//begin
					//	state <= stop_bit;
					//end
					//else 
					//	state <= ack_sd;
					//	state <= idle;
					state <= stop_bit;
				end

				stop_bit : begin
					enable_to_send <= 1;
					ValToSlave <= 1;
					state <= idle;
				end
			endcase
		end
	end

//	always @(posedge clk) begin
//		if (state == idle)
//			scl <= 1;
//		else begin
//			#10 scl = ~scl;
//		end
//	end

	//always @(enable_sda or ValToSlave)
	assign sda = enable_to_send ? ValToSlave : 1'bz; //try to put it inside always block
							//the above statement is called procedural continous statement
	assign ValFromSlave = sda;
//	always @(posedge clk)
//	begin
//		if (!enable_sda)
//			ValFromSlave <= sda;
//	end

endmodule : i2c_master
