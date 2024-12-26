`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/04/20 11:20:02
// Design Name: 
// Module Name: Matric_tran_ctrl
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


module Matric_tran_ctrl
    #(
        parameter ADC_NUM           = 1,
        parameter N_ROW             = 4,
        parameter N_COL             = 8,
        parameter CLK_FRE           = 50, //MHz
        parameter DATA_RATE         = 100 //Hz
    )(
        input       clk,
        input       rst_n,
        // ADC Data
        input [192 * ADC_NUM - 1 : 0]   i_adc_data,
        // Digital Out
        // output [N_ROW - 1 : 0]          o_matrix_row,
        // FX3 Slave FIFO接口
        input                           i_fx3_flaga,     //地址00时，slave fifo写入满标志位（可写）
        input                           i_fx3_flagb,     //地址00时，slave fifo写入快满标志位，该位拉低后还可以写入6个Byte数据
        input                           i_fx3_flagc,     //ctl[8]，地址11时，slave fifo读空标志位（可读）
        input                           i_fx3_flagd,     //ctl[9]，地址11时，slave fifo读快空标志位，该位拉低后还可以写入6个Byte数据（该信号处上电为高电平）
        // output fx3_pclk,            //Slave FIFO同步时钟信号
        output                          o_fx3_slcs_n,    //Slave FIFO片选信号，低电平有效
        output                          o_fx3_slwr_n,    //Slave FIFO写使能信号，低电平有效
        output                          o_fx3_slrd_n,    //Slave FIFO读使能信号，低电平有效
        output                          o_fx3_sloe_n,    //Slave FIFO输出使能信号，低电平有效
        output                          o_fx3_pktend_n,  //包结束信号
        output [1:0]                    o_fx3_a,         //操作FIFO地址
        inout [31:0]                    io_fx3_db,       //数据
        // output uart_tx
        // output                          o_uart_tx,
        // Flag
        input                           i_start_matrix,
        output                          o_start_row,
        input                           i_adc_data_valid,
        output                          o_switch_row,
        // Debug
        output                          o_fifo_full,
        output                          o_fifo_empty
    );

    localparam BITMASK = 10'b11_0111_1111;
    localparam SERIAL_NUM = 1;
    localparam ACCURACY = 1;
 

    wire w_fifo_full;
    wire w_fifo_wr_en;
    wire [31:0] w_data_from_fifo;
    wire [31:0] w_data_from_fifo_change; // w_data_from_fifo中间的数据，由4个8位数据组成，但是放入的先后顺序恰好相反
    wire w_fifo_empty;
    wire w_fifo_prog_empty;
    wire w_fifo_rd_en;
    wire [7:0] w_data_to_fifo;
    
    wire [7:0] w_uart_tx_data;
    wire r_uart_tx_data_valid;
    wire w_uart_tx_data_ready;

    // debug
    assign o_fifo_full = w_fifo_full;
    assign o_fifo_empty = w_fifo_empty;

    matric_ctrl_v1#
    (
        .ADC_NUM(ADC_NUM),
        .SERIAL_NUM(SERIAL_NUM),
        .ACCURACY(ACCURACY),
        .N_ROW(N_ROW),
        .N_COL(N_COL),
        .CLK_FRE(CLK_FRE),
        .DATA_RATE(DATA_RATE),
        .BITMASK(BITMASK)
    ) matrix_ctrl_inst
    (
        .clk                        (clk                      ),
        .rst_n                      (rst_n                    ),
        // ADC Data
        .i_adc_data                 (i_adc_data               ),
        // send data to fifo
        .o_data_to_fifo             (w_data_to_fifo           ),
        // Flag
        .i_start_matrix             (i_start_matrix           ),
        .o_start_row                (o_start_row              ),
        .i_adc_data_valid           (i_adc_data_valid         ),
        .o_switch_row               (o_switch_row             ),
        .i_fifo_full                (w_fifo_full              ),
        .o_fifo_wr_en               (w_fifo_wr_en             )
    );
    logic [3:0] state;
    logic [9:0] num;
    USB_ctrl USB_ctrl_inst(
        .clk                        (clk                      ),
        .rst_n                      (rst_n                    ),
        .fx3_flaga                  (i_fx3_flaga              ),
        .fx3_flagb                  (i_fx3_flagb              ),
        .fx3_flagc                  (i_fx3_flagc              ),
        .fx3_flagd                  (i_fx3_flagd              ),
        // .fx3_pclk                   (o_fx3_pclk               ),
        .fx3_slcs_n                 (o_fx3_slcs_n             ),
        .fx3_slwr_n                 (o_fx3_slwr_n             ),
        .fx3_slrd_n                 (o_fx3_slrd_n             ),
        .fx3_sloe_n                 (o_fx3_sloe_n             ),
        .fx3_pktend_n               (o_fx3_pktend_n           ),
        .fx3_a                      (o_fx3_a                  ),
        .fx3_db                     (io_fx3_db                ),
	    // send data from fifo
        // .i_data_from_fifo           (test_data                ),
        .i_data_from_fifo           (w_data_from_fifo_change  ),
	    // Flag
        .i_fifo_empty               (w_fifo_empty             ),
        .i_fifo_prog_empty          (w_fifo_prog_empty        ),
        .o_fifo_rd_en               (w_fifo_rd_en             ),
        .state                      (state                    ),
        .factnum                    (num                      )
    );


    // out_data_test 测试能否正确发送数据
    logic [31: 0] test_data;
    // logic [ 0: 0] test_wr_en;

    assign test_wr_en = ~w_fifo_full;
    always @(posedge clk) begin
        if(!rst_n) begin
            test_data <= 32'd0;
        end else begin
            if(w_fifo_rd_en) begin
                test_data <= test_data + 1;
            end
        end
    end

    fifo_generator_0 fifo_generator_0_inst (
        .clk                        (clk                      ),    // input wire clk
        .srst                       (!rst_n                   ),    // input wire srst
        .din                        (w_data_to_fifo           ),    // input wire [7 : 0] din
        // .din                        (test_data                ),    // input wire [7 : 0] test_din
        .wr_en                      (w_fifo_wr_en             ),    // input wire wr_en
        // .wr_en                      (test_wr_en               ),    // input wire test_wr_en
        .rd_en                      (w_fifo_rd_en             ),    // input wire rd_en
        .dout                       (w_data_from_fifo         ),    // output wire [31 : 0] dout
        .full                       (w_fifo_full              ),    // output wire full
        .empty                      (w_fifo_empty             ),    // output wire empty
        .prog_empty                 (w_fifo_prog_empty        )     // output wire prog_empty, 256
    );

    assign w_data_from_fifo_change[ 7: 0] = w_data_from_fifo[31:24];
    assign w_data_from_fifo_change[15: 8] = w_data_from_fifo[23:16];
    assign w_data_from_fifo_change[23:16] = w_data_from_fifo[15: 8];
    assign w_data_from_fifo_change[31:24] = w_data_from_fifo[ 7: 0];


    USB_Debug_ILA2 your_instance_name (
        .clk(clk), // input wire clk
    
    
        .probe0({w_fifo_wr_en , w_data_to_fifo}), // input wire [0:0]  probe0  
        .probe1({w_fifo_rd_en, w_data_from_fifo}), // input wire [31:0]  probe1	
        .probe2({o_fx3_slcs_n, o_fx3_slwr_n, i_fx3_flaga, i_fx3_flagb}),
        .probe3(io_fx3_db),
        .probe4({state, num})
    );

    // // TODO：
    // uart_tx#
    // (
    //     .CLK_FRE(CLK_FRE),
    //     .BAUD_RATE(921600)
    // ) uart_tx_inst
    // (
    //     .clk                        (clk                      ),
    //     .rst_n                      (rst_n                    ),
    //     .tx_data                    (w_uart_tx_data           ),
    //     .tx_data_valid              (r_uart_tx_data_valid     ),
    //     .tx_data_ready              (w_uart_tx_data_ready     ),
    //     .tx_pin                     (o_uart_tx                )
    // );
endmodule
