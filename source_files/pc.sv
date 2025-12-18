//Program Counter (PC)- 16-bit
//Synchronous register with enable and async reset
//pc_next(16bit: input) is provided by top-level logic, cpu_top

module pc (
    input  logic clk,
    input  logic reset,   // active high
    input  logic en,      // pc enable (0 = hold)
    input  logic [15:0] pc_next,
    output logic [15:0] pc
);

    always_ff @(posedge clk or posedge reset) 
    begin
        if (reset) begin
            pc <= 16'h0000;      // start at address 0
        end else if (en) begin
            pc <= pc_next;
        end
        // else: hold current pc
    end

endmodule