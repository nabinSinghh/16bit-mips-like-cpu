`timescale 1ns/1ps

// -------------------------------------------------------------
// LD / ST instruction testbench (I-type memory instructions)
//
// Program in tb_cpu_I_mem.hex:
//
//   404A  // ADDI R1, R0, 10     -> R1 = 000A (base address)
//   4087  // ADDI R2, R0, 7      -> R2 = 0007 (data value)
//   8280  // ST   R2, 0(R1)      -> MEM[10] = 0007
//   72C0  // LD   R3, 0(R1)      -> R3 = 0007
//   8281  // ST   R2, 1(R1)      -> MEM[11] = 0007
//   7301  // LD   R4, 1(R1)      -> R4 = 0007
//   F000  // HALT
//
// Expected final registers:
//
//   R1 = 000A
//   R2 = 0007
//   R3 = 0007
//   R4 = 0007
//   R5–R7: unused / don't care
// -------------------------------------------------------------

module tb_cpu_I_mem;

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

        // display register contents
        $display("---- LD / ST instruction test results ----");
        $display("R1 = %h (expect 000A)", dut.u_regfile.regs[1]);
        $display("R2 = %h (expect 0007)", dut.u_regfile.regs[2]);
        $display("R3 = %h (expect 0007)", dut.u_regfile.regs[3]);
        $display("R4 = %h (expect 0007)", dut.u_regfile.regs[4]);
        $display("R5 = %h (unused in this test)", dut.u_regfile.regs[5]);
        $display("R6 = %h (unused in this test)", dut.u_regfile.regs[6]);
        $display("R7 = %h (unused in this test)", dut.u_regfile.regs[7]);

        // self-checking assertions
        assert (dut.u_regfile.regs[1] == 16'h000A)
            else $error("R1 wrong: got %h, expected 000A", dut.u_regfile.regs[1]);

        assert (dut.u_regfile.regs[2] == 16'h0007)
            else $error("R2 wrong: got %h, expected 0007", dut.u_regfile.regs[2]);

        assert (dut.u_regfile.regs[3] == 16'h0007)
            else $error("R3 wrong: got %h, expected 0007", dut.u_regfile.regs[3]);

        assert (dut.u_regfile.regs[4] == 16'h0007)
            else $error("R4 wrong: got %h, expected 0007", dut.u_regfile.regs[4]);

        $display("LD / ST instruction test completed.");
        $finish;
    end

endmodule
