`timescale 1ns/1ps

module tb_cpu_rtype;

    reg  clk;
    reg  reset;
    wire halted;

    // Instantiate top-level CPU
    cpu_top dut (
        .clk   (clk),
        .reset (reset),
        .halted(halted)
    );

    // Simple clock: 10 ns period
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // Cycle counter for simple timeout
    integer cycles;
    integer TIMEOUT_CYCLES;

    initial begin
        cycles = 0;
        TIMEOUT_CYCLES = 200;
    end

    always @(posedge clk) begin
        if (reset) begin
            cycles <= 0;
        end else if (!halted) begin
            cycles <= cycles + 1;
        end
    end

    // Main test sequence
    initial begin
        // Apply reset
        reset = 1'b1;
        // wait a few cycles
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        reset = 1'b0;

        // Wait for HALT or timeout
        // Simple polling loop
        wait (halted || (cycles >= TIMEOUT_CYCLES));

        if (!halted) begin
            $display("ERROR: CPU did not reach HALT before timeout.");
            $finish;
        end

        // At this point, program should have finished.
        // Check register file contents inside dut.u_regfile.regs[]
        $display("---- R-type ALU test results ----");
        $display("R1 = %h", dut.u_regfile.regs[1]);
        $display("R2 = %h", dut.u_regfile.regs[2]);
        $display("R3 = %h (expect 0008)", dut.u_regfile.regs[3]);
        $display("R4 = %h (expect 0002)", dut.u_regfile.regs[4]);
        $display("R5 = %h (expect 0001)", dut.u_regfile.regs[5]);
        $display("R6 = %h (expect 0007)", dut.u_regfile.regs[6]);
        $display("R7 = %h (expect 0006)", dut.u_regfile.regs[7]);

        // Simple checks (no SystemVerilog assert)
        if (dut.u_regfile.regs[3] !== 16'h0008)
            $display("ERROR: R3 wrong: got %h, expected 0008", dut.u_regfile.regs[3]);

        if (dut.u_regfile.regs[4] !== 16'h0002)
            $display("ERROR: R4 wrong: got %h, expected 0002", dut.u_regfile.regs[4]);

        if (dut.u_regfile.regs[5] !== 16'h0001)
            $display("ERROR: R5 wrong: got %h, expected 0001", dut.u_regfile.regs[5]);

        if (dut.u_regfile.regs[6] !== 16'h0007)
            $display("ERROR: R6 wrong: got %h, expected 0007", dut.u_regfile.regs[6]);

        if (dut.u_regfile.regs[7] !== 16'h0006)
            $display("ERROR: R7 wrong: got %h, expected 0006", dut.u_regfile.regs[7]);

        $display("R-type ALU test completed.");
        $finish;
    end

endmodule
