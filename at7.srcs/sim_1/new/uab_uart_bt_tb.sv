`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/10/25 10:01:27
// Design Name: 
// Module Name: uab_uart_bt_tb
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


module uab_uart_bt_tb(

    );

    logic clk;
    logic rst_n;
    logic i_uart_rx;
    logic i_bt_rx;
    logic o_uart_tx;
    logic o_bt_tx;
    logic i_fx3_flaga;
    logic i_fx3_flagb;
    logic i_fx3_flagc;
    logic i_fx3_flagd;
    logic fx3_pclk;
    logic o_fx3_slcs_n;
    logic o_fx3_slwr_n;
    logic o_fx3_slrd_n;
    logic o_fx3_sloe_n;
    logic o_fx3_pktend_n;
    logic [1:0] o_fx3_a;
    wire [31:0] io_fx3_db;
    logic i_start_matrix;
    logic o_start_matrix;
  
    uart_blue_usb # (
        .ADC_NUM(15),
        .N_ROW(240),
        .N_COL(120),
        .CLK_FRE(100),
        .DATA_RATE(100)
    )
    uart_blue_usb_inst (
        .clk(clk),
        .rst_n(rst_n),
        .i_uart_rx(i_uart_rx),
        .i_bt_rx(i_bt_rx),
        .o_uart_tx(o_uart_tx),
        .o_bt_tx(o_bt_tx),
        .i_fx3_flaga(i_fx3_flaga),
        .i_fx3_flagb(i_fx3_flagb),
        .i_fx3_flagc(i_fx3_flagc),
        .i_fx3_flagd(i_fx3_flagd),
        .fx3_pclk(fx3_pclk),
        .o_fx3_slcs_n(o_fx3_slcs_n),
        .o_fx3_slwr_n(o_fx3_slwr_n),
        .o_fx3_slrd_n(o_fx3_slrd_n),
        .o_fx3_sloe_n(o_fx3_sloe_n),
        .o_fx3_pktend_n(o_fx3_pktend_n),
        .o_fx3_a(o_fx3_a),
        .io_fx3_db(io_fx3_db),
        .i_start_matrix(i_start_matrix),
        .o_start_matrix(o_start_matrix)
    );

    initial begin
        clk = 1'b1;
        i_start_matrix = 1'b1;
        forever begin
            #1 clk = ~clk;
        end
    end


endmodule
