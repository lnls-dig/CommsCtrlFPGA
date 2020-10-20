def __dirs():
    dirs = [
              "fofb_cc_arbmux",
              "fofb_cc_cfg_if",
              "fofb_cc_clk_if",
              "fofb_cc_dpbram",
              "fofb_cc_fa_if",
              "fofb_cc_fod",
              "fofb_cc_frame_cntrl",
              "fofb_cc_pkg",
              "fofb_cc_rx_fifo",
              "fofb_cc_sync",
              "fofb_cc_top",
              "fofb_cc_tx_fifo",
            ]

    # Select MGT implementation based on FPGA family
    if (target == "xilinx" and syn_device[0:4].upper()=="XC6V"):
        dirs.extend(["fofb_cc_gtx_if"]);
    elif (target == "xilinx" and syn_device[0:4].upper()=="XC5V"):
        dirs.extend(["fofb_cc_gtp_if"]);
    elif (target == "xilinx" and syn_device[0:4].upper()=="XC6S"):
        dirs.extend(["fofb_cc_gtpa_if"]);
    elif (target == "xilinx" and syn_device[0:4].upper()=="XC2V"):
        dirs.extend(["fofb_cc_mgt_if"]);
    else:
        import sys
        sys.exit("ERROR: MGT: Target/Device not supported: {}/{}".format(target, syn_device))

    return dirs

modules = {
    "local" : __dirs()
}
