//I2C testbench
//input to the testbench declared as wire
//output from the testbench declared as reg

module i2c_testbench();

	//defining the ports
	reg clk; 
	reg [7:0] data_in;
	reg reset,enable;
	reg [6:0] address;
	wire [7:0] data_out;

	reg r_wb = 0; //master writing to the slave
	//reg r_wb = 1; //master reading from the slave

	//instantiating the master and the slave
	i2c_master master(clk,data_in,reset,address,sda,enable);
	i2c_slave slave(scl,sda,data_out,reset,enable,clk);

	// assign scl = 1'b1;
	// assign sda = 1'b1;

	initial 
	begin
		clk = 0;
	end

	always #10 clk = ~clk;

	initial
	begin
		#5;
		reset = 1;
		#10;
		reset = 0;
		enable = 1;
		#5;
		//data_in = 8'b10110101;
		data_in = 8'b01100111;
		//data_in = 8'b01101100;
		//data_in = 8'b10110000;
		address = 7'b0101101;
		#700;
		reset = 1;
		#10;
		reset = 0;
		enable = 0;
	end

endmodule : i2c_testbench