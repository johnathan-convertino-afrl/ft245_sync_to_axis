# Synchronus FT245 to AXI streaming converter
### FT245 to AXIS !!!WARNING!!! WORK IN PROGRESS NOT TESTED IN HARDWARE, SIM IS INCOMPLETE.

![image](docs/manual/img/AFRL.png)

---

  author: Jay Convertino   
  
  date: 2022.08.09  
  
  details: Convert FT245 data stream to axis or axis to FT245, priority to FT245 read.   
  
  license: MIT   
   
  Actions:  

  [![Lint Status](../../actions/workflows/lint.yml/badge.svg)](../../actions)  
  [![Manual Status](../../actions/workflows/manual.yml/badge.svg)](../../actions)  
  
---

### Version
#### Current
  - V0.0.0 - initial release

#### Previous
  - none

### DOCUMENTATION
  For detailed usage information, please navigate to one of the following sources. They are the same, just in a different format.

  - [ft245_sync_to_axis.pdf](docs/manual/ft245_sync_to_axis.pdf)
  - [github page](https://johnathan-convertino-afrl.github.io/ft245_sync_to_axis/)

### PARAMETERS

* BUS_WIDTH : DEFAULT : 1 : Width of the bus for axis and FT245.

### COMPONENTS
#### SRC

* ft245_sync_to_axis.v
  
#### TB

* tb_axis.v

### FUSESOC

* fusesoc_info.core created.
* Simulation uses icarus to run data through the core.

#### Targets

* RUN WITH: (fusesoc run --target=sim VENDER:CORE:NAME:VERSION)
  - default (for IP integration builds)
  - lint
  - sim
