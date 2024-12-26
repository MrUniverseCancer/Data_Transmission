`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/09/26 10:11:36
// Design Name: 
// Module Name: UART_BT_TOP
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


module UART_BT_TOP
#(
    parameter CLK_FRE = 100,
    parameter BAUD_RATE_UART = 2_000_000,
    parameter BAUD_RATE_BT = 921600
)(
    input clk,
    input rst_n,

    input        [ 7: 0] i_data_from_fifo,
    input        [ 0: 0] i_fifo_wr_en,  // FIFO给出的数据是否有效，等价于读使能{默认外界已经知道o_unable_to_write带来的中止写入信号，处理好了}
    // output logic [ 0: 0] o_unable_to_write,  // 自己FIFO写满标志
    // output logic [ 0: 0] o_able_reset_wr, // 给总FIFO，同意重新对uart&&bt输出的信号
    output logic [ 0: 0] o_able_to_write,  // 能否接收数据的信号

    output logic o_uart_tx,
    output logic o_bt_tx,

    // 关于通道的控制信号
    input        [ 1: 0] fact_state // [1] -> bt, [0] -> uart
    // input        [ 0: 0] i_undefined, // 未定义的控制信号 // 后期用于引入控制命令
    // output logic [ 1: 0] o_send_state, // [1] -> bt, [0] -> uart
    // output logic [ 0: 0] o_undefined // 未定义的回复信号 // 后期用于引入控制

    );

    // localparam CLK_FRE   = 100;
    // // localparam BAUD_RATE_UART = 100_000_000;
    // localparam BAUD_RATE_UART = 2_000_000;
    // localparam BAUD_RATE_BT   = 921600;


    // FIFO模块
    logic [ 7: 0] dout;
    logic         wr_en;
    logic         rd_en;
    logic         full;
    logic         empty;
    logic         prog_full;
    logic         prog_empty;    

    // uart,bt输出模块的交互信号
    logic uart_ready;
    logic uart_valid;
    logic bt_ready;
    logic bt_valid;

    always @(posedge clk) begin
        if(!rst_n ) begin
            wr_en <= 1'b0;
        end
        else begin
            wr_en = i_fifo_wr_en && !full;
        end
    end

    // 串口输出模块
    uart_tx # (
        .CLK_FRE(CLK_FRE),
        .BAUD_RATE(BAUD_RATE_UART)
    )
    uart_inst (
        .clk(clk),
        .rst_n(rst_n),
        .tx_data(dout),
        .tx_data_valid(uart_valid),
        .tx_data_ready(uart_ready),
        .tx_pin(o_uart_tx)
    );
  


    // 蓝牙输出模块
    uart_tx # (
        .CLK_FRE(CLK_FRE),
        .BAUD_RATE(BAUD_RATE_BT)
    )
    bt_inst (
        .clk(clk),
        .rst_n(rst_n),
        .tx_data(dout),
        .tx_data_valid(bt_valid),
        .tx_data_ready(bt_ready),
        .tx_pin(o_bt_tx)
    );

    // FIFO模块
    uart_bt_FIFO your_instance_name (
        .clk(clk),              // input wire clk
        .srst(!rst_n),            // input wire srst
        .din(i_data_from_fifo),              // input wire [7 : 0] din
        .wr_en(wr_en),          // input wire wr_en
        .rd_en(rd_en),          // input wire rd_en
        .dout(dout),            // output wire [7 : 0] dout
        .full(full),            // output wire full
        .empty(empty),          // output wire empty
        .prog_full(prog_full),    // output wire prog_full
        .prog_empty(prog_empty)  // output wire prog_empty
    );
    // 参照top模块的FIFO的wr_en 与 fifo_full之间的协调关系，显然这里也需要一个协调关系
    // 实际上，给出的 o_able_to_write 是时序的，所以延缓一个时钟出结果。对于FIFO的读取，本身是自带一个时钟延缓的
    // 所以 当 x = full - 2时，prog_full生效。
    // 这样理论上是完全利用了FIFO的空间.


    logic [ 0: 0] happen_fifo_uart;
    check_module  check_module_inst2 (
        .clk(clk),
        .rstn(rst_n),
        .data_in(i_data_from_fifo),
        .data_valid(wr_en),
        .happen(happen_fifo_uart)
    );
    logic [ 0: 0] happen_uart;
    check_module  check_module_inst3 (
        .clk(clk),
        .rstn(rst_n),
        .data_in(dout),
        .data_valid(uart_valid),
        .happen(happen_uart)
    );



    // TODO: 在可写状态下，由于速度较慢，往往会满。
    // 如果每次都是一旦非满就重启填写FIFO，那么会导致数据断断续续
    // 所以，需要在FIFO满的时候，等待FIFO非满，然后再重启填写FIFO
    // 向外界输出由o_unable_to_write控制
    always @(posedge clk) begin
        if(!rst_n) begin
            o_able_to_write <= 1'b1;
        end
        else if(o_able_to_write == 1'b1) begin
            // 可写状态，一旦收到{满, 将满}，则进入不可写状态
            if(prog_full) begin
                o_able_to_write <= 1'b0;
            end
        end
        else begin
            // 不可写状态，一旦收到{非满, 将空}，则进入可写状态
            // 最长等待的时钟数是每行之间的等待时间，计算得到是4166.67 clk
            // 921600 的波特率，每个字节的时间是 1085 clk
            // 所以，剩下5个数据的时间点，就可以开始写入了
            if(prog_empty) begin
                o_able_to_write <= 1'b1;
            end
        end
    end


    always @(*) begin
        if(fact_state == 2'b00) begin
            // 双通道都禁止
            rd_en = 1'b0;
        end
        else if(fact_state[0]) begin
            // uart通道允许,bt通道禁止
            rd_en = uart_ready && !empty && !uart_valid;
        end
        else if(fact_state[1]) begin
            // bt通道允许
            // 不检查uart通道的允许
            rd_en = bt_ready && !empty && !bt_valid;
        end
        else begin
            rd_en = 1'b0;
        end
    end

    always @(posedge clk) begin
        if(!rst_n) begin
            bt_valid <= 1'b0;
        end
        else if(fact_state[1]) begin
            if(bt_valid == 1'b1) begin
                bt_valid <= 1'b0;
            end
            else begin
                bt_valid <= rd_en;
            end
        end
        else begin
            bt_valid <= 1'b0;
        end
        
    end
    always @(posedge clk) begin
        if(!rst_n) begin
            uart_valid <= 1'b0;
        end
        else if(fact_state[0]) begin
            if(uart_valid == 1'b1) begin
                uart_valid <= 1'b0;
            end
            else begin
                uart_valid <= rd_en;
            end
        end
        else begin
            uart_valid <= 1'b0;
        end
        
    end
endmodule
