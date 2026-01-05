// UART_TX Testbench

module UART_TX_tb;

	// Declare tb signals
	logic clk, reset, start;
	logic [7:0] data_in;
	logic tx, busy;

	// Instantiate UUT
	UART_TX UUT ( // to override parameter, such as 16 clks per bit: UART_TX #(.CLKS_PER_BIT(16)) UUT (...)
		.clk(clk),
		.reset(reset),
		.start(start),
		.data_in(data_in),
		.tx(tx),
		.busy(busy)
	);

	// Clk generator, 10 time units per cycle
	initial begin
	clk = 0;
	forever #5 clk = ~clk;
	end

	// Stimulus 
	initial begin

	// Initialize signals
	reset = 1'b1;
	start = '0;
	data_in = 8'b10110111;

	// Stay in IDLE state
	#20;

	// Release reset
	@ (negedge clk)
	reset = 0;

	// Pulse start for one clock cycle
	// Will go to START state
	@ (negedge clk)
	start = 1;

	@ (negedge clk)
	start = 0;
		
	/*
	start bit: 0 will be output to tx for CLKS_PER_BIT cycles (8)
	8 clock cycles = 80 time units
	bit-tick will be asserted and will move to DATA state
	*/
	// #80;

	/*
	Leave in DATA state until all 8 bits are sent -> bit_idx == 7
	occures after 8 bits x 8 clock cylces = 64 cycles = 640 time units
	Will then move to STOP state
	*/
	// #640;

	/*
	stop bit: 1 will be output to tx for one CLK_PER_BIT cycle
	then will be sent back to IDLE state
	*/
	// #80;

	// Wait for transmitter to run through all bits
	$display("after start pulse t=%0t", $time);

	$display("waiting busy rise t=%0t", $time);
	wait (busy == 1'b1);
	$display("busy rose t=%0t", $time);

	wait (busy == 1'b0); 
	$display("busy fell t=%0t", $time);

	# 20 $display("DONE t=%0t", $time);
	$finish;
	end
endmodule