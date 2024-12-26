`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/02/01 19:58:33
// Design Name: 
// Module Name: cal_pkt_num
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
//
    // cal_pkt_num#
    // (
    //     .LEN_send_pkt_num(LEN_send_pkt_num)
    // ) cal_pkt_num_inst
    // (
    //     .clk                        (clk_50m                  ),
    //     .rst_n                      (sys_rst_n                ),
    //     .i_matrix_valid             (w_matrix_valid           ),
    //     .o_pkt_num                  (send_pkt_num             )
    // );
// 
//////////////////////////////////////////////////////////////////////////////////

//模块实现了一个简单的数据包数量计算器，在接收到有效数据包时自动累加数量，并在输出端口提供计算结果。

module cal_pkt_num
    #(
        parameter LEN_send_pkt_num = 32
    )
    (
        input                                   clk,
        input                                   rst_n,
        // Flag
        input                                   i_matrix_valid,
        // Result
        output reg [8 * LEN_send_pkt_num - 1: 0]    o_pkt_num
    );

    always@(posedge clk or negedge rst_n)
    begin
        if(rst_n == 1'b0)
        begin
            // o_pkt_num <= 1'b0;
            o_pkt_num <= 0;
        end
        else
        begin
            if (i_matrix_valid == 1'b1)
            begin
                o_pkt_num <= o_pkt_num + 1'b1;
            end
        end
    end

endmodule
