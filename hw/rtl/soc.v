module soc #(
    // main_memory
    parameter MEMORY_HEX   = "",
    parameter MEMORY_DEPTH = 1024,
    parameter PC_RESET     = 0,
    parameter TRAP_ADDR    = 0
) (
    input clk,
    input rst
);

  // Instruction Memory
  wire [31:0] main_memory_instr_addr;
  wire [31:0] main_memory_instr;
  wire        main_memory_instr_req;
  wire        main_memory_instr_ack;

  // Data Memory
  wire        main_memory_wb_cyc;
  wire        main_memory_wb_stb;
  wire        main_memory_wb_wr_en;
  wire [31:0] main_memory_wb_addr;
  wire [31:0] main_memory_wb_wr_data;
  wire [ 3:0] main_memory_wb_wr_sel;
  wire        main_memory_wb_ack;
  wire        main_memory_wb_stall;
  wire [31:0] main_memory_wb_rd_data;

  // Interrupts
  wire        external_interrupt;  //! interrupt from external source
  wire        software_interrupt;  //! interrupt from software (inter-processor interrupt)
  wire        timer_interrupt;  //! interrupt from timer


  core #(
      .PC_RESET (PC_RESET),
      .TRAP_ADDR(TRAP_ADDR)
  ) core_dut (
      .clk(clk),
      .rst(rst),

      .main_memory_instr_addr(main_memory_instr_addr),
      .main_memory_instr     (main_memory_instr),
      .main_memory_instr_req (main_memory_instr_req),
      .main_memory_instr_ack (main_memory_instr_ack),

      .main_memory_wb_cyc    (main_memory_wb_cyc),
      .main_memory_wb_stb    (main_memory_wb_stb),
      .main_memory_wb_wr_en  (main_memory_wb_wr_en),
      .main_memory_wb_addr   (main_memory_wb_addr),
      .main_memory_wb_wr_data(main_memory_wb_wr_data),
      .main_memory_wb_wr_sel (main_memory_wb_wr_sel),
      .main_memory_wb_ack    (main_memory_wb_ack),
      .main_memory_wb_stall  (main_memory_wb_stall),
      .main_memory_wb_rd_data(main_memory_wb_rd_data),

      // Interrupts
      .external_interrupt(external_interrupt),
      .software_interrupt(software_interrupt),
      .timer_interrupt   (timer_interrupt)
  );


endmodule
