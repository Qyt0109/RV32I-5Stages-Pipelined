module main_memory #(
    parameter MEMORY_HEX   = "",
    parameter MEMORY_BYTES = 1024
) (
    input clk,

    // region control by [STAGE 1 FETCH]
    // Instruction Memory
    input      [ADDR_WIDTH-1:0] instr_addr,  // instruction memory address
    output reg [          31:0] instr,       // instruction from memory
    input                       instr_stb,   // request for instruction
    output reg                  instr_ack,   // ack
    // endregion control by [STAGE 1 FETCH]

    // region control by [STAGE 4 MEMORY]
    // Data Memory
    input                       wb_cyc,
    input                       wb_stb,
    input                       wb_wr_en,
    input      [ADDR_WIDTH-1:0] wb_addr,
    input      [          31:0] wb_wr_data,
    input      [           3:0] wb_wr_sel,
    output reg                  wb_ack,
    output                      wb_stall,
    output reg [          31:0] wb_rd_data
    // endregion control by [STAGE 4 MEMORY]
);
  localparam ADDR_WIDTH = $clog2(MEMORY_BYTES);
  localparam MEMORY_DEPTH = MEMORY_BYTES / 4;
  reg [31:0] memory[0:MEMORY_DEPTH-1];

  assign wb_stall = 0;  // never stall

  initial begin
    instr_ack  <= 0;
    wb_ack     <= 0;
    instr      <= 0;
    wb_rd_data <= 0;
    if (MEMORY_HEX != "") begin
      $readmemh(MEMORY_HEX, memory);
      $display("Init Memory from %s", MEMORY_HEX);
    end else $display("No Memory Init");
  end

  always @(posedge clk) begin : sync_read_process
    instr_ack  <= instr_stb;  // ack go high next cycle after receiving stb (request)
    instr      <= memory[instr_addr>>2];  // read instruction

    wb_ack     <= (wb_stb && wb_cyc);  // ack go high next cycle after receiving stb (request)
    wb_rd_data <= memory[wb_addr[ADDR_WIDTH-1:2]];  // read data
  end

  always @(posedge clk) begin : sync_write_process
    if (wb_wr_en && wb_stb && wb_cyc) begin
      if (wb_wr_sel[0]) memory[wb_addr[ADDR_WIDTH-1:2]][7:0] <= wb_wr_data[7:0];
      if (wb_wr_sel[1]) memory[wb_addr[ADDR_WIDTH-1:2]][15:8] <= wb_wr_data[15:8];
      if (wb_wr_sel[2]) memory[wb_addr[ADDR_WIDTH-1:2]][23:16] <= wb_wr_data[23:16];
      if (wb_wr_sel[3]) memory[wb_addr[ADDR_WIDTH-1:2]][31:24] <= wb_wr_data[31:24];
    end
  end

endmodule
