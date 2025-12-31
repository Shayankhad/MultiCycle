module ALU (
    input [15:0] In1, In2,    
    input [2:0]  ALUControl, 
    output reg [15:0] ALUResult,
    output Zero 
);
    always @(*) begin
        case (ALUControl)
            3'b000: ALUResult = In1 + In2;    
            3'b001: ALUResult = In1 - In2;    
            3'b010: ALUResult = In1 & In2;   
            3'b011: ALUResult = In1 | In2;    
            3'b100: ALUResult = ~In1;         
            3'b101: ALUResult = In1;          
            3'b110: ALUResult = In2;          
            default: ALUResult = 16'b0;
        endcase
    end

    
    assign Zero = (ALUResult == 16'b0); 
endmodule
