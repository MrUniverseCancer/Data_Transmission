`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/06/02 10:27:55
// Design Name: 
// Module Name: ReceivingData
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

// 取得命令帧，缓存至一个Buffer
// 等待8个传输频率的时间没有传入有效数据，认为传输结束
// 将获得的Buffer按照每个字节的数据，传出

module ReceivingData
#(
	parameter CLK_FRE = 50,      //clock frequency(Mhz)
	parameter BAUD_RATE_UART = 921600, //serial baud rate
	parameter BAUD_RATE_BT = 921600 //serial baud rate
)(
    input  [ 0: 0] clk,
    input  [ 0: 0] rstn,

    input  [ 0: 0] uart_rx_pin, // data for uart module
    input  [ 0: 0] bt_rx_pin,   // data for bluetooth module

    // variant about usb_rx
    input  [31: 0] rx_usb_data,
    input  [ 0: 0] rx_usb_data_valid,
    input  [ 0: 0] usb_waiting_false,
    output logic [ 0: 0] rx_usb_data_ready,


    input        [ 0: 0] i_valid,
    output logic [ 7: 0] w_rx_data
    
    ,output logic [ 0: 0] uart_waiting_false
    ,output logic [ 7: 0] rx_uart_data
    ,output logic [ 0: 0] rx_uart_data_valid
    ,output logic [ 2: 0] state
    ,output logic [ 1: 0] next_state
    ,output logic [ 1: 0] state_uart
    ,output logic [ 7: 0] rx_data_cnt
    );


    // variant about uart_rx
    // logic [7:0] rx_uart_data;
    // logic rx_uart_data_valid;
    logic rx_uart_data_ready;
    // logic uart_waiting_false;

    // localparam CLK = 100;
    // localparam BAUD_RATE_UART = 921600;
    // localparam BAUD_RATE_BT = 921600;

    uart_rx # (
        .CLK_FRE(CLK_FRE),
        .BAUD_RATE(BAUD_RATE_UART)
    )
    uart_rx_inst (
        .clk(clk),
        .rst_n(rstn),
        .rx_data(rx_uart_data),
        .rx_data_valid(rx_uart_data_valid),
        .rx_data_ready(rx_uart_data_ready),
        .rx_pin(uart_rx_pin),
        .wait_false(uart_waiting_false)
        ,.state(state_uart)
    );

    // variant about bluetooth_rx
    logic [7:0] rx_bt_data;
    logic rx_bt_data_valid;
    logic rx_bt_data_ready;
    logic bt_waiting_false;

    bt_rx # (
        .CLK_FRE(CLK_FRE),
        .BAUD_RATE(BAUD_RATE_BT)
    )
    bt_rx_inst (
        .clk(clk),
        .rst_n(rstn),
        .rx_data(rx_bt_data),
        .rx_data_valid(rx_bt_data_valid),
        .rx_data_ready(rx_bt_data_ready),
        .rx_pin(bt_rx_pin),
        .wait_false(bt_waiting_false)
    );



    // variant about usb_rx
    // logic [31:0] rx_usb_data;
    // logic rx_usb_data_valid;
    // logic rx_usb_data_ready;
    // logic usb_waiting_false;


    rx_Buffer  rx_Buffer_inst (
        .clk(clk),
        .rstn(rstn),
        .i_uart_rx_data(rx_uart_data),
        .i_uart_rx_valid(rx_uart_data_valid),
        .i_uart_rx_waiting_false(uart_waiting_false),
        .w_uart_rx_ready(rx_uart_data_ready),
        .i_bt_rx_data(rx_bt_data),
        .i_bt_rx_valid(rx_bt_data_valid),
        .i_bt_rx_waiting_false(bt_waiting_false),
        .w_bt_rx_ready(rx_bt_data_ready),
        .i_usb_rx_data(rx_usb_data),
        .i_usb_rx_valid(rx_usb_data_valid),
        .i_usb_rx_waiting_false(usb_waiting_false),
        .w_usb_rx_ready(rx_usb_data_ready),
        .i_valid(i_valid),
        .w_rx_Buffer(w_rx_data)
        ,.state(state)
        ,.next_state(next_state)
        ,.rx_data_cnt(rx_data_cnt)
      );


endmodule
