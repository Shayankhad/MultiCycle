module GenericReg #(parameter WIDTH = 16) (
    input clk,
    input en,
    input [WIDTH-1:0] d,
    output reg [WIDTH-1:0] q
);
    always @(posedge clk) begin
        if (en) q <= d;
    end
endmodule
