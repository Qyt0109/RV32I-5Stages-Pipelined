# Entity: regs 

- **File**: regs.sv
## Diagram

![Diagram](regs.svg "Diagram")
## Description

 The base registers in RISC-V include 32 general-purpose registers (x0-x31). These registers are used for various operations
 like arithmetic, logical, address calculations, and holding temporary data. Register x0 is hardwired to zero.
 
![alt text](wavedrom_DWjQ0.svg "title") 

 
![alt text](wavedrom_Xef91.svg "title") 


## Ports

| Port name   | Direction | Type   | Description                                |
| ----------- | --------- | ------ | ------------------------------------------ |
| clk         | input     |        | positive edge triggered system clock       |
| rst         | input     |        | asynchronous reset                         |
| rs_rd_en    | input     |        | source registers read enable               |
| rs1         | input     | [4:0]  | source register 1 address                  |
| rs2         | input     | [4:0]  | source register 2 address                  |
| rd          | input     | [ 4:0] | destination register address               |
| rd_wr_data  | input     | [31:0] | data to be written to destination register |
| rd_wr_en    | input     |        | destination register write enable          |
| rs1_rd_data | output    | [31:0] | source register 1 value                    |
| rs2_rd_data | output    | [31:0] | source register 2 value                    |
## Signals

| Name       | Type       | Description                                         |
| ---------- | ---------- | --------------------------------------------------- |
| x          | reg [31:0] | regs from x1 to x31 (x0 is hard-wired with 0 value) |
| r_rs1      | reg [4:0]  | registered rs1                                      |
| r_rs2      | reg [4:0]  | registered rs2                                      |
| need_write | wire       | only need to write if not try to write to x0 (zero) |
## Processes
- sync_read_process: ( @(posedge clk, posedge rst) )
  - **Type:** always
  - **Description**
  syn read with clk 
- sync_write_process: ( @(posedge clk, posedge rst) )
  - **Type:** always
  - **Description**
  syn write with clk and only write if Stage 5 ([writeback](../../hw/rtl/writeback.sv)) is preivously enable. 
