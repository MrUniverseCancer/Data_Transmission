`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/03/29 16:51:33
// Design Name: 
// Module Name: sim_at7
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

`timescale 1ns/1ps
module sim_at7();
	
reg sys_clk_i;	//50MHz时钟信号
reg ext_rst_n;	//复位信号，低电平有效
wire[7:0] led;	//8个LED指示灯接口		
	
at7		uut_at7(
			.sys_clk_i(sys_clk_i),	//外部输入50MHz时钟信号
			.ext_rst_n(ext_rst_n),	//外部输入复位信号，低电平有效
			.led(led)		//8个LED指示灯接口	
		);			
	
initial begin
	sys_clk_i = 0;
	ext_rst_n = 0;	//复位中
	#1000;
	@(posedge sys_clk_i); #2;
	ext_rst_n = 1;	//复位结束，正常工作
	#500_000_000;
	$finish;
end	
	
always #10 sys_clk_i = ~sys_clk_i;	//50MHz时钟产生
	
endmodule
