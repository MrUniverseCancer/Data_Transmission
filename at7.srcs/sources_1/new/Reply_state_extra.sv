`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/10/24 19:43:53
// Design Name: 
// Module Name: Reply_state_extra
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


module Reply_state_extra(
    input [ 0: 0] clk,
    input [ 0: 0] rstn,
    input [ 5: 0] i_command_to_reply,
    input [ 2: 0] i_state_before,
    input [ 2: 0] i_state_after,
    input [ 0: 0] i_valid,

    output logic [15: 0] extra_len,
    output logic [ 7: 0] extra_data,
    output logic [ 0: 0] extra_valid,
    output logic [ 7: 0] state_num,
    output logic [ 0: 0] extra_finish
);
    // 规定state_num的构成：
    /*
        低三位留给uart_bt_usb的状态(012)，仅显示成功
        高5位留给待定
    */

    logic [ 5: 0] single_OK;
    always @(posedge clk) begin
        if(i_command_to_reply[5]) begin
            single_OK[5] <= (i_state_after[2] == 1'b1) ? 1 : 0;
        end
        else begin
            single_OK[5] <= 1;
        end
        if (i_command_to_reply[4]) begin
            single_OK[4] <= (i_state_after[2] == 1'b0) ? 1 : 0;
        end
        else begin
            single_OK[4] <= 1; 
        end
        if (i_command_to_reply[3]) begin
            single_OK[3] <= (i_state_after[1] == 1'b1) ? 1 : 0;
        end
        else begin
            single_OK[3] <= 1;
        end
        if (i_command_to_reply[2]) begin
            single_OK[2] <= (i_state_after[1] == 1'b0) ? 1 : 0;
        end
        else begin
            single_OK[2] <= 1;
        end
        if (i_command_to_reply[1]) begin
            single_OK[1] <= (i_state_after[0] == 1'b1) ? 1 : 0;
        end
        else begin
            single_OK[1] <= 1;
        end
        if (i_command_to_reply[0]) begin
            single_OK[0] <= (i_state_after[0] == 1'b0) ? 1 : 0;
        end
        else begin
            single_OK[0] <= 1;
        end
        // else begin
        //     single_OK <= 6'h00;
        // end
    end


    logic [ 0: 0] has_usb  ;
    logic [ 0: 0] has_bt   ;
    logic [ 0: 0] has_uart ;
    assign has_usb  = i_command_to_reply[5] | i_command_to_reply[4] ;
    assign has_bt   = i_command_to_reply[3] | i_command_to_reply[2] ;
    assign has_uart = i_command_to_reply[1] | i_command_to_reply[0] ;

    always @(posedge clk) begin
        if(!rstn) begin
            extra_len <= 0;
            state_num <= 0;
        end
        else begin
            if(&single_OK) begin
                extra_len <= 0;
                state_num <= {5'd0, has_usb, has_bt, has_uart};
            end
            else begin
                extra_len <= 0;
                state_num <= 0;
            end
        end
    end

    always @(posedge clk) begin
        if(!rstn) begin
            extra_data <= 8'b0;
            extra_valid <= 1'b0;
        end
        // else begin
        //     if(i_valid) begin
                
        //     end
        // end
    end
endmodule
