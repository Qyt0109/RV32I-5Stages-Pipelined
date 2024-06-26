module regs (
    input clk,

    // region control by [STAGE 2 DECODE]
    input       rs_rd_en,  // source registers read enable
    input [4:0] rs1,       // source register 1 address
    input [4:0] rs2,       // source register 2 address
    // endregion control by [STAGE 2 DECODE]

    // region control by [STAGE 5 WRITEBACK]
    input [ 4:0] rd,          // destination register address
    input [31:0] rd_wr_data,  // data to be written to destination register
    input        rd_wr_en,    // destination register write enable
    // endregion control by [STAGE 5 WRITEBACK]

    output rs1_rd_data,  // source register 1 value
    output rs2_rd_data   // source register 2 value
);

  reg [31:0] x[1:31];  // regs from x1 to x31 (x0 is hard-wired with 0 value)

  // region read from x
  `define ZERO_REG_ADDR 0
  `define ZERO_REG_DATA 0

  reg [4:0] r_rs1;  // registered rs1
  reg [4:0] r_rs2;  // registered rs2

  // syn read with clk
  always @(posedge clk) begin : sync_read_process
    if (rs_rd_en) begin
      r_rs1 <= rs1;  // update r_rs1 so the rs1_rdata = x[r_rs1] will also be updated
      r_rs2 <= rs2;  // update r_rs2 so the rs2_rdata = x[r_rs2] will also be updated
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
  always @(posedge clk) begin : sync_write_process
    // [Info] output of [Stage 5] (Writeback) is registered so delayed by 1 clk
    if(need_write) x[rd] <= rd_wr_data;
  end
  // endregion write to x
endmodule
