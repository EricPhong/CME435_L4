# Group bus interfaces in the wave window
add wave -group "Upstream Interface" sim:/top/u_if/*
add wave -group "DUT Core"           sim:/top/dut/*
add wave -group "Downstream Port 1"  sim:/top/d_if0/*
add wave -group "Downstream Port 2"  sim:/top/d_if1/*
add wave -group "Downstream Port 3"  sim:/top/d_if2/*
add wave -group "Downstream Port 4"  sim:/top/d_if3/*

# Formatting
configure wave -namecolwidth 220
configure wave -valuecolwidth 100
configure wave -timelineunits ns
wave zoom full