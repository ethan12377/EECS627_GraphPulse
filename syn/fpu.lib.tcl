
set top_level fpu

read_db /afs/umich.edu/class/eecs627/ibm13/artisan/current/aci/sc-x/synopsys/typical.db

create_qtm_model $top_level

set_qtm_technology -library typical

create_qtm_drive_type drive1 -lib_cell CLKBUFX20TR

create_qtm_port opA[15:0] -type input
create_qtm_port opB[15:0] -type input
create_qtm_port op[1:0] -type input
create_qtm_port status_i[1:0] -type input
create_qtm_port clk -type input
create_qtm_port reset -type input

create_qtm_port result[15:0] -type output
create_qtm_port status_o[1:0] -type output
create_qtm_port empty_o -type output

set_qtm_port_load  [get_qtm_ports "op*"] -value 0.01
set_qtm_port_load  [get_qtm_ports "clk"] -value 0.01
set_qtm_port_load  [get_qtm_ports "reset"] -value 0.01
set_qtm_port_load  [get_qtm_ports "status_i*"] -value 0.01

set_qtm_port_drive [get_qtm_ports "result*"] -type drive1
set_qtm_port_drive [get_qtm_ports "status_o*"] -type drive1
set_qtm_port_drive [get_qtm_ports "empty_o*"] -type drive1

save_qtm_model -output $top_level -format {lib db} -library_cell

exec mv ${top_level}_lib.db ${top_level}.db

exit
