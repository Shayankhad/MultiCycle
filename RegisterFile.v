module RegisterFile (
    input clk,
    input RegWrite,  
    input  [2:0]  A1, A2, A3, 
    input  [15:0] WD3,   
    output [15:0] RD1, RD2 
);
    reg [15:0] rf [7:0]; 

    
    always @(posedge clk) begin
        if (RegWrite)
            rf[A3] <= WD3;
    end

    
    assign RD1 = rf[A1]; 
    assign RD2 = rf[A2]; 
endmodule