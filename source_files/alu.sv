// 16-bit ALU for my ISA
//Takes opcode[15:12] and funct3[2:0]
// R-type: ALU_A (0000) and ALU_L (0001) use funct3; use both opcode and funct3, to decide operation
// I-type: ADDI, ANDI, ORI, LD, ST reuse standard ops; use only opcode to decide operation
// Shift amount for shifts comes from lower 4 bits of B input(rd2[16bit]), (never from immediate), shift from immediate is not supported
// Outputs: Y (result 16bit)
// Flags(1bit): Z (result == 0), LT_s (signed A < B)

module alu (
    input  logic [15:0] A,        // operand from Rs
    input  logic [15:0] B,        // operand from Rt or immediate
    input  logic [3:0]  opcode,   // instr[15:12]
    input  logic [2:0]  funct3,   // instr[2:0] for R-type
    output logic [15:0] Y,        // result, will be stored in alu_y in cpu_top.sv
    output logic Z,        // zero flag; 1 bit, will be stored in alu_z in cpu_top.sv
    output logic LT_s      // signed less-than flag; 1bit, will be stored in alu_lt_s in cpu_top.sv
);

    // Opcode encodings (from your ISA spec)
    localparam OP_ALU_A = 4'b0000;  // R-type arithmetic (ADD, SUB)
    localparam OP_ALU_L = 4'b0001;  // R-type logical / shift
    localparam OP_LHI   = 4'b0010;  // *handled in imm/const unit, not ALU
    localparam OP_LLI   = 4'b0011;  // *handled in imm/const unit, not ALU
    localparam OP_ADDI  = 4'b0100;  // I-type ADDI
    localparam OP_ANDI  = 4'b0101;  // I-type ANDI
    localparam OP_ORI   = 4'b0110;  // I-type ORI
    localparam OP_LD    = 4'b0111;  // I-type LD (base + offset)
    localparam OP_ST    = 4'b1000;  // I-type ST (base + offset)
    localparam OP_BEQ   = 4'b1001;  // *I-type BEQ (branch), does not use ALU result
    localparam OP_BNE   = 4'b1010;  // *I-type BNE (branch), does not use ALU result
    localparam OP_BLT   = 4'b1011;  // *I-type BLT (branch), does not use ALU result
    localparam OP_BGE   = 4'b1100;  // *I-type BGE (branch), does not use ALU result
    localparam OP_CALL  = 4'b1101;  // *J-type CALL, does not use ALU result
    localparam OP_RET   = 4'b1110;  // *J-type RET, does not use ALU result
    localparam OP_HALT  = 4'b1111;  // *HALT, does not use ALU result
    // Note: Branches and J-type instructions do not use ALU result
    // 1001–1111: BEQ(1001), BNE(1010),  BLT(1011), BGE(1100), and
    // CALL(1101), RET(1110), HALT(1111) (don’t need distinct ALU ops)

    // Shift amount: 0..15 for 16-bit datapath
    logic [3:0] shamt;  //variable to store the shift amount
    assign shamt = B[3:0];   // lower 4 bits of B input(rd2[16bit]), (never from immediate), shift from immediate is not supported

    // Main ALU logic
    always_comb begin
        Y = 16'h0000;  // default

         case (opcode)

            // ===== R-type arithmetic: ALU_A =====
            OP_ALU_A: begin //opcode = 4'b0000
                unique case (funct3)
                    3'b000: Y = A + B;          // ADD
                    3'b001: Y = A - B;          // SUB
                    default: Y = 16'h0000;      // reserved
                endcase
            end

            // ===== R-type logical/shift: ALU_L =====
            OP_ALU_L: begin //opcode = 4'b0001
                 case (funct3)
                    3'b000: Y = A & B;          // AND
                    3'b001: Y = A | B;          // OR
                    3'b010: Y = A ^ B;          // XOR
                    3'b011: Y = ~A;             // NOT (ignore B)
                    3'b100: Y = A << shamt;     // SLL
                    3'b101: Y = A >> shamt;     // SRL (logical)
                    default: Y = 16'h0000;      // reserved
                endcase
            end

            // ******* I-type arithmetic / address calc *******
            OP_ADDI: Y = A + B;  //opcode = 0100_______ADDI: Rs + imm, alu_y will store the immediate sum
            OP_LD  : Y = A + B;  //opcode = 0111_______LD:   base + offset, alu_y will store the effective address
            OP_ST  : Y = A + B;  //opcode = 1000_______ST:   base + offset, alu_y will store the effective address

            // ******* I-type logical immediates (optional via ALU) *******
            OP_ANDI: Y = A & B;                 // ANDI: Rs & imm
            OP_ORI : Y = A | B;                 // ORI:  Rs | imm

            // ----------- Everything else does not use ALU result ----------
            default: Y = 16'h0000;
        endcase
    end

    // Flags
    // Zero flag from result
    assign Z    = (Y == 16'h0000);  //Z is automatically asserted whenever the output if (Y == 0)
                                      

    // Signed less-than flag, directly from inputs (for BLT/BGE)
    assign LT_s = ($signed(A) < $signed(B)); //LT_s is asserted whenever if (A < B) in signed comparison
     //these could have also been written as LT_s = ($signed(A) < $signed(B)) ? 1'b1 : 1'b0;
endmodule