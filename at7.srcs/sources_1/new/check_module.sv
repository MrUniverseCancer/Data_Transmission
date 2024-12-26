`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/03 18:14:21
// Design Name: 
// Module Name: check_module
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


module check_module(
    input                clk,
    input                rstn,
    input [ 7: 0]        data_in,
    input [ 0: 0]        data_valid,

    output logic [ 0: 0] happen
    );

    logic [7:0] reg_1;
    logic [7:0] reg_2;
    always @(posedge clk) begin
        if(!rstn) begin
            reg_1 <= 8'b0;
            reg_2 <= 8'b0;
        end 
        else if(data_valid) begin
            reg_1 <= data_in;
            reg_2 <= reg_1;
        end
    end

    wire [7:0] temp_1 = reg_1;
    wire [7:0] temp_2 = reg_2 + 1;


    always @(*) begin
        happen = 1'b1;
        if(temp_1 == temp_2) begin
            happen = 1'b0;
        end
        else begin
            case (reg_2)
                8'h68:
                    if(reg_1 == 8'h01) begin
                        happen = 1'b0;
                    end
                default :
                    happen = 1'b1;
            endcase
        end
    end
    // assign happen = (temp_1 != temp_2);

endmodule
