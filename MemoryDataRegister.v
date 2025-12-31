module MDR_Register (
    input clk,
    input en,
    input [15:0] DataIn,
    output reg [15:0] DataOut
);
    always @(posedge clk) begin
        if (en) DataOut <= DataIn;
    end
endmodule

