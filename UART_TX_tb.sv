// UART_TX Testbench

module UART_TX_tb;

	localparam int CLKS_PER_BIT = 8;

	// Declare tb signals
	logic clk, reset, start;
	logic [7:0] data_in;
	logic tx, busy;

	// Instantiate UUT
	UART_TX #(.CLKS_PER_BIT(CLKS_PER_BIT)) UUT ( // to override parameter, such as 16 clks per bit: UART_TX #(.CLKS_PER_BIT(16)) UUT (...)
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

	// Task: Drive a 1-cycle start pulse and load data
	task automatic pulse_start(input logic [7:0] b);
		@(negedge clk);
		data_in = b;
		start = 1'b1;
		
		@(negedge clk);
		start = 1'b0;
	endtask

	// Task: Self check one UART frame on tx
	task automatic check_byte(input logic [7:0] exp);
		int i;

		// Wait for start bit to begin (tx deasserted)
		@(negedge tx);
		
		// Move to middle of start bit, then sample
		repeat (CLKS_PER_BIT/2) @(posedge clk);
		#1;
		if (tx !== 1'b0) $fatal(1, "Start bit wrong. Expected 0, got %0b at t=%0t", tx, $time);

		// Check busy state
		if (busy !== 1'b1) $fatal(1, "busy not high during transmit at t=%0t", $time);

		// Sample each data bit in the middle of its period
		for (i=0; i < 8; i++) begin
			repeat(CLKS_PER_BIT) @(posedge clk);
			#1;
			if (tx !== exp[i])
				$fatal(1, "Data bit %0d wrong. Expected %0b, got %0b at t=%0t", i, exp[i], tx, $time);
		end

		// Sample stop bit
		repeat (CLKS_PER_BIT) @(posedge clk);
		#1;
		if (tx !== 1'b1) $fatal(1, "Stop bit wrong. Expected 1, got %0b at t=%0t", tx, $time);
	endtask

	// Stimulus 
	initial begin

	// Initialize signals
	reset = 1'b1;
	start = 1'b0;
	data_in = '0;

	// Hold reset, stay in IDLE for a couple cylces
	repeat (2) @(negedge clk);
	reset = 1'b0;
	
	// Start checker before pulse start, run the to in parallel
	fork begin
		check_byte(8'hB7);
	end
	begin
		pulse_start(8'hB7);
		$display("Sending byte = 0x%0h at t=%0t", 8'hB7, $time);
	end
	join

	// Wait until transmitter is back to IDLE
	wait (busy == 1'b0);
		
	$display("Pass: UART_TX transmitted correctly. t=%0t", $time);
	$finish;
	end

endmodule
