`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023 Syed Fahad
//
// Create Date: 01/28/2023 01:47:52 PM
// Project Name: Real-time Audio Processing through FIR filters on Basys-3
// Description: Implementation of a single/dual channel FIR filter module which
//  handles and connects the AXI stream to FIR filter backend
//
//////////////////////////////////////////////////////////////////////////////////

module dual_channel_fir_filter #(
    parameter DATA_WIDTH = 24,
    parameter N_FILTERS = 4 // Number of filters implemented
) (
    input wire clk,
    input wire [N_FILTERS-1:0] sw,
    
    //AXIS SLAVE INTERFACE
    input  wire [DATA_WIDTH-1:0] s_axis_data,
    input  wire s_axis_valid,
    output reg  s_axis_ready = 1'b1,
    input  wire s_axis_last,
    
    // AXIS MASTER INTERFACE
    output reg [DATA_WIDTH-1:0] m_axis_data = 1'b0,
    output reg m_axis_valid = 1'b0,
    input  wire m_axis_ready,
    output reg m_axis_last = 1'b0
);
    reg signed [DATA_WIDTH-1:0] input_data [1:0];    // Left and right channel data
    wire signed [DATA_WIDTH-1:0] output_data [1:0];    // Left and right channel data
    
    wire m_select = m_axis_last;
    wire m_new_word = (m_axis_valid == 1'b1 && m_axis_ready == 1'b1) ? 1'b1 : 1'b0;
    wire m_new_packet = (m_new_word == 1'b1 && m_axis_last == 1'b1) ? 1'b1 : 1'b0;
    
    wire s_select = s_axis_last;
    wire s_new_word = (s_axis_valid == 1'b1 && s_axis_ready == 1'b1) ? 1'b1 : 1'b0;
    wire s_new_packet = (s_new_word == 1'b1 && s_axis_last == 1'b1) ? 1'b1 : 1'b0;
    reg s_new_packet_r = 1'b0;
    
    dual_channel_fir_engine fir_engine(
        .clk(clk),
        .sw(sw),
        .new_packet(s_new_packet_r),
        .input_data(input_data),
        .output_data(output_data)
    );
    always@(posedge clk) begin
        s_new_packet_r <= s_new_packet;
        
        if (s_new_word == 1'b1) // Register AXIS slave data
            input_data[s_select] <= s_axis_data;
    end
            
    
    // Controls the AXIS master interface by setting the validity and end-of-packet signals based on the state of the AXIS slave interface.
    always@(posedge clk)
        if (s_new_packet_r == 1'b1)
            m_axis_valid <= 1'b1;
        else if (m_new_packet == 1'b1)
            m_axis_valid <= 1'b0;
            
    always@(posedge clk)
        if (m_new_packet == 1'b1)
            m_axis_last <= 1'b0;
        else if (m_new_word == 1'b1)
            m_axis_last <= 1'b1;
    
    // Assigns the output data on the AXIS master interface based on the validity and selection signals.
    always@(m_axis_valid, output_data[0], output_data[1], m_select)
        if (m_axis_valid == 1'b1)
            m_axis_data = output_data[m_select];
        else
            m_axis_data = 'b0;
            
    always@(posedge clk)
        if (s_new_packet == 1'b1)
            s_axis_ready <= 1'b0;
        else if (m_new_packet == 1'b1)
            s_axis_ready <= 1'b1;
endmodule

module single_channel_fir_filter #(
    parameter DATA_WIDTH = 24,
    parameter N_FILTERS = 4 // Number of filters implemented
) (
    input wire clk,
    input wire [N_FILTERS-1:0] sw,
    
    //AXIS SLAVE INTERFACE
    input  wire [DATA_WIDTH-1:0] s_axis_data,
    input  wire s_axis_valid,
    output reg  s_axis_ready = 1'b1,
    input  wire s_axis_last,
    
    // AXIS MASTER INTERFACE
    output reg [DATA_WIDTH-1:0] m_axis_data = 1'b0,
    output reg m_axis_valid = 1'b0,
    input  wire m_axis_ready,
    output reg m_axis_last = 1'b0
);
    reg signed [DATA_WIDTH-1:0] input_data [1:0];    // Left and right channel data
    wire signed [DATA_WIDTH-1:0] output_data;    // Combined output data
    
    wire m_select = m_axis_last;
    wire m_new_word = (m_axis_valid == 1'b1 && m_axis_ready == 1'b1) ? 1'b1 : 1'b0;
    wire m_new_packet = (m_new_word == 1'b1 && m_axis_last == 1'b1) ? 1'b1 : 1'b0;
    
    wire s_select = s_axis_last;
    wire s_new_word = (s_axis_valid == 1'b1 && s_axis_ready == 1'b1) ? 1'b1 : 1'b0;
    wire s_new_packet = (s_new_word == 1'b1 && s_axis_last == 1'b1) ? 1'b1 : 1'b0;
    reg s_new_packet_r = 1'b0;
    
    single_channel_fir_engine fir_engine(
        .clk(clk),
        .sw(sw),
        .new_packet(s_new_packet_r),
        .input_data(input_data),
        .output_data(output_data)
    );
    always@(posedge clk) begin
        s_new_packet_r <= s_new_packet;
        
        if (s_new_word == 1'b1) // Register AXIS slave data
            input_data[s_select] <= s_axis_data;
    end
    
    // Controls the AXIS master interface by setting the validity and end-of-packet signals based on the state of the AXIS slave interface.
    always@(posedge clk)
        if (s_new_packet_r == 1'b1)
            m_axis_valid <= 1'b1;
        else if (m_new_packet == 1'b1)
            m_axis_valid <= 1'b0;
            
    always@(posedge clk)
        if (m_new_packet == 1'b1)
            m_axis_last <= 1'b0;
        else if (m_new_word == 1'b1)
            m_axis_last <= 1'b1;
    
    // Assigns the output data on the AXIS master interface based on the validity and selection signals.
    always@(m_axis_valid, output_data, m_select)
        if (m_axis_valid == 1'b1)
            m_axis_data = output_data;
        else
            m_axis_data = 'b0;
            
    always@(posedge clk)
        if (s_new_packet == 1'b1)
            s_axis_ready <= 1'b0;
        else if (m_new_packet == 1'b1)
            s_axis_ready <= 1'b1;
endmodule
