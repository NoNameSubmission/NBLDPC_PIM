###################################################################

# Created by write_sdc on Thu Nov 17 01:23:51 2022

###################################################################
set sdc_version 2.1

set_units -time ns -resistance kOhm -capacitance pF -voltage V -current mA
create_clock [get_ports CLK]  -name ECC_CLK  -period 20  -waveform {0 10}
set_clock_uncertainty 0.3  [get_clocks ECC_CLK]
