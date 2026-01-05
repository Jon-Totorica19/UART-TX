// UART TX - Transmitter only

// UART-TX Module, CLK_PER_BIT Parameter(constant: 8), and Ports 
module UART_TX #(
	parameter int CLKS_PER_BIT = 8
) (
	input logic clk, reset, start,
	input logic [7:0] data_in,
	output logic tx, busy
);

	// Counts clock cylce within a bit
	logic [$clog2(CLKS_PER_BIT)-1:0] bit_clk_cnt; //$clog2(N): Smallest number of bits to represent N
	// Goes high when clock cycle for a bit ends
	logic bit_tick;
	assign bit_tick = (bit_clk_cnt == CLKS_PER_BIT - 1);

	// FSM States. 4 states -> 2 bits Encodings assigned automatically
	typedef enum logic [1:0] {
		IDLE,
		START,
		DATA,
		STOP
	} state_t;

	state_t current_state, next_state;

	// Datapath Registers 
	// Shift register (stores the byte)
	logic [7:0] shreg;
	// Store bit index 
	logic [2:0] bit_idx;

	// Bit Timer: Runs while busy, (not in IDLE)
	always_ff @(posedge clk or posedge reset) begin
		if (reset) begin
			bit_clk_cnt <= '0;
		end else begin			
			if (current_state == IDLE) begin // count only while transmitting
				bit_clk_cnt <= '0;
			end else if (bit_tick) begin
				bit_clk_cnt <= '0;
			end else begin
				bit_clk_cnt <= bit_clk_cnt + 1'b1;
			end 
		end
	end

	// State & Datapath Registers
	always_ff @ (posedge clk or posedge reset) begin
		if (reset) begin
			current_state <= IDLE;
			shreg <= '0;
			bit_idx <= '0;
		end else begin
			current_state <= next_state;

			// Load byte when state goes from IDLE -> START
			if (current_state == IDLE && start) begin
				shreg <= data_in;
				bit_idx <= '0;
			end
		
			// Advance data bits at bit time boundary
			if (current_state == DATA && bit_tick) begin
				shreg <= {1'b0, shreg[7:1]}; // shift bit right with 0
				if (bit_idx != 3'd7) // prevent wrap around of bit index
					bit_idx <= bit_idx + 1'b1; 
			end
		end
	end

	// Next State Logic
	always_comb begin
		next_state = current_state; // deafult: no change in state
		case (current_state)
			IDLE: begin
				if (start)
					next_state = START;
			end
			START:
				if (bit_tick)
					next_state = DATA;
			DATA:
				if (bit_tick && bit_idx == 3'd7)
					next_state = STOP;
			STOP:
				if (bit_tick)
					next_state = IDLE;
			default: next_state = IDLE;
		endcase
	end

	// Output Logic (MOORE)
	assign busy = (current_state != IDLE);
	always_comb begin
		// initialize signals, IDLE
		tx = 1;
		case (current_state)
			IDLE: begin
				tx = 1;
			end
			START: begin
				// drives the start bit low for one bit-time
				tx = 0;
			end
			DATA: begin
				// sends 8 data bits, LSB first
				tx = shreg[0];
			end
			STOP: begin
				// drive stop bit high for one bit time
				tx = 1;
			end
		endcase
	end

endmodule
	