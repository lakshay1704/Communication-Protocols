//I2C slave module

module i2c_slave(scl,sda,data_out,reset,enable,clk);

	input scl; //coming from master
	input clk; //coming from testbench
	input reset; //coming from the testbench
	inout sda; //between master and slave;
	input enable; //coming from the testbench
	output reg [7:0] data_out;

	parameter idle = 3'b000; //idle state
	parameter start_bit = 3'b001; //detecting start bit
	parameter address_bits = 3'b010; //recieving address bits
	parameter ack_ad = 3'b011; //ack for address recieved
	parameter recieve_data = 3'b100; //recieve data
	parameter ack_rd = 3'b101; //ack for data recieved
	parameter stop_bit = 3'b110; //detecting stop bit

	reg [2:0] state;
	reg [3:0] count_data_bit; //this might be increased by 1 bit
	reg [2:0] count_address_bit;
	reg [7:0] temp_data = 0; //data recieved from the master to be stored in this
	reg [6:0] temp_address = 0; //address recieved from the master to be stored in this

	reg enable_to_send_slave = 0; //enable_sda for slave
	wire ValFromMaster; //value from the master will be stored here when enable_sda_slave = 1
	reg ValToMaster = 0; // value to the master will be stored here when enable_sda_slave = 0;

	//always @(posedge scl or posedge reset)
	always @(posedge clk)
	begin
		if (reset)
		begin
			data_out <= 0;
			count_data_bit <= 0;
			count_address_bit <= 0;
			state <= idle;
		end
		else 
		begin
			case (state)
				idle : begin
					if (enable) begin
						//enable_to_send_slave <= 1;
						state <= start_bit;
					end
					else begin
						state <= idle;
					end
				end

				start_bit : begin
					enable_to_send_slave <= 0;
					//ValFromMaster <= sda;
					//if (ValFromMaster == 0)
					//	state <= address_bits;
					//else
					//	state <= idle;
					//@(negedge sda);
					state <= address_bits;
				end

				address_bits : begin
					enable_to_send_slave <= 0;
					if (count_address_bit == 7) begin
						//ValFromMaster <= sda;
						temp_address[0] <= ValFromMaster;
						state <= ack_ad;
					end
					else begin
						//ValFromMaster = sda;
						temp_address[0] = ValFromMaster;
						temp_address = temp_address << 1;
						count_address_bit = count_address_bit + 1; //use shifting
					end
				end

				ack_ad : begin
					enable_to_send_slave <= 1;
					ValToMaster <= 1;
					//sda <= ValToMaster;
					state <= recieve_data;
				end

				recieve_data : begin
					enable_to_send_slave <= 0;
					if (count_data_bit == 8) begin
						//ValFromMaster <= sda;
						temp_data[0] <= ValFromMaster;
						state <= ack_rd;
					end
					else begin
						//ValFromMaster <= sda;
						temp_data[0] = ValFromMaster;
						temp_data = temp_data << 1;
						count_data_bit = count_data_bit + 1; //use shifting
					end
				end

				ack_rd : begin
					enable_to_send_slave <= 1;
					ValToMaster <= 1;
					state <= stop_bit;
					data_out <= temp_data;
				end

				stop_bit : begin
					enable_to_send_slave <= 0;
					//ValFromMaster <= sda;
					//if (ValFromMaster == 1)
					//	state <= idle;
					//else 
					//	state <= stop_bit;
					//@ (posedge sda);
					state <= idle;
				end
			endcase
		end
	end

	//always @(enable_sda_slave or sda)
//	always @(posedge clk)
//		ValFromMaster = enable_sda_slave ? sda : 1'hz;
	
//	assign sda = ValToMaster;

	assign sda = enable_to_send_slave ? ValToMaster : 1'hz;
	assign ValFromMaster = sda;
endmodule : i2c_slave