onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -noupdate                              /microproc_tb/clk
add wave -noupdate                              /microproc_tb/reset

add wave -noupdate -divider "FSM"
add wave -noupdate                              /microproc_tb/DUT/mach/state

add wave -noupdate -divider "Registers"
add wave -noupdate -radix unsigned              /microproc_tb/DUT/s1
add wave -noupdate -radix hexadecimal           /microproc_tb/DUT/opcod
add wave -noupdate -radix hexadecimal           /microproc_tb/DUT/a
add wave -noupdate -radix hexadecimal           /microproc_tb/DUT/s

add wave -noupdate -divider "Bus"
add wave -noupdate -radix unsigned              /microproc_tb/DUT/adresse
add wave -noupdate -radix hexadecimal           /microproc_tb/DUT/data
add wave -noupdate -radix hexadecimal           /microproc_tb/DUT/b
add wave -noupdate -radix binary                /microproc_tb/DUT/aluf

add wave -noupdate -divider "Control signals"
add wave -noupdate                              /microproc_tb/DUT/selA
add wave -noupdate                              /microproc_tb/DUT/selB
add wave -noupdate                              /microproc_tb/DUT/ir_ld
add wave -noupdate                              /microproc_tb/DUT/pc_ld
add wave -noupdate                              /microproc_tb/DUT/acc_ld
add wave -noupdate                              /microproc_tb/DUT/acc_oe
add wave -noupdate                              /microproc_tb/DUT/RnW
add wave -noupdate                              /microproc_tb/DUT/we

add wave -noupdate -divider "Status flags"
add wave -noupdate                              /microproc_tb/DUT/accz
add wave -noupdate                              /microproc_tb/DUT/acc15

TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {30000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 280
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {1600000 ps}
