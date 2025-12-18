// Data Memory (RAM), 16-bit words 
//Depth: 1024, as specified, 1KiWord
//Synchronous write
//Synchronous read (simpler for timing)

module dmem #(
    parameter DEPTH = 1024
) (
    input  logic clk,
    input  logic [15:0] addr, // address from ALU/alu_y (base + offset)
    input  logic [15:0] wdata,   //[input 16 bit] data to store from the rd2(from regfile,rt,ra2) to mem[rs+immediate offset]]
    input  logic we,      // write enable
    input  logic re,      // read enable
    output logic [15:0] rdata    // data loaded
);

    logic [15:0] mem [0:DEPTH-1];

    always_ff @(posedge clk) 
	 begin
        if (we) begin
            mem[addr[9:0]] <= wdata;  //WRITE to memory, using lower 10 bits of address(which was initially 16bit from alu)
        end
    end
	 
	 // async read
    always_comb begin
        if (re)
            rdata = mem[addr[9:0]];
        else
            rdata = 16'h0000; // or hold last value 
    end

endmodule
