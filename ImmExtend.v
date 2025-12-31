module ImmExtend (
    input  [15:0] Instr,  
    input  [1:0]  ImmSrc,    
    output reg [15:0] ImmExt 
);

    always @(*) begin
        case (ImmSrc)
            
            2'b00: ImmExt = {4'b0, Instr[11:0]}; 

            2'b01: ImmExt = {7'b0, Instr[8:0]};

            default: ImmExt = 16'b0;
        endcase
    end
endmodule