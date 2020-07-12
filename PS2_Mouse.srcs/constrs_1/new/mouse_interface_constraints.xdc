# File Name: mouse_interface_constraints.xdc
# Company: School of Engineering, The University of Edinburgh
# Engineer: Yunfan Jiang (s1886282)
# 
# Create Date: 2020/02/04 10:25:16
# Design Name: Assessment 2 - Microprocessor-based Mouse Interface
# File Name: mouse_interface_constraints.xdc
# Project Name: Digital Systems Laboratory 4
# Target Devices: DIGILENT BASYS 3 ARTIX 7
# Tool Versions: Vivado 2015.2
# Version: 3.0
# Last Edited On: 10 March 2020


# CLK to on-board clock
set_property PACKAGE_PIN W5 [get_ports CLK]
	set_property IOSTANDARD LVCMOS33 [get_ports CLK]

# RESET to the middle button    
set_property PACKAGE_PIN U18 [get_ports RESET]
    set_property IOSTANDARD LVCMOS33 [get_ports RESET]

# CLK_MOUSE to the PS2 clock line    
set_property PACKAGE_PIN C17 [get_ports CLK_MOUSE]
	set_property IOSTANDARD LVCMOS33 [get_ports CLK_MOUSE]
	set_property PULLUP true [get_ports CLK_MOUSE]

# DATA_MOUSE to the PS2 data line
set_property PACKAGE_PIN B17 [get_ports DATA_MOUSE]
    set_property IOSTANDARD LVCMOS33 [get_ports DATA_MOUSE]
    set_property PULLUP true [get_ports DATA_MOUSE]
    
# SEG_SELECT to anodes
set_property PACKAGE_PIN U2 [get_ports {SEG_SELECT[0]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {SEG_SELECT[0]}]

set_property PACKAGE_PIN U4 [get_ports {SEG_SELECT[1]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {SEG_SELECT[1]}]

set_property PACKAGE_PIN V4 [get_ports {SEG_SELECT[2]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {SEG_SELECT[2]}]

set_property PACKAGE_PIN W4 [get_ports {SEG_SELECT[3]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {SEG_SELECT[3]}]
    
# DEC_OUT to cathodes
set_property PACKAGE_PIN W7 [get_ports {DEC_OUT[0]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {DEC_OUT[0]}]

set_property PACKAGE_PIN W6 [get_ports {DEC_OUT[1]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {DEC_OUT[1]}]

set_property PACKAGE_PIN U8 [get_ports {DEC_OUT[2]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {DEC_OUT[2]}]

set_property PACKAGE_PIN V8 [get_ports {DEC_OUT[3]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {DEC_OUT[3]}]

set_property PACKAGE_PIN U5 [get_ports {DEC_OUT[4]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {DEC_OUT[4]}]

set_property PACKAGE_PIN V5 [get_ports {DEC_OUT[5]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {DEC_OUT[5]}]

set_property PACKAGE_PIN U7 [get_ports {DEC_OUT[6]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {DEC_OUT[6]}]

set_property PACKAGE_PIN V7 [get_ports {DEC_OUT[7]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {DEC_OUT[7]}]
	
# LED_OUT to LEDs
set_property PACKAGE_PIN L1 [get_ports {LED_OUT[0]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {LED_OUT[0]}]

set_property PACKAGE_PIN U16 [get_ports {LED_OUT[1]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {LED_OUT[1]}]

set_property PACKAGE_PIN W18 [get_ports {LED_OUT[2]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {LED_OUT[2]}]

set_property PACKAGE_PIN U15 [get_ports {LED_OUT[3]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {LED_OUT[3]}]

set_property PACKAGE_PIN U14 [get_ports {LED_OUT[4]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {LED_OUT[4]}]

set_property PACKAGE_PIN V14 [get_ports {LED_OUT[5]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {LED_OUT[5]}]

set_property PACKAGE_PIN V13 [get_ports {LED_OUT[6]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {LED_OUT[6]}]

set_property PACKAGE_PIN V3 [get_ports {LED_OUT[7]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {LED_OUT[7]}]

set_property PACKAGE_PIN W3 [get_ports {LED_OUT[8]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {LED_OUT[8]}]

set_property PACKAGE_PIN U3 [get_ports {LED_OUT[9]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {LED_OUT[9]}]
	
# PRIMARY_BUTTON to slide switch
set_property PACKAGE_PIN V17 [get_ports PRIMARY_BUTTON]
    set_property IOSTANDARD LVCMOS33 [get_ports PRIMARY_BUTTON]
	
# SPEED to slide switch
set_property PACKAGE_PIN R2 [get_ports SPEED]
    set_property IOSTANDARD LVCMOS33 [get_ports SPEED]