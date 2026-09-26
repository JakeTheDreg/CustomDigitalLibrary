## clock
set_property PACKAGE_PIN H4 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 20.000 -name sys_clk -waveform {0.0 10.0} [get_ports clk]

## Reset
set_property PACKAGE_PIN D14 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]

set_property IOSTANDARD LVCMOS33 [get_ports -filter {NAME != "clk" && NAME != "rst_n"}]

# Assume ADC drives data synchronous to clk
set_input_delay -clock sys_clk 5 [get_ports adc_data_i[*]]

# Assume downstream samples outputs
set_output_delay -clock sys_clk 5 [get_ports adc_data_o[*]]
set_output_delay -clock sys_clk 5 [get_ports adc_data_valid]