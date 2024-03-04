// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Author: Matthias Baer <baermatt@student.ethz.ch>
// Author: Igor Loi <igor.loi@unibo.it>
// Author: Andreas Traber <atraber@student.ethz.ch>
// Author: Lukas Mueller <lukasmue@student.ethz.ch>
// Author: Florian Zaruba <zaruabf@iis.ee.ethz.ch>
//
// Date: 19.03.2017
// Description: Ariane ALU based on RI5CY's ALU


module alu
  import ariane_pkg::*;
#(
    parameter config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty
) (
    input  logic         clk_i,            // Clock
    input  logic         rst_ni,           // Asynchronous reset active low
    input  fu_data_t     fu_data_i,        // 输入数据
    output riscv::xlen_t result_o,         // 输出结果
    output logic         alu_branch_res_o  // 分支结果
);

  riscv::xlen_t                   operand_a_rev;  //这是输入操作数A的位反转版本。riscv::xlen_t是根据RISC-V的位宽（32位或64位）定义的类型，确保ALU可以处理RISC-V支持的任何位宽。
  logic         [           31:0] operand_a_rev32;//这是32位版本的操作数A的位反转
  logic         [  riscv::XLEN:0] operand_b_neg;  //这是操作数B的取反加1结果（二进制补码），扩展了一位以支持加法和减法操作中的进位或借位。其大小根据RISC-V的位宽（XLEN）动态定义。
  logic         [riscv::XLEN+1:0] adder_result_ext_o; //这是加法器的结果，包括一个额外的位以支持进位输出
  logic                           less;  // handles both signed and unsigned forms 这个信号用于表示比较操作的结果，可以处理有符号和无符号数的比较
  logic         [           31:0] rolw;  // Rotate Left Word 32位操作数A的左旋转（ROL）结果
  logic         [           31:0] rorw;  // Rotate Right Word 32位操作数A的右旋转（ROR）结果
  logic [31:0] orcbw, rev8w;             //orcbw是OR combine byte-wise操作的结果，rev8w是每8位字节反转操作的结果
  logic [  $clog2(riscv::XLEN) : 0] cpop;  // Count Population 这是操作数A中置位（值为1的位）数量的计数，使用了$clog2系统函数来确定所需的位宽
  logic [$clog2(riscv::XLEN)-1 : 0] lz_tz_count;  // Count Leading Zeros  这是操作数A的前导零（或尾零，取决于上下文）的计数。
  logic [                      4:0] lz_tz_wcount;  // Count Leading Zeros Word 这是32位版本的操作数A的前导零计数
  logic lz_tz_empty, lz_tz_wempty;                  //这两个信号分别表示在完整的XLEN位宽和32位版本的操作数A中，是否没有找到任何非零位
  riscv::xlen_t orcbw_result, rev8w_result;         //这些是基于操作数A执行特定位操作（如ORCB和REV8）后的结果

  // bit reverse operand_a for left shifts and bit counting
  // 这一部分代码使用了SystemVerilog的generate构造来动态创建硬件逻辑。generate语句允许在编译时根据参数生成重复或条件化的结构。在这个例子中，它被用来为不同位宽的操作数生成位反转逻辑。
  generate
    genvar k;
    for (k = 0; k < riscv::XLEN; k++)
      assign operand_a_rev[k] = fu_data_i.operand_a[riscv::XLEN-1-k];

    for (k = 0; k < 32; k++) assign operand_a_rev32[k] = fu_data_i.operand_a[31-k];
  endgenerate

  // ------
  // Adder
  // ------
  logic adder_op_b_negate;
  logic adder_z_flag;
  logic [riscv::XLEN:0] adder_in_a, adder_in_b;
  riscv::xlen_t adder_result;
  logic [riscv::XLEN-1:0] operand_a_bitmanip, bit_indx;

  always_comb begin
    adder_op_b_negate = 1'b0; //逻辑开始时，adder_op_b_negate被初始化为0（表示不取反）

    unique case (fu_data_i.operation)
      // ADDER OPS
      EQ, NE, SUB, SUBW, ANDN, ORN, XNOR: adder_op_b_negate = 1'b1; //（当前ALU要执行的操作）是EQ（等于）、NE（不等于）、SUB（减法）、SUBW（字宽减法）、ANDN（与非）、ORN（或非）、XNOR（异或非），那么adder_op_b_negate被设为1，表示需要对操作数B进行取反操作。
      default: ;
    endcase
  end

  always_comb begin
    operand_a_bitmanip = fu_data_i.operand_a;

    if (ariane_pkg::BITMANIP) begin //如果启用了位操作（ariane_pkg::BITMANIP为真） 对操作数A (operand_a) 进行特定的位操作
      unique case (fu_data_i.operation)
        SH1ADD:             operand_a_bitmanip = fu_data_i.operand_a << 1;
        SH2ADD:             operand_a_bitmanip = fu_data_i.operand_a << 2;
        SH3ADD:             operand_a_bitmanip = fu_data_i.operand_a << 3;
        SH1ADDUW:           operand_a_bitmanip = fu_data_i.operand_a[31:0] << 1;
        SH2ADDUW:           operand_a_bitmanip = fu_data_i.operand_a[31:0] << 2;
        SH3ADDUW:           operand_a_bitmanip = fu_data_i.operand_a[31:0] << 3;
        CTZ:                operand_a_bitmanip = operand_a_rev;
        CTZW:               operand_a_bitmanip = operand_a_rev32;
        ADDUW, CPOPW, CLZW: operand_a_bitmanip = fu_data_i.operand_a[31:0];
        default:            ;
      endcase
    end
  end

  // prepare operand a
  assign adder_in_a         = {operand_a_bitmanip, 1'b1};

  // prepare operand b
  assign operand_b_neg      = {fu_data_i.operand_b, 1'b0} ^ {riscv::XLEN + 1{adder_op_b_negate}};//operand_b_neg是操作数B的取反加1（如果adder_op_b_negate为真）或原值的表示。这种处理允许使用同一加法器执行减法操作
  assign adder_in_b         = operand_b_neg;

  // actual adder
  assign adder_result_ext_o = $unsigned(adder_in_a) + $unsigned(adder_in_b);
  assign adder_result       = adder_result_ext_o[riscv::XLEN:1];  //通过去除最低位（通过[riscv::XLEN:1]）来获取最终的加法结果adder_result
  assign adder_z_flag       = ~|adder_result;                     //标志指示加法结果是否为零，这对于等于（EQ）和不等于（NE）分支条件判断很重要。

  // get the right branch comparison result
  always_comb begin : branch_resolve
    // set comparison by default
    alu_branch_res_o = 1'b1;
    case (fu_data_i.operation)
      EQ:       alu_branch_res_o = adder_z_flag;
      NE:       alu_branch_res_o = ~adder_z_flag;
      LTS, LTU: alu_branch_res_o = less;
      GES, GEU: alu_branch_res_o = ~less;
      default:  alu_branch_res_o = 1'b1;
    endcase
  end

  // ---------
  // Shifts
  // ---------

  // TODO: this can probably optimized significantly
  logic                         shift_left;  // should we shift left 一个逻辑信号，如果要执行左移操作，则为真
  logic                         shift_arithmetic; //一个逻辑信号，如果要执行算术右移（保留符号位），则为真

  riscv::xlen_t                 shift_amt;  // amount of shift, to the right 一个逻辑信号，如果要执行算术右移（保留符号位），则为真
  riscv::xlen_t                 shift_op_a;  // input of the shifter 位操作的输入值，可能是原始输入或位反转的版本，取决于是否是左移操作。
  logic         [         31:0] shift_op_a32;  // input to the 32 bit shift operation 32位输入值，用于处理32位的移位操作

  riscv::xlen_t                 shift_result; //64位
  logic         [         31:0] shift_result32; //32位移位操作的结果

  logic         [riscv::XLEN:0] shift_right_result;
  logic         [         32:0] shift_right_result32;

  riscv::xlen_t                 shift_left_result;
  logic         [         31:0] shift_left_result32;

  assign shift_amt = fu_data_i.operand_b;           // 这是要进行位移的数量，直接从fu_data_i.operand_b获得

  assign shift_left = (fu_data_i.operation == SLL) | (fu_data_i.operation == SLLW);//这个标志用来指示是否进行左移操作。它根据当前操作是否为SLL（Shift Left Logical）或SLLW（Shift Left Logical Word）来设置

  assign shift_arithmetic = (fu_data_i.operation == SRA) | (fu_data_i.operation == SRAW);//: 这个标志用来指示是否进行算术右移操作。算术右移与逻辑右移不同，它考虑了数值的符号位。如果操作是SRA（Shift Right Arithmetic）或SRAW（Shift Right Arithmetic Word），则此标志被设置为真

  // right shifts, we let the synthesizer optimize this
  logic [riscv::XLEN:0] shift_op_a_64;
  logic [32:0] shift_op_a_32;

  // choose the bit reversed or the normal input for shift operand a
  assign shift_op_a           = shift_left ? operand_a_rev : fu_data_i.operand_a;
  assign shift_op_a32         = shift_left ? operand_a_rev32 : fu_data_i.operand_a[31:0];//如果是左移操作（shift_left为真），则选择operand_a的位逆序（operand_a_rev或operand_a_rev32）作为位移的操作数（shift_op_a或shift_op_a32）如果不是左移操作，则直接使用操作数operand_a的原始值或其32位子集（对于32位操作）

  assign shift_op_a_64        = {shift_arithmetic & shift_op_a[riscv::XLEN-1], shift_op_a};
  assign shift_op_a_32        = {shift_arithmetic & shift_op_a[31], shift_op_a32};

  assign shift_right_result   = $unsigned($signed(shift_op_a_64) >>> shift_amt[5:0]);//通过对扩展后的操作数执行算术右移（>>>）操作来计算。这里使用了算术右移而不是逻辑右移，因为算术右移会保留符号位。

  assign shift_right_result32 = $unsigned($signed(shift_op_a_32) >>> shift_amt[4:0]);//移位量由shift_amt指定，对于64位操作，使用shift_amt[5:0]（最多移动63位）对于32位操作，使用shift_amt[4:0]（最多移动31位）
  // bit reverse the shift_right_result for left shifts
  genvar j;
  generate
    for (j = 0; j < riscv::XLEN; j++)
      assign shift_left_result[j] = shift_right_result[riscv::XLEN-1-j];//对于左移操作，首先需要计算一个"伪"的右移结果（shift_right_result和shift_right_result32），然后将这个结果的位序列颠倒（即逆序），得到最终的左移结果。

    for (j = 0; j < 32; j++) assign shift_left_result32[j] = shift_right_result32[31-j];

  endgenerate

  assign shift_result   = shift_left ? shift_left_result : shift_right_result[riscv::XLEN-1:0];
  assign shift_result32 = shift_left ? shift_left_result32 : shift_right_result32[31:0];

  // ------------
  // Comparisons
  // ------------

  always_comb begin
    logic sgn;
    sgn = 1'b0; //sgn是一个局部逻辑变量，用于指示是否进行有符号比较，默认为0（无符号）

    if ((fu_data_i.operation == SLTS) ||
            (fu_data_i.operation == LTS)  ||
            (fu_data_i.operation == GES)  ||
            (fu_data_i.operation == MAX)  ||
            (fu_data_i.operation == MIN))
      sgn = 1'b1;       //如果操作是有符号比较（SLTS, LTS, GES）或求最大最小值（MAX, MIN），则sgn设置为1

    less = ($signed({sgn & fu_data_i.operand_a[riscv::XLEN-1], fu_data_i.operand_a}) <
            $signed({sgn & fu_data_i.operand_b[riscv::XLEN-1], fu_data_i.operand_b}));  //这行代码实现了比较逻辑。它通过扩展操作数的符号位（根据sgn变量），将两个操作数转换为有符号数并进行比较。
  end

  if (ariane_pkg::BITMANIP) begin : gen_bitmanip //这行代码检查是否启用了位操作（BITMANIP）功能
    // Count Population + Count population Word

    popcount #(
        .INPUT_WIDTH(riscv::XLEN)
    ) i_cpop_count (
        .data_i    (operand_a_bitmanip),
        .popcount_o(cpop)
    );  //使用popcount模块计算operand_a_bitmanip中1的数量，并将结果存储在cpop中。这是位操作中的“计数位”功能

    // Count Leading/Trailing Zeros
    // 64b
    lzc #(
        .WIDTH(riscv::XLEN),
        .MODE (1)
    ) i_clz_64b (
        .in_i(operand_a_bitmanip),
        .cnt_o(lz_tz_count),
        .empty_o(lz_tz_empty)
    ); //使用lzc模块计算64位操作数operand_a_bitmanip的前导零数量，并将结果存储在lz_tz_count中。empty_o输出指示是否输入全零
    //32b
    lzc #(
        .WIDTH(32),
        .MODE (1)
    ) i_clz_32b (
        .in_i(operand_a_bitmanip[31:0]),
        .cnt_o(lz_tz_wcount),
        .empty_o(lz_tz_wempty)
    );
  end

  if (ariane_pkg::BITMANIP) begin : gen_orcbw_rev8w_results //这行代码再次检查是否启用了位操作功能，用于实现特定的位操作ORCBW和REV8W
    assign orcbw = {{8{|fu_data_i.operand_a[31:24]}}, {8{|fu_data_i.operand_a[23:16]}}, {8{|fu_data_i.operand_a[15:8]}}, {8{|fu_data_i.operand_a[7:0]}}};//orcbw操作对每个字节执行OR操作，如果字节中任何一位为1，则该字节所有位都置为1
    assign rev8w = {{fu_data_i.operand_a[7:0]}, {fu_data_i.operand_a[15:8]}, {fu_data_i.operand_a[23:16]}, {fu_data_i.operand_a[31:24]}};   //rev8w操作将32位操作数的每个字节逆序排列。
    if (riscv::XLEN == 64) begin : gen_64b //这行代码检查操作数的长度是否为64位，如果是，则进行64位操作的特定处理。
      assign orcbw_result = {{8{|fu_data_i.operand_a[63:56]}}, {8{|fu_data_i.operand_a[55:48]}}, {8{|fu_data_i.operand_a[47:40]}}, {8{|fu_data_i.operand_a[39:32]}}, orcbw};
      assign rev8w_result = {rev8w , {fu_data_i.operand_a[39:32]}, {fu_data_i.operand_a[47:40]}, {fu_data_i.operand_a[55:48]}, {fu_data_i.operand_a[63:56]}};
    end else begin : gen_32b
      assign orcbw_result = orcbw;
      assign rev8w_result = rev8w;
    end
  end

  // -----------
  // Result MUX
  // -----------
  always_comb begin
    result_o = '0;
    unique case (fu_data_i.operation)
      // Standard Operations
      ANDL, ANDN: result_o = fu_data_i.operand_a & operand_b_neg[riscv::XLEN:1];
      ORL, ORN:   result_o = fu_data_i.operand_a | operand_b_neg[riscv::XLEN:1];
      XORL, XNOR: result_o = fu_data_i.operand_a ^ operand_b_neg[riscv::XLEN:1];

      // Adder Operations 这里处理加法器操作，如ADD（加法）、SUB（减法）等，结果直接来自于之前计算的adder_result。
      ADD, SUB, ADDUW, SH1ADD, SH2ADD, SH3ADD, SH1ADDUW, SH2ADDUW, SH3ADDUW:
      result_o = adder_result;
      // Add word: Ignore the upper bits and sign extend to 64 bit 对于32位操作（ADDW, SUBW），取结果的低32位并进行符号扩展到64位。
      ADDW, SUBW: result_o = {{riscv::XLEN - 32{adder_result[31]}}, adder_result[31:0]};
      // Shift Operations 处理64位或32位的逻辑左移（SLL）、逻辑右移（SRL）、算术右移（SRA），结果取决于riscv::XLEN的值。
      SLL, SRL, SRA: result_o = (riscv::XLEN == 64) ? shift_result : shift_result32;
      // Shifts 32 bit 对于32位移位操作，执行符号扩展。
      SLLW, SRLW, SRAW: result_o = {{riscv::XLEN - 32{shift_result32[31]}}, shift_result32[31:0]};

      // Comparison Operations 对于比较操作，结果为一个布尔值，表示是否小于，扩展到整个result_o的大小。
      SLTS, SLTU: result_o = {{riscv::XLEN - 1{1'b0}}, less};

      default: ;  // default case to suppress unique warning
    endcase

    if (ariane_pkg::BITMANIP) begin //这里检查是否启用了位操作扩展（BITMANIP）
      // Index for Bitwise Rotation
      bit_indx = 1 << (fu_data_i.operand_b & (riscv::XLEN - 1));//计算位操作的索引，这是通过将1左移operand_b与XLEN - 1的按位与结果来实现的，用于确定哪一位会被操作
      // rolw, roriw, rorw
      rolw = ({{riscv::XLEN-32{1'b0}},fu_data_i.operand_a[31:0]} << fu_data_i.operand_b[4:0]) | ({{riscv::XLEN-32{1'b0}},fu_data_i.operand_a[31:0]} >> (riscv::XLEN-32-fu_data_i.operand_b[4:0]));
      rorw = ({{riscv::XLEN-32{1'b0}},fu_data_i.operand_a[31:0]} >> fu_data_i.operand_b[4:0]) | ({{riscv::XLEN-32{1'b0}},fu_data_i.operand_a[31:0]} << (riscv::XLEN-32-fu_data_i.operand_b[4:0]));//这里执行了32位的左旋转（rolw）和右旋转（rorw）操作。这是通过组合左移和右移的结果来完成的，左移和右移的量由operand_b的低5位决定。
      unique case (fu_data_i.operation)
        // Left Shift 32 bit unsigned
        SLLIUW:
        result_o = {{riscv::XLEN-32{1'b0}}, fu_data_i.operand_a[31:0]} << fu_data_i.operand_b[5:0];
        // Integer minimum/maximum
        MAX: result_o = less ? fu_data_i.operand_b : fu_data_i.operand_a;
        MAXU: result_o = less ? fu_data_i.operand_b : fu_data_i.operand_a;
        MIN: result_o = ~less ? fu_data_i.operand_b : fu_data_i.operand_a;
        MINU: result_o = ~less ? fu_data_i.operand_b : fu_data_i.operand_a;

        // Single bit instructions operations
        BCLR, BCLRI: result_o = fu_data_i.operand_a & ~bit_indx;
        BEXT, BEXTI: result_o = {{riscv::XLEN - 1{1'b0}}, |(fu_data_i.operand_a & bit_indx)};
        BINV, BINVI: result_o = fu_data_i.operand_a ^ bit_indx;
        BSET, BSETI: result_o = fu_data_i.operand_a | bit_indx;

        // Count Leading/Trailing Zeros
        CLZ, CTZ:
        result_o = (lz_tz_empty) ? ({{riscv::XLEN - $clog2(riscv::XLEN) {1'b0}}, lz_tz_count} + 1) :
            {{riscv::XLEN - $clog2(riscv::XLEN) {1'b0}}, lz_tz_count};
        CLZW, CTZW: result_o = (lz_tz_wempty) ? 32 : {{riscv::XLEN - 5{1'b0}}, lz_tz_wcount};

        // Count population
        CPOP, CPOPW: result_o = {{(riscv::XLEN - ($clog2(riscv::XLEN) + 1)) {1'b0}}, cpop};

        // Sign and Zero Extend
        SEXTB: result_o = {{riscv::XLEN - 8{fu_data_i.operand_a[7]}}, fu_data_i.operand_a[7:0]};
        SEXTH: result_o = {{riscv::XLEN - 16{fu_data_i.operand_a[15]}}, fu_data_i.operand_a[15:0]};
        ZEXTH: result_o = {{riscv::XLEN - 16{1'b0}}, fu_data_i.operand_a[15:0]};

        // Bitwise Rotation
        ROL:
        result_o = (riscv::XLEN == 64) ? ((fu_data_i.operand_a << fu_data_i.operand_b[5:0]) | (fu_data_i.operand_a >> (riscv::XLEN-fu_data_i.operand_b[5:0]))) : ((fu_data_i.operand_a << fu_data_i.operand_b[4:0]) | (fu_data_i.operand_a >> (riscv::XLEN-fu_data_i.operand_b[4:0])));
        ROLW: result_o = {{riscv::XLEN - 32{rolw[31]}}, rolw};
        ROR, RORI:
        result_o = (riscv::XLEN == 64) ? ((fu_data_i.operand_a >> fu_data_i.operand_b[5:0]) | (fu_data_i.operand_a << (riscv::XLEN-fu_data_i.operand_b[5:0]))) : ((fu_data_i.operand_a >> fu_data_i.operand_b[4:0]) | (fu_data_i.operand_a << (riscv::XLEN-fu_data_i.operand_b[4:0])));
        RORW, RORIW: result_o = {{riscv::XLEN - 32{rorw[31]}}, rorw};
        ORCB:
        result_o = orcbw_result;
        REV8:
        result_o = rev8w_result;

        default: ;  // default case to suppress unique warning
      endcase
    end
    if (CVA6Cfg.ZiCondExtEn) begin //如果启用了条件扩展，则根据operand_b是否为零来决定是否将operand_a的值或零写入result_o。
      unique case (fu_data_i.operation)
        CZERO_EQZ:
        result_o = (|fu_data_i.operand_b) ? fu_data_i.operand_a : '0;  // move zero to rd if rs2 is equal to zero else rs1
        CZERO_NEZ:
        result_o = (|fu_data_i.operand_b) ? '0 : fu_data_i.operand_a; // move zero to rd if rs2 is nonzero else rs1
        default: ;  // default case to suppress unique warning
      endcase
    end
  end
endmodule
