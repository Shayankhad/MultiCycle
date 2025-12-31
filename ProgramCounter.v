module PC_Register (
    input clk,
    input reset,      
    input PCWrite,    
    input [11:0] PCNext, 
    output reg [11:0] PC
);
    
    always @(posedge clk or posedge reset) begin
        if (reset)
            PC <= 12'b0; 
        else if (PCWrite)
            PC <= PCNext;
    end
endmodule