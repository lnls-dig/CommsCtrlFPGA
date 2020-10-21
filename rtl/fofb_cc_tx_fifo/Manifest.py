files = [
    "rtl/vhdl/fofb_cc_tx_buffer.vhd"
]

if (target == "xilinx" and syn_device[0:4].upper()=="XC6V"):
    files.extend(["coregen/virtex6/fofb_cc_tx_fifo.vhd"]);
elif (target == "xilinx" and syn_device[0:4].upper()=="XC5V"):
    files.extend(["coregen/virtex5/fofb_cc_tx_fifo.vhd"]);
elif (target == "xilinx" and syn_device[0:4].upper()=="XC6S"):
    files.extend(["coregen/spartan6/fofb_cc_tx_fifo.vhd"]);
elif (target == "xilinx" and syn_device[0:4].upper()=="XC2V"):
    files.extend(["coregen/virtex2pro/fofb_cc_tx_fifo.vhd"]);
elif (target == "xilinx" and syn_device[0:4].upper()=="XC7A"):
    files.extend(["coregen/artix7/fofb_cc_tx_fifo.vhd"]);
else:
    import sys
    sys.exit("ERROR: fofb_cc_tx_fifo: Target/Device not supported: {}/{}".format(target, syn_device))
