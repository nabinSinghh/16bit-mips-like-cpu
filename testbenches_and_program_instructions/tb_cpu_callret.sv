`timescale 1ns/1ps

// -------------------------------------------------------------
// CALL / RET instruction testbench
//
// Program (tb_cpu_callret.hex):
//   0: 4041  ADDI R1, R0, 1
//   1: 4082  ADDI R2, R0, 2
//   2: D005  CALL 5          ; LR(R7) = 3, PC -> 5
//   3: 40C9  ADDI R3, R0, 9  ; executed after RET
//   4: F000  HALT
//   5: 4243  ADDI R1, R1, 3  ; R1 = 4
//   6: 4484  ADDI R2, R2, 4  ; R2 = 6
//   7: E000  RET             ; PC <- R7 (3)
//
// Expected at end:
//   R1 = 0004
//   R2 = 0006
//   R3 = 0009
//   R7 = 0003   (saved return address)
// -------------------------------------------------------------

module tb_cpu_callret;

    logic clk;
    logic reset;
    logic halted;

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

    // timeout counter
    int cycles;
    localparam int TIMEOUT_CYCLES = 200;

    always_ff @(posedge clk) begin
        if (reset) begin
            cycles <= 0;
        end else if (!halted) begin
            cycles <= cycles + 1;
        end
    end

    initial begin
        // reset
        reset = 1'b1;
        repeat (4) @(posedge clk);
        reset = 1'b0;

        // wait for HALT or timeout
        wait (halted || (cycles >= TIMEOUT_CYCLES));

        if (!halted) begin
            $fatal(1, "ERROR: CPU did not reach HALT before timeout.");
        end

        // show register file
        $display("---- CALL / RET instruction test results ----");
        $display("R1 = %h (expect 0004)", dut.u_regfile.regs[1]);
        $display("R2 = %h (expect 0006)", dut.u_regfile.regs[2]);
        $display("R3 = %h (expect 0009)", dut.u_regfile.regs[3]);
        $display("R4 = %h (unused)",       dut.u_regfile.regs[4]);
        $display("R5 = %h (unused)",       dut.u_regfile.regs[5]);
        $display("R6 = %h (unused)",       dut.u_regfile.regs[6]);
        $display("R7 = %h (expect 0003)",  dut.u_regfile.regs[7]);

        // checks
        assert (dut.u_regfile.regs[1] == 16'h0004)
            else $error("R1 wrong: got %h, expected 0004", dut.u_regfile.regs[1]);

        assert (dut.u_regfile.regs[2] == 16'h0006)
            else $error("R2 wrong: got %h, expected 0006", dut.u_regfile.regs[2]);

        assert (dut.u_regfile.regs[3] == 16'h0009)
            else $error("R3 wrong: got %h, expected 0009", dut.u_regfile.regs[3]);

        assert (dut.u_regfile.regs[7] == 16'h0003)
            else $error("R7 wrong: got %h, expected 0003", dut.u_regfile.regs[7]);

        $display("CALL / RET instruction test completed.");
        $finish;
    end

endmodule
