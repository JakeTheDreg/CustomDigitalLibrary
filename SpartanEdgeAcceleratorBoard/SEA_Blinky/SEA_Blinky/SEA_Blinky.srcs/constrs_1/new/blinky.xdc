set_property IOSTANDARD LVCMOS33 [get_ports led]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]
set_property PACKAGE_PIN J1 [get_ports led]
set_property PACKAGE_PIN H4 [get_ports clk]
set_property PACKAGE_PIN C3 [get_ports rst_n]

create_clock -period 10.000 -name clk -waveform {0.000 5.000} [get_ports clk]
