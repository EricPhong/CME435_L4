
#!/bin/csh -f

# =========================================================
# Directory Setup (Run from any directory)
# Script resides in project/script; DUT in project/dut;
# Verification sources in project/verification.
# =========================================================
set SCRIPT_DIR = `dirname "$0"`
set SCRIPT_DIR = `cd "$SCRIPT_DIR" && pwd`
set PROJECT_DIR = `cd "$SCRIPT_DIR/.." && pwd`
set VERIF_DIR = "$PROJECT_DIR/verification"
set DUT_DIR = "$PROJECT_DIR/dut"

# Sourcing the required Siemens QuestaSim script
source /CMC/scripts/siemens.questasim.2022.1_2.csh

# =========================================================
# Command Line Arguments Handling (Using if-else)
# =========================================================
set TEST_NAME = "pdm_test_base"
set GUI = 0

while ( $#argv > 0 )
    # 1. Clean up project directory
    if ( "$argv[1]" == "-c" ) then
        cd "$PROJECT_DIR"
        echo "Cleaning up project directory..."
        touch dummy.wlf dummy.mpf dummy.f
        rm -rf work transcript *.wlf *.mpf modelsim.ini dummy.wlf dummy.mpf dummy.f
        echo "Clean complete."
        exit 0

    # 2. Package directory for submission
    else if ( "$argv[1]" == "-z" ) then
        cd "$PROJECT_DIR"
        set zip_name = "lab_submission.zip"
        echo "Zipping project directory to $zip_name..."
        if ( -f "$zip_name" ) rm -f "$zip_name"
        zip -r "$zip_name" . -x "work/*" "*.wlf" "transcript"
        echo "Zip complete."
        exit 0

    # 3. Explicit Batch Mode
    else if ( "$argv[1]" == "-b" ) then
        echo "Batch mode selected."
        set GUI = 0
        shift argv

    # 4. GUI Mode
    else if ( "$argv[1]" == "-g" ) then
        echo "GUI mode selected."
        set GUI = 1
        shift argv

    # 5. UVM Test Selection
    else if ( "$argv[1]" == "-t" ) then
        if ( $#argv < 2 ) then
            echo "ERROR: -t requires a test name"
            echo "Usage: csh script/run.csh [-c] [-z] [-b] [-g] [-t test_name]"
            exit 1
        endif
        set TEST_NAME = "$argv[2]"
        echo "UVM Test selected: $TEST_NAME"
        shift argv
        shift argv

    # Default / Unknown option
    else
        echo "Error: Unknown argument '$argv[1]'"
        echo "Usage: csh script/run.csh [-c] [-z] [-b] [-g] [-t test_name]"
        exit 1
    endif
end

# Navigate to project root before library creation & compilation
cd "$PROJECT_DIR"

# =========================================================
# Library Setup (Avoiding vlib warnings)
# =========================================================
if ( ! -d work ) then
    echo "Creating work library..."
    vlib work
    if ( $status != 0 ) exit 1
else
    echo "Directory 'work' already exists. Skipping vlib..."
endif

# Use local modelsim.ini
if ( ! -e "$PROJECT_DIR/modelsim.ini" ) then
    unsetenv MODELSIM
    vmap -c
    if ( $status != 0 ) exit 1
endif

setenv MODELSIM "$PROJECT_DIR/modelsim.ini"

vmap work work
if ( $status != 0 ) exit 1

# =========================================================
# Compilation
# =========================================================
echo "Compiling design and testbench files..."
vlog -sv -L mtiUvm \
    "+incdir+$VERIF_DIR" \
    "$DUT_DIR/pdm_core.svp" \
    "$DUT_DIR/pdm_top.v" \
    "$VERIF_DIR/pdm_upstream_if.sv" \
    "$VERIF_DIR/pdm_downstream_if.sv" \
    "$VERIF_DIR/pdm_pkg.sv" \
    "$VERIF_DIR/top.sv"
if ( $status != 0 ) exit 1

# =========================================================
# Start Simulation
# =========================================================
set wlf_file = "waves.wlf"
setenv TESTNAME "$TEST_NAME"
setenv PDM_GUI "$GUI"

if ( $GUI == 1 ) then
    echo "Starting Questa Simulator in GUI mode for test: $TEST_NAME..."
    vsim -L mtiUvm -wlf "$wlf_file" -do "do $SCRIPT_DIR/run.do"
else
    echo "Starting Questa Simulator in BATCH mode for test: $TEST_NAME..."
    vsim -c -L mtiUvm -wlf "$wlf_file" -do "do $SCRIPT_DIR/run.do"
endif

exit $status
# eof