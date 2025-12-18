//8 Registers (R0..R7), each 16 bits wide
//R0 is hardwired to 0
//2 read ports (ra1, ra2 -> rd1, rd2)
//1 write port (wa, wd, we)
//R0 is hardwired to 0 (writes to reg 0 are ignored)

module regfile (
    input logic clk,
    input logic we,          // write enable
    input logic [2:0] ra1,   // read address 1
    input logic [2:0] ra2,    // read address 2
    input logic [2:0] wa,     // write address
    input logic [15:0] wd,       // write data

    output logic [15:0] rd1, // read data 1
    output logic [15:0] rd2  // read data 2
);

    logic [15:0] regs [7:0];         // R0..R7, all of them 16 bits wide
    //array of 8 registers(each 16 bit) made, name of this array is regs
    // to access this array, regs[0] is R0, regs[1] is R1, ..., regs[7] is R7
    //thus, those ra1, ra2, wa will access these above 8 defined 16 bit registers, with it's 3 bit address

    //Read ports are purely combinational
    //this is for teh inputs to the ALU, or the one input(rt/ra2) to the dmem(data memory) write data
    always_comb begin
        rd1 = (ra1 == 3'd0) ? 16'h0000 : regs[ra1];  //read address ra1, and stores 16bit data into rd1
        rd2 = (ra2 == 3'd0) ? 16'h0000 : regs[ra2];  //read address ra2, and stores 16bit data into rd2
    end  //both these rd1 and rd2 goes firts to cpu_top, and then from cpu_top to alu as input A and B respectively in cpu_top.sv

    //Write port: synchronous on clock edge
    //this is for writing the 16bit data from alu, dmem, or li_unit back to the register file at wa address
    always_ff @(posedge clk) begin
        if (we && (wa != 3'd0)) begin  //does only when we=1 and wa is not R0
            regs[wa] <= wd;         // ignore writes to R0
        end  //16bit data(wd) got from the cpu_top.sv is received by regfile.sv and writes back to the register at wa address
    end       //i.e. regs[wa] gets the 16bit data from wd

endmodule