module IR_Register (
    input clk,
    input IRWrite,    
    input [15:0] InstrIn,    
    output reg [15:0] Instr   
);
    always @(posedge clk) begin
        if (IRWrite)
            Instr <= InstrIn;
    end
endmodule