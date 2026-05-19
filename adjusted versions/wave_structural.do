# State encoding reference:
#   0 (0000) = LOAD      fetch instruction into IR
#   1 (0001) = INCR      increment PC
#   2 (0010) = DECODE    decode opcode, evaluate branch condition
#   3 (0011) = ALU_EXEC  execute ADD or SUB
#   4 (0100) = MEM       LDA (read RAM into ACC) or STO (write ACC to RAM)
#   5 (0101) = JUMP      load branch target into PC
#   6 (0110) = HALT      STP reached, self-loop

onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -noupdate                              /microproc_str_tb/clk
add wave -noupdate                              /microproc_str_tb/reset

add wave -noupdate -divider "FSM"
add wave -noupdate                              /microproc_str_tb/DUT/mach/state
add wave -noupdate                              /microproc_str_tb/DUT/mach/next_state

add wave -noupdate -divider "Registers"
add wave -noupdate -radix unsigned              /microproc_str_tb/DUT/s1
add wave -noupdate -radix hexadecimal           /microproc_str_tb/DUT/opcod
add wave -noupdate -radix hexadecimal           /microproc_str_tb/DUT/a
add wave -noupdate -radix hexadecimal           /microproc_str_tb/DUT/s

add wave -noupdate -divider "Bus"
add wave -noupdate -radix unsigned              /microproc_str_tb/DUT/adresse
add wave -noupdate -radix hexadecimal           /microproc_str_tb/DUT/data
add wave -noupdate -radix hexadecimal           /microproc_str_tb/DUT/b
add wave -noupdate -radix binary                /microproc_str_tb/DUT/aluf

add wave -noupdate -divider "Control signals"
add wave -noupdate                              /microproc_str_tb/DUT/selA
add wave -noupdate                              /microproc_str_tb/DUT/selB
add wave -noupdate                              /microproc_str_tb/DUT/ir_ld
add wave -noupdate                              /microproc_str_tb/DUT/pc_ld
add wave -noupdate                              /microproc_str_tb/DUT/acc_ld
add wave -noupdate                              /microproc_str_tb/DUT/acc_oe
add wave -noupdate                              /microproc_str_tb/DUT/RnW
add wave -noupdate                              /microproc_str_tb/DUT/we

add wave -noupdate -divider "Status flags"
add wave -noupdate                              /microproc_str_tb/DUT/accz
add wave -noupdate                              /microproc_str_tb/DUT/acc15

TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {30000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 300
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
