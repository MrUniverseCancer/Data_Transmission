`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/09/22 20:00:26
// Design Name: 
// Module Name: uart_blue_usb
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


module uart_blue_usb
    #(
        parameter ADC_NUM           = 15,
        parameter N_ROW             = 240,
        parameter N_COL             = 120,
        parameter CLK_FRE           = 100, //MHz
        parameter DATA_RATE         = 100 //Hz
    )(
    input                clk,
    input                rst_n,

    // blue tooth io接口
    input        i_uart_rx,
    input        i_bt_rx,
    output logic o_uart_tx,
    output logic o_bt_tx,


    // FX3 Slave FIFO接口
    input                           i_fx3_flaga,     //地址00时，slave fifo写入满标志位（可写）
    input                           i_fx3_flagb,     //地址00时，slave fifo写入快满标志位，该位拉低后还可以写入6个Byte数据
    input                           i_fx3_flagc,     //ctl[8]，地址11时，slave fifo读空标志位（可读）
    input                           i_fx3_flagd,     //ctl[9]，地址11时，slave fifo读快空标志位，该位拉低后还可以写入6个Byte数据（该信号处上电为高电平）
    output fx3_pclk,            //Slave FIFO同步时钟信号
    output                          o_fx3_slcs_n,    //Slave FIFO片选信号，低电平有效
    output                          o_fx3_slwr_n,    //Slave FIFO写使能信号，低电平有效
    output                          o_fx3_slrd_n,    //Slave FIFO读使能信号，低电平有效
    output                          o_fx3_sloe_n,    //Slave FIFO输出使能信号，低电平有效
    output                          o_fx3_pktend_n,  //包结束信号
    output [1:0]                    o_fx3_a,         //操作FIFO地址
    inout [31:0]                    io_fx3_db,       //数据
    // output                          o_fx3_clkin,    // reserved
    // output                          o_fx3_reset_n,  // reserved
    // input                           i_fx3_int_n,    // reserved
    // inout [3:0]                     io_fx3_gpio,    // reserved

    // ADC Data
    // input [192 * ADC_NUM - 1 : 0]   i_adc_data,
    // Flag
    input                           i_start_matrix,
    output logic                    o_start_matrix


    );

    localparam BAUD_RATE_UART = 2_000_000;
    localparam BAUD_RATE_BT   =   921_600;

    assign o_start_matrix = ~i_start_matrix;

    // TODO:
    // output                          o_start_row,
    // output                          o_switch_row
    logic o_start_row;
    logic o_switch_row;

   

    logic [192 * ADC_NUM - 1 : 0] i_adc_data;  
    logic i_adc_data_valid;
    logic [ 0: 0] o_data_valid;
    logic [ 7: 0] w_data_to_fifo;

    // assign i_adc_data = {48{8'h11, 8'h22, 8'h33, 8'h44, 8'h55, 8'h66, 8'h77, 8'h88}};
    generate_data  generate_data_inst (
        .data(i_adc_data)
    );
    assign i_adc_data_valid = 1;

    // 调整后的时钟信号
    logic sys_rst_n;
    logic clk_25m;
    logic clk_50m;
    logic clk_100m;


    // USB 模块
    // logic [ 0: 0] usb_fifo_full; // fifo满标志 // 可读的反
    logic [ 7: 0] usb_data_from_fifo;
    logic [ 0: 0] usb_fifo_wr_en;
    logic [ 0: 0] usb_able_to_write;

    // 接收模块和解析模块需要的
    logic [ 0: 0] uart_rx_pin;
    logic [ 0: 0] bt_rx_pin;
    logic [31: 0] rx_usb_data;
    logic [ 0: 0] rx_usb_data_valid;
    logic [ 0: 0] usb_waiting_false; // usb读取数据包结束标志
    logic [ 0: 0] rx_usb_data_ready; // usb模块允许读取数据
    logic [ 0: 0] i_ready;
    logic [ 7: 0] w_pkg_num;
    logic [ 0: 0] w_valid;
    logic [15: 0] w_instru_type;
    logic [127:0] w_data;
    logic [15: 0] w_length;

    // uart && bt
    logic [ 7: 0] uart_data_from_fifo;
    logic [ 0: 0] uart_fifo_wr_en;
    logic [ 0: 0] uart_able_to_write;
    // logic [ 0: 0] uart_able_reset_wr;
    // logic [ 1: 0] uart_fact_state;
    // logic [ 0: 0] uart_undefined;
    // logic [ 0: 0] uart_undefined2;


    // fifo信号
    logic [ 7: 0] fifo_wr_data;
    logic [ 0: 0] fifo_wr_en;
    logic [ 0: 0] fifo_rd_en;
    logic [ 7: 0] fifo_rd_data;
    logic [ 0: 0] fifo_full;
    logic [ 0: 0] fifo_prog_full;
    logic [ 0: 0] fifo_empty;

    // 返回帧处理模块 和 其与数据帧处理模块交互的
    logic [ 5: 0] command_usb_bt_uart;
    logic [ 0: 0] command_work;
    logic [ 0: 0] o_return_data_valid;
    logic [ 7: 0] o_return_data;
    logic [ 0: 0] i_returnFrame_begin;
    logic [ 0: 0] o_returnFrame_begin;

    localparam INITIAL_STATE = 4'b0001; // initial state of sending
    logic [ 3: 0] send_state; // 记录各个通道能否发送数据
    // 0 -> uart
    // 1 -> bt
    // 2 -> usb
    // 3 -> SD卡
    // 默认开机为SD卡和bt
    initial begin
        send_state = INITIAL_STATE;
    end

    always @(posedge clk_100m) begin
        if(!rst_n) begin
            send_state <= send_state; // 重置不改变其传输状态
        end
        else if(command_work) begin
            if(command_usb_bt_uart[0]) begin
                // uart_off
                send_state[0] = 1'b0;
            end
            else if(command_usb_bt_uart[1]) begin
                // uart_on
                send_state[0] = 1'b1;
            end
            
            else if(command_usb_bt_uart[2]) begin
                // bt_off
                send_state[1] = 1'b0;
            end
            else if(command_usb_bt_uart[3]) begin
                // bt_on
                send_state[1] = 1'b1;
            end
            else if(command_usb_bt_uart[4]) begin
                // usb_off
                send_state[2] = 1'b0;
            end
            else if(command_usb_bt_uart[5]) begin
                // usb_on
                send_state[2] = 1'b1;
            end
        end
        
    end
    



    // 通过返回帧o_return_data_valid来控制，为了减小延时，统一缓存一个周期
    // 即使在输出状态，o_return_data_valid=0，由于之前的保证也能够使得o_data_valid一定为0
    always @(posedge clk_100m) begin
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
        else if(send_state[1] | send_state[0]) begin
            // 允许蓝牙,uart发送数据
            fifo_rd_en = uart_able_to_write & usb_able_to_write; // uart/bt优先级最高的情况下，uart/bt模块愿意接收数据，才从fifo中读取数据
        end
        else if(send_state[2]) begin
            // 允许USB发送数据
            fifo_rd_en = usb_able_to_write; // usb优先级最高的情况下，usb模块愿意接收数据，才从fifo中读取数据
        end    
        else if(send_state[3]) begin
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
    //         fifo_rd_en = (usb_able_to_write && send_state[2]) | (uart_able_to_write && (send_state[0] | send_state[1]));
    //     end
    // end
    
    

    // 接收模块和解析模块需要的
    // assign uart_rx_pin = i_uart_rx & send_state[0];
    // assign bt_rx_pin   = i_bt_rx   & send_state[1];
    assign uart_rx_pin = i_uart_rx; // 保持接收常开，不受发送状态影响
    assign bt_rx_pin   = i_bt_rx  ; // 保持接收常开，不受发送状态影响


    // USB 模块
    assign usb_data_from_fifo = fifo_rd_data;
    assign usb_fifo_wr_en = fifo_rd_en && send_state[2] && usb_able_to_write; // TODO:

    // uart && bt
    assign uart_data_from_fifo = fifo_rd_data;
    assign uart_fifo_wr_en = fifo_rd_en && (send_state[1] | send_state[0]) && uart_able_to_write; 
    // 是否需要接收数据，控制权完全交给uart_bt_top模块自行决定

  


    sys_ctrl  sys_ctrl_inst (
        .ext_clk(clk),
        .ext_rst_n(rst_n),

        .sys_rst_n(sys_rst_n),
        .clk_25m(clk_25m),
        .clk_50m(clk_50m),
        .clk_100m(clk_100m),
        .fx3_pclk(fx3_pclk)
    );



    TOP_REC_DECODE #
    (
        .CLK_FRE(CLK_FRE),
        .BAUD_RATE_UART(BAUD_RATE_UART),
        .BAUD_RATE_BT(BAUD_RATE_BT)
    ) TOP_REC_DECODE_inst (
        .clk(clk_100m),
        .rstn(sys_rst_n),
        .uart_rx_pin(uart_rx_pin),
        .bt_rx_pin(bt_rx_pin),
        .rx_usb_data(rx_usb_data),
        .rx_usb_data_valid(rx_usb_data_valid),
        .usb_waiting_false(usb_waiting_false),
        .rx_usb_data_ready(rx_usb_data_ready),
        .i_ready(i_ready),
        .w_pkg_num(w_pkg_num),
        .w_valid(w_valid),
        .w_instru_type(w_instru_type),
        .w_data(w_data),
        .w_length(w_length)
    );

    Execute_Reply  Execute_Reply_inst (
        .clk(clk_100m),
        .rstn(sys_rst_n),
        .i_valid(w_valid),
        .i_pkg_num(w_pkg_num),
        .i_instru_type(w_instru_type),
        .i_data(w_data),
        .i_length(w_length),
        .w_ready(i_ready),
        .command_usb_bt_uart(command_usb_bt_uart),
        .command_work(command_work),
        .usb_bt_uart_state(send_state[ 2: 0]),
        .i_fifo_full(fifo_prog_full),
        .i_matrix_has_stop(o_returnFrame_begin),
        .o_matrix_control(i_returnFrame_begin),
        .o_return_data_valid(o_return_data_valid),
        .o_return_data(o_return_data)
    );

    // USB 的io
    USB_TOP  USB_TOP_inst (
        .clk(clk_100m),
        .rst_n(sys_rst_n),
        .fx3_flaga(i_fx3_flaga),
        .fx3_flagb(i_fx3_flagb),
        .fx3_flagc(i_fx3_flagc),
        .fx3_flagd(i_fx3_flagd),
        .fx3_slcs_n(o_fx3_slcs_n),
        .fx3_slwr_n(o_fx3_slwr_n),
        .fx3_slrd_n(o_fx3_slrd_n),
        .fx3_sloe_n(o_fx3_sloe_n),
        .fx3_pktend_n(o_fx3_pktend_n),
        .fx3_a(o_fx3_a),
        .fx3_db(io_fx3_db),
        .i_data_from_fifo(usb_data_from_fifo),
        .i_fifo_wr_en(usb_fifo_wr_en),
        // .w_fifo_full(usb_fifo_full),
        .o_able_to_write(usb_able_to_write),

        .i_fifo_rd_ready(rx_usb_data_ready),
        .o_data_from_fifo(rx_usb_data),
        .o_data_valid(rx_usb_data_valid),
        .o_waiting_false(usb_waiting_false)
    );

    // uart&&bt的output
    UART_BT_TOP #
    (
        .CLK_FRE(CLK_FRE),
        .BAUD_RATE_UART(BAUD_RATE_UART),
        .BAUD_RATE_BT(BAUD_RATE_BT)
    ) UART_BT_TOP_inst (
        .clk(clk_100m),
        .rst_n(sys_rst_n),
        .i_data_from_fifo(uart_data_from_fifo),
        .i_fifo_wr_en(uart_fifo_wr_en),
        .o_able_to_write(uart_able_to_write),
        // .o_able_reset_wr(uart_able_reset_wr),
        .o_uart_tx(o_uart_tx),
        .o_bt_tx(o_bt_tx),
        .fact_state(send_state[1:0])
        // .i_undefined(1'b0),
        // .o_send_state(uart_fact_state),
        // .o_undefined(uart_undefined2)
    );


    // FIFO module, get the pancaged data and send for other module
    // 数据来源：数据帧处理模块和返回帧处理模块，优先级：返回帧处理模块>数据帧处理模块
    // fifo_wr_en 是缓存了一个周期的，所以不能够给产生数据的模块fifo_full信号，这样会导致 fifo_wr_en 多一个周期，导致数据丢失1
    // 所以这里将 fifo_prog_full 当作full信号传给产生数据的模块(包括数据帧和指令帧)
    // 要求 x = full -1 时，prog_full = 1，这样有一个空间的缓冲，使得刚好满利用fifo，同时保证数据不会丢失
    in8_out8_fifo bigFIFO (
        .clk(clk_100m),      // input wire clk
        .srst(!sys_rst_n),    // input wire srst
        .din(fifo_wr_data),      // input wire [7 : 0] din
        .wr_en(fifo_wr_en),  // input wire wr_en
        .rd_en(fifo_rd_en),  // input wire rd_en
        .dout(fifo_rd_data),    // output wire [7 : 0] dout
        .full(fifo_full),    // output wire full
        .prog_full(fifo_prog_full),    // output wire prog_full
        .empty(fifo_empty)  // output wire empty
    );


    // for test
    logic [ 0: 0] happen_top;
    check_module  check_module_inst1 (
        .clk(clk_100m),
        .rstn(sys_rst_n),
        .data_in(fifo_wr_data),
        .data_valid(fifo_wr_en),
        .happen(happen_top)
    );
    

    // get initial data and process it module
    localparam BITMASK = 10'b11_0111_1111;
    localparam SERIAL_NUM = 1;
    localparam ACCURACY = 1;
    // temp
    logic [12: 0] matric_state;
    //temp
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
        .clk                        (clk_100m                 ),
        .rst_n                      (sys_rst_n                ),
        // ADC Data
        .i_adc_data                 (i_adc_data               ),
        // send data to fifo
        .o_data_to_fifo             (w_data_to_fifo           ),
        // Flag
        .i_returnFrame_begin        (i_returnFrame_begin      ),
        .o_returnFrame_begin        (o_returnFrame_begin      ),
        .i_start_matrix             (i_start_matrix           ),
        .o_start_row                (o_start_row              ),
        .i_adc_data_valid           (i_adc_data_valid         ),
        .o_switch_row               (o_switch_row             ),
        .i_fifo_full                (fifo_prog_full          ),
        .o_fifo_wr_en               (o_data_valid             )

        ,.state(matric_state)
    );


    // ila_1 your_instance_name (
    //     .clk(clk_100m), // input wire clk


    //     .probe0({fifo_wr_data, fifo_wr_en, fifo_empty}), // input wire [9:0]  probe0  
    //     .probe1({send_state, uart_rx_pin, bt_rx_pin, 3'd0}) // input wire [9:0]  probe1
    // );
//     ila_2 your_instance_name (
// 	.clk(clk), // input wire clk


// 	.probe0({i_returnFrame_begin, o_returnFrame_begin, o_return_data_valid}), // input wire [1:0]  probe0  
// 	.probe1({fifo_wr_data, fifo_wr_en}), // input wire [8:0]  probe1 
// 	.probe2({fifo_rd_data, fifo_rd_en}), // input wire [8:0]  probe2 
// 	.probe3({uart_fifo_wr_en, o_uart_tx, o_bt_tx}), // input wire [4:0]  probe3
// 	// .probe1({o_return_data_valid, o_return_data}), // input wire [8:0]  probe1 
// 	// .probe2({o_data_valid, w_data_to_fifo}), // input wire [8:0]  probe2 
// 	// .probe3({send_state, uart_rx_pin}), // input wire [4:0]  probe3
//     .probe4({matric_state}) // input wire [12:0]  probe4
// );
// {i_returnFrame_begin, o_returnFrame_begin}
// {o_return_data_valid, o_return_data}
// {o_data_valid, w_data_to_fifo}
// {send_state, uart_rx_pin}

endmodule
