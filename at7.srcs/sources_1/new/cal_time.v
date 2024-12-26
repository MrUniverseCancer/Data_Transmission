`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/02/01 19:58:33
// Design Name: 
// Module Name: cal_time
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
    // cal_time#
    // (
    //     .LEN_send_time(LEN_send_time)
    // ) cal_time_inst
    // (
    //     .clk                        (clk_50m                  ),
    //     .rst_n                      (sys_rst_n                ),
    //     .o_time                     (send_time                )
    // );
// 
//////////////////////////////////////////////////////////////////////////////////


//计时器+计数功能
//在外在规定时钟频率的前提下，每0.1ms计数

module cal_time
    #(
        parameter LEN_send_time = 32,
        parameter CLK_FRE       = 50 //MHz
    )
    (
        input                               clk,
        input                               rst_n,
        // Result
        output reg [8 * LEN_send_time - 1: 0]   o_time
    );

    localparam                              WAIT_TIME_0_1ms = CLK_FRE * 100 - 1;  // 0.1ms for 50MHz

    reg [$clog2(WAIT_TIME_0_1ms+1)-1 : 0]   r_clk_cnt;

    always@(posedge clk or negedge rst_n)
    begin
        if(rst_n == 1'b0)
        begin
            // r_clk_cnt <= 1'b0;
            // o_time <= 1'b0;
            r_clk_cnt <= 0;
            o_time <= 0;
        end
        else
        begin
            if (r_clk_cnt == WAIT_TIME_0_1ms)
            begin
                // r_clk_cnt <= 1'b0;
                r_clk_cnt <= 0;
                o_time <= o_time + 1'b1;
            end
            else
            begin
                r_clk_cnt <= r_clk_cnt + 1'b1;
            end
        end
    end

endmodule
