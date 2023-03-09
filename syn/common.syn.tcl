# common.tcl setup library files

# 0.13um IBM Artisan Library
# Set library paths
set ARTISAN "/afs/umich.edu/class/eecs627/ibm13/artisan/current/aci/sc-x/synopsys/"
set SYNOPSYS [get_unix_variable SYNOPSYS]
set search_path [list "." $ARTISAN ${SYNOPSYS}/libraries/syn]
set link_library "* typical.db dw_foundation.sldb"
set target_library "typical.db"

# set_dont_use any *XL* cell
set_dont_use { typical/*XLTR }
