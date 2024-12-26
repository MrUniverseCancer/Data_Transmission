`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/10/09 15:00:43
// Design Name: 
// Module Name: Execute_Reply
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


module Execute_Reply(
    input  [ 0: 0] clk,
    input  [ 0: 0] rstn,

    input        [ 0: 0] i_valid,
    input        [ 7: 0] i_pkg_num,
    input        [15: 0] i_instru_type,
    input        [127:0] i_data,
    input        [15: 0] i_length,
    output logic [ 0: 0] w_ready,

    output logic [ 5: 0] command_usb_bt_uart,
    output logic [ 0: 0] command_work,
    input        [ 2: 0] usb_bt_uart_state, // 记载3种通道的状态，对于通道的开关的控制返回结果都在这里，验证即可。

    
    input        [ 0: 0] i_fifo_full, // FIFO已满
    input        [ 0: 0] i_matrix_has_stop, // 矩阵数据传输停止，允许返回帧开始
    output logic [ 0: 0] o_matrix_control, // 0表示矩阵数据传输允许，1表示矩阵数据传输完成最近一个后停止，开始完成返回帧。返回帧完成后，自动清零
    output logic [ 0: 0] o_return_data_valid,
    output logic [ 7: 0] o_return_data


    );


    logic [ 3: 0] exe_State;
    logic [ 7: 0] reply_State;
    // execate和reply之间的交互
    logic [ 0: 0] reply_OK;   // 确保应答帧被正确推入FIFO
    logic [ 5: 0] command_to_reply; // 传递给reply模块的命令
    logic [ 2: 0] state_before;
    logic [ 2: 0] state_after;
    logic [ 0: 0] execate_finish; // 完成操作,开始应答帧制作

  


    execute  execute_inst (
        .clk(clk),
        .rstn(rstn),
        .i_valid(i_valid),
        .i_instru_type(i_instru_type),
        .i_data(i_data),
        .i_length(i_length),
        .w_ready(w_ready),
        .usb_bt_uart_state(usb_bt_uart_state),
        .reply_OK(reply_OK),
        .command_to_reply(command_to_reply),
        .state_before(state_before),
        .state_after(state_after),
        .execate_finish(execate_finish),
        .command_usb_bt_uart(command_usb_bt_uart),
        .command_work(command_work)
        ,.state(exe_State)
    );

    reply  reply_inst (
        .clk(clk),
        .rstn(rstn),
        .i_reply_begin(o_matrix_control),
        .i_pkg_num(i_pkg_num),
        .state_before(state_before),
        .state_after(state_after),
        .command_to_reply(command_to_reply),
        .reply_OK(reply_OK),
        .o_return_data_valid(o_return_data_valid),
        .o_return_data(o_return_data),
        .i_fifo_full(i_fifo_full),
        .i_matrix_has_stop(i_matrix_has_stop)
        ,.state(reply_State)
    );

    always @(posedge clk) begin
        if(!rstn) begin
            o_matrix_control <= 1'b0;
        end else begin
            if(execate_finish) begin
                o_matrix_control <= 1'b1;
            end 
            else if(reply_OK) begin
                o_matrix_control <= 1'b0;
            end
        end
    end


    // ila_3 your_instance_name (
    //     .clk(clk), // input wire clk


    //     .probe0({i_valid, i_pkg_num, i_instru_type[7:0], i_length[7:0]}), // input wire [24:0]  probe0  
    //     .probe1({exe_State, reply_State}), // input wire [10:0]  probe1 
    //     .probe2({i_matrix_has_stop, o_matrix_control, usb_bt_uart_state, command_work}), // input wire [9:0]  probe2 
    //     .probe3({o_return_data, o_return_data_valid}), // input wire [9:0]  probe3
    //     .probe4({command_usb_bt_uart}) // input wire [5:0]  probe3
    // );



endmodule
