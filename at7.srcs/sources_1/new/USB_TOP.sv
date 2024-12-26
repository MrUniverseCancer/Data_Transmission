`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/09/23 19:11:39
// Design Name: 
// Module Name: USB_TOP
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


module USB_TOP(
        input [ 0: 0] clk,
        input [ 0: 0] rst_n,

        // FX3 Slave FIFO接口
        input fx3_flaga,            	//地址00时，slave fifo写入满标志位（可写）
        input fx3_flagb,            	//地址00时，slave fifo写入快满标志位，该位拉低后还可以写入6个Byte数据
        input fx3_flagc,            	//ctl[8]，地址11时，slave fifo读空标志位（可读）
        input fx3_flagd,            	//ctl[9]，地址11时，slave fifo读快空标志位，该位拉低后还可以写入6个Byte数据（该信号处上电为高电平）
        // output fx3_pclk,            //Slave FIFO同步时钟信号
        output reg fx3_slcs_n,      	//Slave FIFO片选信号，低电平有效
        output reg fx3_slwr_n,      	//Slave FIFO写使能信号，低电平有效
        output reg fx3_slrd_n,      	//Slave FIFO读使能信号，低电平有效
        output reg fx3_sloe_n,      	//Slave FIFO输出使能信号，低电平有效
        output reg fx3_pktend_n,    	//包结束信号
        output reg[1:0] fx3_a,      	//操作FIFO地址
        inout[31:0] fx3_db,         	//数据

        input        [ 7: 0] i_data_from_fifo,
        input        [ 0: 0] i_fifo_wr_en,
        // output logic [ 0: 0] w_fifo_full, //不需要传递full了，由usb_able_to_write来控制
        output logic [ 0: 0] o_able_to_write,

        input        [ 0: 0] i_fifo_rd_ready,
        output logic [31: 0] o_data_from_fifo,
        output logic [ 0: 0] o_data_valid,
        output logic [ 0: 0] o_waiting_false

    );

    wire [31:0] w_data_from_fifo;
    wire [31:0] w_data_from_fifo_change; // w_data_from_fifo中间的数据，由4个8位数据组成，但是放入的先后顺序恰好相反
    wire w_fifo_empty;
    wire w_fifo_prog_full;
    wire w_fifo_prog_empty;
    wire w_fifo_rd_en;
    logic [ 0: 0] fifo_wr_en;
    
    // TODO:
    assign w_data_from_fifo_change = {w_data_from_fifo[7:0], w_data_from_fifo[15:8], w_data_from_fifo[23:16], w_data_from_fifo[31:24]};
    always @(posedge clk) begin
        if(!rst_n) begin
            fifo_wr_en <= 1'b0;
        end 
        else begin
            fifo_wr_en <= i_fifo_wr_en && !w_fifo_full;
        end
        
    end

    // 该语段来自于UART_BT_TOP.sv的相同逻辑实现中的小修改 
    // TODO: 在可写状态下，由于速度较慢，往往会满。(这里指代的是SD卡可写)
    // 如果每次都是一旦非满就重启填写FIFO，那么会导致数据断断续续
    // 所以，需要在FIFO满的时候，等待FIFO非满，然后再重启填写FIFO
    // 向外界输出由o_unable_to_write控制
    always @(posedge clk) begin
        if(!rst_n) begin
            o_able_to_write <= 1'b1;
        end
        else if(o_able_to_write == 1'b1) begin
            // 可写状态，一旦收到{满, 将满}，则进入不可写状态
            if(w_fifo_prog_full) begin
                o_able_to_write <= 1'b0;
            end
        end
        else begin
            // 不可写状态，一旦收到{非满, 将空}，则进入可写状态
            // 不能是空，因为USB的FIFO总是留有一些冗余，因为不在prog_empty的时候，是不能写入的
            if(w_fifo_prog_empty) begin
                o_able_to_write <= 1'b1;
            end
        end
    end
    fifo_generator_0 fifo_generator_0_inst (
        .clk                        (clk                      ),    // input wire clk
        .srst                       (!rst_n                   ),    // input wire srst
        .din                        (i_data_from_fifo         ),    // input wire [7 : 0] din
        .wr_en                      (fifo_wr_en               ),    // input wire wr_en
        .rd_en                      (w_fifo_rd_en             ),    // input wire rd_en
        .dout                       (w_data_from_fifo         ),    // output wire [31 : 0] dout
        .full                       (w_fifo_full              ),    // output wire full
        .empty                      (w_fifo_empty             ),    // output wire empty
        .prog_full                  (w_fifo_prog_full         ),    // output wire prog_full
        .prog_empty                 (w_fifo_prog_empty        )     // output wire prog_empty, 256
    );

    // USB_ctrl module
    logic [3:0] state;
    logic [9:0] num;
    USB_ctrl_io USB_ctrl_inst(
        .clk                        (clk                      ),
        .rst_n                      (rst_n                    ),
        .fx3_flaga                  (fx3_flaga              ),
        .fx3_flagb                  (fx3_flagb              ),
        .fx3_flagc                  (fx3_flagc              ),
        .fx3_flagd                  (fx3_flagd              ),
        // .fx3_pclk                   (o_fx3_pclk               ),
        .fx3_slcs_n                 (fx3_slcs_n             ),
        .fx3_slwr_n                 (fx3_slwr_n             ),
        .fx3_slrd_n                 (fx3_slrd_n             ),
        .fx3_sloe_n                 (fx3_sloe_n             ),
        .fx3_pktend_n               (fx3_pktend_n           ),
        .fx3_a                      (fx3_a                  ),
        .fx3_db                     (fx3_db                 ),
	    // send data from fifo
        // .i_data_from_fifo           (test_data                ),
        .i_data_from_fifo           (w_data_from_fifo         ),
	    // Flag
        .i_fifo_empty               (w_fifo_empty             ),
        .i_fifo_prog_empty          (w_fifo_prog_empty        ),
        .o_fifo_rd_en               (w_fifo_rd_en             ),
        .i_fifo_rd_ready            (i_fifo_rd_ready          ),
        .o_data_from_fifo           (o_data_from_fifo         ),
        .o_data_valid               (o_data_valid             ),
        .o_waiting_false            (o_waiting_false          ),
        .state                      (state                    ),
        .factnum                    (num                      )
    );
endmodule
