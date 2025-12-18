`timescale 1ns/1ps

// ---------------------------------------------------------------------
// Immediate instruction testbench
// Program expected in IMEM (one 16-bit word per line, hex):
//   2224  ; LHI  R1, 0x12   -> R1 = 0x1200
//   3268  ; LLI  R1, 0x34   -> R1 = 0x1234
//   42BF  ; ADDI R2, R1,-1  -> R2 = 0x1233
//   52C4  ; ANDI R3, R1,4   -> R3 = 0x0004
//   613C  ; ORI  R4, R0,0x3C-> R4 = 0x003C
//   F000  ; HALT
//
// Expected final register values:
//   R1 = 1234
//   R2 = 1233
//   R3 = 0004
//   R4 = 003C
//   R5–R7: don't care (unused in this test)
// ---------------------------------------------------------------------

module tb_cpu_I_type;

    // clock / reset
    logic clk;
    logic reset;
    logic halted;

    // instantiate DUT
    cpu_top dut (
        .clk    (clk),
        .reset  (reset),
        .halted (halted)
    );

    // simple 10 ns clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // cycle counter for timeout
    int cycles;
    localparam int TIMEOUT_CYCLES = 200;

    always @(posedge clk) begin
        if (reset) begin
            cycles <= 0;
        end else if (!halted) begin
            cycles <= cycles + 1;
        end
    end

    // main test
    initial begin
        // reset for a few cycles
        reset = 1;
        repeat (4) @(posedge clk);
        reset = 0;

        // wait for HALT or timeout
        wait (halted || (cycles >= TIMEOUT_CYCLES));

        if (!halted) begin
            $fatal(1, "ERROR: CPU did not reach HALT before timeout.");
        end

        // display register contents
        $display("---- Immediate instruction test results ----");
        $display("R1 = %h (expect 1234)", dut.u_regfile.regs[1]);
        $display("R2 = %h (expect 1233)", dut.u_regfile.regs[2]);
        $display("R3 = %h (expect 0004)", dut.u_regfile.regs[3]);
        $display("R4 = %h (expect 003C)", dut.u_regfile.regs[4]);
        $display("R5 = %h (unused in this test)", dut.u_regfile.regs[5]);
        $display("R6 = %h (unused in this test)", dut.u_regfile.regs[6]);
        $display("R7 = %h (unused in this test)", dut.u_regfile.regs[7]);

        // self-checking assertions for the instructions we are testing
        assert (dut.u_regfile.regs[1] == 16'h1234)
            else $error("R1 wrong: got %h, expected 1234", dut.u_regfile.regs[1]);

        assert (dut.u_regfile.regs[2] == 16'h1233)
            else $error("R2 wrong: got %h, expected 1233", dut.u_regfile.regs[2]);

        assert (dut.u_regfile.regs[3] == 16'h0004)
            else $error("R3 wrong: got %h, expected 0004", dut.u_regfile.regs[3]);

        assert (dut.u_regfile.regs[4] == 16'h003C)
            else $error("R4 wrong: got %h, expected 003C", dut.u_regfile.regs[4]);

        $display("Immediate instruction test completed.");
        $finish;
    end

endmodule
