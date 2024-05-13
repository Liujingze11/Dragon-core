set_property SRC_FILE_INFO {cfile:/home/imtuser/Documents/Dragon-core/corev_apu/fpga/xilinx/xlnx_clk_gen/xlnx_clk_gen.srcs/sources_1/ip/xlnx_clk_gen/xlnx_clk_gen/xlnx_clk_gen_in_context.xdc rfile:../../../xilinx/xlnx_clk_gen/xlnx_clk_gen.srcs/sources_1/ip/xlnx_clk_gen/xlnx_clk_gen/xlnx_clk_gen_in_context.xdc id:1 order:EARLY scoped_inst:i_xlnx_clk_gen} [current_design]
set_property SRC_FILE_INFO {cfile:/home/imtuser/Documents/Dragon-core/corev_apu/fpga/constraints/zybo_z7_20.xdc rfile:../../../constraints/zybo_z7_20.xdc id:2} [current_design]
set_property SRC_FILE_INFO {cfile:/home/imtuser/Documents/Dragon-core/corev_apu/fpga/constraints/cva6_fpga.xdc rfile:../../../constraints/cva6_fpga.xdc id:3} [current_design]
current_instance i_xlnx_clk_gen
set_property src_info {type:SCOPED_XDC file:1 line:1 export:INPUT save:INPUT read:READ} [current_design]
create_clock -period 8.000 [get_ports -no_traverse {}]
set_property src_info {type:SCOPED_XDC file:1 line:4 export:INPUT save:INPUT read:READ} [current_design]
create_generated_clock -source [get_ports clk_in1] -edges {1 2 3} -edge_shift {0.000 6.000 12.000} [get_ports {}]
set_property src_info {type:SCOPED_XDC file:1 line:6 export:INPUT save:INPUT read:READ} [current_design]
create_generated_clock -source [get_ports clk_in1] -edges {1 2 3} -edge_shift {0.000 0.000 0.000} [get_ports {}]
set_property src_info {type:SCOPED_XDC file:1 line:8 export:INPUT save:INPUT read:READ} [current_design]
create_generated_clock -source [get_ports clk_in1] -edges {1 2 3} -edge_shift {2.000 2.000 2.000} [get_ports {}]
set_property src_info {type:SCOPED_XDC file:1 line:10 export:INPUT save:INPUT read:READ} [current_design]
create_generated_clock -source [get_ports clk_in1] -edges {1 2 3} -edge_shift {0.000 6.000 12.000} [get_ports {}]
current_instance
set_property src_info {type:XDC file:2 line:1 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN K17 [get_ports clk_sys]
set_property src_info {type:XDC file:2 line:5 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict {PACKAGE_PIN Y16 IOSTANDARD LVCMOS33} [get_ports cpu_reset]
set_property src_info {type:XDC file:2 line:8 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict {PACKAGE_PIN V13 IOSTANDARD LVCMOS33} [get_ports trst_n]
set_property src_info {type:XDC file:2 line:9 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict {PACKAGE_PIN H15 IOSTANDARD LVCMOS33} [get_ports tck]
set_property src_info {type:XDC file:2 line:10 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict {PACKAGE_PIN W16 IOSTANDARD LVCMOS33} [get_ports tdi]
set_property src_info {type:XDC file:2 line:11 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict {PACKAGE_PIN J15 IOSTANDARD LVCMOS33} [get_ports tdo]
set_property src_info {type:XDC file:2 line:12 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict {PACKAGE_PIN V12 IOSTANDARD LVCMOS33} [get_ports tms]
set_property src_info {type:XDC file:2 line:15 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict {PACKAGE_PIN W8 IOSTANDARD LVCMOS33} [get_ports tx]
set_property src_info {type:XDC file:2 line:16 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict {PACKAGE_PIN U7 IOSTANDARD LVCMOS33} [get_ports rx]
set_property src_info {type:XDC file:3 line:4 export:INPUT save:INPUT read:READ} [current_design]
set_input_jitter tck 1.000
set_property src_info {type:XDC file:3 line:5 export:INPUT save:INPUT read:READ} [current_design]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets tck_IBUF]
set_property src_info {type:XDC file:3 line:14 export:INPUT save:INPUT read:READ} [current_design]
set_max_delay -datapath_only -from [get_pins i_dmi_jtag/i_dmi_cdc/i_cdc_resp/i_src/data_src_q_reg*/C] -to [get_pins i_dmi_jtag/i_dmi_cdc/i_cdc_resp/i_dst/data_dst_q_reg*/D] 20.000
set_property src_info {type:XDC file:3 line:15 export:INPUT save:INPUT read:READ} [current_design]
set_max_delay -datapath_only -from [get_pins i_dmi_jtag/i_dmi_cdc/i_cdc_resp/i_src/req_src_q_reg/C] -to [get_pins i_dmi_jtag/i_dmi_cdc/i_cdc_resp/i_dst/req_dst_q_reg/D] 20.000
set_property src_info {type:XDC file:3 line:16 export:INPUT save:INPUT read:READ} [current_design]
set_max_delay -datapath_only -from [get_pins i_dmi_jtag/i_dmi_cdc/i_cdc_req/i_dst/ack_dst_q_reg/C] -to [get_pins i_dmi_jtag/i_dmi_cdc/i_cdc_req/i_src/ack_src_q_reg/D] 20.000
set_property src_info {type:XDC file:3 line:20 export:INPUT save:INPUT read:READ} [current_design]
set_multicycle_path -hold -from [get_pins {i_rstgen_main/i_rstgen_bypass/synch_regs_q_reg[3]/C}] 3