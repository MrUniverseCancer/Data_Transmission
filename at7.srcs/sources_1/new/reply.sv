`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/10/09 16:23:22
// Design Name: 
// Module Name: reply
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


 module reply #(
   parameter CLK_FRE           = 50, //MHz
   parameter BITMASK           = 10'b11_1111_1111
)(
   input [ 0: 0] clk,
   input [ 0: 0] rstn,

   input [ 0: 0] i_reply_begin,
   input [ 7: 0] i_pkg_num,
   input [ 2: 0] state_before,
   input [ 2: 0] state_after,
   input [ 5: 0] command_to_reply,

   output logic [ 0: 0] reply_OK,
   output logic [ 0: 0] o_return_data_valid,
   output logic [ 7: 0] o_return_data,
   input        [ 0: 0] i_fifo_full, // FIFO已满
   input        [ 0: 0] i_matrix_has_stop // 矩阵数据传输停止，允许返回帧开始\

   ,output logic [ 7: 0] state

);
   logic [ 7: 0] r_data_to_fifo;
   logic [ 0: 0] r_data_to_fifo_valid;
   assign o_return_data_valid = r_data_to_fifo_valid;
   assign o_return_data = r_data_to_fifo;



   logic [ 0: 0] i_valid;
   logic [ 7: 0] extra_data;
   logic [ 0: 0] extra_valid;
   logic [ 0: 0] extra_finish;


   /*
   Head      8
   all_len   2
   pkg_num   1
   state_num 1
   extra     undifined
   sum_check 1
   */

   localparam  LEN_send_head           = 4;  // 32
   localparam  LEN_send_all_len        = 2;  // 16
   localparam  LEN_send_pkt_num        = 1;  // 8
   localparam  LEN_send_state_num      = 1;  // 8
   localparam  LEN_send_sum_check      = 1;  // 8
   // localparam  LEN_send_reserved       = 4;  // 32
   logic [15: 0] extra_len;

   logic [8 * LEN_send_head - 1: 0]      send_head;
   logic [8 * LEN_send_all_len - 1: 0]   send_all_len;
   logic [8 * LEN_send_pkt_num - 1: 0]   send_pkt_num;
   logic [8 * LEN_send_state_num - 1: 0] send_state_num;
   // logic [8 * LEN_send_reserved - 1: 0]  send_reserved;
   logic [8 * LEN_send_sum_check - 1: 0] send_sum_check;


   assign send_head = 32'h24_68_AC_E0;
   // assign send_all_len = 16'h00_0A;
   assign send_pkt_num = i_pkg_num;
   Reply_state_extra  Reply_state_extra_inst (
      .clk(clk),
      .rstn(rstn),
      .i_command_to_reply(command_to_reply),
      .i_state_before(state_before),
      .i_state_after(state_after),
      .i_valid(i_valid),
      .extra_len(extra_len),
      .extra_data(extra_data),
      .extra_valid(extra_valid),
      .state_num(send_state_num),
      .extra_finish(extra_finish)
   );
   assign send_all_len = LEN_send_head + LEN_send_all_len + LEN_send_pkt_num + 
                         LEN_send_state_num + extra_len + LEN_send_sum_check; 
                         
   localparam                          S_IDLE              = 8'b0000_0001;
   localparam                          S_SEND_HEAD         = 8'b0000_0010;
   localparam                          S_SEND_ALL_LEN      = 8'b0000_0100;
   localparam                          S_SEND_PKT_NUM      = 8'b0000_1000;
   localparam                          S_SEND_STATE_NUM    = 8'b0001_0000;
   localparam                          S_SEND_EXTRA        = 8'b0010_0000;
   localparam                          S_SEND_SUM_CHECK    = 8'b0100_0000;
   localparam                          S_WAIT              = 8'b1000_0000; 
   // 实验发现，结束后如果不等待一个时钟，会导致发送两次。本质上是Reply_OK信号发送后，在下一个时钟周期exe才会进入下一个状态，所以需要等待一个时钟周期错过这个开始指令
   // 由于我的Reply_OK是于IDLE等状态的，所以不能够使用!Reply_OK去区分exe_finish，否则Reply永远不能够开始
   
   // 状态寄存器
   // logic [6:0] state;
   logic [7:0] next_state;

   // 计时器
   logic [ 4: 0] r_shift_cnt;

   // 状态转移
   always @(posedge clk ) begin
      if (!rstn) 
         state <= S_IDLE;
      else 
         state <= next_state;
   end

   always @(*) begin
      case(state)
         S_IDLE: begin
            if (i_reply_begin && ~i_fifo_full && i_matrix_has_stop)
               next_state = S_SEND_HEAD;
            else
               next_state = S_IDLE;
         end

         S_SEND_HEAD: begin
            if (r_shift_cnt == LEN_send_head && ~i_fifo_full)
               next_state = S_SEND_ALL_LEN;
            else
               next_state = S_SEND_HEAD;
         end

         S_SEND_ALL_LEN: begin
            if (r_shift_cnt == LEN_send_all_len && ~i_fifo_full)
               next_state = S_SEND_PKT_NUM;
            else
               next_state = S_SEND_ALL_LEN;
         end

         S_SEND_PKT_NUM: begin
            if (r_shift_cnt == LEN_send_pkt_num && ~i_fifo_full)
               next_state = S_SEND_STATE_NUM;
            else
               next_state = S_SEND_PKT_NUM;
         end

         S_SEND_STATE_NUM: begin
            if (r_shift_cnt == LEN_send_state_num && ~i_fifo_full)
               next_state = S_SEND_EXTRA;
            else
               next_state = S_SEND_STATE_NUM;
         end

         S_SEND_EXTRA: begin
            if (r_shift_cnt == extra_len && ~i_fifo_full)
               next_state = S_SEND_SUM_CHECK;
            else
               next_state = S_SEND_EXTRA;
         end

         S_SEND_SUM_CHECK: begin
            if (r_shift_cnt == LEN_send_sum_check && ~i_fifo_full)
               next_state = S_WAIT;
            else
               next_state = S_SEND_SUM_CHECK;
         end
         S_WAIT: begin
            next_state = S_IDLE;
         end
         default: next_state = S_IDLE;
      endcase
   end

   always @(posedge clk) begin
      if(!rstn) begin
         reply_OK <= 1'b0;
         r_shift_cnt <= 0;
         send_sum_check <= 1'b0;
         r_data_to_fifo <= 1'b0;
         r_data_to_fifo_valid <= 1'b0;
      end
      else begin
         case (state)
            S_IDLE: begin
               r_shift_cnt <= 1'b0;
               r_data_to_fifo_valid <= 1'b0;
            end 
            S_SEND_HEAD: begin
               if (~i_fifo_full) begin
                  if (r_shift_cnt < LEN_send_head) begin
                     r_data_to_fifo <= send_head[(8 * (LEN_send_head - r_shift_cnt) - 1)-:8];
                     send_sum_check <= send_sum_check + send_head[(8 * (LEN_send_head - r_shift_cnt) - 1)-:8];
                     r_shift_cnt <= r_shift_cnt + 1'b1;
                     r_data_to_fifo_valid <= 1'b1;
                  end
                  else begin
                     r_shift_cnt <= 1'b0;
                     r_data_to_fifo_valid <= 1'b0;
                  end
               end
            end

            S_SEND_ALL_LEN: begin
               if (~i_fifo_full) begin
                  if (r_shift_cnt < LEN_send_all_len) begin
                     r_data_to_fifo <= send_all_len[(8 * (LEN_send_all_len - r_shift_cnt) - 1)-:8];
                     send_sum_check <= send_sum_check + send_all_len[(8 * (LEN_send_all_len - r_shift_cnt) - 1)-:8];
                     r_shift_cnt <= r_shift_cnt + 1'b1;
                     r_data_to_fifo_valid <= 1'b1;
                  end
                  else begin
                     r_shift_cnt <= 1'b0;
                     r_data_to_fifo_valid <= 1'b0;
                  end
               end
            end

            S_SEND_PKT_NUM: begin
               if (~i_fifo_full) begin
                  if (r_shift_cnt < LEN_send_pkt_num) begin
                     r_data_to_fifo <= send_pkt_num[(8 * (LEN_send_pkt_num - r_shift_cnt) - 1)-:8];
                     send_sum_check <= send_sum_check + send_pkt_num[(8 * (LEN_send_pkt_num - r_shift_cnt) - 1)-:8];
                     r_shift_cnt <= r_shift_cnt + 1'b1;
                     r_data_to_fifo_valid <= 1'b1;
                  end
                  else begin
                     r_shift_cnt <= 1'b0;
                     r_data_to_fifo_valid <= 1'b0;
                  end
               end
            end

            S_SEND_STATE_NUM: begin
               if (~i_fifo_full) begin
                  if (r_shift_cnt < LEN_send_state_num) begin
                     r_data_to_fifo <= send_state_num[(8 * (LEN_send_state_num - r_shift_cnt) - 1)-:8];
                     send_sum_check <= send_sum_check + send_state_num[(8 * (LEN_send_state_num - r_shift_cnt) - 1)-:8];
                     r_shift_cnt <= r_shift_cnt + 1'b1;
                     r_data_to_fifo_valid <= 1'b1;
                  end
                  else begin
                     r_shift_cnt <= 1'b0;
                     r_data_to_fifo_valid <= 1'b0;
                  end
               end
            end

            S_SEND_EXTRA: begin
               if (~i_fifo_full) begin
                  if (r_shift_cnt < extra_len) begin
                     r_data_to_fifo <= extra_data;
                     send_sum_check <= send_sum_check + extra_data;
                     r_shift_cnt <= r_shift_cnt + 1'b1;
                     r_data_to_fifo_valid <= 1'b1;
                  end
                  else begin
                     r_shift_cnt <= 1'b0;
                     r_data_to_fifo_valid <= 1'b0;
                  end
               end
            end

            S_SEND_SUM_CHECK: begin
               if (~i_fifo_full) begin
                  if (r_shift_cnt < LEN_send_sum_check) begin
                     r_data_to_fifo <= send_sum_check[(8 * (LEN_send_sum_check - r_shift_cnt) - 1)-:8];
                     r_shift_cnt <= r_shift_cnt + 1'b1;
                     r_data_to_fifo_valid <= 1'b1;
                  end
                  else begin
                     reply_OK <= 1'b1;
                     send_sum_check <= 1'b0;
                     r_shift_cnt <= 1'b0;
                     r_data_to_fifo_valid <= 1'b0;
                  end
               end
            end
            default: begin
               r_shift_cnt <= 1'b0;
               r_data_to_fifo_valid <= 1'b0;
               send_sum_check <= 1'b0;
            end
         endcase
      end
   end

   // FSM END

endmodule
