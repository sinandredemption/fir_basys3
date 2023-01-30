`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023 Syed Fahad
//
// Create Date: 01/29/2023 05:13:37 PM
// Project Name: Real-time Audio Processing through FIR filters on Basys-3
// Description: Testbench for single-channel FIR filter backend
//
//////////////////////////////////////////////////////////////////////////////////


module single_channel_fir_filter_tb;
  reg clk;
  reg [3:0] sw;
  reg new_packet;
  reg signed [23:0] input_data [1:0];
  wire signed [23:0] output_data;
  wire signed [24-1:0] buffer [89-1:0];  // Buffer for data
  wire signed [16+24-1:0] op_buffer;

  wire [2:0] selected_filter;

  // Instantiate the fir_filter module
  single_channel_fir_engine uut (
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
    sw <= 4'b0001;
    clk = 0;
    forever #1 clk = ~clk;
  end

  // Initialize inputs for the test
  initial begin
    // Set up initial values for inputs
    #178.5
    input_data[0] <= 24'hF00000;
    input_data[1] <= 24'h00000F;
    #1
    input_data[0] <= 24'h000000;
    input_data[1] <= 24'h000000;
    
    // TODO Add more data...
  end
endmodule

