`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023 Syed Fahad
//
// Create Date: 01/29/2023 05:13:37 PM
// Project Name: Real-time Audio Processing through FIR filters on Basys-3
// Description: Testbench for dual-channel FIR filter backend
//
//////////////////////////////////////////////////////////////////////////////////


module dual_channel_fir_filter_tb;
  reg clk;
  reg [3:0] sw;
  reg new_packet;
  reg [23:0] input_data [1:0];
  wire [23:0] output_data [1:0];
  wire [24-1:0] buffer [45-1:0][1:0];  // Buffer for data
  wire [16+24-1:0] op_buffer [1:0];

  wire [2:0] selected_filter;

  // Instantiate the fir_filter module
  dual_channel_fir_engine uut (
    .clk(clk),
    .sw(sw),
    .new_packet(new_packet),
    .input_data(input_data),
    .output_data(output_data),
    .buffer(buffer),
    .op_buffer(op_buffer),
    .selected_filter(selected_filter)
  );

  // Clock generation for the testbench
  initial begin
    input_data[0] <= 24'h000000;
    input_data[1] <= 24'h000000;
    new_packet <= 1;
    sw <= 4'b0010;
    clk = 0;
    forever #1 clk = ~clk;
  end

  // Initialize inputs for the test
  initial begin
    // Set up initial values for inputs
    #90.5
    input_data[0] <= 24'h100000;
    input_data[1] <= 24'hF0000F;
    #1
    input_data[0] <= 24'h000000;
    input_data[1] <= 24'h000000;
    
    // TODO Add more data...
  end
endmodule

