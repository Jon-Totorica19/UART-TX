# UART-TX

## Overview
UART Transmitter that sends an 8-bit byte on the transmitter line using UART framing (1 start, 8 data bits: LSB first, 1 stop).

## Interface
- Inputs: clk, reset (active high), start, data_in[7:0]
- Outputs: tx, busy
- Parameter: CLKS_PER_BIT: clock cyclers per UART bit

## Behavior
- tx idles high
- When start is asserted in IDLE, transmission begins: start bit (0) --> 8 data bits --> stop bit (1)
- busy is asserted while transmitting (state != IDLE)

## Timing
- Each UART bit is held for CLKS_PER_BIT clock cycles
 Total frame time = 10 * CLKS_PER_BIT cycles

## Files
- UART_TX.sv: RTL implementation (FSM + bit-timer + shift register)
- UART_TX_tb.sv: Testbench

## How to Simulate (ModelSim)
```tcl
vlib work
vlog -sv UART_TX.sv UART_TX_tb.sv
vsim work.UART_TX_tb
add wave -r *
run -all
```

## Testbench Coverage
- Reset to IDLE
- One-cycle pulse in IDLE
- Transmit an example byte (0xB7)
- Wait for busy to go from high --> low
- Verify waveform shows correct start/data/stop timing

## Result Waveform
<img width="1025" height="329" alt="image" src="https://github.com/user-attachments/assets/91abb55e-5d30-4f00-8fdd-11331619f95b" />

