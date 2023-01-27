#Baseline Synthesis script
#Visvesh S Sathe
#sathe@uw.edu

# set search path, target lib, link path.
# Specify the libraries, tluplus files, import ddc file.

#Note. Go through these lines below and search online for what they mean.
#L I N E     B Y     L I N E.
#Yes its boring, but you'll only have to do this once if you do it right.


#Target libs are the libraries you use to map generic_lib cells and logical functions into cells. Standard cells are an example of this.

#Search Path:This variable specifies directories that the tool searches for files specified without directory names. The search includes looking for technology and symbol libraries, design files, and so on. The value of this variable is a list of directory names and is usually set to a central library directory.

# Link Libraries: This variable specifies the list of design files and libraries used during linking. The link command looks at the files and tries to resolve references in the order of the specified files. A "*" entry in the value of this variable indicates that the link command is to search all the designs loaded in dc_shell while trying to resolve references. If file names do not include directory names, files are searched for in the directories in search_path. The default is {"*" your_library.db}. Change your_library.db to reflect your library name.

# The Milkyway database consists of libraries that contain information about
# your design. Libraries contains information about design cells, standard cells,
# macro cells, an so on. They contain physical descriptions, such as metal,
# diffusion, and polygon geometries. Libraries also contain logical information
# (functionality and timing characteristics) for every cell in the library.
# Finally, libraries contain technology information required for design and fabrication
# Milkyway provides two types of libraries that you can use: reference Libraries
# and design libraries. Reference libraries contain standard cells and hard or
# soft macro cells, which are typically created by vendors. Reference Libraries
# contain physical inforrmation necessary for design implementation. Physical
# information includes the routing directions and the placement until tile
# implementation. A design library contains a design cell. The design cell might
# contain references.

# CEL is a full layout view, and FRAM is the abstract view for place and route
# and route operation




set TSMCPATH /home/lab.apps/vlsiapps/kits/tsmc/N65RF/1.0c/digital
set TARGETCELLLIB $TSMCPATH/Front_End/timing_power_noise/CCS/tcbn65gplus_200a
set search_path   [concat  $search_path $TARGETCELLLIB ./db  $synopsys_root/libraries/syn]
lappend search_path [glob $TSMCPATH/Back_End/milkyway/tcbn65gplus_200a/cell_frame/tcbn65gplus/LM/*]
set target_library "tcbn65gpluswc0d72_ccs.db tcbn65gplusbc0d88_ccs.db tcbn65gplustc0d8_ccs.db"
set symbol_library tcbn65gplustc0d8_ccs.db
set link_path {"*" tcbn65gpluswc0d72_ccs.db tcbn65gplusbc0d88_ccs.db tcbn65gplustc0d8_ccs.db }

set mw_techfile_path $TSMCPATH/Back_End/milkyway/tcbn65gplus_200a/techfiles
# Technical file: It has the technology description *.tf file
set mw_tech_file $mw_techfile_path/tsmcn65_9lmT2.tf
# Technical library location
set mw_reference_library $TSMCPATH/Back_End/milkyway/tcbn65gplus_200a/frame_only/tcbn65gplus
# dc special command create milkway library - last word is the name of the library
create_mw_lib -technology $mw_tech_file -mw_reference_library $mw_reference_library fpu_design
# open the milkway, by default it is not activated.
open_mw_lib fpu_design

#What is tlu_plus files? Virtual route and post-layout DRC rules with rules - Extraction rules -Parasitic extraction. Vias.
set_tlu_plus_files \
-max_tluplus $mw_techfile_path/tluplus/cln65g+_1p09m+alrdl_rcbest_top2.tluplus \
-min_tluplus $mw_techfile_path/tluplus/cln65g+_1p09m+alrdl_rcworst_top2.tluplus \
-tech2itf_map $mw_techfile_path/tluplus/star.map_9M

#Interconnect technology/ check layer numbers

#################################### fsm #####################################
# Read Design
# read_file will analyze (read,check) and elaborate(GTech map, DW map) the design in one shot.
set RTLPATH ../../src/verilog


read_file $RTLPATH -recursive -autoread -top fpu -format sverilog

#Define environment
set_operating_conditions -analysis_type bc_wc \
-min BC0D88COM -max WC0D72COM  -max_library tcbn65gpluswc0d72_ccs \
-min_library tcbn65gplusbc0d88_ccs

#check the .lib file .db compress
set_min_library tcbn65gpluswc0d72_ccs.db -min_version tcbn65gplusbc0d88_ccs.db

#Loading and drive settings. weakest inverter super weaker - timming contraints based on wc
set_driving_cell -lib_cell INVD1 clk
set_driving_cell -lib_cell INVD1 reset
set_driving_cell -lib_cell INVD1 opA
set_driving_cell -lib_cell INVD1 opB
set_driving_cell -lib_cell INVD1 op

# set_load for outputs what comes after? driving load-telling info about load! BC absolute units too
set_load [load_of tcbn65gpluswc0d72_ccs/INVD1/I] [get_ports result]
set_load [load_of tcbn65gpluswc0d72_ccs/INVD1/I] [get_ports FPUFlags]
set_load [load_of tcbn65gpluswc0d72_ccs/INVD1/I] [get_ports overflow]
set_load [load_of tcbn65gpluswc0d72_ccs/INVD1/I] [get_ports underflow]
set_load [load_of tcbn65gpluswc0d72_ccs/INVD1/I] [get_ports inexact]


#connect referenced library components to the current design
link

#Define design constraints - why 6 in fanout?

set_max_transition 0.4 [get_designs fpu]
set_max_fanout 6 fpu 
create_clock -name "clk" -period 6 -waveform {0 1} [get_ports clk]
set_clock_uncertainty -setup 0.05 [get_clocks]
set_clock_uncertainty -hold 0.01 [get_clocks]
set_clock_transition 0.05 [get_clocks]
set_input_delay 0.1 -clock clk [remove_from_collection [all_inputs] [get_ports clk]]
set_fix_hold {clk}

#multicycle paths
# set in_ports [get_ports [list opA opB]]
# set out_ports [get_ports [list result FPUFlags overflow underflow inexact]]
# set div_ports [get_ports [list divide/opA divide/opB]]
# set_multicycle_path -setup 2 -from $in_ports -through $div_ports -to $out_ports
# set_multicycle_path -hold 1 -from $in_ports -through $div_ports -to $out_ports
set_multicycle_path -setup 2 -through {divide}
set_multicycle_path -hold 1 -through {divide}

#Compile ultra will take care of ungrouping and flattening for improved performance.
set_critical_range 0.1 $current_design
compile_ultra -no_autoungroup
check_design

#write out design files
file mkdir reports
report_power > reports/fpu.power
report_constraint -verbose > reports/fpu.constraint
report_constraint -all_violators > reports/fpu.violation
report_timing -path full -delay max -max_paths 20   -nworst 2 > "reports/timing.max.fullpath.rpt"
report_timing -path full -delay min -max_paths 5   -nworst 2 > "reports/timing.min.fullpath.rpt"
report_timing -path full -through [get_cells divide] > "reports/timing.divide.rpt"
# report_area -hierarchy > "reports/area.rpt"
# 
# write_sdc  reports/fpu.sdc
# file mkdir db
# write -h fpu -output ./db/fpu.db
# write_sdf -context verilog -version 1.0 reports/fpu.sdf
# file mkdir netlist
# write -h -f verilog fpu -output netlist/fpu.v -pg
# file mkdir ddc
# write_file -format ddc -hierarchy -output ddc/DIG_TOP.ddc
# exit
