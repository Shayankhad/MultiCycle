// ALUOut Register Module
module ALUOutReg (
    input clk,
    input [15:0] alu_result_wire, 
    output reg [15:0] alu_out_reg 
);
    always @(posedge clk) begin
        
        alu_out_reg <= alu_result_wire;
    end
endmodule