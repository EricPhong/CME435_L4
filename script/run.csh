#!/bin/csh -f

# This script resides in project/script; DUT in project/dut;
# verification sources in project/verification.
set SCRIPT_DIR = `dirname "$0"`
set SCRIPT_DIR = `cd "$SCRIPT_DIR" && pwd`
set PROJECT_DIR = `cd "$SCRIPT_DIR/.." && pwd`
set VERIF_DIR = "$PROJECT_DIR/verification"
set DUT_DIR = "$PROJECT_DIR/dut"

source /CMC/scripts/siemens.questasim.2022.1_2.csh

set TEST_NAME = "pdm_test_base"
set GUI = 0
while ($#argv > 0)
    switch ("$argv[1]")
        case "-g":
            set GUI = 1
            shift argv
            breaksw
        case "-t":
            if ($#argv < 2) then
                echo "ERROR: -t requires a test name"
                exit 1
            endif
            set TEST_NAME = "$argv[2]"
            shift argv
            shift argv
            breaksw
        default:
            echo "Usage: csh script/run.csh [-g] [-t test_name]"
            exit 1
    endsw
end

cd "$PROJECT_DIR"

if (! -d work) vlib work
if ($status != 0) exit 1

# Use local modelsim.ini
if (! -e "$PROJECT_DIR/modelsim.ini") then
    unsetenv MODELSIM
    vmap -c
    if ($status != 0) exit 1
endif

setenv MODELSIM "$PROJECT_DIR/modelsim.ini"

vmap work work
if ($status != 0) exit 1

# Compile DUT, interface, wrapper, clock, package, and top in order.
vlog -sv -L mtiUvm \
    "+incdir+$VERIF_DIR" \
    "$DUT_DIR/pdm_core.svp" \
    "$DUT_DIR/pdm_top.v" \
    "$VERIF_DIR/pdm_upstream_if.sv" \
    "$VERIF_DIR/pdm_downstream_if.sv" \
    "$VERIF_DIR/pdm_pkg.sv" \
    "$VERIF_DIR/top.sv"
if ($status != 0) exit 1

# Make selected test available to run.do.
setenv TESTNAME "$TEST_NAME"
setenv PDM_GUI "$GUI"
if ($GUI == 1) then
    vsim -L mtiUvm -do "do $SCRIPT_DIR/run.do"
else
    vsim -c -L mtiUvm -do "do $SCRIPT_DIR/run.do"
endif
exit $status
