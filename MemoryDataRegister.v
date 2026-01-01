module MDR_Register (
    input clk,
    input reset,
    input en,
    input [15:0] DataIn,
    output reg [15:0] DataOut
);
    always @(posedge clk or posedge reset) begin
        if (reset) DataOut <= 16'h0000;
        else if (en) DataOut <= DataIn;
    end
endmodule
