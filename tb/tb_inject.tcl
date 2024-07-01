// Copyright 2024 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Description: Testbench for --force command in questa vsim

# Set working library.
set LIB work

# If a simulation is loaded, quit it so that it compiles in a clean working library.
set STATUS [runStatus]
if {$STATUS ne "nodesign"} {
    quit -sim
}

# Start with a clean working library.
if { [file exists $LIB] == 1} {
    echo "lib exist"
    file delete -force -- $LIB
}
vlib $LIB

# Compile testbench
vlog +cover -sv -work ${LIB} tb_inject.sv

# Set simulation args
set VOPT_ARG "+acc"
echo $VOPT_ARG
set DB_SW "-debugdb"

vsim -voptargs=$VOPT_ARG $DB_SW -pedanticerrors -lib $LIB tb_inject

add wave -r sim:/*

# Define the procedure to force signals
proc force_signals {} {
    set inject_val [examine -radix binary /tb_inject/signal_inject]
    echo $inject_val
    # force -freeze /tb_inject/signal_q 2#$inject_val -cancel 10ns
    force -deposit /tb_inject/signal_q 2#$inject_val
}

# Notes: Deposit works as expected, intermediate overwrites it
# Freeze does not get unforced at the end!

# Monitor inject_q and trigger the procedure on rising edge
when -label force_on_inject_q {sim:/tb_inject/inject_q == 1} {
    force_signals
}

run -a
