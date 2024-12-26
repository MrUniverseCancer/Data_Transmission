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
	
reg sys_clk_i;	//50MHzʱ���ź�
reg ext_rst_n;	//��λ�źţ��͵�ƽ��Ч
wire[7:0] led;	//8��LEDָʾ�ƽӿ�		
	
at7		uut_at7(
			.sys_clk_i(sys_clk_i),	//�ⲿ����50MHzʱ���ź�
			.ext_rst_n(ext_rst_n),	//�ⲿ���븴λ�źţ��͵�ƽ��Ч
			.led(led)		//8��LEDָʾ�ƽӿ�	
		);			
	
initial begin
	sys_clk_i = 0;
	ext_rst_n = 0;	//��λ��
	#1000;
	@(posedge sys_clk_i); #2;
	ext_rst_n = 1;	//��λ��������������
	#500_000_000;
	$finish;
end	
	
always #10 sys_clk_i = ~sys_clk_i;	//50MHzʱ�Ӳ���
	
endmodule
