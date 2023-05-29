`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/17 15:51:08
// Design Name: 
// Module Name: Timer_module
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 用于定时提供一个触发信号，可循环产生可只产生一次；
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Timer_module (
    input             clk,
    input             rst_n,
    input      [31:0] I_app_wait_us,
    input             I_app_req,
    output reg        O_app_busy,
    output reg        O_app_ack
);
  parameter CLK_FRE = 50;
  parameter US_CNT = CLK_FRE;  //50*1000
  parameter LOOP = 1;


  /**************************同步状态****************************/
  reg [4:0] STATE_CURRENT;
  reg [4:0] STATE_NEXT;
  localparam S_IDLE = 5'd0;  //空闲，fifo无数据状态
  localparam S_WAIT = 5'd1;  //正常间隔
  localparam S_ACK = 5'd2;
  localparam S_DONE = 5'd3;
  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) STATE_CURRENT <= S_IDLE;
    else STATE_CURRENT <= STATE_NEXT;
  end
  reg [31:0] state_clk_cnt;
  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) state_clk_cnt <= 'd0;
    else if (STATE_NEXT != STATE_CURRENT || state_clk_cnt == US_CNT - 1) state_clk_cnt <= 'd0;
    else state_clk_cnt <= state_clk_cnt + 1'd1;
  end
  reg [31:0] state_us;
  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) state_us <= 'd0;
    else if (STATE_NEXT != STATE_CURRENT) state_us <= 'd0;
    else if (state_clk_cnt == US_CNT - 1) state_us <= state_us + 1'd1;
    else state_us <= state_us;
  end
  /**************************转移状态****************************/
  always @(*) begin
    case (STATE_CURRENT)
      S_IDLE: begin
        if (I_app_req) STATE_NEXT = S_WAIT;
        else STATE_NEXT = S_IDLE;
      end
      S_WAIT: begin
        if (state_us == I_app_wait_us - 1) STATE_NEXT = S_ACK;
        else STATE_NEXT = S_WAIT;
      end
      S_ACK: begin
        STATE_NEXT = S_DONE;
      end
      S_DONE: begin
        if (LOOP) STATE_NEXT = S_IDLE;
        else STATE_NEXT = S_DONE;
      end
      default: STATE_NEXT = S_IDLE;
    endcase
  end

  /**************************状态输出****************************/
  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) O_app_ack <= 1'd0;
    else if (STATE_CURRENT == S_ACK) O_app_ack <= 1'd1;
    else O_app_ack <= 1'd0;
  end

  /**************************状态输出****************************/
  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) O_app_busy <= 1'd0;
    else if (STATE_CURRENT == S_WAIT) O_app_busy <= 1'd1;
    else O_app_busy <= 1'd0;
  end
endmodule
