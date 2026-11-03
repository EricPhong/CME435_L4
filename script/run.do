# Invoked by script/run.csh after compilation.
# TESTNAME is provided by -t; default allows manual invocation.
if {[info exists env(TESTNAME)] && $env(TESTNAME) ne ""} {
    set TESTNAME $env(TESTNAME)
} else {
    set TESTNAME "pdm_test_base"
}

# Load the compiled DUT/UVM test and pass the standard UVM plusarg.
vsim -L mtiUvm work.top +UVM_TESTNAME=$TESTNAME +UVM_NO_RELNOTES
if {[info exists env(PDM_GUI)] && $env(PDM_GUI) eq "1"} {
    add wave -r sim:/top/*
}
run -all
if {![info exists env(PDM_GUI)] || $env(PDM_GUI) ne "1"} {
    quit -f
}


