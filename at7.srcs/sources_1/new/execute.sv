`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/10/09 15:06:14
// Design Name: 
// Module Name: execute
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


module execute(
    input [ 0: 0] clk,
    input [ 0: 0] rstn,

    input        [ 0: 0] i_valid,
    input        [15: 0] i_instru_type,
    input        [127:0] i_data,
    input        [15: 0] i_length,
    output logic [ 0: 0] w_ready,
    

    input        [ 2: 0] usb_bt_uart_state,


    input        [ 0: 0] reply_OK,   // 确保应答帧被正确推入FIFO
    output logic [ 5: 0] command_to_reply, // 传递给reply模块的命令
    output logic [ 2: 0] state_before,
    output logic [ 2: 0] state_after,
    output logic [ 0: 0] execate_finish, // 完成操作,开始应答帧制作


    output logic [ 5: 0] command_usb_bt_uart,
    output logic [ 0: 0] command_work // 表示信号有效

    ,output logic [ 3: 0] state
    );

    localparam S_IDLE  = 0;
    localparam S_TRANS = 1; // 解析信号，并且传递给外界
    localparam S_SEND_WAIT_CHECK = 2; // 确保信号送出，开始检查是否成功完成操作
    localparam S_SUCC  = 3;
    localparam S_FAIL  = 4;
    localparam S_pause = 5; // 中间停留，为了确保i_valid变成0

    // logic [ 3: 0] state;
    logic [ 3: 0] next_sate;

    logic [ 2: 0] usb_bt_uart_state_REG_before; // 记载操作前的状态，与操作后进行比较
    logic [ 2: 0] usb_bt_uart_state_REG_after;  // 记载操作后的状态
    logic [ 5: 0] command_usb_bt_uart_reg; // 记载操作的命令


    logic [ 0: 0] execute_OK; // 检测发现操作被正确执行

    logic [ 0: 0] usb_ON;
    logic [ 0: 0] usb_OFF;
    logic [ 0: 0] bt_ON;
    logic [ 0: 0] bt_OFF;
    logic [ 0: 0] uart_ON;
    logic [ 0: 0] uart_OFF;

    always @(posedge clk) begin
        if( !rstn ) begin
            state <= S_IDLE;
        end
        else begin
            state <= next_sate;
        end
    end

    always @(*) begin
        case (state)
            S_IDLE : begin
                if(i_valid) begin
                    next_sate = S_TRANS;
                end
                else begin
                    next_sate = S_IDLE;
                end
            end 

            S_TRANS : begin
                next_sate = S_SEND_WAIT_CHECK;
                // 默认一个时钟内，完成信号的解析
            end

            S_SEND_WAIT_CHECK : begin
                if(execute_OK) begin
                    next_sate = S_SUCC;
                end
                else begin
                    next_sate = S_SEND_WAIT_CHECK;
                end
            end

            S_SUCC : begin
                if(reply_OK) begin
                    next_sate = S_pause;
                end
                else begin
                    next_sate = S_SUCC;
                end
            end

            S_pause : begin
                if(!i_valid) begin
                    next_sate = S_IDLE;
                end
                else begin
                    next_sate = S_pause;
                end
            end

            default:  next_sate = S_IDLE;
        endcase
    end


    assign w_ready = (state == S_pause) ? 1 : 0; // 告知接收器，可以接受新的数据（命令帧）TODO:这里可能有问题
    always @(posedge clk) begin
        if(!rstn) begin
            usb_bt_uart_state_REG_before <= 3'h0;
            usb_bt_uart_state_REG_after  <= 3'h0;
        end
        else if(state == S_TRANS) begin
            usb_bt_uart_state_REG_before <= usb_bt_uart_state;
        end
        else if(state == S_SEND_WAIT_CHECK) begin
            usb_bt_uart_state_REG_after <= usb_bt_uart_state;
        end
    end

    // command_usb_bt_uart和command_usb_bt_uart_reg其实可以合并，并没有差别
    // 但是这里不合并的原因是：为了在将来拓展的时候方便操作
    always @(posedge clk) begin
        if(!rstn) begin
            command_usb_bt_uart <= 6'h00;
            command_usb_bt_uart_reg <= 6'h00;
        end
        else if(state == S_TRANS) begin
            command_usb_bt_uart <= {usb_ON, usb_OFF, bt_ON, bt_OFF, uart_ON, uart_OFF};
            command_usb_bt_uart_reg <= {usb_ON, usb_OFF, bt_ON, bt_OFF, uart_ON, uart_OFF};
        end
        else begin
            command_usb_bt_uart <= 6'h00;
        end
    end
    always @(posedge clk) begin
        if(!rstn) begin
            command_work <= 1'b0;
        end
        else if(state == S_TRANS) begin
            command_work <= 1'b1;
        end
        else begin
            command_work <= 1'b0;
        end
    end

    always @(*) begin
        if(state == S_TRANS) begin
            // 在trans模块解析
            uart_ON  = 1'b0;
            uart_OFF = 1'b0;
            usb_ON   = 1'b0;
            usb_OFF  = 1'b0;
            bt_ON    = 1'b0;
            bt_OFF   = 1'b0;
            case (i_instru_type)
                16'h000f: begin
                    // 开启蓝牙
                    bt_ON = 1'b1;
                end 
                16'h0010:begin
                    // 关闭蓝牙
                    bt_OFF = 1'b1;
                end
                16'h0011: begin
                    // 开启uart
                    uart_ON = 1'b1;
                end 
                16'h0012:begin
                    // 关闭uart
                    uart_OFF = 1'b1;
                end
                16'h0013: begin
                    // 开启usb
                    usb_ON = 1'b1;
                end 
                16'h0014:begin
                    // 关闭usb 
                    usb_OFF = 1'b1;
                end
                default: ;
            endcase
        end
        else begin
            uart_ON  = 1'b0;
            uart_OFF = 1'b0;
            usb_ON   = 1'b0;
            usb_OFF  = 1'b0;
            bt_ON    = 1'b0;
            bt_OFF   = 1'b0;
        end
    end

    logic [ 5: 0] single_OK;
    assign execute_OK = &single_OK;
    always @(posedge clk) begin
        if(state == S_SEND_WAIT_CHECK) begin
            if(command_usb_bt_uart_reg[5]) begin
                single_OK[5] <= (usb_bt_uart_state[2] == 1'b1) ? 1 : 0;
            end
            else begin
                single_OK[5] <= 1;
            end
            if (command_usb_bt_uart_reg[4]) begin
                single_OK[4] <= (usb_bt_uart_state[2] == 1'b0) ? 1 : 0;
            end
            else begin
                single_OK[4] <= 1; 
            end
            if (command_usb_bt_uart_reg[3]) begin
                single_OK[3] <= (usb_bt_uart_state[1] == 1'b1) ? 1 : 0;
            end
            else begin
                single_OK[3] <= 1;
            end
            if (command_usb_bt_uart_reg[2]) begin
                single_OK[2] <= (usb_bt_uart_state[1] == 1'b0) ? 1 : 0;
            end
            else begin
                single_OK[2] <= 1;
            end
            if (command_usb_bt_uart_reg[1]) begin
                single_OK[1] <= (usb_bt_uart_state[0] == 1'b1) ? 1 : 0;
            end
            else begin
                single_OK[1] <= 1;
            end
            if (command_usb_bt_uart_reg[0]) begin
                single_OK[0] <= (usb_bt_uart_state[0] == 1'b0) ? 1 : 0;
            end
            else begin
                single_OK[0] <= 1;
            end
        end
        else begin
            single_OK <= 6'h00;
        end
    end

    always @(*) begin
        command_to_reply = command_usb_bt_uart_reg;
        state_before = usb_bt_uart_state_REG_before;
        state_after  = usb_bt_uart_state_REG_after;
        execate_finish = execute_OK ; // execute_OK本身慢一拍，应答帧开始reply等一节拍 
    end







endmodule
