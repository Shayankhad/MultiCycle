module ALUOutReg (
    input clk,
    input reset,
    input [15:0] alu_result_wire,
    output reg [15:0] alu_out_reg
);
    always @(posedge clk or posedge reset) begin
        if (reset) alu_out_reg <= 16'h0000;
        else alu_out_reg <= alu_result_wire;
    end
endmodule
