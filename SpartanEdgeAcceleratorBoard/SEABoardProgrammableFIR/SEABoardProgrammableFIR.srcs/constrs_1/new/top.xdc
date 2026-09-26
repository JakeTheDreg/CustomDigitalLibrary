## clock
set_property PACKAGE_PIN H4 [get_ports sys_clk]
set_property IOSTANDARD LVCMOS33 [get_ports sys_clk]
create_clock -period 10.000 -name sys_clk -waveform {0.0 5.0} [get_ports sys_clk]
set_input_jitter [get_clocks -of_objects [get_ports sys_clk]] 0.100
# set_property PHASESHIFT_MODE WAVEFORM [get_cells -hierarchical *adv*]

## Reset
set_property PACKAGE_PIN D14 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]

## Set all pins that are NOT sys_clk or rst_n to LVCMOS33
set_property IOSTANDARD LVCMOS33 [get_ports -filter {NAME != "sys_clk" && NAME != "rst_n"}]

## Set package pins for inputs
## set_property PACKAGE_PIN C3 [get_ports enable]
## set_property PACKAGE_PIN J3 [get_ports adc_data[0]]
## set_property PACKAGE_PIN J2 [get_ports adc_data[1]]
## set_property PACKAGE_PIN D12 [get_ports adc_data[2]]
## set_property PACKAGE_PIN E12 [get_ports adc_data[3]]
## set_property PACKAGE_PIN F12 [get_ports adc_data[4]]
## set_property PACKAGE_PIN C11 [get_ports adc_data[5]]
## set_property PACKAGE_PIN H11 [get_ports adc_data[6]]
## set_property PACKAGE_PIN H12 [get_ports adc_data[7]]
## 
## ## Set package pins for outputs
## set_property PACKAGE_PIN J4 [get_ports adc_en_n]
## set_property PACKAGE_PIN C5 [get_ports adc_clk]
## set_property PACKAGE_PIN M1 [get_ports dac_clk]
## set_property PACKAGE_PIN L1 [get_ports dac_data]
## set_property PACKAGE_PIN N1 [get_ports dac_sync_n]
## 
## 
## ## ADC data inputs
## set_input_delay -clock clk_out1_clk_wiz_0 -max 5.0 [get_ports {adc_data[*]}]
## set_input_delay -clock clk_out1_clk_wiz_0 -min 0.0 [get_ports {adc_data[*]}]
## 
## ## Assume simple output delay
## set outputs [get_ports {adc_en_n dac_data dac_sync_n}]
## ## DAC data/control outputs
## set_output_delay -clock clk_out1_clk_wiz_0 -max 2.0 [get_ports {dac_data dac_sync_n adc_en_n}]
## set_output_delay -clock clk_out1_clk_wiz_0 -min 0.0 [get_ports {dac_data dac_sync_n adc_en_n}]