# Copyright (C) 2025  AGH University of Science and Technology
# MTM UEC2
# Author: Piotr Kaczmarczyk
#
# Description:
# Project details required for generate_bitstream.tcl.

#-----------------------------------------------------#
#                   Project details                   #
#-----------------------------------------------------#
set project_name vga_project
set top_module top_vga_basys3
set target xc7a35tcpg236-1

#-----------------------------------------------------#
#                    Design sources                   #
#-----------------------------------------------------#
set xdc_files {
    constraints/top_vga_basys3.xdc
    constraints/clk_wiz_0.xdc
    constraints/clk_wiz_0_late.xdc
}

set sv_files {
    ../rtl/vga_pkg.sv
    ../rtl/vga_if.sv
    ../rtl/vga_timing.sv
    ../rtl/draw_bg.sv
    ../rtl/image_rom.sv
    ../rtl/draw_rect_ctl.sv
    ../rtl/draw_rect.sv
    ../rtl/draw_mouse.sv
    ../rtl/top_vga.sv
    rtl/top_vga_basys3.sv
}

set verilog_files {
    ../rtl/clk_wiz_0_clk_wiz.v
    ../rtl/clk_wiz_0.v
}

set vhdl_files {
   ../rtl/Ps2Interface.vhd
   ../rtl/MouseCtl.vhd
   ../rtl/MouseDisplay.vhd
}

set mem_files {
    ../rtl/rect/image_rom.data
}
