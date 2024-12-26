`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/06/02 19:15:59
// Design Name: 
// Module Name: TOP_REC_DECODE
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


module TOP_REC_DECODE
#(
	parameter CLK_FRE = 50,      //clock frequency(Mhz)
	parameter BAUD_RATE_UART = 921600, //serial baud rate
	parameter BAUD_RATE_BT = 921600 //serial baud rate
)(
        input  [ 0: 0] clk,
        input  [ 0: 0] rstn,
        input  [ 0: 0] uart_rx_pin,
        input  [ 0: 0] bt_rx_pin,

        // 关于USB3.0的io
        input  [31: 0] rx_usb_data,
        input  [ 0: 0] rx_usb_data_valid,
        input  [ 0: 0] usb_waiting_false,
        output logic [ 0: 0] rx_usb_data_ready,


        input        [ 0: 0] i_ready,
        output logic [ 7: 0] w_pkg_num,
        output logic [ 0: 0] w_valid,
        output logic [15: 0] w_instru_type,
        output logic [127:0] w_data,
        output logic [15: 0] w_length

    );


    logic [ 7: 0]  w_rx_data;

    //test
    logic [ 0: 0] uart_waiting_false;
    logic [ 7: 0] rx_uart_data;
    logic [ 0: 0] rx_uart_data_valid ;
    logic [ 1: 0] state;
    logic [ 1: 0] next_state;
    logic [ 2: 0] state_uart;
    logic [ 3: 0] parse_state;
    logic [ 7: 0] rx_data_cnt;


    ReceivingData #
    (
        .CLK_FRE(CLK_FRE),
        .BAUD_RATE_UART(BAUD_RATE_UART),
        .BAUD_RATE_BT(BAUD_RATE_BT)
    ) ReceivingData_inst (
        .clk(clk),
        .rstn(rstn),
        .uart_rx_pin(uart_rx_pin),
        .bt_rx_pin(bt_rx_pin),
        .rx_usb_data(rx_usb_data),
        .rx_usb_data_valid(rx_usb_data_valid),
        .usb_waiting_false(usb_waiting_false),
        .rx_usb_data_ready(rx_usb_data_ready),
        .i_valid(w_valid),
        .w_rx_data(w_rx_data)
        ,.uart_waiting_false(uart_waiting_false)
        ,.rx_uart_data(rx_uart_data)
        ,.rx_uart_data_valid(rx_uart_data_valid)
        ,.state(state)
        ,.next_state(next_state)
        ,.state_uart(state_uart)
        ,.rx_data_cnt(rx_data_cnt)
    );


    parse  parse_inst (
        .clk(clk),
        .rstn(rstn),
        .i_data(w_rx_data),
        .i_ready(i_ready),
        .w_pkg_num(w_pkg_num),
        .w_valid(w_valid),
        .w_instru_type(w_instru_type),
        .w_data(w_data),
        .w_length(w_length)
        ,.state(parse_state)
    );
    // ila_1 your_instance_name (
    //     .clk(clk), // input wire clk
    
    
    //     .probe0({w_rx_data, state}), // input wire [9:0]  probe0  
    //     .probe1({rx_usb_data }), // input wire [31:0]  probe1 
    //     .probe2({rx_usb_data_valid, usb_waiting_false, w_valid}), // input wire [2:0]  probe2
    //     .probe3({parse_state, rx_data_cnt[ 3: 0]}) // input wire [8:0]  probe3
    // );

endmodule
