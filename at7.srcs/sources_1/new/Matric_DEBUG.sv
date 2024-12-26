`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/17 22:21:10
// Design Name: 
// Module Name: Matric_DEBUG
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Matric_DEBUG(
    input clk,rst_n,
    input i_start_matrix,

    output led,
    output o_uart_tx

    );
    wire [191: 0] i_adc_data;
    // wire i_start_matrix;
    wire i_data_valid = 1;;
    wire o_start_row;
    wire o_switch_row;
    assign i_adc_data = {8'h66, {22{8'h1a}}, 8'h99};
    assign led = i_start_matrix;
    
    matrix_ctrl_new  
    #(
        .ADC_NUM(1),
        .N_ROW(4),
        .N_COL(8),
        .CLK_FRE(50),
        .DATA_RATE(100),
        .BITMASK(10'b11_0111_1111)
    )matrix_ctrl_v2
    (
        .clk(clk),
        .rst_n(rst_n),
        .i_adc_data(i_adc_data),
        .i_start_matrix(i_start_matrix),
        .i_data_valid(i_data_valid),
        .o_start_row(o_start_row),
        .o_switch_row(o_switch_row),
        .o_uart_tx(o_uart_tx)
    );
endmodule
