//LHI / LLI helper
//Takes imm8 and the old value of Rt
//Produces the new Rt value for LHI or LLI

module li_unit (
    input  logic  is_lhi,  // 1bit signal, from control unit
    input  logic  is_lli,  // 1bit signal, from control unit
    input  logic [7:0] imm8, // instr[8:1], to define the 8bit immediate value, instr[0} is unused]
    input  logic [15:0] old_rt,    // value currently in Rt (register file rd2)
    output logic [15:0] li_value // new value to write into Rt
);

    always_comb begin
        if (is_lhi) begin
            // LHI Rt, imm8  => Rt = imm8 << 8
            li_value = {imm8, 8'h00};
        end else if (is_lli) begin
            // LLI Rt, imm8  => Rt[7:0] = imm8, upper byte unchanged
            li_value = {old_rt[15:8], imm8};
        end else begin
            li_value = 16'h0000;   // not used
        end
    end

endmodule
