`define ZERO_REG_ADDR 0
`define ZERO_REG_DATA 0

module regs (
    input clk,
    input rst,

    input       rs_rd_en,  // source registers read enable
    input [4:0] rs1,       // source register 1 address
    input [4:0] rs2,       // source register 2 address

    // region control by [STAGE 5 WRITEBACK]
    input [ 4:0] rd,          // destination register address
    input [31:0] rd_wr_data,  // data to be written to destination register
    input        rd_wr_en,    // destination register write enable
    // endregion control by [STAGE 5 WRITEBACK]

    output [31:0] rs1_rd_data,  // source register 1 value
    output [31:0] rs2_rd_data   // source register 2 value
);

  reg [31:0] x[1:31];  // regs from x1 to x31 (x0 is hard-wired with 0 value)

  // region read from x
  reg [4:0] r_rs1;  // registered rs1
  reg [4:0] r_rs2;  // registered rs2

  // syn read with clk
  always @(posedge clk, posedge rst) begin : sync_read_process
    if (rst) begin
      r_rs1 <= 0;
      r_rs2 <= 0;
    end else begin
      // only read the register if [STAGE 2 DECODE] is enabled
      if (rs_rd_en) begin
        r_rs1 <= rs1;  // update r_rs1 so the rs1_rdata = x[r_rs1] will also be updated
        r_rs2 <= rs2;  // update r_rs2 so the rs2_rdata = x[r_rs2] will also be updated
      end
    end
  end

  // if read from x0, return 0 else return x[rs]
  assign rs1_rd_data = (r_rs1 == `ZERO_REG_ADDR) ? `ZERO_REG_DATA : x[r_rs1];
  assign rs2_rd_data = (r_rs2 == `ZERO_REG_ADDR) ? `ZERO_REG_DATA : x[r_rs2];
  // endregion read from x

  // region write to x
  // only need to write if not try to write to x0 (zero)
  wire need_write = rd_wr_en && (rd != `ZERO_REG_ADDR);

  // syn write with clk and only write if [Stage 5] (Writeback) is preivously enable.
  integer i;
  always @(posedge clk, posedge rst) begin : sync_write_process
    if (rst) begin
      // reset x
      for (i = 1; i < 32; i = i + 1) begin
        x[i] <= 0;
      end
    end else begin
      // output of [Stage 5 WRITEBACK] is registered so delayed by 1 clk
      if (need_write) x[rd] <= rd_wr_data;
    end
  end
  // endregion write to x
endmodule
