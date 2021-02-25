# parsing argument
if {$argc != 3} {
	puts "Error: The argument should be hw_act val output_dir"
	exit
} else {
	set act [lindex $argv 0]
	set val [lindex $argv 1]
	set out_dir [lindex $argv 2]
}

set project_name prj_2

# setting parameters
set topmodule_src_fpga top

# setting parameters
set bd_design mpsoc
set device xczu19eg-ffvc1760-2-e
set board sugon:nf_card:part0:2.0

set mips_dir sources/ip_catalog/mips_core
set mips_top_dir sources/hdl
set tb_dir sources/testbench

set prj_file ${project_name}/${project_name}.xpr

set script_dir [file dirname [info script]]

set rtl_chk_dir ${script_dir}/../vivado_out/rtl_chk
set synth_rpt_dir ${script_dir}/../vivado_out/synth_rpt
set impl_rpt_dir ${script_dir}/../vivado_out/impl_rpt
set dcp_dir ${script_dir}/../vivado_out/dcp
set sim_out_dir ${script_dir}/../vivado_out/sim

set bench_dir ${script_dir}/../../benchmark

set static top
set pm user
set inst_pm1 inst_user1
set inst_pm2 inst_user2
set inst_pm3 inst_user3
set inst_pm4 inst_user4


if {$act == "rtl_chk" || $act == "sch_gen" || $act == "bhv_sim" || $act == "pst_sim" || $act == "bit_gen"} {
	# setting up the project
	create_project ${project_name} -force -dir "./${project_name}" -part ${device}
	set_property board_part ${board} [current_project]
	
	# complete project setup
	if {$act == "rtl_chk" || $act == "sch_gen" || $act == "bhv_sim" || $act == "pst_sim"} {
		
		set_property verilog_define { {MIPS_CPU_FULL_SIMU} } [get_filesets sources_1]

		# setting top module of sources_1
		if {$act == "sch_gen"} {
			set module_src [get_files *${val}.v]
			if {${module_src} == ""} {
				puts "Error: No such specified module for RTL schematics generation"
				exit
			}
			set top_module ${val}

		} else {
			set top_module mips_cpu_top
		}

		set_property "top" ${top_module} [get_filesets sources_1]
		update_compile_order -fileset [get_filesets sources_1]

		if {$act == "bhv_sim" || $act == "pst_sim"} {
			
			set_property verilog_define { {MIPS_CPU_FULL_SIMU} {USE_MEM_INIT} } [get_filesets sources_1]
			add_files -fileset constrs_1 -norecurse ${script_dir}/../constraints/mips_cpu_simu.xdc

			#parse names of benchmark and suite it belongs to 
			set bench_suite [lindex $val 0]
			set bench_name [lindex $val 1]
			set sim_time [lindex $val 2]

			# add instruction stream for simulation
			exec cp ${bench_dir}/${bench_suite}/sim/${bench_name}.vh ${sim_out_dir}/inst.mem 

			add_files -norecurse -fileset sources_1 ${sim_out_dir}/inst.mem
			update_compile_order -fileset [get_filesets sources_1]

			add_files -norecurse -fileset sim_1 ${sim_out_dir}/inst.mem
			update_compile_order -fileset [get_filesets sim_1]

			# set verilog define value
			set_property verilog_define { {MIPS_CPU_FULL_SIMU} {USE_MEM_INIT} } [get_filesets sim_1]

			# set verilog simulator 
			set_property target_simulator "XSim" [current_project]

			# add testbed file and set top module to sim_1
			add_files -norecurse -fileset sim_1 ${script_dir}/../${tb_dir}/mips_cpu_test.v
			set_property "top" mips_cpu_test [get_filesets sim_1]
			update_compile_order -fileset [get_filesets sim_1]
		}

	} else {
		add_files -norecurse -fileset sources_1 ${script_dir}/../${mips_top_dir}/axi_lite_if.v
# MIPS source files
		add_files -norecurse -fileset sources_1 ${script_dir}/../${mips_dir}/
		add_files -norecurse -fileset sources_1 ${script_dir}/../${mips_top_dir}/ideal_mem.v
		add_files -norecurse -fileset sources_1 ${script_dir}/../${mips_top_dir}/mips_cpu_top_pr.v
		add_files -norecurse -fileset sources_1 ${script_dir}/../${mips_top_dir}/mips_cpu_fpga.v
		
		# setup ILA hardware debugger if HW_ACT is specified 
		if {$val != "none"} {
			foreach ila_conf $val {
				source ${script_dir}/ila.tcl
				
				set_property synth_checkpoint_mode None [get_files ./${project_name}/${project_name}.srcs/sources_1/bd/${ila_conf}/${ila_conf}.bd]
				generate_target all [get_files ./${project_name}/${project_name}.srcs/sources_1/bd/${ila_conf}/${ila_conf}.bd]
				
				make_wrapper -files [get_files ./${project_name}/${project_name}.srcs/sources_1/bd/${ila_conf}/${ila_conf}.bd] -top
				import_files -force -norecurse -fileset sources_1 ./${project_name}/${project_name}.srcs/sources_1/bd/${ila_conf}/hdl/${ila_conf}_wrapper.v
				
				validate_bd_design
				save_bd_design
				close_bd_design ${ila_conf}
			}
		}
		#add pr top file
		add_files -norecurse -fileset sources_1 ${script_dir}/../${mips_top_dir}/${pm}.v
		set_property "top" ${pm} [get_filesets sources_1]
		update_compile_order -fileset [get_filesets sources_1]
	}
	
	if {$act == "pst_sim" || $act == "bit_gen"} {
		# setting Synthesis options
		set_property strategy {Vivado Synthesis defaults} [get_runs synth_1]
		# keep module port names in the netlist
		set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY {none} [get_runs synth_1]

		# setting Implementation options
		set_property steps.phys_opt_design.is_enabled true [get_runs impl_1]
		# the following implementation options will increase runtime, but get the best timing results
		#set_property strategy Performance_Explore [get_runs impl_1]

		# Generate HDF
		if {$act == "bit_gen"} {
			write_hwdef -force -file ${out_dir}/system.hdf
		}
	}
	set_property source_mgmt_mode All [current_project]

	# Vivado operations
	if {$act == "rtl_chk" || $act == "sch_gen"} {

		# calling elabrated design
		synth_design -rtl -rtl_skip_constraints -rtl_skip_ip -top ${top_module}

		if {$act == "sch_gen"} {
			write_schematic -format pdf -force ${rtl_chk_dir}/${top_module}_sch.pdf
		}

	} elseif {$act == "pst_sim" || $act == "bit_gen"} {
		if {$act == "pst_sim"} {
			set rpt_prefix pst_sim
			
			# synthesizing design
			synth_design -top mips_cpu_top -part ${device} -flatten_hierarchy none
		} else {
			set rpt_prefix synth
			# synthesizing design
			synth_design -mode out_of_context -top ${pm} -part ${device}
		}

		# setup output logs and reports
		report_utilization -hierarchical -file ${synth_rpt_dir}/${rpt_prefix}_util_hier.rpt
		report_utilization -file ${synth_rpt_dir}/${rpt_prefix}_util.rpt
		report_timing_summary -file ${synth_rpt_dir}/${rpt_prefix}_timing.rpt -delay_type max -max_paths 1000

		# Processing opt_design, placement, routing and bitstream generation
		if {$act == "bit_gen"} {
			set rpt_prefix synth 
		} else {
			set rpt_prefix pst_sim_
		}

		write_checkpoint -force ${dcp_dir}/${rpt_prefix}_1.dcp
		file copy -force ${dcp_dir}/${rpt_prefix}_1.dcp ${dcp_dir}/${rpt_prefix}_2.dcp
		file copy -force ${dcp_dir}/${rpt_prefix}_1.dcp ${dcp_dir}/${rpt_prefix}_3.dcp
		file copy -force ${dcp_dir}/${rpt_prefix}_1.dcp ${dcp_dir}/${rpt_prefix}_4.dcp

		add_files ${script_dir}/../shell/top_static.dcp
		
		add_file ${dcp_dir}/${rpt_prefix}_1.dcp
		add_file ${dcp_dir}/${rpt_prefix}_2.dcp
		add_file ${dcp_dir}/${rpt_prefix}_3.dcp
		add_file ${dcp_dir}/${rpt_prefix}_4.dcp

		set_property SCOPED_TO_CELLS "${inst_pm1}" [get_files ${dcp_dir}/${rpt_prefix}_1.dcp]
		set_property SCOPED_TO_CELLS "${inst_pm2}" [get_files ${dcp_dir}/${rpt_prefix}_2.dcp]
		set_property SCOPED_TO_CELLS "${inst_pm3}" [get_files ${dcp_dir}/${rpt_prefix}_3.dcp]
		set_property SCOPED_TO_CELLS "${inst_pm4}" [get_files ${dcp_dir}/${rpt_prefix}_4.dcp]

		link_design -mode default -reconfig_partitions "${inst_pm4} ${inst_pm3} ${inst_pm2} ${inst_pm1}" -part $device -top $static
		write_checkpoint -force ${dcp_dir}/top_link_design.dcp

		# Design optimization
		opt_design

		# Placement
		place_design

		report_clock_utilization -file ${impl_rpt_dir}/${rpt_prefix}clock_util.rpt

		# Physical design optimization
		phys_opt_design
		
		write_checkpoint -force ${dcp_dir}/${rpt_prefix}place.dcp

		report_utilization -file ${impl_rpt_dir}/${rpt_prefix}post_place_util.rpt
		report_timing_summary -file ${impl_rpt_dir}/${rpt_prefix}post_place_timing.rpt -delay_type max -max_paths 1000

		# routing
		route_design
		write_checkpoint -force ${dcp_dir}/route.dcp

		report_utilization -file ${impl_rpt_dir}/${rpt_prefix}post_route_util.rpt
		report_timing_summary -file ${impl_rpt_dir}/${rpt_prefix}post_route_timing.rpt -delay_type max -max_paths 1000

		report_route_status -file ${impl_rpt_dir}/${rpt_prefix}post_route_status.rpt

		# bitstream generation
		open_checkpoint ${dcp_dir}/route.dcp
		write_bitstream -force  -cell ${inst_pm1} ${out_dir}/system_pr1.bit
		write_bitstream -force  -cell ${inst_pm2} ${out_dir}/system_pr2.bit
		write_bitstream -force  -cell ${inst_pm3} ${out_dir}/system_pr3.bit
		write_bitstream -force  -cell ${inst_pm4} ${out_dir}/system_pr4.bit
		
		if {$act == "bit_gen"} {
			# bitstream generation
			#write_bitstream -force ${out_dir}/system.bit
		}
	}

	# launching simulation
	if {$act == "bhv_sim" || $act == "pst_sim"} { 

		# launch simulation
		set_property runtime ${sim_time}us [get_filesets sim_1]
		set_property xsim.simulate.custom_tcl ${script_dir}/sim/xsim_run.tcl [get_filesets sim_1]

		if {$act == "bhv_sim"} {
			launch_simulation -mode behavioral -simset [get_filesets sim_1] 
		} else {
			launch_simulation -mode post-implementation -type timing -simset [get_filesets sim_1]
		}
	}
	close_project

	if {$act == "sch_gen"} {
		exit
	}

} elseif {$act == "wav_chk"} {

	if {$val != "pst" && $val != "bhv"} {
		puts "Error: Please specify the name of waveform to be opened"
		exit
	}

	current_fileset

	if {$val == "bhv"} {
		set file_name behav
	} else {
		set file_name time_synth
	}

	open_wave_database ${sim_out_dir}/${file_name}.wdb
	open_wave_config ${sim_out_dir}/${file_name}.wcfg

} else {
	puts "Error: No specified actions for Vivado hardware project"
	exit
}

