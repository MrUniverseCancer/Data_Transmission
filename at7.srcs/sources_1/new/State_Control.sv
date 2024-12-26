`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/26 18:00:36
// Design Name: 
// Module Name: State_Control
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


module State_Control
#(
    parameter INITIAL_STATE = 4'b0001
)(
    input clk,
    input rstn,

    // 命令帧的控制信号相关
    input [ 5: 0] command_usb_bt_uart,
    input [ 0: 0] command_work,
    
    // FIFO获得的信息
    input [ 7: 0] fifo_rd_data,
    input [ 0: 0] fifo_empty,

    // USB，UART模块的控制信号
    input [ 0: 0] usb_able_to_write,
    input [ 0: 0] uart_able_to_write,

    // 返回帧和数据帧相互竞争的控制信号和双方的数据
    input [ 7: 0] o_return_data,
    input [ 0: 0] o_return_data_valid,
    input [ 7: 0] w_data_to_fifo,
    input [ 0: 0] o_data_valid,

    // 基础、核心的输出控制
    output logic [ 3: 0] send_state,

    // 给USB模块的输出
    output logic [ 7: 0] usb_data_from_fifo,
    output logic [ 0: 0] usb_fifo_wr_en,
    // 给UART模块的输出
    output logic [ 7: 0] uart_data_from_fifo,
    output logic [ 0: 0] uart_fifo_wr_en,

    // 给FIFO的输入控制信号
    output logic [ 7: 0] fifo_wr_data,
    output logic [ 0: 0] fifo_rd_en,
    output logic [ 0: 0] fifo_wr_en
    );

    logic [ 3: 0] send_state_tmp; // 记录各个通道能否发送数据
    assign send_state = send_state_tmp;
    // 0 -> uart
    // 1 -> bt
    // 2 -> usb
    // 3 -> SD卡
    
    // 相关信号
    




    initial begin
        send_state_tmp = INITIAL_STATE;
    end
    always @(posedge clk) begin
        if(!rstn) begin
            send_state_tmp <= send_state_tmp; // 重置不改变其传输状态
        end
        else if(command_work) begin
            if(command_usb_bt_uart[0]) begin
                // uart_off
                send_state_tmp[0] = 1'b0;
            end
            else if(command_usb_bt_uart[1]) begin
                // uart_on
                send_state_tmp[0] = 1'b1;
            end
            
            else if(command_usb_bt_uart[2]) begin
                // bt_off
                send_state_tmp[1] = 1'b0;
            end
            else if(command_usb_bt_uart[3]) begin
                // bt_on
                send_state_tmp[1] = 1'b1;
            end
            else if(command_usb_bt_uart[4]) begin
                // usb_off
                send_state_tmp[2] = 1'b0;
            end
            else if(command_usb_bt_uart[5]) begin
                // usb_on
                send_state_tmp[2] = 1'b1;
            end
        end
        
    end

    // USB 模块
    assign usb_data_from_fifo = fifo_rd_data;
    assign usb_fifo_wr_en = fifo_rd_en && send_state_tmp[2] && usb_able_to_write; // TODO:

    // uart && bt
    assign uart_data_from_fifo = fifo_rd_data;
    assign uart_fifo_wr_en = fifo_rd_en && (send_state_tmp[1] | send_state_tmp[0]) && uart_able_to_write; 
    // 是否需要接收数据，控制权完全交给uart_bt_top模块自行决定

    // 通过返回帧o_return_data_valid来控制，为了减小延时，统一缓存一个周期
    // 即使在输出状态，o_return_data_valid=0，由于之前的保证也能够使得o_data_valid一定为0
    always @(posedge clk) begin
        if(o_return_data_valid) begin
            fifo_wr_data <= o_return_data; // 在i_returnFrame_begin期间，才会输出返回帧，以返回帧优先
            fifo_wr_en <= o_return_data_valid;
        end
        else begin
            fifo_wr_data <= w_data_to_fifo;
            fifo_wr_en <= o_data_valid;
        end
    end

    // 输出数据的权限
    always @(*) begin
        fifo_rd_en = 0;
        if(fifo_empty) begin
            // fifo为空
            fifo_rd_en = 0;
        end
        else if(send_state_tmp[1] | send_state_tmp[0]) begin
            // 允许蓝牙,uart发送数据
            fifo_rd_en = uart_able_to_write & usb_able_to_write; // uart/bt优先级最高的情况下，uart/bt模块愿意接收数据，才从fifo中读取数据
        end
        else if(send_state_tmp[2]) begin
            // 允许USB发送数据
            fifo_rd_en = usb_able_to_write; // usb优先级最高的情况下，usb模块愿意接收数据，才从fifo中读取数据
        end    
        else if(send_state_tmp[3]) begin
            // 允许SD卡发送数据
            // TODO:
        end
        else begin
            // 不允许发送数据
            fifo_rd_en = 0;
        end
    end
    // 没有所谓的权限，能传就传，不管优先级，满了就自己停住
    // 为什么总是有错？？222
    // always @(*) begin
    //     if(fifo_empty) begin
    //         fifo_rd_en = 0;
    //     end
    //     else begin
    //         fifo_rd_en = (usb_able_to_write && send_state_tmp[2]) | (uart_able_to_write && (send_state_tmp[0] | send_state_tmp[1]));
    //     end
    // end
    


endmodule
