`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/09/26 15:19:20
// Design Name: 
// Module Name: TOP_edi1_tb
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


module TOP_edi1_tb(

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
    wire  [31:0] io_fx3_db;
    logic i_start_matrix;
    logic o_start_row;
    logic o_switch_row;
  

    
    uart_blue_usb # (
        .ADC_NUM(1),
        .N_ROW(4),
        .N_COL(8),
        .CLK_FRE(50),
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
        .o_start_row(o_start_row),
        .o_switch_row(o_switch_row)
    );

    initial begin
        clk = 1'b0;
        forever begin
            #1 clk = ~clk;
        end
    end
    initial begin
        i_bt_rx = 1'b0;
        i_uart_rx = 1'b0;
        i_fx3_flaga = 1'b1;
        i_fx3_flagb = 1'b0;
        i_fx3_flagc = 1'b0;
        i_fx3_flagd = 1'b0;
    end
    initial begin
        rst_n = 1'b0;
        #10 rst_n = 1'b1;
        #1000 i_start_matrix = 1'b1;
        // #10 i_start_matrix = 1'b0;
    end
endmodule
