`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023 Syed Fahad
// 
// Create Date: 01/28/2023 01:47:52 PM
// Project Name: Real-time Audio Processing through FIR filters on Basys-3
// Description: Implementation of a single/dual channel FIR filter backend
// 
//////////////////////////////////////////////////////////////////////////////////

module dual_channel_fir_engine #(
    parameter DATA_WIDTH = 24,
    parameter N_FILTERS = 4, // Number of filters implemented
    parameter N_TAPS = 45,
    parameter COEFF_WIDTH = 16
) (
    input wire clk,
    input wire [N_FILTERS-1:0] sw,
    input wire new_packet,
    
    input reg signed [DATA_WIDTH-1:0] input_data [1:0],
    output reg signed [DATA_WIDTH-1:0] output_data [1:0],
    
    output reg signed [DATA_WIDTH-1:0] buffer [N_TAPS-1:0][1:0],  // Buffer for data
    output reg signed [COEFF_WIDTH+DATA_WIDTH-1:0] op_buffer [1:0],
    
    output reg [2:0] selected_filter
);
    // Coefficients for FIR filter
   reg signed [COEFF_WIDTH-1:0] coeffs [N_FILTERS-1:0][N_TAPS-1:0] = '{
   '{ // Low-pass filter: 1KHz
        16'h0007, 16'h0015, 16'h002B, 16'h004C, 16'h007E,
        16'h00C5, 16'h0127, 16'h01A6, 16'h0243, 16'h02FF,
        16'h03D9, 16'h04CC, 16'h05D4, 16'h06EA, 16'h0807,
        16'h0920, 16'h0A2E, 16'h0B25, 16'h0BFF, 16'h0CB1,
        16'h0D35, 16'h0D87, 16'h0DA3, 16'h0D87, 16'h0D35,
        16'h0CB1, 16'h0BFF, 16'h0B25, 16'h0A2E, 16'h0920,
        16'h0807, 16'h06EA, 16'h05D4, 16'h04CC, 16'h03D9,
        16'h02FF, 16'h0243, 16'h01A6, 16'h0127, 16'h00C5,
        16'h007E, 16'h004C, 16'h002B, 16'h0015, 16'h0007
    },
    '{ // High pass filter: 2KHz
        16'h0003, 16'h000F, 16'h001F, 16'h0035, 16'h0053,
        16'h0076, 16'h0098, 16'h00B3, 16'h00BB, 16'h00A4,
        16'h0062, 16'hFFEB, 16'hFF38, 16'hFE47, 16'hFD1E,
        16'hFBC7, 16'hFA54, 16'hF8DC, 16'hF778, 16'hF642,
        16'hF551, 16'hF4B8, 16'h7485, 16'hF4B8, 16'hF551,
        16'hF642, 16'hF778, 16'hF8DC, 16'hFA54, 16'hFBC7,
        16'hFD1E, 16'hFE47, 16'hFF38, 16'hFFEB, 16'h0062,
        16'h00A4, 16'h00BB, 16'h00B3, 16'h0098, 16'h0076,
        16'h0053, 16'h0035, 16'h001F, 16'h000F, 16'h0003
    },
    '{ // Bandpass: 1KHz to 4KHz
        16'hFFF3, 16'hFFB9, 16'hFF79, 16'hFF3B, 16'hFF16,
        16'hFF26, 16'hFF74, 16'hFFE3, 16'h0024, 16'hFFC6,
        16'hFE5D, 16'hFBBB, 16'hF826, 16'hF468, 16'hF1B5,
        16'hF15D, 16'hF45E, 16'hFAFF, 16'h0495, 16'h0F8A,
        16'h19B7, 16'h20EA, 16'h2384, 16'h20EA, 16'h19B7,
        16'h0F8A, 16'h0495, 16'hFAFF, 16'hF45E, 16'hF15D,
        16'hF1B5, 16'hF468, 16'hF826, 16'hFBBB, 16'hFE5D,
        16'hFFC6, 16'h0024, 16'hFFE3, 16'hFF74, 16'hFF26,
        16'hFF16, 16'hFF3B, 16'hFF79, 16'hFFB9, 16'hFFF3
    },
    '{ // Moving Average Filter
        16'h05B0, 16'h05B0, 16'h05B0, 16'h05B0, 16'h05B0,
        16'h05B0, 16'h05B0, 16'h05B0, 16'h05B0, 16'h05B0,
        16'h05B0, 16'h05B0, 16'h05B0, 16'h05B0, 16'h05B0,
        16'h05B0, 16'h05B0, 16'h05B0, 16'h05B0, 16'h05B0,
        16'h05B0, 16'h05B0, 16'h05B0, 16'h05B0, 16'h05B0,
        16'h05B0, 16'h05B0, 16'h05B0, 16'h05B0, 16'h05B0,
        16'h05B0, 16'h05B0, 16'h05B0, 16'h05B0, 16'h05B0,
        16'h05B0, 16'h05B0, 16'h05B0, 16'h05B0, 16'h05B0,
        16'h05B0, 16'h05B0, 16'h05B0, 16'h05B0, 16'h05B0
    }};
    
    always@(posedge clk) begin
        // Update the currently selected filter
        case (sw)
            4'b0000: selected_filter <= 0;
            4'b0001: selected_filter <= 4;
            4'b0010: selected_filter <= 3;
            4'b0100: selected_filter <= 2;
            4'b1000: selected_filter <= 1;
            default: selected_filter <= 0;
        endcase
            
        // Hold the latest input on top of buffer (buffer[N_TAPS - 1])
        if (new_packet == 1'b1) begin // New packet recieved
            buffer[N_TAPS - 1][0] <= input_data[0];
            buffer[N_TAPS - 1][1] <= input_data[1];
        end
    end

    // The input buffer acts like a large shift register
    generate
    for (genvar i = 0; i < N_TAPS - 1; i = i+1) begin
        always@(posedge clk)
            if (new_packet == 1'b1) begin // New packet recieved
                // Shift the old packets so that buffer[N_TAPS - 1] holds the latest one
                buffer[i][0]  <= buffer[i + 1][0];
                buffer[i][1]  <= buffer[i + 1][1];
            end
    end
    endgenerate
    
    // Actually compute the output
    always@(posedge clk)
        if (new_packet == 1'b1 && selected_filter != 0) begin // New packet recieved
            op_buffer[0] = coeffs[selected_filter - 1][0] * buffer[N_TAPS - 1][0];
            op_buffer[1] = coeffs[selected_filter - 1][0] * buffer[N_TAPS - 1][1];
            for (int i = 1; i < N_TAPS; i = i+1) begin
                op_buffer[0] = op_buffer[0] + coeffs[selected_filter - 1][i] * buffer[N_TAPS - i - 1][0];
                op_buffer[1] = op_buffer[1] + coeffs[selected_filter - 1][i] * buffer[N_TAPS - i - 1][1];
            end
            if (op_buffer[0][COEFF_WIDTH+DATA_WIDTH-1] == 1'b1) begin   // If is negative
                output_data[0] = -((-op_buffer[0]) >> COEFF_WIDTH);     // Convert to +ve for shifting
            end
            else output_data[0] <= op_buffer[0][COEFF_WIDTH+DATA_WIDTH-1:COEFF_WIDTH];
            if (op_buffer[1][COEFF_WIDTH+DATA_WIDTH-1] == 1'b1) begin   // If is negative
                output_data[1] = -((-op_buffer[1]) >> COEFF_WIDTH);     // Convert to +ve for shifting
            end
            else output_data[1] <= op_buffer[1][COEFF_WIDTH+DATA_WIDTH-1:COEFF_WIDTH];
        end
        else if (new_packet == 1'b1 && selected_filter == 0) begin
                output_data[0] <= input_data[0];
                output_data[1] <= input_data[1];
        end
endmodule

module single_channel_fir_engine #(
    parameter DATA_WIDTH = 24,
    parameter N_FILTERS = 4, // Number of filters implemented
    parameter N_TAPS = 89,
    parameter COEFF_WIDTH = 16
) (
    input wire clk,
    input wire [N_FILTERS-1:0] sw,
    input wire new_packet,
    
    input reg signed [DATA_WIDTH-1:0] input_data [1:0],
    output reg signed [DATA_WIDTH-1:0] output_data,
    
    output reg signed [DATA_WIDTH-1:0] buffer [N_TAPS-1:0],  // Buffer for data
    output reg signed [COEFF_WIDTH+DATA_WIDTH-1:0] op_buffer,
    
    output reg [2:0] selected_filter
);
    // --
   reg signed [COEFF_WIDTH-1:0] coeffs [N_FILTERS-1:0][N_TAPS-1:0] = '{
   '{ // Low-pass filter: 1KHz
        -16'h0006, -16'h0011, -16'h001C, -16'h0027, -16'h0031,
        -16'h003A, -16'h0040, -16'h0041, -16'h003B, -16'h002C,
        -16'h0013, 16'h0011, 16'h003D, 16'h0071, 16'h00A7,
        16'h00DA, 16'h0104, 16'h011C, 16'h011D, 16'h00FF,
        16'h00BF, 16'h005C, -16'h002A, -16'h00CB, -16'h017C,
        -16'h0231, -16'h02D7, -16'h035B, -16'h03A7, -16'h03AA,
        -16'h0351, -16'h028F, -16'h015E, 16'h0043, 16'h024D,
        16'h04B0, 16'h0755, 16'h0A22, 16'h0CF4, 16'h0FA8,
        16'h121B, 16'h142A, 16'h15BA, 16'h16B3, 16'h1707,
        16'h16B3, 16'h15BA, 16'h142A, 16'h121B, 16'h0FA8,
        16'h0CF4, 16'h0A22, 16'h0755, 16'h04B0, 16'h024D,
        16'h0043, -16'h015E, -16'h028F, -16'h0351, -16'h03AA,
        -16'h03A7, -16'h035B, -16'h02D7, -16'h0231, -16'h017C,
        -16'h00CB, -16'h002A, 16'h005C, 16'h00BF, 16'h00FF,
        16'h011D, 16'h011C, 16'h0104, 16'h00DA, 16'h00A7,
        16'h0071, 16'h003D, 16'h0011, -16'h0013, -16'h002C,
        -16'h003B, -16'h0041, -16'h0040, -16'h003A, -16'h0031,
        -16'h0027, -16'h001C, -16'h0011, -16'h0006
    },
    '{ // High pass filter: 2KHz
        16'h0003, 16'h0008, 16'h000E, 16'h0013, 16'h0019,
        16'h001D, 16'h0020, 16'h0020, 16'h001D, 16'h0016,
        16'h0009, -16'h0008, -16'h001F, -16'h0038, -16'h0053,
        -16'h006D, -16'h0082, -16'h008E, -16'h008E, -16'h007F,
        -16'h005F, -16'h002E, 16'h0015, 16'h0065, 16'h00BE,
        16'h0118, 16'h016B, 16'h01AC, 16'h01D2, 16'h01D4,
        16'h01A7, 16'h0147, 16'h00AE, -16'h0022, -16'h0126,
        -16'h0256, -16'h03A8, -16'h050E, -16'h0676, -16'h07CF,
        -16'h0907, -16'h0A0F, -16'h0AD6, -16'h0B52, 16'h7483,
        -16'h0B52, -16'h0AD6, -16'h0A0F, -16'h0907, -16'h07CF,
        -16'h0676, -16'h050E, -16'h03A8, -16'h0256, -16'h0126,
        -16'h0022, 16'h00AE, 16'h0147, 16'h01A7, 16'h01D4,
        16'h01D2, 16'h01AC, 16'h016B, 16'h0118, 16'h00BE,
        16'h0065, 16'h0015, -16'h002E, -16'h005F, -16'h007F,
        -16'h008E, -16'h008E, -16'h0082, -16'h006D, -16'h0053,
        -16'h0038, -16'h001F, -16'h0008, 16'h0009, 16'h0016,
        16'h001D, 16'h0020, 16'h0020, 16'h001D, 16'h0019,
        16'h0013, 16'h000E, 16'h0008, 16'h0003
    },
    '{ // Bandpass: 1KHz to 4KHz
        -16'h0002, -16'h0010, -16'h0017, -16'h0013, 16'h0001,
        16'h0025, 16'h0054, 16'h0086, 16'h00AD, 16'h00BA,
        16'h00A6, 16'h0073, 16'h0031, -16'h0006, -16'h0014,
        16'h001B, 16'h0089, 16'h011D, 16'h01A8, 16'h01EC,
        16'h01B6, 16'h00EE, -16'h0057, -16'h01D6, -16'h032C,
        -16'h03F4, -16'h03EA, -16'h030B, -16'h01A5, -16'h004A,
        16'h0050, -16'h0071, -16'h02D8, -16'h06B4, -16'h0B46,
        -16'h0F67, -16'h11BF, -16'h1127, -16'h0CFB, -16'h055D,
        16'h04C0, 16'h0FB6, 16'h198B, 16'h2059, 16'h22C8,
        16'h2059, 16'h198B, 16'h0FB6, 16'h04C0, -16'h055D,
        -16'h0CFB, -16'h1127, -16'h11BF, -16'h0F67, -16'h0B46,
        -16'h06B4, -16'h02D8, -16'h0071, 16'h0050, -16'h004A,
        -16'h01A5, -16'h030B, -16'h03EA, -16'h03F4, -16'h032C,
        -16'h01D6, -16'h0057, 16'h00EE, 16'h01B6, 16'h01EC,
        16'h01A8, 16'h011D, 16'h0089, 16'h001B, -16'h0014,
        -16'h0006, 16'h0031, 16'h0073, 16'h00A6, 16'h00BA,
        16'h00AD, 16'h0086, 16'h0054, 16'h0025, 16'h0001,
        -16'h0013, -16'h0017, -16'h0010, -16'h0002
    },
    '{ // Moving Average Filter
        16'h02E0, 16'h02E0, 16'h02E0, 16'h02E0, 16'h02E0,
        16'h02E0, 16'h02E0, 16'h02E0, 16'h02E0, 16'h02E0,
        16'h02E0, 16'h02E0, 16'h02E0, 16'h02E0, 16'h02E0,
        16'h02E0, 16'h02E0, 16'h02E0, 16'h02E0, 16'h02E0,
        16'h02E0, 16'h02E0, 16'h02E0, 16'h02E0, 16'h02E0,
        16'h02E0, 16'h02E0, 16'h02E0, 16'h02E0, 16'h02E0,
        16'h02E0, 16'h02E0, 16'h02E0, 16'h02E0, 16'h02E0,
        16'h02E0, 16'h02E0, 16'h02E0, 16'h02E0, 16'h02E0,
        16'h02E0, 16'h02E0, 16'h02E0, 16'h02E0, 16'h02E0,
        16'h02E0, 16'h02E0, 16'h02E0, 16'h02E0, 16'h02E0,
        16'h02E0, 16'h02E0, 16'h02E0, 16'h02E0, 16'h02E0,
        16'h02E0, 16'h02E0, 16'h02E0, 16'h02E0, 16'h02E0,
        16'h02E0, 16'h02E0, 16'h02E0, 16'h02E0, 16'h02E0,
        16'h02E0, 16'h02E0, 16'h02E0, 16'h02E0, 16'h02E0,
        16'h02E0, 16'h02E0, 16'h02E0, 16'h02E0, 16'h02E0,
        16'h02E0, 16'h02E0, 16'h02E0, 16'h02E0, 16'h02E0,
        16'h02E0, 16'h02E0, 16'h02E0, 16'h02E0, 16'h02E0,
        16'h02E0, 16'h02E0, 16'h02E0, 16'h02E0
    }};
    
    always@(posedge clk) begin
        // Update the currently selected filter
        case (sw)
            4'b0000: selected_filter <= 0;
            4'b0001: selected_filter <= 4;
            4'b0010: selected_filter <= 3;
            4'b0100: selected_filter <= 2;
            4'b1000: selected_filter <= 1;
            default: selected_filter <= 0;
        endcase
            
        // Hold the latest input on top of buffer (buffer[N_TAPS - 1])
        if (new_packet == 1'b1) begin // New packet recieved
            buffer[N_TAPS - 1] <= (input_data[0] + input_data[1]) / 2;
        end
    end
            
    generate
    for (genvar i = 0; i < N_TAPS - 1; i = i+1) begin
        always@(posedge clk)
            if (new_packet == 1'b1) begin // New packet recieved
                // Shift the old packets so that buffer[N_TAPS - 1] holds the latest one
                buffer[i]  <= buffer[i + 1];
            end
    end
    endgenerate
    
    // Actually compute the output
    always@(posedge clk)
        if (new_packet == 1'b1 && selected_filter != 0) begin // New packet recieved
            op_buffer = coeffs[selected_filter - 1][0] * buffer[N_TAPS - 1];
            for (int i = 1; i < N_TAPS; i = i+1)
                op_buffer = op_buffer + coeffs[selected_filter - 1][i] * buffer[N_TAPS - i - 1];
            
            
            if (op_buffer[COEFF_WIDTH+DATA_WIDTH-1] == 1'b1)   // If is negative
                output_data = -((-op_buffer) >> COEFF_WIDTH);     // Convert to +ve for shifting
            else output_data <= op_buffer[COEFF_WIDTH+DATA_WIDTH-1:COEFF_WIDTH];
            
        end
        else if (new_packet == 1'b1 && selected_filter == 0)
            output_data <= (input_data[0] + input_data[1]) / 2;
endmodule
