`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/31 10:24:08
// Design Name: 
// Module Name: Matric_DEBUG_tb
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


module Matric_DEBUG_tb(

    );

    logic [ 0: 0] clk, rst_n;
    logic [ 0: 0] i_start_matrix;
    logic [ 0: 0] o_uart_tx;


    Matric_DEBUG  Matric_DEBUG_inst (
        .clk(clk),
        .rst_n(rst_n),
        .i_start_matrix(i_start_matrix),
        .o_uart_tx(o_uart_tx)
      );
    initial begin
        clk = 1;
        rst_n = 0;
        forever begin
            #1 clk = ~clk;
        end
    end
    initial begin
        i_start_matrix = 0;
        #2 rst_n = 1;
        #5 i_start_matrix = 1;
        #3 i_start_matrix = 0;
    end
endmodule
