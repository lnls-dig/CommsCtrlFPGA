if [file exists work] {
    vdel -all -lib work
}

vlib work
vmap work

vcom -work work -f compile_common.f
vcom -work work -f compile_spartan6.f
vcom -work work ../../../rtl/fofb_cc_rx_fifo/coregen/spartan6/fofb_cc_rx_fifo.vhd
vcom -work work ../../../rtl/fofb_cc_tx_fifo/coregen/spartan6/fofb_cc_tx_fifo.vhd
vcom -work work ../../../rtl/fofb_cc_top/rtl/vhdl/fofb_cc_top.vhd
vcom -work work -f compile_tb.f

vsim +notimingchecks -novopt -L secureip -L unisim -t ps  -do vsim.do work.fofb_cc_top_tb

