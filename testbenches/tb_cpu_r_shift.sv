`timescale 1ns/1ps

// -------------------------------------------------------------
// R-type shift instruction testbench
// Program in tb_cpu_r_shift.hex:
//
//   4050  // ADDI R1, R0, 16   -> R1 = 0x0010
//   4081  // ADDI R2, R0, 1    -> R2 = 0x0001
//   129C  // SLL  R3, R1, R2   -> R3 = 0x0020
//   12A5  // SRL  R4, R1, R2   -> R4 = 0x0008
//   F000  // HALT
//
// Expected final register values:
//   R1 = 0010
//   R2 = 0001
//   R3 = 0020  (shift left by 1)
//   R4 = 0008  (shift right by 1)
//   R5–R7: unused in this test
// -------------------------------------------------------------

module tb_cpu_r_shift;

    // clock / reset / halted
    logic clk;
    logic reset;
    logic halted;

    // DUT
    cpu_top dut (
        .clk    (clk),
        .reset  (reset),
        .halted (halted)
    );

    // simple 10 ns clock
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

        // display register file contents
        $display("---- R-type shift instruction test results ----");
        $display("R1 = %h (expect 0010)", dut.u_regfile.regs[1]);
        $display("R2 = %h (expect 0001)", dut.u_regfile.regs[2]);
        $display("R3 = %h (expect 0020)", dut.u_regfile.regs[3]);
        $display("R4 = %h (expect 0008)", dut.u_regfile.regs[4]);
        $display("R5 = %h (unused in this test)", dut.u_regfile.regs[5]);
        $display("R6 = %h (unused in this test)", dut.u_regfile.regs[6]);
        $display("R7 = %h (unused in this test)", dut.u_regfile.regs[7]);

        // simple self-checks
        assert (dut.u_regfile.regs[1] == 16'h0010)
            else $error("R1 wrong: got %h, expected 0010", dut.u_regfile.regs[1]);

        assert (dut.u_regfile.regs[2] == 16'h0001)
            else $error("R2 wrong: got %h, expected 0001", dut.u_regfile.regs[2]);

        assert (dut.u_regfile.regs[3] == 16'h0020)
            else $error("R3 wrong: got %h, expected 0020", dut.u_regfile.regs[3]);

        assert (dut.u_regfile.regs[4] == 16'h0008)
            else $error("R4 wrong: got %h, expected 0008", dut.u_regfile.regs[4]);

        $display("R-type shift instruction test completed.");
        $finish;
    end

endmodule
