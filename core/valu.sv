// Author: Alexandre Zhang
// Author: Jingze Liu
// Author: Yongxin Sun
//
// Date: 25.03.2024
// Description: Vector ALU that does the multiply accumulation between InputA and InputB (4x8bit int)

module valu
  import ariane_pkg::*;
  (
    input  logic         clk_i,     // Clock
    input  logic         rst_ni,    // Asynchronous reset active low
    input  logic [31:0] operand_a_i,  // 32 bit operand_a
    input  logic [31:0] operand_b_i,  // 32 bit operand_b
    output logic [31:0] result_o,   // 32 bit output
);

logic signed [7:0]  operand_a_8bits [3:0] 
logic signed [7:0]  operand_b_8bits [3:0] 
logic signed [15:0] mult_result [3:0] 

always_comb begin
  operand_a_8bits[0] = operand_a_i[7:0];
  operand_a_8bits[1] = operand_a_i[15:8];
  operand_a_8bits[2] = operand_a_i[23:16];
  operand_a_8bits[3] = operand_a_i[31:24];

  operand_b_8bits[0] = operand_b_i[7:0];
  operand_b_8bits[1] = operand_b_i[15:8];
  operand_b_8bits[2] = operand_b_i[23:16];
  operand_b_8bits[3] = operand_b_i[31:24];
end

always_comb begin
  mult_result[0] = operand_a_8bits[0] * operand_b_8bits[0];
  mult_result[1] = operand_a_8bits[1] * operand_b_8bits[1];
  mult_result[2] = operand_a_8bits[2] * operand_b_8bits[2];
  mult_result[3] = operand_a_8bits[3] * operand_b_8bits[3];
end

assign result_o = (mult_result[0] + mult_result[1]) + (mult_result[2] + mult_result[3]);

endmodule