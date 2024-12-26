`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/05/06 14:20:02
// Design Name: 
// Module Name: USB_Debug
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


module USB_Debug
    #(
        parameter ADC_NUM           = 1,
        parameter N_ROW             = 4,
        parameter N_COL             = 8,
        parameter CLK_FRE           = 50, //MHz
        parameter DATA_RATE         = 100 //Hz
    )(
    input               logic clk,
    input               logic rst_n,
    input               logic i_fx3_flaga,
    input               logic i_fx3_flagb,
    input               logic i_fx3_flagc,
    input               logic i_fx3_flagd,

    output              logic fx3_pclk, // Slave FIFO同步时钟信号
    output              logic o_fx3_slcs_n,
    output              logic o_fx3_slwr_n,
    output              logic o_fx3_slrd_n,
    output              logic o_fx3_sloe_n,
    output              logic o_fx3_pktend_n,
    output              logic [1:0] o_fx3_a,
    inout               logic [31:0] io_fx3_db,

    
    input               logic i_start_matrix,
    output              logic o_start_matrix

    );



    logic [192 * ADC_NUM - 1 : 0] i_adc_data;    
    logic o_start_row;
    logic i_adc_data_valid;
    logic o_switch_row;
    logic o_fifo_full;
    logic o_fifo_empty;

    assign i_adc_data = {3{8'h11, 8'h22, 8'h33, 8'h44, 8'h55, 8'h66, 8'h77, 8'h88}};
    assign i_adc_data_valid = 1;
    assign o_start_matrix = i_start_matrix;
  

    logic sys_rst_n;
    logic clk_25m;
    logic clk_50m;
    logic clk_100m;
    logic fx3_pclk;

    sys_ctrl  sys_ctrl_inst (
        .ext_clk(clk),
        .ext_rst_n(rst_n),

        .sys_rst_n(sys_rst_n),
        .clk_25m(clk_25m),
        .clk_50m(clk_50m),
        .clk_100m(clk_100m),
        .fx3_pclk(fx3_pclk)
    );

    Matric_tran_ctrl # (
        .ADC_NUM(ADC_NUM),
        .N_ROW(N_ROW),
        .N_COL(N_COL),
        .CLK_FRE(CLK_FRE),
        .DATA_RATE(DATA_RATE)
    )
    Matric_tran_ctrl_inst (
        // .clk(clk),
        // .rst_n(rst_n),
        .clk(clk_100m),
        .rst_n(sys_rst_n),
        .i_adc_data(i_adc_data),
        .i_fx3_flaga(i_fx3_flaga),
        .i_fx3_flagb(i_fx3_flagb),
        .i_fx3_flagc(i_fx3_flagc),
        .i_fx3_flagd(i_fx3_flagd),
        .o_fx3_slcs_n(o_fx3_slcs_n),
        .o_fx3_slwr_n(o_fx3_slwr_n),
        .o_fx3_slrd_n(o_fx3_slrd_n),
        .o_fx3_sloe_n(o_fx3_sloe_n),
        .o_fx3_pktend_n(o_fx3_pktend_n),
        .o_fx3_a(o_fx3_a),
        .io_fx3_db(io_fx3_db),
        .i_start_matrix(i_start_matrix),
        .o_start_row(o_start_row),
        .i_adc_data_valid(i_adc_data_valid),
        .o_switch_row(o_switch_row),
        .o_fifo_full(o_fifo_full),
        .o_fifo_empty(o_fifo_empty)
    );
endmodule
