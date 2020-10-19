DOFILE=-do vsim.do

main: all

xilinx:

worklib:
	vlib work

workmap:
	vmap work

compile:
	vcom -work work -f compile.f

sim:
	vsim +notimingchecks -L work -L secureip -L unisims_ver $(DOFILE) work.fofb_cc_gtx_crc32_tb

all: clean worklib workmap compile sim

clean:
	rm -rf work transcript vsim.wlf *.dat *.vcd
