module cnn_alu
    import ariane_pkg::*;
 #(
    parameter config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
)
(
    input logic clk_i,
    input logic rst_n,
    // 控制信号
    //input [3:0] opcode,  // 操作码：vload, vstore, conv, vadd
    //input [ADDR_WIDTH-1:0] src_addr1, // 源地址1
    //input [ADDR_WIDTH-1:0] src_addr2, // 源地址2（vadd和conv使用）
    //input [ADDR_WIDTH-1:0] dest_addr, // 目标地址
    input  logic [31:0] operand_a,
    input  logic [31:0] operand_b,
    input  logic [3:0] control_signal, // 控制信号输入 从decoder
    output logic [31:0] result
    output logic ready, // 准备好接受下一个
    
    // 数据接口（与内存或寄存器文件连接）
    input [DATA_WIDTH-1:0] mem_data_in,
    output logic [DATA_WIDTH-1:0] mem_data_out,
    output logic [ADDR_WIDTH-1:0] mem_addr, // 内存地址
    output logic mem_read,  // 内存读请求
    output logic mem_write  // 内存写请求
    // 可能还需要更多控制和状态信号
);
//中间信号
reg [31:0] partial_result;
reg [3:0] state;

//操作码编码
parameter IDLE = 4'b0000;
parameter CONV_MUL = 4'b0001;
parameter VADD = 4'b0010;

// 实现细节：根据opcode执行不同操作，如数据加载、存储、卷积计算等

always_ff (posedge clk_i or posedge rst_n) begin
    if (rst_n) begin
        state <= IDLE;
        ready <= 1'b1;
    end else begin
        case (state)
            IDLE: begin
                // 等待命令
                if (ready) begin
                    case (control_signal)
                        CONV_MUL: begin
                            // 执行卷积运算（乘法）
                            partial_result <= operand_a * operand_b;
                            state <= CONV_MUL;
                        end
                        VADD: begin
                            // 执行向量加法
                            partial_result <= partial_result + operand_a;
                            state <= VADD;
                        end
                        // 添加其他控制信号...
                        default: begin
                            // 如果是未知控制信号，保持空闲状态
                            state <= IDLE;
                        end
                    endcase
                    // 将结果发送给下一个阶段
                    result <= partial_result;
                end
            end
            CONV_MUL: begin
                // 等待乘法完成
                if (ready) begin
                    state <= IDLE;
                end
            end
            VADD: begin
                // 等待加法完成
                if (ready) begin
                    state <= IDLE;
                end
            end
            // 其他状态...
        endcase
    end
end

// 总线读写控制逻辑
assign mem_read = (state == CONV_MUL); // 当执行卷积运算时，发起内存读请求
assign mem_write = (state == VADD); // 当执行向量加法时，发起内存写请求
assign mem_data_out = partial_result; // 写回部分结果到内存

endmodule
