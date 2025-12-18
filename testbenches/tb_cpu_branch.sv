`timescale 1ns/1ps

// -------------------------------------------------------------
// Branch instruction testbench: BEQ, BNE, BLT, BGE
//
// Program in tb_cpu_branch.hex:
//
//   4045  // ADDI R1, R0, 5
//   4085  // ADDI R2, R0, 5
//   40C1  // ADDI R3, R0, 1
//   9282  // BEQ  R1, R2, +2   (taken, skip 4,5)
//   46C1  // ADDI R3, R3, 1    (only if BEQ not taken)
//   46C1  // ADDI R3, R3, 1    (only if BEQ not taken)
//   A2C2  // BNE  R1, R3, +2   (taken, skip 7,8)
//   4101  // ADDI R4, R0, 1    (only if BNE not taken)
//   4901  // ADDI R4, R4, 1    (only if BNE not taken)
//   417F  // ADDI R5, R0, -1   (R5 = FFFF)
//   4181  // ADDI R6, R0, 1    (R6 = 0001)
//   BB82  // BLT  R5, R6, +2   (taken, skip 12,13)
//   46C1  // ADDI R3, R3, 1    (only if BLT not taken)
//   46C1  // ADDI R3, R3, 1    (only if BLT not taken)
//   CD42  // BGE  R6, R5, +2   (taken, skip 15,16)
//   4901  // ADDI R4, R4, 1    (only if BGE not taken)
//   4901  // ADDI R4, R4, 1    (only if BGE not taken)
//   F000  // HALT
//
// Expected final registers if all branches behave correctly:
//
//   R1 = 0005
//   R2 = 0005
//   R3 = 0001   (BEQ and BLT both taken, so no extra increments)
//   R4 = (don't care, never written if BNE/BGE taken)
//   R5 = FFFF   (-1)
//   R6 = 0001
//   R7 = don't care / unused
// -------------------------------------------------------------

module tb_cpu_branch;

    logic clk;
    logic reset;
    logic halted;

    // DUT
    cpu_top dut (
        .clk    (clk),
        .reset  (reset),
        .halted (halted)
    );

    // 10 ns clock
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // cycle counter for timeout
    int cycles;
    localparam int TIMEOUT_CYCLES = 200;

    always_ff @(posedge clk) begin
        if (reset) begin
            cycles <= 0;
        end else if (!halted) begin
            cycles <= cycles + 1;
        end
    end

    // main test
    initial begin
        // apply reset for a few cycles
        reset = 1'b1;
        repeat (4) @(posedge clk);
        reset = 1'b0;

        // wait for HALT or timeout
        wait (halted || (cycles >= TIMEOUT_CYCLES));

        if (!halted) begin
            $fatal(1, "ERROR: CPU did not reach HALT before timeout.");
        end

        // print register contents
        $display("---- Branch instruction test results ----");
        $display("R1 = %h (expect 0005)", dut.u_regfile.regs[1]);
        $display("R2 = %h (expect 0005)", dut.u_regfile.regs[2]);
        $display("R3 = %h (expect 0001)", dut.u_regfile.regs[3]);
        $display("R4 = %h (unused / don't care in this test)", dut.u_regfile.regs[4]);
        $display("R5 = %h (expect FFFF)", dut.u_regfile.regs[5]);
        $display("R6 = %h (expect 0001)", dut.u_regfile.regs[6]);
        $display("R7 = %h (unused in this test)", dut.u_regfile.regs[7]);

        // self-checking assertions (only for registers we care about)
        assert (dut.u_regfile.regs[1] == 16'h0005)
            else $error("R1 wrong: got %h, expected 0005", dut.u_regfile.regs[1]);

        assert (dut.u_regfile.regs[2] == 16'h0005)
            else $error("R2 wrong: got %h, expected 0005", dut.u_regfile.regs[2]);

        assert (dut.u_regfile.regs[3] == 16'h0001)
            else $error("R3 wrong: got %h, expected 0001", dut.u_regfile.regs[3]);

        assert (dut.u_regfile.regs[5] == 16'hFFFF)
            else $error("R5 wrong: got %h, expected FFFF", dut.u_regfile.regs[5]);

        assert (dut.u_regfile.regs[6] == 16'h0001)
            else $error("R6 wrong: got %h, expected 0001", dut.u_regfile.regs[6]);

        $display("Branch instruction test completed.");
        $finish;
    end

endmodule
