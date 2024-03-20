module cnn_alu
    import ariane_pkg::*;
  #(
    parameter config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty
    parameter DATA_WIDTH = 8,  // 数据和卷积核的位宽
    parameter KERNEL_SIZE = 3  // 卷积核大小，这里为3x3
  )
  (
    input logic clk_i,            // 时钟信号
    input logic rst_ni,             // 复位信号，低电平有效
    //input wire enable,            // ALU使能信号
    input logic [DATA_WIDTH*KERNEL_SIZE*KERNEL_SIZE-1:0] image_data,  // 图像数据输入
    input logic [DATA_WIDTH*KERNEL_SIZE*KERNEL_SIZE-1:0] kernel_data, // 卷积核数据输入
    input logic conv_start,        // 开始卷积指令
    output reg [DATA_WIDTH+4:0] conv_result, // 卷积结果输出，位宽略大以避免溢出
    output reg valid              // 输出结果有效标志
  );

  // 内部信号定义
  reg [DATA_WIDTH-1:0] image_block [KERNEL_SIZE*KERNEL_SIZE-1:0];
  reg [DATA_WIDTH-1:0] kernel [KERNEL_SIZE*KERNEL_SIZE-1:0];
  integer i;

  // 图像数据和卷积核数据加载
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      valid <= 0;
    end else if (enable && conv_start) begin
      for (i = 0; i < KERNEL_SIZE*KERNEL_SIZE; i=i+1) begin
        image_block[i] <= image_data[(i+1)*DATA_WIDTH-1 -: DATA_WIDTH];
        kernel[i] <= kernel_data[(i+1)*DATA_WIDTH-1 -: DATA_WIDTH];
      end
      valid <= 1;  // 加载完成，准备计算
    end else begin
      valid <= 0;
    end
  end

  // 卷积计算
  always @(posedge clk) begin
    if (valid) begin
      conv_result = 0;
      for (i = 0; i < KERNEL_SIZE*KERNEL_SIZE; i=i+1) begin
        conv_result = conv_result + (image_block[i] * kernel[i]);
      end
      valid <= 0;  // 计算完成，清除有效标志
    end
  end

endmodule

// CNN卷积执行单元
module cnn_conv_unit
#(
    parameter DATA_WIDTH = 8,  // 输入数据位宽
    parameter WEIGHT_WIDTH = 8, // 权重数据位宽
    parameter ADDR_WIDTH = 32,  // 地址位宽
    parameter SIZE_WIDTH = 8,   // 卷积窗口大小位宽
    parameter OUT_WIDTH = 16    // 输出数据位宽
)
(
    input logic clk,  // 时钟信号
    input logic rst_n, // 复位信号，低电平有效
    // CONV指令输入
    input logic [ADDR_WIDTH-1:0] src_addr1, // 源地址1，指向输入特征图
    input logic [ADDR_WIDTH-1:0] src_addr2, // 源地址2，指向卷积核
    input logic [ADDR_WIDTH-1:0] dest_addr, // 目标地址，存储卷积结果
    input logic [SIZE_WIDTH-1:0] size,      // 卷积窗口大小
    input logic conv_start,                  // CONV操作开始信号
    output logic conv_done                   // CONV操作完成信号
);

// 假设存在一个内存接口，用于读写操作数和写入结果
// 需要设计适合您的系统的内存接口

// 内部状态和逻辑
logic [OUT_WIDTH-1:0] conv_result; // 存储临时卷积结果
logic processing; // 指示当前是否正在执行卷积操作

// 实现简化版本的卷积操作
// 注意：这里省略了具体的卷积计算实现，需要根据您的需求设计
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        conv_done <= 0;
        processing <= 0;
        // 其他必要的初始化
    end
    else if (conv_start && !processing) begin
        processing <= 1;
        // 开始卷积计算
        // 根据src_addr1, src_addr2, size读取数据，执行卷积，结果写入dest_addr
        // 这里假设conv_result已经计算出来
        // memory_write(dest_addr, conv_result); // 将结果写入目标地址，需要实现memory_write函数
        conv_done <= 1;
        processing <= 0;
    end
    else begin
        conv_done <= 0;
    end
end

// TODO: 实现具体的卷积计算逻辑，包括读取输入数据、执行卷积操作、将结果写回内存

endmodule

