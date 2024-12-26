`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/05/18 21:26:46
// Design Name: 
// Module Name: parse
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

// Bug : data_reg的存储在最后一位遇见了问题
// 原因是USB会在校验位之后追加许多为0的数据
// 导致在state = 14的时候，data_reg被

module parse(
    input         [ 0: 0] clk,
    input         [ 0: 0] rstn,
    input         [ 7: 0] i_data,

    input        [ 0: 0] i_ready,            // 握手有效信号
    output logic [ 7: 0] w_pkg_num,          // 包号
    output logic [ 0: 0] w_valid,            // 有效信号
    output logic [15: 0] w_instru_type,      // 指令类型
    output logic [127:0] w_data,             // 额外信息
    output logic [15: 0] w_length            // 额外信息长度

    ,output logic [ 3: 0] state
);

    parameter [31: 0] pac_head = 32'h13_57_9A_CE;
    // logic [ 3: 0] state;
    logic [ 3: 0] next_state;
    logic [15: 0] length;
    logic [ 7: 0] check_digit;
    logic [ 7: 0] data_reg;

    logic [15: 0] static_data_len = 16'd10;


    // check_digit
    always @(posedge clk, negedge rstn) begin
        if(!rstn) begin
            check_digit <= 0;
        end
        else if (state == 4'd15 || state == 4'd1) begin
            check_digit <= 0;
        end
        else begin
            check_digit <= check_digit + i_data;
        end
    end

    // w_length & length & w_data
    always @(posedge clk, negedge rstn) begin
        if( !rstn ) begin
            length <= 16'b0;
            w_length <= 16'b0;
            w_data <= 128'b0;
        end
        else begin
            if(state == 4'd8) begin
                length   <= {length[ 7: 0], i_data};   
                w_length <= {length[ 7: 0], i_data};   
            end
            else if(state == 4'd9) begin
                length   <= {length[ 7: 0], i_data} - static_data_len;   
                w_length <= {length[ 7: 0], i_data} - static_data_len;  
            end
            else if(state == 13 && length != 0) begin
                length <= length - 1;
                w_data <= {w_data[119:0], i_data};
            end
        end
    end
    // pkg_num
    always @(posedge clk, negedge rstn) begin
        if( !rstn ) begin
            w_pkg_num <= 8'b0;
        end
        else begin
            if(state == 4'd10) begin
                w_pkg_num <= i_data;
            end
        end
    end


    // w_valid
    always @(posedge clk, negedge rstn) begin
        if( !rstn ) begin
            w_valid <= 1'b0;
        end
        else if(w_valid == 0) begin
            if(state == 4'd15) begin
                w_valid <= 1'b1;
            end
            else begin
                w_valid <= 1'b0;
            end
        end
        else begin
            if(i_ready == 1'b1) begin
                w_valid <= 1'b0;
            end
        end
    end

    // w_instru_type
    always @(posedge clk, negedge rstn) begin
        if( !rstn ) begin
            w_instru_type <= 16'b0;
        end
        else begin
            if(state == 4'd11 || state == 4'd12) begin
                w_instru_type <= {w_instru_type[ 7: 0] , i_data};
            end
        end
    end






    always @(posedge clk, negedge rstn) begin
        if( !rstn ) begin
            data_reg <= 8'b0;
        end
        else begin
            data_reg <= i_data;
        end
    end

    // FSM state

    always @(posedge clk, negedge rstn) begin
        if( ! rstn ) begin
            state <= 4'd0;
        end
        else begin
            state <= next_state;
        end
    end

    always @(*) begin
        case (state)
            // 4'd0: begin
            //     if(i_data == pac_head[63:56]) begin
            //         next_state = 4'd1;
            //     end
            //     else begin
            //         next_state = 4'd0;
            //     end
            // end
                
            // 4'd1: begin
            //     if(i_data == pac_head[55:48]) begin
            //         next_state = 4'd2;
            //     end
            //     else begin
            //         next_state = 4'd0;
            //     end
            // end

            // 4'd2: begin
            //     if(i_data == pac_head[47:40]) begin
            //         next_state = 4'd3;
            //     end
            //     else begin
            //         next_state = 4'd0;
            //     end
            // end

            // 4'd3: begin
            //     if(i_data == pac_head[39:32]) begin
            //         next_state = 4'd4;
            //     end
            //     else begin
            //         next_state = 4'd0;
            //     end
            // end
    
            4'd0: begin
                if(i_data == pac_head[31:24]) begin
                    next_state = 4'd5;
                end
                else begin
                    next_state = 4'd0;
                end
            end
    
            4'd5: begin
                if(i_data == pac_head[23:16]) begin
                    next_state = 4'd6;
                end
                else begin
                    next_state = 4'd0;
                end
            end
    
            4'd6: begin
                if(i_data == pac_head[15: 8]) begin
                    next_state = 4'd7;
                end
                else begin
                    next_state = 4'd0;
                end
            end
    
            4'd7: begin
                if(i_data == pac_head[ 7: 0]) begin
                    next_state = 4'd8;
                end
                else begin
                    next_state = 4'd0;
                end
            end
    
            4'd8: begin
                next_state = 4'd9;
            end
    
            4'd9: begin
                next_state = 4'd10;
            end
    
            4'd10: begin
                next_state = 4'd11;
                // 包号
            end
    
            4'd11: begin
                next_state = 4'd12;
                // 指令码1
            end
    
            4'd12: begin
                next_state = 4'd13;
                // 指令码2
            end
    
            4'd13: begin
                if(length == 0) begin
                    next_state = 4'd14;
                end
                else begin
                    next_state = 4'd13;
                end
            end
    
            4'd14: begin
                if(check_digit == (data_reg << 1)) begin
                    // 校验字审核通过
                    // length = 0 必定延后一个周期
                    next_state = 4'd15;
                end
                else begin
                    // 校验字审核不通过
                    next_state = 4'd1;
                end
            end
    
            4'd15: begin
                // Success
                next_state = 4'd0;
            end

            4'd1: begin
                // Failed
                next_state = 4'd0;
            end
            default: begin
                next_state = 4'd0;
            end
        endcase

    end



endmodule