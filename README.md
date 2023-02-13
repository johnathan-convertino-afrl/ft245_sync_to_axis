# Synchronus FT245 to AXI streaming converter
## FT245 to AXIS
---

   author: Jay Convertino   
   
   date: 2022.08.09  
   
   details: Convert FT245 data stream to axis or axis to FT245, priority to FT245 read.   
   
   license: MIT   
   
---

![rtl_img](./rtl.png)

### Dependencies 
#### Simulation
  - AFRL:simulation:axis_stimulator

### IP USAGE
#### INSTRUCTIONS

Untested in hardware, simulation needs work.

#### PARAMETERS

* BUS_WIDTH : DEFAULT : 1 : Width of the bus for axis and FT245.

### COMPONENTS
#### SRC

* ft245_sync_to_axis.v
  
#### TB

* tb_axis.v
* in.bin

### fusesoc

* fusesoc_info.core created.
* Simulation uses icarus to run data through the core.
