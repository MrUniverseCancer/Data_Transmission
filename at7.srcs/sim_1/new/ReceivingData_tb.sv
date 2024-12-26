`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/06/02 18:39:56
// Design Name: 
// Module Name: ReceivingData_tb
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

// 按照0.1倍时钟频率的波特率，传递数据为112'habababababababab111212000140ce,

module ReceivingData_tb(

    );

    reg [ 0: 0] clk;
    reg [ 0: 0] rstn;
    reg [ 0: 0] uart_rx_pin;
    reg [ 0: 0] bt_rx_pin;
    reg [7:0] w_rx_data;

    reg [ 0: 0] w_valid;
    reg [15: 0] w_instru_type;
    reg [127:0] w_data;
    reg [15: 0] w_length;

    TOP_REC_DECODE  TOP_REC_DECODE_inst (
        .clk(clk),
        .rstn(rstn),
        .uart_rx_pin(uart_rx_pin),
        .bt_rx_pin(bt_rx_pin),
        .w_valid(w_valid),
        .w_instru_type(w_instru_type),
        .w_data(w_data),
        .w_length(w_length)
    );
    initial begin
        clk = 1'b0;
        forever begin
            #1 clk = ~clk;
        end
    end
    initial begin
        rstn = 1'b0;
        bt_rx_pin = 1'b1;
        uart_rx_pin = 1'b1;
        #10 rstn = 1'b1;

        //AB
        #20 uart_rx_pin = 1'b0; //start bit
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b1; //stop bit
        //AB
        #20 uart_rx_pin = 1'b0; //start bit
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b1; //stop bit
        //AB
        #20 uart_rx_pin = 1'b0; //start bit
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b1; //stop bit
        //AB
        #20 uart_rx_pin = 1'b0; //start bit
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b1; //stop bit
        //AB
        #20 uart_rx_pin = 1'b0; //start bit
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b1; //stop bit
        //AB
        #20 uart_rx_pin = 1'b0; //start bit
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b1; //stop bit
        //AB
        #20 uart_rx_pin = 1'b0; //start bit
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b1; //stop bit
        //AB
        #20 uart_rx_pin = 1'b0; //start bit
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b1; //stop bit

        //11
        #20 uart_rx_pin = 1'b0; //start bit
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b1; //stop bit

        //12
        #20 uart_rx_pin = 1'b0; //start bit
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b1; //stop bit

        //12
        #20 uart_rx_pin = 1'b0; //start bit
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b1; //stop bit
        
        //00
        #20 uart_rx_pin = 1'b0; //start bit
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b1; //stop bit
        
        //01
        #20 uart_rx_pin = 1'b0; //start bit
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b1; //stop bit
        //40
        #20 uart_rx_pin = 1'b0; //start bit
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b1; //stop bit
        //8d
        #20 uart_rx_pin = 1'b0; //start bit
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b0;
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b1;
        #20 uart_rx_pin = 1'b1; //stop bit
        
    end

endmodule
