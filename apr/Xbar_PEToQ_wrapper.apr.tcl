###################################
# EECS 627 W22
# Innovus basic script
# Cadence EDI Version 14.1 
###################################

set top_level Xbar_PEToQ_wrapper

#############################################################

proc get_multithread_lic { } {
    setMultiCpuUsage -acquireLicense 4
}

#############################################################

source Xbar_PEToQ_wrapper.globals

#############################################################

proc run_init { } {
    
    global top_level

    init_design    

    clearGlobalNets

    setCteReport

    saveDesign ${top_level}.init.enc
}

#############################################################

proc connect_std_cells_to_power { } {

    globalNetConnect VDD -type tiehi -inst * -verbose
    globalNetConnect VSS -type tielo -inst * -verbose

    globalNetConnect VDD -type pgpin -pin VDD -inst * -verbose
    globalNetConnect VSS -type pgpin -pin VSS -inst * -verbose
}


#############################################################

proc run_floorplan { } { 
    
    global top_level
    
    if {[expr ![dbIsHeadDesignInMemory]]} {
        puts "##############"
        puts "###"
        puts "### RESTORING INIT!!! "
        puts "###"
        puts "##############" 
        restoreDesign "${top_level}.init.enc.dat" ${top_level}
    }
    
    get_multithread_lic

    floorPlan -s 400 1000 10 10 10 10

    loadIoFile ${top_level}.io

    fit

    # Create Power Rings
    addRing -nets {VDD VSS} -type core_rings -layer_top M1 -layer_bottom M1 -layer_right M2 -layer_left M2 \
        -width_top 2 -width_bottom 2 -width_left 2 -width_right 2 -spacing_top 1 -spacing_bottom 1 -spacing_right 1 -spacing_left 1 
    addRing -nets {VDD VSS} -type core_rings -layer_top M3 -layer_bottom M3 -layer_right M4 -layer_left M4 \
        -width_top 2 -width_bottom 2 -width_left 2 -width_right 2 -spacing_top 1 -spacing_bottom 1 -spacing_right 1 -spacing_left 1 
    
    # Add Stripes
    addStripe -direction vertical -nets {VDD VSS}  -break_stripes_at_block_rings 1 -extend_to design_boundary \
        -set_to_set_distance 24.0 -width 1.2 -spacing 10.8 -layer M4 -stacked_via_bottom_layer M3 -stacked_via_top_layer M5 -create_pins 1 -xleft_offset 0
    addStripe -direction horizontal -nets {VDD VSS}  -break_stripes_at_block_rings 1 -extend_to design_boundary \
        -set_to_set_distance 24.0 -width 1.2 -spacing 10.8 -layer M5 -stacked_via_bottom_layer M3 -stacked_via_top_layer M5 -create_pins 1 -xleft_offset 0

    # Macro Placement
    # Specifically, add reset driver in this lab. Feel free to change its placement
    # placeInstance reset_driver_inst 10 10 R0 -fixed
    # addHaloToBlock 2 2 2 2 reset_driver_inst

    # Link Power Nets with Power Pins of std cells
    connect_std_cells_to_power

    # Route the M1 Stripes
    sroute -connect corePin -allowJogging 0 -layerChangeRange {1 2} -crossoverViaTopLayer 2 

    # To-Do: Route Power Pins for the Reset Driver
    # Hint:
		# Step1 - 'globalNetConnect' to link Power Nets with reset driver's power pins
    	# Step2 - 'sroute' to let the tool route reset driver's power pins to existing power rings/stripes 
    # globalNetConnect VDD -type tiehi -inst reset_driver_inst -verbose
    # globalNetConnect VSS -type tielo -inst reset_driver_inst -verbose

    # globalNetConnect VDD -type pgpin -pin VDD -inst reset_driver_inst -verbose
    # globalNetConnect VSS -type pgpin -pin VSS -inst reset_driver_inst -verbose
    # sroute -inst reset_driver_inst -nets {VDD VSS}

    # Save Floorplan
    saveDesign ${top_level}.floorplan.enc
}
    
    
#############################################################

proc run_place { } {
    
    global top_level
    
    if {[expr ![dbIsHeadDesignInMemory]]} {
        puts "##############"
        puts "###"
        puts "### RESTORING FLOORPLAN!!! "
        puts "###"
        puts "##############" 
        restoreDesign "${top_level}.floorplan.enc.dat" ${top_level}
    } 

    puts "####################"
    puts "###"
    puts "### Place Design ..."
    puts "###"
    puts "####################"
    
    get_multithread_lic
    
    # Run Placement
    puts "PLACE ITER 0"
    setTrialRouteMode -highEffort true -ignoreNetIsSpecial false
    setPlaceMode  -timingDriven true -congEffort high 
    placeDesign  -inPlaceOpt

    connect_std_cells_to_power

    puts "PLACE ITER 1"
    placeDesign  -inPlaceOpt -incremental
    
    puts "PLACE ITER 2"
    optDesign -preCTS
    
    saveDesign ${top_level}.place.enc
}

#############################################################

proc run_clock { } {
    
    global top_level
    
    get_multithread_lic
    
    if {[expr ![dbIsHeadDesignInMemory]]} {
        puts "##############"
        puts "###"
        puts "### RESTORING PLACE!!! "
        puts "###"
        puts "##############" 
        restoreDesign "${top_level}.place.enc.dat" ${top_level}
    } 
    
    puts "##############"
    puts "###"
    puts "### Run CTS..."
    puts "###"
    puts "##############"
    
    if {[sizeof_collection [get_clocks -quiet]] == 0} {
        puts "No clocks found... not running CTS."
        return
    }
    
    connect_std_cells_to_power
    
    # Create Clock Tree Spec
    set_ccopt_mode -cts_opt_priority insertion_delay -cts_opt_type full
    set_ccopt_effort -high
    
    create_ccopt_clock_tree_spec -file ${top_level}.cts    

    set_ccopt_property target_insertion_delay 600ps 
    set_ccopt_property target_skew 600ps
    set_ccopt_property source_input_max_trans 10ps 

    
    # Clock Tree Synthesis
    source ${top_level}.cts

    ccopt_design    

    # Post CTS Timing Optimizations
    puts "POSTCTS ITER 0"
    optDesign -postCTS
    
    puts "POSTCTS ITER 1"
    optDesign -postCTS -hold
    
    # Link power pins of any newly added cells to the power nets
    connect_std_cells_to_power
    
    saveDesign ${top_level}.clock.enc  
}


#############################################################


proc run_route { } {
    
    global top_level
    
    get_multithread_lic
    
    if {[expr ![dbIsHeadDesignInMemory]]} {
        puts "##############"
        puts "###"
        puts "### RESTORING CLOCK!!! "
        puts "###"
        puts "##############" 
        restoreDesign "${top_level}.clock.enc.dat" ${top_level}
    } 
    
    puts "################################"
    puts "###"
    puts "### Final Routing   .... "
    puts "###"
    puts "################################"
    
    setNanoRouteMode -quiet -routeWithTimingDriven true
    setNanoRouteMode -quiet -routeSiEffort medium
    setNanoRouteMode -quiet -routeWithSiDriven false
    setNanoRouteMode -quiet -routeWithSiPostRouteFix false
    
    setNanoRouteMode -drouteFixAntenna true
    setNanoRouteMode -drouteAutoStop false
    setNanoRouteMode -routeAntennaCellName "ANTENNATR"
    setNanoRouteMode -routeReplaceFillerCellList "fillercelllist.txt"
    setNanoRouteMode -routeInsertAntennaDiode true
    setNanoRouteMode -drouteSearchAndRepair true 
    
    setNanoRouteMode -quiet -routeWithViaInPin true
    setNanoRouteMode -quiet -drouteOnGridOnly none
    setNanoRouteMode -quiet -droutePostRouteSwapVia false
    setNanoRouteMode -quiet -drouteUseMultiCutViaEffort medium
    setNanoRouteMode -quiet -routeSelectedNetOnly false
    setNanoRouteMode -quiet -routeTopRoutingLayer    6
    setNanoRouteMode -quiet -routeBottomRoutingLayer 1
    
    setAttribute -net @CLOCK -weight 5 -preferred_extra_space 1
    
    routeDesign
    
    # Comment out some of the following post-route optimization iterations if it's taking too much time
    # Typically a simple design like this don't need so many iterations

    # For Innovus
    setDelayCalMode -engine aae -SIAware true
    setAnalysisMode -analysisType onChipVariation -cppr both
    setOptMode -addInst true -addInstancePrefix POSROT

    puts "POSTROUTE ITER 0"
    extractRC
    optDesign -postRoute
    connect_std_cells_to_power
    saveDesign ${top_level}.route_step0.enc
    
    puts "POSTROUTE ITER 1"
    extractRC
    optDesign -postRoute -drv
    connect_std_cells_to_power
    saveDesign ${top_level}.route_step1.enc
    
    puts "POSTROUTE ITER 2"
    extractRC
    optDesign -postRoute -hold
    connect_std_cells_to_power
    saveDesign ${top_level}.route_step2.enc
    
    # puts "POSTROUTE ITER 4"
    # extractRC
    # optDesign -postRoute -drv
    # connect_std_cells_to_power
    # saveDesign ${top_level}.route_step6.enc
    
    # puts "POSTROUTE ITER 5"
    # extractRC
    # optDesign -postRoute -hold
    # connect_std_cells_to_power
    # saveDesign ${top_level}.route_step7.enc
    
    # puts "POSTROUTE ITER 6"
    # extractRC
    # optDesign -postRoute
    # connect_std_cells_to_power
    # saveDesign ${top_level}.route_step8.enc
    
    puts "Multicut via insertion"
    setNanoRouteMode -quiet -routeWithTimingDriven true
    setNanoRouteMode -quiet -routeSiEffort high
    setNanoRouteMode -quiet -routeWithSiDriven true
    setNanoRouteMode -quiet -routeWithSiPostRouteFix true   
    setNanoRouteMode -quiet -droutePostRouteSwapVia multiCut
    detailRoute
    
    connect_std_cells_to_power
    
    saveDesign ${top_level}.route.enc      
}

#############################################################

proc run_final { } {
    
    global top_level
    
    if {[expr ![dbIsHeadDesignInMemory]]} {
        puts "##############"
        puts "###"
        puts "### RESTORING ROUTE!!! "
        puts "###"
        puts "##############" 
        restoreDesign "${top_level}.route.enc.dat" ${top_level}
    } 
    
    # Grab floorplan information
    get_multithread_lic
    
    set floorplan_width  [dbDBUToMicrons [lindex [dbFPlanBox [dbHeadFPlan]] 2]]
    set floorplan_height [dbDBUToMicrons [lindex [dbFPlanBox [dbHeadFPlan]] 3]]
    
    # Add fill cells
    addFiller -cell {FILL64TR FILL32TR FILL16TR FILL8TR FILL4TR FILL2TR FILL1TR} -prefix FILLER
    connect_std_cells_to_power

    # Report timing before metal fill so that sta mode works
    report_timing
        
    # Add metal fill
    set window_size 100

    setMetalFill -layer {1 2 3 4 5} -minDensity 20 -preferredDensity 25 -maxDensity 80 -maxLength 4 -maxWidth 1 -windowSize $window_size $window_size -windowStep $window_size $window_size
    
    for {set i 0} {[expr $i < $floorplan_width]} {set i [expr $i + $window_size]} {
        for {set j 0} {[expr $j < $floorplan_height]} {set j [expr $j + $window_size]} {
            addMetalFill -layer {1 2 3 4 5} -onCells -timingAware sta -area $i $j [expr min($floorplan_width,$i+$window_size)] [expr min($floorplan_height,$j+$window_size)]
        }
    }
    
    trimMetalFill -deleteViols
    
    # Run some checks, not that they matter
    clearDrc
    verifyGeometry -error 1000000 -noRoutingBlkg
    
    verifyConnectivity -type regular -error 1000000 -warning 500000
    verifyProcessAntenna -error 1000000
    
    # Output DEF
    set dbgLefDefOutVersion 5.5
    defOut -floorplan -netlist -routing ${top_level}.apr.def
    
    # Output LEF
    lefout "$top_level.lef" -stripePin -PGpinLayers 1 2 3 4 5 
    
    # Output GDSII
    setStreamOutMode -snapToMGrid true
    streamOut "$top_level.gds" -mapFile /afs/umich.edu/class/eecs627/w23/lab_resource/lab2_Innovus/apr/enc2gdsLM.map -libName ${top_level} -structureName $top_level -stripes 1 -mode ALL
    
    # Output Netlist
    saveNetlist -excludeLeafCell ${top_level}.apr.v
    saveNetlist -excludeLeafCell -lineLength 10000000 -includePowerGround -includePhysicalInst ${top_level}.apr.physical.v
    
    # Generate SDF
    extractRC -outfile ${top_level}.cap
    rcOut -spef ${top_level}.spef
    
    # write_sdf appears broken, but delayCal works.
    write_sdf -version 3.0 -collapse_internal_pins ${top_level}.apr.sdf 
    #delayCal -sdf ${top_level}.apr.sdf -version 3.0
    
    # Save Final Design
    saveDesign ${top_level}.final.enc
}

#############################################################

proc run_main { } {
    
    global top_level
    
    if { ![info exists top_level] } {
        puts "top_level must be provided to common.apr.tcl"
        exit
    }
    
    run_init
    run_floorplan
    run_place
    run_clock
    run_route  
    run_final
}

run_main

puts "**************************************"
puts "*                                    *"
puts "* Innovus script finished            *"
puts "*                                    *"
puts "**************************************"

# comment out the exit if you want innovus to remain open at the end of the run
# exit

#############################################################
