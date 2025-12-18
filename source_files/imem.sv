// Instruction Memory, 16-bit word addressed Depth: 1024 words
//Read-only in hardware (we use $readmemh for simulation)
//Address comes from PC (we use lower 10 bits)

module imem #(
    parameter DEPTH = 1024,
    parameter INIT_FILE = "tb_cpu_callret.hex"   // hex file with instructions
 ) (
    input  logic [15:0] addr,   // PC value
    output logic [15:0] data    // instruction word
 );

    logic [15:0] mem [0:DEPTH-1];

    // Initialize from file for simulation
    initial 
    begin
        if (INIT_FILE != "") 
        begin  //if not empty, then read file
            $readmemh(INIT_FILE, mem); //read hex file into memory, done by syntax $readmemh
        end
    end

    //Asynchronous read (combinational logic used)
    always_comb 
    begin   //value at addrs is simple the value of pc(in the cpu_top), 
         //which accesses the 16bit instruction from the imem
        data = mem[addr[9:0]];  // use lower 10 bits as index from the pc/addr, 
                                 //since depth is 1024 = 2^10
                //the 16bit data/instruction is accessed and stored in [15:0] data
    end
endmodule