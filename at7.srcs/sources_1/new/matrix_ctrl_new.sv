`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/17 16:42:32
// Design Name: 
// Module Name: matrix_ctrl_new
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


module matrix_ctrl_new
    #(
        parameter ADC_NUM           = 1,
        parameter SERIAL_NUM        = 1,
        parameter ACCURACY          = 1,
        parameter N_ROW             = 4,
        parameter N_COL             = 8,
        parameter CLK_FRE           = 50, //MHz
        parameter DATA_RATE         = 100, //Hz
        parameter BITMASK           = 10'b11_1111_1111
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

    // Data Format: {SEND_HEAD4, SEND_ALL_LEN2, SEND_SERIALNUM1, SEND_DATA_LEN4, send_pkt_num4, send_time4,send_accuracy, reserved ,matrix_data(3*N_ROW*N_COL), send_sum_check1}
    localparam  LEN_send_head           = 4;  // 32
    localparam  LEN_send_all_len        = 2;  // 16
    localparam  LEN_send_serialNum      = 1;  // 8
    localparam  LEN_send_data_len       = 4;  // 32,Made up of rows and columns
    localparam  LEN_send_pkt_num        = 4;  // 32
    localparam  LEN_send_time           = 4;  // 32
    localparam  LEN_send_accuracy       = 1;  // 8
    localparam  LEN_send_reserved       = 4;  // 32
    localparam  LEN_row_data            = 24 * ADC_NUM;  // 192 * ADC_NUM
    localparam  LEN_send_sum_check      = 1;  // 8


    wire [8 * LEN_send_head - 1: 0]         send_head;
    wire [8 * LEN_send_all_len - 1: 0]      send_all_len;
    wire [8 * LEN_send_serialNum - 1: 0]    send_serialNum;
    wire [8 * LEN_send_data_len - 1: 0]     send_data_len;
    wire [8 * LEN_send_pkt_num - 1: 0]      send_pkt_num;
    wire [8 * LEN_send_time - 1: 0]         send_time;
    wire [8 * LEN_send_accuracy - 1: 0]     send_accuracy;
    wire [8 * LEN_send_reserved - 1: 0]     send_reserved;
    wire [8 * LEN_row_data - 1: 0]          send_row_data;
    reg  [8 * LEN_send_sum_check - 1: 0]    send_sum_check;

    wire [ 0: 0] head_send;
    wire [ 0: 0] all_len_send;
    wire [ 0: 0] serialNum_send;
    wire [ 0: 0] data_len_send;
    wire [ 0: 0] pkt_num_send;
    wire [ 0: 0] time_send;
    wire [ 0: 0] accuracy_send;
    wire [ 0: 0] reserved_send;
    wire [ 0: 0] row_data_send;
    wire [ 0: 0] sum_check_send;

    assign head_send        = | (BITMASK & 10'b10_0000_0000);
    assign all_len_send     = | (BITMASK & 10'b01_0000_0000);
    assign serialNum_send   = | (BITMASK & 10'b00_1000_0000);
    assign data_len_send    = | (BITMASK & 10'b00_0100_0000);
    assign pkt_num_send     = | (BITMASK & 10'b00_0010_0000);
    assign time_send        = | (BITMASK & 10'b00_0001_0000);
    assign accuracy_send    = | (BITMASK & 10'b00_0000_1000);
    assign reserved_send    = | (BITMASK & 10'b00_0000_0100);
    assign row_data_send    = | (BITMASK & 10'b00_0000_0010);
    assign sum_check_send   = | (BITMASK & 10'b00_0000_0001);

    localparam                          WAIT_TIME_row   = CLK_FRE * 1000000 / DATA_RATE / N_ROW - 1;

    localparam                          S_IDLE              = 13'b0_0000_0000_0001;
    localparam                          S_SEND_HEAD         = 13'b0_0000_0000_0010;
    localparam                          S_SEND_ALL_LEN      = 13'b0_0000_0000_0100;
    localparam                          S_SEND_SERAILNUM    = 13'b0_0000_0000_1000;
    localparam                          S_SEND_DATA_LEN     = 13'b0_0000_0001_0000;
    localparam                          S_SEND_PKT_NUM      = 13'b0_0000_0010_0000;
    localparam                          S_SEND_TIME         = 13'b0_0000_0100_0000;
    localparam                          S_SEND_ACCURACY     = 13'b0_0000_1000_0000;
    localparam                          S_SEND_RESERVED     = 13'b0_0001_0000_0000;
    localparam                          S_SET_ROW           = 13'b0_0010_0000_0000;
    localparam                          S_WAIT_DATA         = 13'b0_0100_0000_0000;
    localparam                          S_SEND_ROW          = 13'b0_1000_0000_0000;
    localparam                          S_SEND_SUM_CHECK    = 13'b1_0000_0000_0000;

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

    reg  [12:0]                           state;
    reg  [12:0]                           next_state;

    // Data Format
    assign send_head        = 32'h13_57_9A_CE;
    // assign send_all_len     = LEN_send_head & {32{head_send}}           + LEN_send_all_len & {32{all_len_send}} + 
    //                           LEN_send_serialNum & {32{serialNum_send}} + LEN_send_data_len  & {32{data_len_send}}+ 
    //                           LEN_send_pkt_num & {32{pkt_num_send}}     + LEN_send_time & {32{time_send}} + 
    //                           LEN_send_accuracy & {32{accuracy_send}}   + LEN_send_reserved  & {32{reserved_send}}+
    //                           LEN_send_sum_check & {32{sum_check_send}} + (LEN_row_data & {32{row_data_send}}) << 2;
    wire [31: 0] len_1  = LEN_send_head & {32{head_send}}           ;
    wire [31: 0] len_2  = LEN_send_serialNum & {32{serialNum_send}} ;
    wire [31: 0] len_3  = LEN_send_pkt_num & {32{pkt_num_send}}     ;
    wire [31: 0] len_4  = LEN_send_accuracy & {32{accuracy_send}}   ;
    wire [31: 0] len_5  = LEN_send_sum_check & {32{sum_check_send}} ;
    wire [31: 0] len_6  = LEN_send_all_len & {32{all_len_send}}     ;
    wire [31: 0] len_7  = LEN_send_data_len  & {32{data_len_send}}  ;
    wire [31: 0] len_8  = LEN_send_time & {32{time_send}}           ;
    wire [31: 0] len_9  = LEN_send_reserved  & {32{reserved_send}}  ;
    wire [31: 0] len_a  = (LEN_row_data & {32{row_data_send}}) << 2 ;
    assign send_all_len = len_1 + len_2 + len_3 + len_4 + len_5 + len_6 + len_7 + len_8 + len_9 + len_a;
    // 莫名其妙的Bugs，拆开就正常输出，写在一起就报错

    assign send_serialNum   = SERIAL_NUM;
    // assign send_data_len    = 3 * N_ROW * N_COL;
    wire [15: 0] temp_row   = N_ROW;
    wire [15: 0] temp_col   = N_COL;
    assign send_data_len    = {temp_row,temp_col};
    assign send_accuracy    = (ACCURACY == 1) ? 8'h96 : 8'h69;
    assign send_reserved    = 32'h0000_0000;

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
                    next_state = S_SEND_HEAD;
                else
                    next_state = S_IDLE;
            S_SEND_HEAD:
                if (r_shift_cnt == LEN_send_head && ~w_fifo_full || ~head_send)
                    next_state = S_SEND_ALL_LEN;
                else
                    next_state = S_SEND_HEAD;
            S_SEND_ALL_LEN:
                if (r_shift_cnt == LEN_send_all_len && ~w_fifo_full || ~all_len_send)
                    next_state = S_SEND_SERAILNUM;
                else 
                    next_state = S_SEND_ALL_LEN;
            S_SEND_SERAILNUM:
                if (r_shift_cnt == LEN_send_serialNum && ~w_fifo_full || ~serialNum_send)
                    next_state = S_SEND_DATA_LEN;
                else
                    next_state = S_SEND_SERAILNUM;
            S_SEND_DATA_LEN:
                if (r_shift_cnt == LEN_send_data_len && ~w_fifo_full || ~data_len_send)
                    next_state = S_SEND_PKT_NUM;
                else
                    next_state = S_SEND_DATA_LEN;
            S_SEND_PKT_NUM:
                if (r_shift_cnt == LEN_send_pkt_num && ~w_fifo_full || ~pkt_num_send)
                    next_state = S_SEND_TIME;
                else
                    next_state = S_SEND_PKT_NUM;
            S_SEND_TIME:
                if (r_shift_cnt == LEN_send_time && ~w_fifo_full || ~time_send)
                    next_state = S_SEND_ACCURACY;
                else
                    next_state = S_SEND_TIME;
            S_SEND_ACCURACY:
                if (r_shift_cnt == LEN_send_accuracy && ~w_fifo_full || ~accuracy_send)
                    next_state = S_SEND_RESERVED;
                else
                    next_state = S_SEND_ACCURACY;
            S_SEND_RESERVED:
                if (r_shift_cnt == LEN_send_reserved && ~w_fifo_full || ~reserved_send)
                    next_state = S_SET_ROW;
                else
                    next_state = S_SEND_RESERVED;
            S_SET_ROW:
                if (r_clk_cnt == WAIT_TIME_row)
                    next_state = S_WAIT_DATA;
                else
                    next_state = S_SET_ROW;
            S_WAIT_DATA:
                if (i_data_valid == 1'b1 && ~w_fifo_full)
                    next_state = S_SEND_ROW;
                else
                    next_state = S_WAIT_DATA;
            S_SEND_ROW:
                if (r_shift_cnt == LEN_row_data && ~w_fifo_full)
                    if (r_row_cnt < N_ROW)
                        next_state = S_SET_ROW;
                    else
                        next_state = S_SEND_SUM_CHECK;
                else
                    next_state = S_SEND_ROW;
            S_SEND_SUM_CHECK:
                if (r_shift_cnt == LEN_send_sum_check && ~w_fifo_full || ~sum_check_send)
                    // next_state = S_SEND_HEAD;
                    next_state = S_IDLE;
                else
                    next_state = S_SEND_SUM_CHECK;
            default:
                next_state = S_IDLE;
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
                if (~w_fifo_full & head_send)
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
            S_SEND_ALL_LEN:
            begin
                if(~w_fifo_full & all_len_send)
                begin
                    if (r_shift_cnt < LEN_send_all_len)
                    begin
                        r_data_to_fifo <= send_all_len[(8 * (LEN_send_all_len - r_shift_cnt) - 1)-:8];
                        send_sum_check <= send_sum_check + send_all_len[(8 * (LEN_send_all_len - r_shift_cnt) - 1)-:8];
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
            S_SEND_SERAILNUM:
            begin
                if (~w_fifo_full & serialNum_send)
                begin
                    if (r_shift_cnt < LEN_send_serialNum)
                    begin
                        r_data_to_fifo <= send_serialNum[(8 * (LEN_send_serialNum - r_shift_cnt) - 1)-:8];
                        send_sum_check <= send_sum_check + send_serialNum[(8 * (LEN_send_serialNum - r_shift_cnt) - 1)-:8];
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
                if (~w_fifo_full & data_len_send)
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
                if (~w_fifo_full & pkt_num_send)
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
                if (~w_fifo_full & time_send)
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
                if (~w_fifo_full & accuracy_send)
                begin
                    if (r_shift_cnt < LEN_send_accuracy)
                    begin
                        r_data_to_fifo <= send_accuracy[(8 * (LEN_send_accuracy - r_shift_cnt) - 1)-: 8];
                        send_sum_check <= send_sum_check + send_accuracy[(8 * (LEN_send_accuracy - r_shift_cnt) - 1)-: 8];
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
            S_SEND_RESERVED:
            begin
                if (~w_fifo_full & reserved_send)
                begin
                    if (r_shift_cnt < LEN_send_reserved)
                    begin
                        r_data_to_fifo <= send_reserved[(8 * (LEN_send_reserved - r_shift_cnt) - 1)-: 8];
                        // send_sum_check <= send_sum_check + send_accuracy[(8 * (LEN_send_accuracy - r_shift_cnt) - 1)-: 8];
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
                if (~w_fifo_full & sum_check_send)
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

