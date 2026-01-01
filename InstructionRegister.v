module IR_Register (
    input clk,
    input reset,
    input IRWrite,
    input [15:0] InstrIn,
    output reg [15:0] Instr
);
    always @(posedge clk or posedge reset) begin
        if (reset) Instr <= 16'h0000;
        else if (IRWrite) Instr <= InstrIn;
    end
endmodule
