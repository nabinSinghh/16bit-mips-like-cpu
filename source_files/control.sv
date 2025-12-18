//Control Unit for 16-bit CPU
//Generates all control signals based on opcode[15:12] and funct3[2:0]
//This version supports the following instruction classes:

//--- R-type ALU_A (opcode 0000):   ADD, SUB   (funct3 selects op)
//--- R-type ALU_L (opcode 0001):   AND, OR, XOR, NOT, SLL, SRL
//---- LHI  (0010) / LLI (0011)
//---- ADDI (0100)
// ---- ANDI (0101)
//---- ORI  (0110)
// ---- LD   (0111)
//---- ST   (1000)
//---- BEQ  (1001)
//--- BNE  (1010)
//---- BLT  (1011)
//---- BGE  (1100)
//  ---- CALL (1101)
//  ---- RET  (1110)
//  ---- HALT (1111)

// The top-level cpu_top.sv will use these control signals to:
//  - select ALU sources (register vs immediate)
//  - select writeback source (ALU / memory / LI-unit / PC+1 for CALL)
//  - control data memory read/write
//  - select which registers to use for rs/rt/rd
//  - decide PC next value (normal vs branch vs CALL/RET)
//  - stop the CPU on HALT

module control (
    input  logic [3:0] opcode,       //instr[15:12]
    input  logic [2:0] funct3,       //instr[2:0] (for R-type)

    //main datapath control signals
    output logic reg_write,    //write to register file
    output logic mem_read,     //read from data memory
    output logic mem_write,    //write to data memory
    output logic mem_to_reg,   //1: writeback from memory, 0: from ALU/LI
    output logic alu_src_imm,  //1: ALU B comes from imm6, 0: from register

    //immediate control
    //is_imm_zero_ext_flag = 0 -> use sign-extended imm6 (ADDI, LD, ST, branches)
    //is_imm_zero_ext_flag = 1 -> use zero-extended imm6 (ANDI, ORI)
    output logic is_imm_zero_ext_flag,

    // type flags for cpu_top
    output logic is_rtype,     //R-type ALU instruction (OP_ALU_A / OP_ALU_L)
    output logic is_li_type,   //LHI/LLI
    output logic is_lhi,       //specifically LHI
    output logic is_lli,       //specifically LLI

    // branch type flags for cpu_top branch logic
    output logic is_beq,       //BEQ (branch if equal)
    output logic is_bne,       //BNE (branch if not equal)
    output logic is_blt,       //BLT (branch if less than, signed)
    output logic is_bge,       //BGE (branch if greater or equal, signed)

    // J-type: CALL / RET
    output logic is_call,      //CALL target
    output logic is_ret,       //RET
    // HALT
    output logic halt          //HALT instruction
);

    // opcode encodings (must match the ISA and ALU)
    localparam OP_ALU_A = 4'b0000;  //4'd0 R-type arithmetic
    localparam OP_ALU_L = 4'b0001;  //4'd1 R-type logical/shift
    localparam OP_LHI   = 4'b0010;  //4'd2 LHI Rt, imm8
    localparam OP_LLI   = 4'b0011;  //4'd3 LLI Rt, imm8
    localparam OP_ADDI  = 4'b0100;  //4'd4 I-type ADDI
    localparam OP_ANDI  = 4'b0101;  //4'd5 I-type ANDI
    localparam OP_ORI   = 4'b0110;  //4'd6 I-type ORI
    localparam OP_LD    = 4'b0111;  //4'd7 I-type LD
    localparam OP_ST    = 4'b1000;  //4'd8 I-type ST
    localparam OP_BEQ   = 4'b1001;  //4'd9 I-type BEQ
    localparam OP_BNE   = 4'b1010;  //4'd10 I-type BNE
    localparam OP_BLT   = 4'b1011;  //4'd11 I-type BLT
    localparam OP_BGE   = 4'b1100;  //4'd12 I-type BGE
    localparam OP_CALL  = 4'b1101;  //4'd13 J-type CALL
    localparam OP_RET   = 4'b1110;  //4'd14 J-type RET
    localparam OP_HALT  = 4'b1111;  //4'd15 J-type HALT

    //combinational decode logic
    always_comb begin
        //defaults = "do nothing"
        reg_write = 1'b0;
        mem_read  = 1'b0;
        mem_write = 1'b0;
        mem_to_reg = 1'b0;
        alu_src_imm = 1'b0;

        is_imm_zero_ext_flag = 1'b0;  // default: sign-extend imm6

        is_rtype = 1'b0;
        is_li_type = 1'b0;
        is_lhi = 1'b0;
        is_lli = 1'b0;

        is_beq = 1'b0;
        is_bne = 1'b0;
        is_blt = 1'b0;
        is_bge = 1'b0;

        is_call = 1'b0;
        is_ret = 1'b0;
        halt = 1'b0;

        //main opcode decode
        case (opcode)
            //R-type ALU_A: arithmetic class
            //All R-type instructions write to rd.
            OP_ALU_A: begin
                //for now, we simply treat any valid funct3 as an ALU operation.
                // the ALU uses opcode+funct3 to decide ADD/SUB/etc.
                is_rtype = 1'b1;
                reg_write = 1'b1;  // write rd
                alu_src_imm = 1'b0;  // ALU B from register (rt)
                // is_imm_zero_ext_flag is irrelevant for pure R-type
            end

            //R-type ALU_L: logical/shift class
            OP_ALU_L: begin
                is_rtype = 1'b1;
                reg_write = 1'b1;  // write rd  
                alu_src_imm = 1'b0;  // ALU B from register (rt)
            end

            //LHI and LLI (LI-type)
            OP_LHI: begin
                //LHI Rt, imm8 : Rt = {imm8, 8'h00}
                is_li_type = 1'b1;
                is_lhi = 1'b1;
                reg_write = 1'b1;  // write Rt
            end

            OP_LLI: begin
                //LLI Rt, imm8 : Rt = {old_Rt[15:8], imm8}
                is_li_type = 1'b1;
                is_lli = 1'b1;
                reg_write = 1'b1;  // write Rt
            end

            //I-type arithmetic and logical immediates
            OP_ADDI: begin
                //ADDI Rt, Rs, imm6 : Rt = Rs + signext(imm6)
                reg_write = 1'b1;   //write Rt
                alu_src_imm = 1'b1;   //ALU B = imm6
                is_imm_zero_ext_flag = 1'b0;   //sign-extend imm6
            end

            OP_ANDI: begin
                //ANDI Rt, Rs, imm6 : Rt = Rs & zeroext(imm6)
                reg_write = 1'b1;   //write Rt
                alu_src_imm = 1'b1;   //ALU B = imm6
                is_imm_zero_ext_flag = 1'b1;   //zero-extend imm6
            end

            OP_ORI: begin
                //ORI Rt, Rs, imm6 : Rt = Rs | zeroext(imm6)
                reg_write = 1'b1;   //write Rt
                alu_src_imm = 1'b1;   //ALU B = imm6
                is_imm_zero_ext_flag = 1'b1;   //zero-extend imm6
            end

            // Load / Store
            OP_LD: begin
                // LD Rt, offset(Rs) : Rt = MEM[Rs + signext(imm6)]
                reg_write = 1'b1;   //write Rt
                mem_read = 1'b1;   //enable memory read
                mem_to_reg = 1'b1;   //writeback from memory
                alu_src_imm = 1'b1;   //address = Rs + imm6
                is_imm_zero_ext_flag = 1'b0;   //sign-extend imm6 for address
            end

            OP_ST: begin
                // ST Rt, offset(Rs) : MEM[Rs + signext(imm6)] = Rt
                mem_write = 1'b1;   //enable memory write
                alu_src_imm = 1'b1;   //address = Rs + imm6
                is_imm_zero_ext_flag = 1'b0;   //sign-extend imm6 for address
            end

            // Branches (no reg write, no memory)
            OP_BEQ: begin
                // BEQ Rs, Rt, offset : if (Rs == Rt) PC = PC+1+signext(imm6)
                is_beq = 1'b1;
                alu_src_imm = 1'b0;   //ALU not used for compare, cpu_top uses rd1/rd2 directly
            end

            OP_BNE: begin
                //BNE Rs, Rt, offset : if (Rs != Rt) PC = PC+1+signext(imm6)
                is_bne = 1'b1;
                alu_src_imm = 1'b0;
            end

            OP_BLT: begin
                //BLT Rs, Rt, offset : if (Rs < Rt, signed) PC = PC+1+signext(imm6)
                is_blt = 1'b1;
                alu_src_imm = 1'b0;
            end

            OP_BGE: begin
                //BGE Rs, Rt, offset : if (Rs >= Rt, signed) PC = PC+1+signext(imm6)
                is_bge = 1'b1;
                alu_src_imm = 1'b0;
            end

            //J-type: CALL and RET
            OP_CALL: begin
                //CALL target :
                //LR (R7) <- PC+1 (handled in cpu_top writeback)
                //PC      <- target (handled in cpu_top pc_next mux)
                is_call = 1'b1;
                reg_write = 1'b1;   // write LR (R7) with PC+1
                // no memory, no immediate ALU usage
            end

            OP_RET: begin
                // RET :
                //   PC <- LR (R7)
                is_ret = 1'b1;
                // reg_write stays 0 (no register write)
                // no memory, no immediate ALU usage
            end

            // HALT
            OP_HALT: begin
                // HALT : stop CPU (pc_en goes low in cpu_top)
                halt = 1'b1;
            end

            // default case: keep all defaults
            default: begin
                // unknown opcode then do nothing
            end

        endcase
    end

endmodule
