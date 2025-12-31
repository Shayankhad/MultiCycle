module Memory (
    input clk,
    input MemWrite,   
    input [11:0] Address,    
    input [15:0] WriteData,   
    output [15:0] ReadData     
);
    
    reg [15:0] ram [4095:0];

    
    always @(posedge clk) begin
        if (MemWrite)
            ram[Address] <= WriteData;
    end

    
    assign ReadData = ram[Address];

    
    initial begin
        $readmemh("program.hex", ram);
    end
endmodule