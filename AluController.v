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
            case (func)
                9'b000000001: begin
                    aluOpc = 3'b101;  
                    moveTo = 1'b1;
                end

                9'b000000010: begin

                    aluOpc = 3'b110;  
                end

                9'b000000100: begin
                    aluOpc = 3'b000;  
                end

                9'b000001000: begin
                    aluOpc = 3'b001;  
                end

                9'b000010000: begin
                    aluOpc = 3'b010;  
                end

                9'b000100000: begin
                    aluOpc = 3'b011; 
                end

                9'b001000000: begin
                    aluOpc = 3'b100;  
                end

                9'b010000000: begin
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
