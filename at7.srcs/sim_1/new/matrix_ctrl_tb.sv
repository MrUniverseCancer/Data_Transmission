`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/16 21:58:08
// Design Name: 
// Module Name: matrix_ctrl_tb
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


module matrix_ctrl_tb(

    );
    reg clk, rst_n;
    wire [191: 0] i_adc_data;
    reg i_start_matrix;
    wire i_data_valid = 1;;

    wire o_start_row;
    wire o_switch_row;
    wire o_uart_tx;
    matrix_ctrl_new  matrix_ctrl_v2 (
        .clk(clk),
        .rst_n(rst_n),
        .i_adc_data(i_adc_data),
        .i_start_matrix(i_start_matrix),
        .i_data_valid(i_data_valid),
        .o_start_row(o_start_row),
        .o_switch_row(o_switch_row),
        .o_uart_tx(o_uart_tx)
    );    
    
    assign i_adc_data = {8'h66, {22{8'h1a}}, 8'h99};
    initial begin
        clk = 1;
        forever begin
            #1 clk = ~clk;
        end
    end
    initial begin
        rst_n = 0;
        i_start_matrix = 1;
        #3 rst_n = 1;
        #3 i_start_matrix = 0;
    end
endmodule
