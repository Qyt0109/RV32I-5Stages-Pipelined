
// region decode
`define ALU_WIDTH 14
`define ADD 0
`define SUB 1
`define SLT 2
`define SLTU 3
`define XOR 4
`define OR 5
`define AND 6
`define SLL 7
`define SRL 8
`define SRA 9
`define EQ 10
`define NEQ 11
`define GE 12
`define GEU 13

`define OPCODE_WIDTH 11
`define RTYPE 0
`define ITYPE 1
`define LOAD 2
`define STORE 3
`define BRANCH 4
`define JAL 5
`define JALR 6
`define LUI 7
`define AUIPC 8
`define SYSTEM 9
`define FENCE 10

`define EXCEPTION_WIDTH 4
`define ILLEGAL 0
`define ECALL 1
`define EBREAK 2
`define MRET 3
// endregion decode
