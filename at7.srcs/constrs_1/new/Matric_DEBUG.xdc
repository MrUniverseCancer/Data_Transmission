# set_property IOSTANDARD LVTTL [get_ports clk]
# set_property PACKAGE_PIN M21 [get_ports clk]
# # create_clock -period 20.000 -name clk -waveform {0.000 10.000} [get_ports clk]


# set_property IOSTANDARD LVTTL [get_ports rst_n]
# set_property PACKAGE_PIN M24 [get_ports rst_n]
set_property IOSTANDARD LVTTL [get_ports clk]
set_property PACKAGE_PIN N11 [get_ports clk]
create_clock -period 20.000 -name clk -waveform {0.000 10.000} [get_ports clk]

set_property IOSTANDARD LVTTL [get_ports rst_n]
set_property PACKAGE_PIN T2 [get_ports rst_n]


# set_property IOSTANDARD LVTTL [get_ports {o_uart_tx}]
# set_property PACKAGE_PIN K12 [get_ports {o_uart_tx}]
set_property IOSTANDARD LVTTL [get_ports {o_uart_tx}]
set_property PACKAGE_PIN E3 [get_ports {o_uart_tx}]

set_property IOSTANDARD LVTTL [get_ports {i_start_matrix}]
set_property PACKAGE_PIN M2 [get_ports {i_start_matrix}]

set_property IOSTANDARD LVTTL [get_ports {led}]
set_property PACKAGE_PIN M1 [get_ports {led}]
# set_property PACKAGE_PIN R1 [get_ports rst_n]
# set_property IOSTANDARD LVCMOS33 [get_ports rst_n]
# set_property PACKAGE_PIN P5 [get_ports clk]
# set_property IOSTANDARD LVCMOS33 [get_ports clk]
# set_property IOSTANDARD LVTTL [get_ports {o_data_35t_75t[0]}]
# set_property PACKAGE_PIN M20 [get_ports {o_data_35t_75t[0]}]
# set_property IOSTANDARD LVTTL [get_ports {o_data_35t_75t[1]}]
# set_property PACKAGE_PIN M22 [get_ports {o_data_35t_75t[1]}]

# adc
# usb30
# others
# gpio