# Run modelsim on command line with -c flag
CMDLINE = false

# FPGA Device
FPGA = spartan6

PATH := /dls_sw/apps/FPGA/Questa/10.2/questasim/bin/:$(PATH)
#PATH := /dls_sw/apps/FPGA/Questa/6.6c/questasim/bin/:$(PATH)

# Virtex 2Pro support was dropped starting from ISE 11.1.
# Therefore we will need ISE 10.1.
ifneq ($(FPGA),virtex2pro)
	export XILINX = /dls_sw/apps/FPGA/Xilinx/14.7/ISE_DS/ISE
else
	export XILINX = /dls_sw/apps/FPGA/Xilinx/10.1/ISE/
	export LMC_HOME = /dls_sw/apps/FPGA/Xilinx/10.1/ISE/smartmodel/lin/installed_lin
endif

ifeq ($(CMDLINE),true)
	CMD_FLAG=-c
	DOFILE=-do "run -all"
else
	CMD_FLAG=
	DOFILE=-do vsim.do
endif

main: all

xilinx:

worklib:
	vlib work

workmap:
	vmap work

compile:
	vcom -work work -f compile_common.f
	vcom -work work -f compile_$(FPGA).f
	vcom -work work ../../../rtl/fofb_cc_rx_fifo/coregen/$(FPGA)/fofb_cc_rx_fifo.vhd
	vcom -work work ../../../rtl/fofb_cc_tx_fifo/coregen/$(FPGA)/fofb_cc_tx_fifo.vhd
	vcom -work work ../../../rtl/fofb_cc_top/rtl/vhdl/fofb_cc_top.vhd
	vcom -work work -f compile_tb.f

sim:
	vsim $(CMD_FLAG) -t 1ps -novopt -L work -L secureip -L unisims_ver $(DOFILE) work.fofb_cc_top_tb

all: clean worklib workmap compile sim


clean:
	rm -rf work transcript vsim.wlf *.dat *.vcd
