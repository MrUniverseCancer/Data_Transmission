`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/04/20 11:20:57
// Design Name: 
// Module Name: USB_ctrl
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
/////////////////////////////////////////////////////////////////////////////
//特权同学 精心打造 Xilinx FPGA开发板系列
//工程硬件平台： Xilinx Artex7 FPGA 
//开发套件型号： SF-AT7 特权打造
//版   权  申   明： 本例程由《深入浅出玩转FPGA》作者“特权同学”原创，
//              仅供SF-AT7开发套件学习使用，谢谢支持
//官方淘宝店铺： http://myfpga.taobao.com/
//最新资料下载： http://pan.baidu.com/s/1c2iTPra
//公                司： 上海或与电子科技有限公司
/////////////////////////////////////////////////////////////////////////////


module USB_ctrl_io(
    input clk,                  	//100MHz
    input rst_n,
    // FX3 Slave FIFO接口
    input fx3_flaga,            	//地址00时，slave fifo写入满标志位（可写）
    input fx3_flagb,            	//地址00时，slave fifo写入快满标志位，该位拉低后还可以写入6个Byte数据
    input fx3_flagc,            	//ctl[8]，地址11时，slave fifo读空标志位（可读）
    input fx3_flagd,            	//ctl[9]，地址11时，slave fifo读快空标志位，该位拉低后还可以写入6个Byte数据（该信号处上电为高电平）
    // output fx3_pclk,            //Slave FIFO同步时钟信号
    output reg fx3_slcs_n,      	//Slave FIFO片选信号，低电平有效
    output reg fx3_slwr_n,      	//Slave FIFO写使能信号，低电平有效
    output reg fx3_slrd_n,      	//Slave FIFO读使能信号，低电平有效
    output reg fx3_sloe_n,      	//Slave FIFO输出使能信号，低电平有效
    output reg fx3_pktend_n,    	//包结束信号
    output reg[1:0] fx3_a,      	//操作FIFO地址
    inout[31:0] fx3_db,         	//数据
	// send data from fifo
	input[31:0] i_data_from_fifo,	//data to send
	// Flag
	input        [ 0: 0] i_fifo_empty,
	input        [ 0: 0] i_fifo_prog_empty,    	// 256
	output logic [ 0: 0] o_fifo_rd_en,

	// receive message from usb's slave fifo
	input        [ 0: 0] i_fifo_rd_ready,
	output logic [31: 0] o_data_from_fifo,
	output logic [ 0: 0] o_data_valid,
	output logic [ 0: 0] o_waiting_false,

	output logic [3:0] state,
	output logic [9:0] factnum
);


/////////////////////////////////////////////////////////////
//FX3 FIFO同步时钟产生
//assign fx3_pclk = clk;

/////////////////////////////////////////////////////////////
//寄存器和参数定义

// parameter	WRITE_NUM	= 10'd512;
parameter	WRITE_NUM	= 10'd256;
// parameter	WRITE_NUM	= 10'd8;

reg[9:0] num;		//数据寄存器
reg[3:0] delaycnt;	//计数器
reg[3:0] fxstate;	//状态寄存器
assign state = fxstate;
assign factnum = num;
parameter	FXS_REST	= 4'd0;
parameter	FXS_IDLE	= 4'd1;
parameter	FXS_READ	= 4'd2;
parameter	FXS_RDLY	= 4'd3;
parameter	FXS_RSOP	= 4'd4;
parameter	FXS_WRIT	= 4'd5;
parameter	FXS_WSOP	= 4'd6;

reg [31:0] r_data_from_fifo; // 写数据寄存器


// wire[9:0] fifo_used;	//FIFO已经使用数据个数
// reg fifo_rdreq;			//FIFO读请求信号，高电平有效

/*
/////////////////////////////////////////////////////////////
reg fx3_dir;	//FX3读写方向指示信号，1--read, 0--write

always @(posedge clk or negedge rst_n)
	if(!rst_n) fx3_dir <= 1'b1;		//read
	else if(fxstate == FXS_RSOP) fx3_dir <= 1'b0;		//write
	else if(fxstate == FXS_WSOP) fx3_dir <= 1'b1;		//read
*/
/////////////////////////////////////////////////////////////
//定时读取FX3 FIFO数据并送入FIFO中
//定时读写操作状态机
always @(posedge clk or negedge rst_n)
	if(!rst_n) fxstate <= FXS_REST;
	else begin
		case(fxstate)
			FXS_REST: begin
				fxstate <= FXS_IDLE;
			end
			FXS_IDLE: begin
			//	if(fx3_dir && fx3_flaga) fxstate <= FXS_READ;	//读数据，读取数据个数必须是8-1024
				// if(/*!fx3_dir &&*/ fx3_flaga) fxstate <= FXS_WRIT;	//写数据
				// if(fx3_flaga && ~i_fifo_prog_empty) fxstate <= FXS_WRIT;	//写数据
				// else fxstate <= FXS_IDLE;
				if( i_fifo_rd_ready && fx3_flagc ) fxstate <= FXS_READ;	//读数据 // 应读尽读
				else if(fx3_flaga && ~i_fifo_prog_empty) fxstate <= FXS_WRIT;	//写数据
				else fxstate <= FXS_IDLE;
			end	
		  	FXS_READ: begin
				if(!fx3_flagd) fxstate <= FXS_RDLY;
				else fxstate <= FXS_READ;
			end	 
			FXS_RDLY: begin	//读取flagd拉低后的6个数据 
				if(delaycnt >= 4'd6) fxstate <= FXS_RSOP;
				else fxstate <= FXS_RDLY;				
			end
			FXS_RSOP: fxstate <= FXS_IDLE;
			FXS_WRIT: begin	
				if(num >= WRITE_NUM + 1) fxstate <= FXS_WSOP;
				else fxstate <= FXS_WRIT;
			end	
			FXS_WSOP: begin
				if(delaycnt >= 4'd4) fxstate <= FXS_IDLE;
				else fxstate <= FXS_WSOP;
			end
			default: fxstate <= FXS_IDLE;
		endcase
	end

	//数据计数器，用于产生读写时序
always @(posedge clk or negedge rst_n)
	if(!rst_n) begin
		num <= 10'd0;
	end
	else if(fxstate == FXS_READ) begin
		num <= num+1'b1;	//Slave FIFO读操作
	end
	else if(fxstate == FXS_WRIT) begin
		if (fx3_flaga) begin
			num <= num+1'b1;	//Slave FIFO写操作
		end
	end
	else begin
		num <= 10'd0;
	end
	
	//6个clock的延时计数器
always @(posedge clk or negedge rst_n)
	if(!rst_n) delaycnt <= 4'd0;
	else if(fxstate == FXS_RDLY) delaycnt <= delaycnt+1'b1;
	else if(fxstate == FXS_WSOP) delaycnt <= delaycnt+1'b1;
	else delaycnt <= 4'd0;
	
/////////////////////////////////////////////////////////////
//FX3 Slave FIFO控制信号时序产生
parameter FX3_ON	= 1'b0;
parameter FX3_OFF	= 1'b1;
	
always @(posedge clk or negedge rst_n)
	if(!rst_n) begin
		r_data_from_fifo <= 32'b0;
		fx3_slcs_n <= FX3_OFF;		//Slave FIFO片选信号，低电平有效
		fx3_slwr_n <= FX3_OFF;		//Slave FIFO写使能信号，低电平有效
		fx3_slrd_n <= FX3_OFF;		//Slave FIFO读使能信号，低电平有效
		fx3_sloe_n <= FX3_OFF;		//Slave FIFO输出使能信号，低电平有效
		fx3_pktend_n <= FX3_OFF;	//包结束信号
		fx3_a <= 2'b00;			//操作FIFO地址
	end
	else if(fxstate == FXS_IDLE) begin
		fx3_slcs_n <= FX3_OFF;		//Slave FIFO片选信号，低电平有效
		fx3_slwr_n <= FX3_OFF;		//Slave FIFO写使能信号，低电平有效
		fx3_slrd_n <= FX3_OFF;		//Slave FIFO读使能信号，低电平有效
		fx3_sloe_n <= FX3_OFF;		//Slave FIFO输出使能信号，低电平有效
		fx3_pktend_n <= FX3_OFF;	//包结束信号
		fx3_a <= 2'b00;	//写数据
		//if(fx3_dir) fx3_a <= 2'b11;	//读数据
		//else fx3_a <= 2'b00;	//写数据	
	end
  	else if(fxstate == FXS_READ) begin	//cs = 0; addr = 2'b11;rd = 0; oe=0
		fx3_slcs_n <= FX3_ON;		//Slave FIFO片选信号，低电平有效
		fx3_slwr_n <= FX3_OFF;		//Slave FIFO写使能信号，低电平有效
		fx3_slrd_n <= FX3_ON;		//Slave FIFO读使能信号，低电平有效
		fx3_sloe_n <= FX3_ON;		//Slave FIFO输出使能信号，低电平有效
		fx3_pktend_n <= FX3_OFF;	//包结束信号
		fx3_a <= 2'b11;			//FIFO读地址			
	end
	else if(fxstate == FXS_RDLY) begin
		if(delaycnt == 4'd2) begin	//rd = 1;
			fx3_slcs_n <= FX3_ON;		//Slave FIFO片选信号，低电平有效
			fx3_slwr_n <= FX3_OFF;		//Slave FIFO写使能信号，低电平有效
			fx3_slrd_n <= FX3_OFF;		//Slave FIFO读使能信号，低电平有效
			fx3_sloe_n <= FX3_ON;		//Slave FIFO输出使能信号，低电平有效
			fx3_pktend_n <= FX3_OFF;	//包结束信号
			fx3_a <= 2'b11;			//FIFO读地址			
		end
		else if(delaycnt == 4'd6) begin
			fx3_slcs_n <= FX3_OFF;		//Slave FIFO片选信号，低电平有效
			fx3_slwr_n <= FX3_OFF;		//Slave FIFO写使能信号，低电平有效
			fx3_slrd_n <= FX3_OFF;		//Slave FIFO读使能信号，低电平有效
			fx3_sloe_n <= FX3_OFF;		//Slave FIFO输出使能信号，低电平有效
			fx3_pktend_n <= FX3_OFF;	//包结束信号
			fx3_a <= 2'b11;			//操作FIFO地址
		end 
	end	
	else if(fxstate == FXS_WRIT) begin
		r_data_from_fifo <= i_data_from_fifo;
		if (fx3_flaga) begin
			if(num == 10'd1) begin	//cs = 0; addr = 2'b00;wr = 0;
				fx3_slcs_n <= FX3_ON;		//Slave FIFO片选信号，低电平有效
				fx3_slwr_n <= FX3_ON;		//Slave FIFO写使能信号，低电平有效
				fx3_slrd_n <= FX3_OFF;		//Slave FIFO读使能信号，低电平有效
				fx3_sloe_n <= FX3_OFF;		//Slave FIFO输出使能信号，低电平有效
				if (WRITE_NUM == 1)
					fx3_pktend_n <= FX3_ON;	//包结束信号
				else
					fx3_pktend_n <= FX3_OFF;	//包结束信号
				fx3_a <= 2'b00;			//FIFO写地址			
			end
			else if(num == WRITE_NUM) begin	//fx3_pktend_n =0
				fx3_slcs_n <= FX3_ON;		//Slave FIFO片选信号，低电平有效
				fx3_slwr_n <= FX3_ON;		//Slave FIFO写使能信号，低电平有效
				fx3_slrd_n <= FX3_OFF;		//Slave FIFO读使能信号，低电平有效
				fx3_sloe_n <= FX3_OFF;		//Slave FIFO输出使能信号，低电平有效
				fx3_pktend_n <= FX3_ON;		//包结束信号
				fx3_a <= 2'b00;			//FIFO写地址		
			end		
			else if(num == WRITE_NUM + 1) begin	//cs = 0; addr = 2'b00;
				fx3_slcs_n <= FX3_OFF;		//Slave FIFO片选信号，低电平有效
				fx3_slwr_n <= FX3_OFF;		//Slave FIFO写使能信号，低电平有效
				fx3_slrd_n <= FX3_OFF;		//Slave FIFO读使能信号，低电平有效
				fx3_sloe_n <= FX3_OFF;		//Slave FIFO输出使能信号，低电平有效
				fx3_pktend_n <= FX3_OFF;		//包结束信号
				fx3_a <= 2'b00;			//FIFO写地址		
			end
		end
	end
	else if(fxstate == FXS_WSOP) begin
		fx3_slcs_n <= FX3_OFF;		//Slave FIFO片选信号，低电平有效
		fx3_slwr_n <= FX3_OFF;		//Slave FIFO写使能信号，低电平有效
		fx3_slrd_n <= FX3_OFF;		//Slave FIFO读使能信号，低电平有效
		fx3_sloe_n <= FX3_OFF;		//Slave FIFO输出使能信号，低电平有效
		fx3_pktend_n <= FX3_OFF;	//包结束信号
		fx3_a <= 2'b00;			//操作FIFO地址	
	end
	else begin
		fx3_slcs_n <= FX3_OFF;		//Slave FIFO片选信号，低电平有效
		fx3_slwr_n <= FX3_OFF;		//Slave FIFO写使能信号，低电平有效
		fx3_slrd_n <= FX3_OFF;		//Slave FIFO读使能信号，低电平有效
		fx3_sloe_n <= FX3_OFF;		//Slave FIFO输出使能信号，低电平有效
		fx3_pktend_n <= FX3_OFF;	//包结束信号
	end 

/////////////////////////////////////////////////////////////
//Slave FIFO读操作数据缓存
reg[31:0] fx3_rdb;	//FX3读出数据缓存
reg fx3_rdb_en;		//FX3读出数据有效标志位，高电平有效
// wire[31:0] fx3_wdb;	//FX3写数据寄存器
	
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		fx3_rdb <= 32'd0;
		fx3_rdb_en <= 1'b0;
	end
	else if((fxstate == FXS_READ) && (num >= 10'd3)) begin
		fx3_rdb <= fx3_db;
		fx3_rdb_en <= 1'b1;
	end
	else if((fxstate == FXS_RDLY) && (delaycnt < 4'd5)) begin
		fx3_rdb <= fx3_db;
		fx3_rdb_en <= 1'b1;	
	end
	else begin
		fx3_rdb <= 32'd0;
		fx3_rdb_en <= 1'b0;
	end
end
assign o_data_from_fifo = fx3_rdb;
assign o_data_valid = fx3_rdb_en;
/////////////////////////////////////////////////////////////
// fifo
logic fx3_dir;
assign fx3_dir = (fxstate == FXS_WRIT || fxstate == FXS_WSOP);  // 仅在FXS_WRIT状态下，才能写数据
assign o_fifo_rd_en = (fxstate == FXS_WRIT) && (num < WRITE_NUM) && fx3_flaga && ~i_fifo_empty;
assign fx3_db = fx3_dir ? r_data_from_fifo : 32'hzz_zz_zz_zz;	//FX3数据总线方向控制

/////////////////////////////////////////////////////////////


// 处理 Waiting False 信号
// 每一次IDLE进入WRITE状态视为输入完成，副作用没有
// 或者IDLE等待1ms，视为输入完成(100mHz)
logic [ 3: 0] state_reg;
logic [31: 0] count;     // 100k=100000 需要18位

always @(posedge clk) begin
	if(!rst_n) begin
		state_reg <= FXS_REST;
	end
	else begin
		state_reg <= fxstate;
	end
end
localparam CNT = 32'd10;
always @(posedge clk) begin
	if(!rst_n) begin
		count <= CNT;
	end
	else if(state_reg != FXS_IDLE && fxstate == FXS_IDLE) begin
		count <= CNT;
	end
	else if(fxstate == FXS_IDLE) begin
		count <= count - 1;
	end
end

// 阻塞赋值
// 位宽
// rstn -> !rstn



assign o_waiting_false = ((state_reg == FXS_WRIT && fxstate == FXS_IDLE) || count == 0) ? 1 : 0;

// ila_4_for_USB your_instance_name (
// 	.clk(clk), // input wire clk


// 	.probe0({fx3_flaga, fx3_flagb, fx3_flagc, fx3_flagd, o_waiting_false}), // input wire [4:0]  probe0  
// 	.probe1({state_reg, fxstate, o_data_valid}), // input wire [8:0]  probe1
// 	.probe2({o_data_from_fifo}) // input wire [31:0]  probe2
// );
endmodule
