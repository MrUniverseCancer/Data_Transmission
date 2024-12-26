/////////////////////////////////////////////////////////////////////////////
//特权同学 精心打造 Xilinx FPGA开发板系列
//工程硬件平台： Xilinx Artex7 FPGA 
//开发套件型号： SF-AT7 特权打造
//版   权  申   明： 本例程由《深入浅出玩转FPGA》作者“特权同学”原创，
//				仅供SF-AT7开发套件学习使用，谢谢支持
//官方淘宝店铺： http://myfpga.taobao.com/
//最新资料下载： http://pan.baidu.com/s/1c2iTPra
//公                司： 上海或与电子科技有限公司
/////////////////////////////////////////////////////////////////////////////
//LED闪烁逻辑产生模块
module led_controller(
				//时钟和复位接口
			input clk,		//25MHz输入时钟	
			input rst_n,	//低电平系统复位信号输入	
				//LED指示灯接口
			output led		//用于测试的LED指示灯
		);
		
////////////////////////////////////////////////////		
//计数产生LED闪烁频率	
reg[23:0] cnt;

always @(posedge clk or negedge rst_n)
	if(!rst_n) cnt <= 24'd0;
	else cnt <= cnt+1'b1;

assign led = cnt[23];	
	

endmodule

