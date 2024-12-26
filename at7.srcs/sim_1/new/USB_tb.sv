`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/09/10 20:15:54
// Design Name: 
// Module Name: USB_tb
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


module USB_tb(

    );

    logic clk;
    logic rst_n;
    logic i_fx3_flaga;
    logic i_fx3_flagb;
    logic i_fx3_flagc;
    logic i_fx3_flagd;
    logic o_fx3_slcs_n;
    logic o_fx3_slwr_n;
    logic o_fx3_slrd_n;
    logic o_fx3_sloe_n;
    logic o_fx3_pktend_n;
    logic [1:0] o_fx3_a;
    wire [31:0] io_fx3_db;
    logic i_start_matrix;
    logic o_start_matrix;
  

    USB_Debug # (
        .ADC_NUM(1),
        .N_ROW(4),
        .N_COL(8),
        .CLK_FRE(50),
        .DATA_RATE(100)
    )
    USB_Debug_inst (
        .clk(clk),
        .rst_n(rst_n),
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
        .o_start_matrix(o_start_matrix)
    );

    initial begin
        clk = 1'b0;
        forever #1 clk = ~clk;
    end

    initial begin
        rst_n = 1'b0;
        i_start_matrix = 1'b0;
        i_fx3_flaga = 1'b1;
        #5; 
        rst_n = 1'b1;
        i_start_matrix = 1'b1;
        
        #10 i_start_matrix = 1'b0;
    end
endmodule
