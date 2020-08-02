onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib sawtooth_opt

do {wave.do}

view wave
view structure
view signals

do {sawtooth.udo}

run -all

quit -force
