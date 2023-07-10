vlib work 
vlog spimaster.v
vsim spimaster

log {/*}
add wave {/*}


force {CLOCK_50} 0,1 10ns -r 20ns
force {enable} 1
force {scltrig} 0 

force {reset_n} 0
run 25ns 

force {reset_n} 1
run 25ns

force {ldData} 0
run 25ns

force {ldData} 1
run 25ns 

force {ldData} 0
run 25ns 

force {scltrig} 1
force {shift} 1
run 250ns

force {scltrig} 0
run 100ns

force {shift} 1


run 1000ns
