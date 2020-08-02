onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib dpram2048x8_opt

do {wave.do}

view wave
view structure
view signals

do {dpram2048x8.udo}

run -all

quit -force
