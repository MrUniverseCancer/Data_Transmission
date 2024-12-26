`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/06/02 10:20:04
// Design Name: 
// Module Name: rx_Buffer
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

// 通过串口读取不定长的数据，存储到缓冲区中，缓冲区的大小为30字节，当缓冲区满时，不再接收数据，当缓冲区为空时，不再读取数据。

// TODO: 小改逻辑
// 如何三选一：
// IDLE状态，如果只有一个模块有数据，直接选择他。如果都没有，重复在IDLE状态。
//          如果有多个模块有数据，选择一个，其他的等待。
// 重点在于：rx_data_valid_reg的逻辑不同：
//          1. IDLE：只有一个模块有数据，rx_data_valid_reg = 1(下一周期)
//          2. Read：rx_data_valid_reg = 1 当正在读取的模块有数据，否则为0————避免读A模块，但是B模块有数据，导致错误有效

// Bug: 由于USB的输入在规模较大的时候才能够获取正确值，所以前面默认要求USB的大小大于32
// 在某一次试验中，我输入了一个大小为40Bytes的数据，但是在rx_Buffer中只能够获取到32Bytes的数据，
// 导致计数器cnt溢出出现了错误，所以需要扩大空间。

// Bug:USB输出的4Bytes是逆序的，所以在rx_Buffer中需要逆序处理
module rx_Buffer(
    input        [ 0: 0] clk,
    input        [ 0: 0] rstn,
     
    input        [ 7: 0] i_uart_rx_data,
    input        [ 0: 0] i_uart_rx_valid,
    input        [ 0: 0] i_uart_rx_waiting_false,
    output logic [ 0: 0] w_uart_rx_ready,

    input        [ 7: 0] i_bt_rx_data,
    input        [ 0: 0] i_bt_rx_valid,
    input        [ 0: 0] i_bt_rx_waiting_false,
    output logic [ 0: 0] w_bt_rx_ready,

    input        [31: 0] i_usb_rx_data,
    input        [ 0: 0] i_usb_rx_valid,
    input        [ 0: 0] i_usb_rx_waiting_false,
    output logic [ 0: 0] w_usb_rx_ready,

    input        [ 0: 0] i_valid,
    output logic [ 7: 0] w_rx_Buffer

    ,output logic [ 1: 0] state
    ,output logic [ 1: 0] next_state
    ,output logic [ 7: 0] rx_data_cnt

    );

    localparam S_IDLE = 0;
    localparam S_Read = 1;
    localparam S_Write = 2;
    localparam S_Check = 3; // 在得到输入停止后，检查parsing产生的信号是否被接收的等待期间

    // logic [ 1: 0] state;
    // logic [ 1: 0] next_state;
    // logic [255:0] rx_Buffer;
    // logic [ 7: 0] rx_data_cnt; // 0-30 get how many data left in rx_Buffer
    logic [ 7: 0] cnt_max_lenth; // final length of input Command frame,to help decide which out for parsing(head and tail is reverse in Buffer)
    // increase from 32 to 256 Bytes

    logic [2047: 0] rx_Buffer;

    always @(posedge clk, negedge rstn) begin
        if( !rstn ) begin
            w_rx_Buffer <= 0;
        end
        else begin
            if(state == S_Write && rx_data_cnt > 0) begin
                w_rx_Buffer <= rx_Buffer[(cnt_max_lenth - rx_data_cnt)*8 +: 8];
            end
            else begin
                w_rx_Buffer <= 0;
            end
        end
    end


    // variant about uart_rx
    logic [ 7: 0] rx_uart_data;
    assign w_uart_rx_ready = (state == S_Write) ? 0 : 1; // decide whether to receive data by uart
    always @(posedge clk, negedge rstn) begin
        if( !rstn ) begin
            rx_uart_data <= 0;
        end
        else begin
            if(i_uart_rx_valid == 1) begin
                rx_uart_data <= i_uart_rx_data;
            end
        end
    end
    // variant about uart_bt
    logic [ 7: 0] rx_bt_data;
    assign w_bt_rx_ready = (state == S_Write) ? 0 : 1;
    always @(posedge clk, negedge rstn) begin
        if( !rstn ) begin
            rx_bt_data <= 0;
        end
        else begin
            if(i_bt_rx_valid == 1) begin
                rx_bt_data <= i_bt_rx_data;
            end
        end
    end
    // variant about usb , 缓存32bits的数据一个时钟
    logic [31:0] rx_usb_data;
    assign w_usb_rx_ready = (state == S_Write) ? 0 : 1;
    always @(posedge clk, negedge rstn) begin
        if( !rstn ) begin
            rx_usb_data <= 0;
        end
        else begin
            if(i_usb_rx_valid == 1) begin
                // 逆序存储
                rx_usb_data <= {i_usb_rx_data[7:0], i_usb_rx_data[15:8], i_usb_rx_data[23:16], i_usb_rx_data[31:24]};
            end
        end
    end


    // decide when is finish waiting
    logic [ 0: 0] wait_false;
    // deal which is valid
    logic [ 0: 0] uart_valid;
    logic [ 0: 0] bt_valid;
    logic [ 0: 0] usb_valid;
    logic [ 0: 0] rx_data_valid_IDLE;
    logic [ 0: 0] rx_data_valid_READ;
    logic [ 0: 0] rx_data_valid_reg; // Cache one cycle
    always @(posedge clk, negedge rstn) begin
        if(!rstn) begin
            uart_valid <= 0;
            bt_valid <= 0;
            usb_valid <= 0;
        end
        else begin
            if(state == S_IDLE) begin
                // only one is valid(1)
                uart_valid <= i_uart_rx_valid;
                bt_valid <= i_bt_rx_valid && !i_uart_rx_valid;
                usb_valid <= i_usb_rx_valid && (!i_bt_rx_valid && !i_uart_rx_valid);
            end
        end
    end
    assign rx_data_valid_IDLE = i_bt_rx_valid || i_usb_rx_valid || i_uart_rx_valid;
    assign rx_data_valid_READ = (uart_valid & i_uart_rx_valid) || (bt_valid & i_bt_rx_valid) || (usb_valid & i_usb_rx_valid); // 强调对应的模块有数据才有效
    assign wait_false = (uart_valid == 1) ? i_uart_rx_waiting_false : (bt_valid == 1) ? i_bt_rx_waiting_false : (usb_valid == 1) ? i_usb_rx_waiting_false : 0;
    always @(posedge clk ,negedge rstn) begin
        if( !rstn ) begin
            rx_data_valid_reg <= 0;
        end
        else begin
            if(state == S_IDLE) begin
                rx_data_valid_reg <= rx_data_valid_IDLE;
            end
            else if(state == S_Read) begin
                rx_data_valid_reg <= rx_data_valid_READ;
            end
        end
    end


    // write data to rx_Buffer according to data_valid
    always @(*) begin
        case (state)
            S_IDLE: begin
                if(i_bt_rx_valid || i_usb_rx_valid || i_uart_rx_valid) begin
                    next_state = S_Read;
                end
                else begin
                    next_state = S_IDLE;
                end
            end
            S_Read: begin
                if(wait_false == 1) begin
                    next_state = S_Check;
                end
                else begin
                    next_state = S_Read;
                end
            end
            S_Check: begin
                if( ~i_valid ) begin
                    // i_valid == 0，说明已经待处理为空，可以进行处理
                    next_state = S_Write;
                end
                else begin
                    next_state = S_Check;
                end
            end
            S_Write: begin
                if(rx_data_cnt == 1) begin
                    next_state = S_IDLE;
                end
                else begin
                    next_state = S_Write;
                end
            end
            default: begin
                next_state = S_IDLE;
            end
        endcase
    end
    always @(posedge clk, negedge rstn) begin
        if( !rstn ) begin
            state <= S_IDLE;
        end
        else begin
            state <= next_state;
        end
    end


    // rx_Buffer && rx_data_cnt
    always @(posedge clk, negedge rstn) begin
        if( !rstn ) begin
            rx_Buffer <= 0;
        end
        else begin
            if(rx_data_valid_reg == 1) begin
                if(uart_valid) begin
                    rx_Buffer[rx_data_cnt*8 +: 8] <= rx_uart_data;
                end
                else if(bt_valid) begin
                    rx_Buffer[rx_data_cnt*8 +: 8] <= rx_bt_data;
                end
                else if(usb_valid) begin
                    rx_Buffer[rx_data_cnt*8 +: 32] <= rx_usb_data;
                end
            end
        end
    end
    always @(posedge clk, negedge rstn) begin
        if( !rstn ) begin
            rx_data_cnt <= 0;
            cnt_max_lenth <= 0;
        end
        else begin
            if(rx_data_valid_reg == 1) begin
                // usb add 4,others add 1
                // record every time(exist data sending here), how many is put in
                if(usb_valid) begin
                    rx_data_cnt <= rx_data_cnt + 4;
                    cnt_max_lenth <= rx_data_cnt + 4;
                end
                else begin
                    rx_data_cnt <= rx_data_cnt + 1;
                    cnt_max_lenth <= rx_data_cnt + 1;
                end
            end
            else if(state == S_Write) begin
                rx_data_cnt <= rx_data_cnt - 1;
            end
        end
    end
endmodule
