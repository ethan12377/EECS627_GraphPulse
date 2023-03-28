#!/bin/csh -f

cd /home/ganrunxu/eecs627/EECS627_GraphPulse/verilog

#This ENV is used to avoid overriding current script in next vcselab run 
setenv SNPS_VCSELAB_SCRIPT_NO_OVERRIDE  1

/usr/caen/vcs-2020.12-SP2-1/linux64/bin/vcselab $* \
    -o \
    sim_synth \
    -nobanner \
    +vcs+lic+wait \

cd -

