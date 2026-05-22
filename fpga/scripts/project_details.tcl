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
}

set sv_files {
    ../rtl/vga/vga_pkg.sv
    ../rtl/vga/vga_if.sv
    ../rtl/vga/vga_timing.sv
    ../rtl/render/draw_bg.sv
    ../rtl/render/ui_renderer.sv
    ../rtl/render/face_renderer.sv
    ../rtl/mouse/draw_mouse.sv
    ../rtl/top/top_vga.sv
    rtl/top_vga_basys3.sv
}

set mem_files {
    ../rtl/assets/faces/head_shape.dat
    ../rtl/assets/faces/glasses_2.dat
    ../rtl/assets/faces/hair_1_1.dat
    ../rtl/assets/faces/hair_long_1.dat
    ../rtl/assets/faces/payot.dat
}

set verilog_files {
    rtl/clk_wiz_0_clk_wiz.v
    rtl/clk_wiz_0.v
}

set vhdl_files {
   ../rtl/mouse/Ps2Interface.vhd
   ../rtl/mouse/MouseCtl.vhd
   ../rtl/mouse/MouseDisplay.vhd
}
