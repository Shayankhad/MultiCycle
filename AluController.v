module AluController (
    input  wire [2:0] aluOp,
    input  wire [8:0] func,
    output reg  [2:0] aluOpc,
    output reg        noOp,
    output reg        moveTo
);

    always @(*) begin
        aluOpc = 3'b000; 
        noOp   = 1'b0;
        moveTo = 1'b0;

        if (aluOp != 3'b111) begin
            aluOpc = aluOp;
        end
        else begin
            // Type-C decode using func field 
            case (func)
                9'b000000001: begin
                    // MoveTo Ri : Ri <- R0
                    aluOpc = 3'b101;  // Pass In1
                    moveTo = 1'b1;
                end

                9'b000000010: begin
                    // MoveFrom Ri : R0 <- Ri

                    aluOpc = 3'b110;  
                end

                9'b000000100: begin
                    // Add Ri : R0 <- R0 + Ri
                    aluOpc = 3'b000;  
                end

                9'b000001000: begin
                    // Sub Ri : R0 <- R0 - Ri
                    aluOpc = 3'b001;  // SUB
                end

                9'b000010000: begin
                    // And Ri : R0 <- R0 & Ri
                    aluOpc = 3'b010;  // AND
                end

                9'b000100000: begin
                    // Or Ri : R0 <- R0 | Ri
                    aluOpc = 3'b011;  // OR
                end

                9'b001000000: begin
                    // Not Ri : R0 <- NOT Ri

                    aluOpc = 3'b100;  
                end

                9'b010000000: begin
                    // Nop : No operation
                    aluOpc = 3'b101; 
                    noOp   = 1'b1;
                end

                default: begin
                    aluOpc = 3'b000;
                    noOp   = 1'b0;
                    moveTo = 1'b0;
                end
            endcase
        end
    end

endmodule
