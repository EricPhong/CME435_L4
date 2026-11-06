# Invoked by script/run.csh after compilation.
# 1. Check Tcl variable first, then shell environment variable, then fallback
if {[info exists TESTNAME] && $TESTNAME ne ""} {
    # Taken from Tcl command-line 'set TESTNAME ...'
} elseif {[info exists env(TESTNAME)] && $env(TESTNAME) ne ""} {
    set TESTNAME $env(TESTNAME)
} else {
    set TESTNAME "pdm_test_base"
}

echo "=========================================================="
echo "  RUN.DO: Launching UVM test: $TESTNAME"
echo "=========================================================="

# 2. Load the compiled DUT/UVM test and pass the standard UVM plusarg
vsim -L mtiUvm work.top +UVM_TESTNAME=$TESTNAME +UVM_NO_RELNOTES

# 3. Add waves if GUI mode was requested
if {[info exists env(PDM_GUI)] && $env(PDM_GUI) eq "1"} {
    add wave -r sim:/top/*
}

run -all

# 4. Exit if running in batch mode
if {![info exists env(PDM_GUI)] || $env(PDM_GUI) ne "1"} {
    quit -f
}