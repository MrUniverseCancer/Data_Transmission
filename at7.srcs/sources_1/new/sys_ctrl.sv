`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/02/27 17:26:32
// Design Name: 
// Module Name: sys_ctrl
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


module sys_ctrl(
        // FPGA external input 50MHz clock, reset signal
        input ext_clk,          // extern input 50MHz clock
        input ext_rst_n,        // extern input reset signal
        // PLL output clock, reset, used in FPGA
        output reg sys_rst_n,   // system reset signal, active low
        output clk_25m,         // PLL output 25MHz
        output clk_50m,         // PLL output 50MHz
        output clk_100m,        // PLL output 100MHz
        output fx3_pclk         // PLL output 100MHz, with phase difference
    );

    //-------------------------------------
    // PLL reset signal generation, active high
    // asynchronous reset, synchronous release
    reg rst_r1;
    reg rst_r2;

    always@(posedge ext_clk or negedge ext_rst_n)
    begin
        if(!ext_rst_n)
            rst_r1 <= 1'b0;
        else
            rst_r1 <= 1'b1;
    end

    always@(posedge ext_clk or negedge ext_rst_n)
    begin
        if(!ext_rst_n)
            rst_r2 <= 1'b0;
        else
            rst_r2 <= rst_r1;
    end

    //-------------------------------------
    // PLL
    wire locked;	// PLL output locked status, active low
    clk_wiz_0 clk_wiz_0_inst_1
    (
        // Clock out ports
        .clk_out1(clk_100m),     // output clk_out1
        .clk_out2(fx3_pclk),     // output clk_out2
        .clk_out3(clk_50m),     // output clk_out3
        .clk_out4(clk_25m),     // output clk_out4
        // Status and control signals
        .reset(!rst_r2), // input reset
        .locked(locked),       // output locked
        // Clock in ports
        .clk_in1(ext_clk)      // input clk_in1
    );      
    // clk_wiz_0 clk_wiz_0_inst_1
    // (
    //     // Clock in ports
    //     .clk_in1(ext_clk),      // input clk_in1
    //     // Clock out ports
    //     .clk_out1(clk_25m),     // output clk_out1
    //     .clk_out2(clk_50m),     // output clk_out2
    //     .clk_out3(clk_100m),    // output clk_out3
    //     .clk_out4(fx3_pclk),    // output clk_out4
    //     // Status and control signals
    //     .reset(!rst_r2),        // input reset
    //     .locked(locked));       // output locked

    //----------------------------------------------
    // system reset signal generation, active low
    reg sys_rst_nr;

    always@(posedge clk_100m)
    begin
        if(!locked)
            sys_rst_nr <= 1'b0;
        else
            sys_rst_nr <= 1'b1;
    end

    always@(posedge clk_100m or negedge sys_rst_nr)
    begin
        if(!sys_rst_nr)
            sys_rst_n <= 1'b0;
        else
            sys_rst_n <= sys_rst_nr;
    end


endmodule
