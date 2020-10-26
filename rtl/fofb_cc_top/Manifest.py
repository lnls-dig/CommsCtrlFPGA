files = [
    "rtl/vhdl/fofb_cc_fifo_rst.vhd",
    "rtl/vhdl/fofb_cc_puls_exp.vhd",
    "rtl/vhdl/fofb_cc_top.vhd",
]

comms_cc_wrapper_dict = {
    'bpm_wrapper':          "rtl/vhdl/fofb_cc_top_bpm_wrapper.vhd",
    'sniffer_s6_wrapper':   "rtl/vhdl/fofb_cc_top_sniffer_s6_wrapper.vhd",
    'sniffer_v5_wrapper':   "rtl/vhdl/fofb_cc_top_sniffer_v5_wrapper.vhd",
    'sniffer_v6_wrapper':   "rtl/vhdl/fofb_cc_top_sniffer_v6_wrapper.vhd",
}

try:
    if comms_cc_wrapper is not None:
        for p in comms_cc_wrapper:
            f = comms_cc_wrapper_dict.get(p, None)
            assert f is not None, "unknown name {} in 'comms_cc_wrapper'".format(p)
            files.append(f)
except NameError:
    # Do nothing, as nothing needs to be added to the files list
    pass
