`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/05/18 21:13:36
// Design Name: 
// Module Name: pause_tb
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


module pause_tb(

    );

    // logic clk;0
    // logic rstn;
    // logic [7:0] i_data;
    // logic w_valid;
    // logic [15:0] w_instru_type;
    // logic [127:0] w_data;
    // logic [15:0] w_length;

    // // Instantiate the module under test (MUT)
    // parse parse_inst (
    //     .clk(clk),
    //     .rstn(rstn),
    //     .i_data(i_data),
    //     .w_valid(w_valid),
    //     .w_instru_type(w_instru_type),
    //     .w_data(w_data),
    //     .w_length(w_length)
    // );

    // // Clock generator
    // initial begin
    //     clk = 0;
    //     forever begin
    //         #1 clk = ~clk;
    //     end
    // end
    // // Test sequence
    // initial begin
    //     // Initialize signals
    //     rstn = 0;
    //     i_data = 8'h00;

    //     #2 rstn = 1;  // De-assert reset
    //     #2 i_data = 8'hAB;  // Send first byte of packet header
    //     #2 i_data = 8'hAB;  // Send second byte of packet header
    //     #2 i_data = 8'hAB;
    //     #2 i_data = 8'hAB;
    //     #2 i_data = 8'hAB;
    //     #2 i_data = 8'hAB;
    //     #2 i_data = 8'hAB;
    //     #2 i_data = 8'hAB;

    //     #2 i_data = 8'h08;
    //     #2 i_data = 8'h22;
    //     #2 i_data = 8'h33;

    //     #2 i_data = 8'h00;
    //     #2 i_data = 8'h04;

    //     #2 i_data = 8'h56;
    //     #2 i_data = 8'h9B;
    //     #2 i_data = 8'h99;
    //     #2 i_data = 8'h66;

    //     // 计算16进制的校验和
    //     #2 i_data = 8'ha9;

    // end

endmodule
