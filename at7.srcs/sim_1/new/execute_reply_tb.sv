`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/10/10 14:10:36
// Design Name: 
// Module Name: execute_reply_tb
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


module execute_reply_tb(

    );
    // 生成所有的信号声明
    logic [ 0: 0] clk;
    logic [ 0: 0] rstn;

    logic [ 0: 0] i_valid;
    logic [15: 0] i_instru_type;
    logic [127:0] i_data;
    logic [15: 0] i_length;
    logic [ 0: 0] w_ready;

    logic [ 5: 0] command_usb_bt_uart;
    logic [ 2: 0] usb_bt_uart_state;

    logic [ 0: 0] i_fifo_full;
    logic [ 0: 0] i_matrix_has_stop;

    logic [ 0: 0] o_return_data_valid;
    logic [11: 0] o_return_data;


    Execute_Reply  Execute_Reply_inst (
        .clk(clk),
        .rstn(rstn),

        .i_valid(i_valid),
        .i_instru_type(i_instru_type),
        .i_data(i_data),
        .i_length(i_length),
        .w_ready(w_ready),

        .command_usb_bt_uart(command_usb_bt_uart),
        .usb_bt_uart_state(usb_bt_uart_state),

        .i_fifo_full(i_fifo_full),
        .i_matrix_has_stop(i_matrix_has_stop),
        .o_return_data_valid(o_return_data_valid),
        .o_return_data(o_return_data)
    );

    initial begin
        clk = 1'b0;
        forever begin
            #1 clk = ~clk;
        end
    end

    initial begin
        i_data = 128'h0;
        i_length = 16'h0;
        i_fifo_full = 1'b0;
        i_matrix_has_stop = 1'b1;
    end

    initial begin
        rstn = 1'b0;
        #10 rstn = 1'b1;

        i_instru_type = 16'h000f;
        i_valid = 1'b1;
        #3 i_valid = 1'b0;

        #40;
        i_instru_type = 16'h0011;
        i_valid = 1'b1;
        #3 i_valid = 1'b0;
    end
    always @(posedge clk) begin
        if(!rstn) begin
            usb_bt_uart_state <= 3'h0;
        end
        else begin
            case (command_usb_bt_uart)
                6'h01:begin
                    usb_bt_uart_state[0] <= 1'b0;
                end
                6'h02:begin
                    usb_bt_uart_state[0] <= 1'b1;
                end
                6'h04:begin
                    usb_bt_uart_state[1] <= 1'b0;
                end
                6'h08:begin
                    usb_bt_uart_state[1] <= 1'b1;
                end
                6'h10:begin
                    usb_bt_uart_state[2] <= 1'b0;
                end
                6'h20:begin
                    usb_bt_uart_state[2] <= 1'b1;
                end
            endcase
        end
    end

    // 应答回复成功
endmodule
