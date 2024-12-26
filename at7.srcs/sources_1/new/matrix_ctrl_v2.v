`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/03/07 10:32:02
// Design Name: 
// Module Name: matrix_ctrl_v2
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
//
    // matrix_ctrl_v2#
    // (
    //     .ADC_NUM(ADC_NUM),
    //     .N_ROW(N_ROW),
    //     .N_COL(N_COL),
    //     .CLK_FRE(100),
    //     .DATA_RATE(DATA_RATE)
    // ) matrix_ctrl_inst
    // (
    //     .clk                        (clk_100m                 ),
    //     .rst_n                      (sys_rst_n                ),
    //     // ADC Data
    //     .i_adc_data                 (w_adc_data_fast          ),
    //     // UART Interface
    //     .o_uart_tx                  (o_uart_tx                ),
    //     // Flag
    //     .i_start_matrix             (w_start_matrix_and       ),
    //     .o_start_row                (w_start_row              ),
    //     .i_data_valid               (w_data_valid             ),
    //     .o_switch_row               (w_switch_row             )
    // );
// 
//////////////////////////////////////////////////////////////////////////////////


module matrix_ctrl_v2
    #(
        parameter ADC_NUM           = 1,
        parameter ACCURACY          = 1,
        parameter N_ROW             = 4,
        parameter N_COL             = 8,
        parameter CLK_FRE           = 50, //MHz
        parameter DATA_RATE         = 100 //Hz
    )(
        input       clk,
        input       rst_n,
        // ADC Data
        input [192 * ADC_NUM - 1 : 0]               i_adc_data,
        // UART Interface
        output                                      o_uart_tx,
        // Flag
        input                                       i_start_matrix,
        output reg                                  o_start_row,
        input                                       i_data_valid,
        output reg                                  o_switch_row
    );

    // Data Format: {SEND_HEAD4, SEND_FUNC1, SEND_DATA_LEN4, send_pkt_num4, send_time4,send_accuracy, reserved ,matrix_data(3*N_ROW*N_COL), send_sum_check1}

    localparam  LEN_send_head           = 4;  // 32
    localparam  LEN_send_func           = 1;  // 8
    localparam  LEN_send_data_len       = 4;  // 32
    localparam  LEN_send_pkt_num        = 4;  // 32
    localparam  LEN_send_time           = 4;  // 32
    localparam  LEN_send_accuracy       = 1;  // 8
    localparam  LEN_send_reserved       = 4;  // 32
    localparam  LEN_row_data            = 24 * ADC_NUM;  // 192 * ADC_NUM
    localparam  LEN_send_sum_check      = 1;  // 8
    wire [8 * LEN_send_head - 1: 0]         send_head;
    wire [8 * LEN_send_func - 1: 0]         send_func;
    wire [8 * LEN_send_data_len - 1: 0]     send_data_len;
    wire [8 * LEN_send_pkt_num - 1: 0]      send_pkt_num;
    wire [8 * LEN_send_time - 1: 0]         send_time;
    wire [8 * LEN_send_accuracy - 1: 0]     send_accuracy;
    wire [8 * LEN_send_reserved - 1: 0]     send_reserved;
    wire [8 * LEN_row_data - 1: 0]          send_row_data;
    reg  [8 * LEN_send_sum_check - 1: 0]    send_sum_check;

    localparam                          WAIT_TIME_row   = CLK_FRE * 1000000 / DATA_RATE / N_ROW - 1;

    localparam                          S_IDLE              = 12'b000000000001;
    localparam                          S_SEND_HEAD         = 12'b000000000010;
    localparam                          S_SEND_FUNC         = 12'b000000000100;
    localparam                          S_SEND_DATA_LEN     = 12'b000000001000;
    localparam                          S_SEND_PKT_NUM      = 12'b000000010000;
    localparam                          S_SEND_TIME         = 12'b000000100000;
    localparam                          S_SEND_ACCURACY     = 12'b000001000000;
    localparam                          S_SEND_RESERVED     = 12'b000010000000;
    localparam                          S_SET_ROW           = 12'b000100000000;
    localparam                          S_WAIT_DATA         = 12'b001000000000;
    localparam                          S_SEND_ROW          = 12'b010000000000;
    localparam                          S_SEND_SUM_CHECK    = 12'b100000000000;

    reg [$clog2(WAIT_TIME_row+1)-1 : 0] r_clk_cnt;
    reg [$clog2(N_ROW+1)-1 : 0]         r_row_cnt;
    reg [$clog2(LEN_row_data+1)-1 : 0]  r_shift_cnt;

    reg                                 r_matrix_valid;

    reg [192 * ADC_NUM - 1 : 0]         r_adc_data;

    // FIFO
    wire                                w_fifo_wr_en;
    wire                                w_fifo_rd_en;
    wire                                w_fifo_full;
    wire                                w_fifo_empty;
    reg [7:0]                           r_data_to_fifo;
    reg                                 r_data_to_fifo_valid;
    // UART
    wire [7:0]                          w_uart_tx_data;
    reg                                 r_uart_tx_data_valid;
    wire                                w_uart_tx_data_ready;

    reg [9:0]                           state;
    reg [9:0]                           next_state;

    // Data Format
    assign send_head        = 32'hAA_BB_AB_AB;
    assign send_func        = 8'h01;
    assign send_accuracy    = (ACCURACY == 1) ? 8'h96 : 8'h69;
    assign send_reserved    = 32'h0000_0000;
    assign send_data_len    = 3 * N_ROW * N_COL;

    // Control Signal
    assign w_fifo_wr_en = r_data_to_fifo_valid && ~w_fifo_full;
    assign w_fifo_rd_en = w_uart_tx_data_ready && ~r_uart_tx_data_valid && ~w_fifo_empty;

    always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin
            r_uart_tx_data_valid <= 0;
        end
        else
        begin
            if (w_uart_tx_data_ready == 1'b1 && r_uart_tx_data_valid == 1'b0 && ~w_fifo_empty)
            begin
                r_uart_tx_data_valid <= 1'b1;
            end
            if (r_uart_tx_data_valid == 1'b1)
            begin
                r_uart_tx_data_valid <= 1'b0;
            end
        end
    end


    // FSM begin
    always@(posedge clk or negedge rst_n)
    begin
        if(rst_n == 1'b0)
            state <= S_IDLE;
        else
            state <= next_state;
    end

    always@(*)
    begin
        case(state)
            S_IDLE:
                if (i_start_matrix == 1'b1 && ~w_fifo_full)
                    next_state <= S_SEND_HEAD;
                else
                    next_state <= S_IDLE;
            S_SEND_HEAD:
                if (r_shift_cnt == LEN_send_head && ~w_fifo_full)
                    next_state <= S_SEND_FUNC;
                else
                    next_state <= S_SEND_HEAD;
            S_SEND_FUNC:
                if (r_shift_cnt == LEN_send_func && ~w_fifo_full)
                    next_state <= S_SEND_DATA_LEN;
                else
                    next_state <= S_SEND_FUNC;
            S_SEND_DATA_LEN:
                if (r_shift_cnt == LEN_send_data_len && ~w_fifo_full)
                    next_state <= S_SEND_PKT_NUM;
                else
                    next_state <= S_SEND_DATA_LEN;
            S_SEND_PKT_NUM:
                if (r_shift_cnt == LEN_send_pkt_num && ~w_fifo_full)
                    next_state <= S_SEND_TIME;
                else
                    next_state <= S_SEND_PKT_NUM;
            S_SEND_TIME:
                if (r_shift_cnt == LEN_send_time && ~w_fifo_full)
                    next_state <= S_SEND_ACCURACY;
                else
                    next_state <= S_SEND_TIME;
            S_SEND_ACCURACY:
                if (r_shift_cnt == LEN_send_accuracy && ~w_fifo_full)
                    next_state <= S_SEND_RESERVED;
                else
                    next_state <= S_SEND_ACCURACY;
            S_SEND_RESERVED:
                if (r_shift_cnt == LEN_send_reserved && ~w_fifo_full)
                    next_state <= S_SET_ROW;
                else
                    next_state <= S_SEND_RESERVED;
            S_SET_ROW:
                if (r_clk_cnt == WAIT_TIME_row)
                    next_state <= S_WAIT_DATA;
                else
                    next_state <= S_SET_ROW;
            S_WAIT_DATA:
                if (i_data_valid == 1'b1 && ~w_fifo_full)
                    next_state <= S_SEND_ROW;
                else
                    next_state <= S_WAIT_DATA;
            S_SEND_ROW:
                if (r_shift_cnt == LEN_row_data && ~w_fifo_full)
                    if (r_row_cnt < N_ROW)
                        next_state <= S_SET_ROW;
                    else
                        next_state <= S_SEND_SUM_CHECK;
                else
                    next_state <= S_SEND_ROW;
            S_SEND_SUM_CHECK:
                if (r_shift_cnt == LEN_send_sum_check && ~w_fifo_full)
                    next_state <= S_SEND_HEAD;
                else
                    next_state <= S_SEND_SUM_CHECK;
            default:
                next_state <= S_IDLE;
        endcase
    end

    always@(posedge clk or negedge rst_n)
    begin
        if(rst_n == 1'b0)
        begin
            r_clk_cnt <= 1'b0;
            r_row_cnt <= 1'b0;
            r_shift_cnt <= 1'b0;
            r_matrix_valid <= 1'b0;
            r_adc_data <= 1'b0;
            r_data_to_fifo <= 1'b0;
            r_data_to_fifo_valid <= 1'b0;
            o_start_row <= 1'b0;
            o_switch_row <= 1'b0;
            send_sum_check <= 1'b0;
        end
        else
        case(state)
            S_IDLE:
            begin
            end
            S_SEND_HEAD:
            begin
                if (~w_fifo_full)
                begin
                    if (r_shift_cnt < LEN_send_head)
                    begin
                        r_data_to_fifo <= send_head[(8 * (LEN_send_head - r_shift_cnt) - 1)-:8];
                        send_sum_check <= send_sum_check + send_head[(8 * (LEN_send_head - r_shift_cnt) - 1)-:8];
                        r_shift_cnt <= r_shift_cnt + 1'b1;
                        r_data_to_fifo_valid <= 1'b1;
                    end
                    else
                    begin
                        r_shift_cnt <= 1'b0;
                        r_data_to_fifo_valid <= 1'b0;
                    end
                end
                if (r_clk_cnt < WAIT_TIME_row)
                begin
                    r_clk_cnt <= r_clk_cnt + 1'b1;
                end
            end
            S_SEND_FUNC:
            begin
                if (~w_fifo_full)
                begin
                    if (r_shift_cnt < LEN_send_func)
                    begin
                        r_data_to_fifo <= send_func[(8 * (LEN_send_func - r_shift_cnt) - 1)-:8];
                        send_sum_check <= send_sum_check + send_func[(8 * (LEN_send_func - r_shift_cnt) - 1)-:8];
                        r_shift_cnt <= r_shift_cnt + 1'b1;
                        r_data_to_fifo_valid <= 1'b1;
                    end
                    else
                    begin
                        r_shift_cnt <= 1'b0;
                        r_data_to_fifo_valid <= 1'b0;
                    end
                end
                if (r_clk_cnt < WAIT_TIME_row)
                begin
                    r_clk_cnt <= r_clk_cnt + 1'b1;
                end
            end
            S_SEND_DATA_LEN:
            begin
                if (~w_fifo_full)
                begin
                    if (r_shift_cnt < LEN_send_data_len)
                    begin
                        r_data_to_fifo <= send_data_len[(8 * (LEN_send_data_len - r_shift_cnt) - 1)-:8];
                        send_sum_check <= send_sum_check + send_data_len[(8 * (LEN_send_data_len - r_shift_cnt) - 1)-:8];
                        r_shift_cnt <= r_shift_cnt + 1'b1;
                        r_data_to_fifo_valid <= 1'b1;
                    end
                    else
                    begin
                        r_shift_cnt <= 1'b0;
                        r_data_to_fifo_valid <= 1'b0;
                    end
                end
                if (r_clk_cnt < WAIT_TIME_row)
                begin
                    r_clk_cnt <= r_clk_cnt + 1'b1;
                end
            end
            S_SEND_PKT_NUM:
            begin
                if (~w_fifo_full)
                begin
                    if (r_shift_cnt < LEN_send_pkt_num)
                    begin
                        r_data_to_fifo <= send_pkt_num[(8 * (LEN_send_pkt_num - r_shift_cnt) - 1)-:8];
                        send_sum_check <= send_sum_check + send_pkt_num[(8 * (LEN_send_pkt_num - r_shift_cnt) - 1)-:8];
                        r_shift_cnt <= r_shift_cnt + 1'b1;
                        r_data_to_fifo_valid <= 1'b1;
                    end
                    else
                    begin
                        r_shift_cnt <= 1'b0;
                        r_data_to_fifo_valid <= 1'b0;
                    end
                end
                if (r_clk_cnt < WAIT_TIME_row)
                begin
                    r_clk_cnt <= r_clk_cnt + 1'b1;
                end
            end
            S_SEND_TIME:
            begin
                if (~w_fifo_full)
                begin
                    if (r_shift_cnt < LEN_send_time)
                    begin
                        r_data_to_fifo <= send_time[(8 * (LEN_send_time - r_shift_cnt) - 1)-:8];
                        send_sum_check <= send_sum_check + send_time[(8 * (LEN_send_time - r_shift_cnt) - 1)-:8];
                        r_shift_cnt <= r_shift_cnt + 1'b1;
                        r_data_to_fifo_valid <= 1'b1;
                    end
                    else
                    begin
                        r_shift_cnt <= 1'b0;
                        r_data_to_fifo_valid <= 1'b0;
                    end
                end
                if (r_clk_cnt < WAIT_TIME_row)
                begin
                    r_clk_cnt <= r_clk_cnt + 1'b1;
                end
            end
            S_SEND_ACCURACY:
            begin
                if (~w_fifo_full)
                begin
                    if (r_shift_cnt < LEN_send_accuracy)
                    begin
                        r_data_to_fifo <= send_accuracy[(8 * (LEN_send_accuracy - r_shift_cnt) - 1)-: 8];
                        send_sum_check <= send_sum_check + send_accuracy[(8 * (LEN_send_accuracy - r_shift_cnt) - 1)-: 8];
                        r_shift_cnt <= r_shift_cnt + 1'b1;
                        r_data_to_fifo <= 1'b1;
                    end
                    else
                    begin
                        r_shift_cnt <= 1'b0;
                        r_data_to_fifo_valid <= 1'b0;
                    end
                end
                if (r_clk_cnt < WAIT_TIME_row)
                begin
                    r_clk_cnt <= r_clk_cnt + 1'b1;
                end
            end
            S_SEND_RESERVED:
            begin
                if (~w_fifo_full)
                begin
                    if (r_shift_cnt < LEN_send_reserved)
                    begin
                        r_data_to_fifo <= send_reserved[(8 * (LEN_send_accuracy - r_shift_cnt) - 1)-: 8];
                        // send_sum_check <= send_sum_check + send_accuracy[(8 * (LEN_send_accuracy - r_shift_cnt) - 1)-: 8];
                        r_shift_cnt <= r_shift_cnt + 1'b1;
                        r_data_to_fifo <= 1'b1;
                    end
                    else
                    begin
                        r_shift_cnt <= 1'b0;
                        r_data_to_fifo_valid <= 1'b0;
                    end
                end
                if (r_clk_cnt < WAIT_TIME_row)
                begin
                    r_clk_cnt <= r_clk_cnt + 1'b1;
                end
            end
            S_SET_ROW:
            begin
                if (r_clk_cnt == WAIT_TIME_row)
                begin
                    r_clk_cnt <= 1'b0;
                    r_row_cnt <= r_row_cnt + 1'b1;
                    o_start_row <= 1'b1;
                end
                else
                begin
                    r_clk_cnt <= r_clk_cnt + 1'b1;
                end
            end
            S_WAIT_DATA:
            begin
                if (~w_fifo_full)
                begin
                    if (i_data_valid == 1'b1)
                    begin
                        o_switch_row <= 1'b1;
                        r_adc_data <= i_adc_data;
                    end
                end
                if (o_start_row == 1'b1)
                begin
                    o_start_row <= 1'b0;
                end
                if (r_clk_cnt < WAIT_TIME_row)
                begin
                    r_clk_cnt <= r_clk_cnt + 1'b1;
                end
            end
            S_SEND_ROW:
            begin
                if (o_switch_row == 1'b1)
                begin
                    o_switch_row <= 1'b0;
                end
                if (~w_fifo_full)
                begin
                    if (r_shift_cnt < LEN_row_data)
                    begin
                        r_data_to_fifo <= r_adc_data[(8 * (LEN_row_data - r_shift_cnt) - 1)-:8];
                        send_sum_check <= send_sum_check + r_adc_data[(8 * (LEN_row_data - r_shift_cnt) - 1)-:8];
                        r_shift_cnt <= r_shift_cnt + 1'b1;
                        r_data_to_fifo_valid <= 1'b1;
                    end
                    else
                    begin
                        r_shift_cnt <= 1'b0;
                        r_data_to_fifo_valid <= 1'b0;
                        if (r_row_cnt == N_ROW)
                        begin
                            r_row_cnt <= 1'b0;
                            r_matrix_valid <= 1'b1;
                        end
                    end
                end
                if (r_clk_cnt < WAIT_TIME_row)
                begin
                    r_clk_cnt <= r_clk_cnt + 1'b1;
                end
            end
            S_SEND_SUM_CHECK:
            begin
                if (~w_fifo_full)
                begin
                    if (r_shift_cnt < LEN_send_sum_check)
                    begin
                        r_data_to_fifo <= send_sum_check[(8 * (LEN_send_sum_check - r_shift_cnt) - 1)-:8];
                        r_shift_cnt <= r_shift_cnt + 1'b1;
                        r_data_to_fifo_valid <= 1'b1;
                    end
                    else
                    begin
                        send_sum_check <= 1'b0;
                        r_shift_cnt <= 1'b0;
                        r_data_to_fifo_valid <= 1'b0;
                    end
                end
                if (r_matrix_valid == 1'b1)
                begin
                    r_matrix_valid <= 1'b0;
                end
                if (r_clk_cnt < WAIT_TIME_row)
                begin
                    r_clk_cnt <= r_clk_cnt + 1'b1;
                end
            end
            default:
            begin
            end
        endcase
    end
    // FSM end

//-------------------------------------
    // Data Format
    cal_pkt_num#
    (
        .LEN_send_pkt_num(LEN_send_pkt_num)
    ) cal_pkt_num_inst
    (
        .clk                        (clk                      ),
        .rst_n                      (rst_n                    ),
        .i_matrix_valid             (r_matrix_valid           ),
        .o_pkt_num                  (send_pkt_num             )
    );
    
    cal_time#
    (
        .LEN_send_time(LEN_send_time),
        .CLK_FRE(CLK_FRE)
    ) cal_time_inst
    (
        .clk                        (clk                      ),
        .rst_n                      (rst_n                    ),
        .o_time                     (send_time                )
    );

    fifo_generator_3 fifo_generator_3_inst ( //同步FIFO
        .clk                        (clk                      ),      // input wire clk
        .srst                       (~rst_n                   ),    // input wire srst
        .din                        (r_data_to_fifo           ),      // input wire [7 : 0] din
        .wr_en                      (w_fifo_wr_en             ),  // input wire wr_en
        .rd_en                      (w_fifo_rd_en             ),  // input wire rd_en
        .dout                       (w_uart_tx_data           ),    // output wire [7 : 0] dout
        .full                       (w_fifo_full              ),    // output wire full
        .empty                      (w_fifo_empty             )  // output wire empty
    );

    uart_tx#
    (
        .CLK_FRE(CLK_FRE),
        .BAUD_RATE(921600)
    ) uart_tx_inst
    (
        .clk                        (clk                      ),
        .rst_n                      (rst_n                    ),
        .tx_data                    (w_uart_tx_data           ),
        .tx_data_valid              (r_uart_tx_data_valid     ),
        .tx_data_ready              (w_uart_tx_data_ready     ),
        .tx_pin                     (o_uart_tx                )
    );

endmodule

