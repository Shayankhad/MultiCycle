module AluController (
    input  wire [3:0] Op,          // Instruction opcode (IR[15:12])
    input  wire [8:0] Func,        // Func field for Type-C instructions
    output reg  [2:0] ALUControl,  // Control signal sent to ALU
    output reg isMoveTo,     // Asserted for MoveTo (Ri <- R0)
    output reg isNop         // Asserted for NOP instruction
);

    always @(*) begin
        // Default safe values
        ALUControl = 3'b000;   // Default operation: ADD
        isMoveTo   = 1'b0;
        isNop      = 1'b0;

        case (Op)

            // ---------- Type-D (Immediate) Instructions ----------
            // Addi: R0 <- R0 + imm
            4'b1100: ALUControl = 3'b000;

            // Subi: R0 <- R0 - imm
            4'b1101: ALUControl = 3'b001;

            // Andi: R0 <- R0 AND imm
            4'b1110: ALUControl = 3'b010;

            // Ori:  R0 <- R0 OR imm
            4'b1111: ALUControl = 3'b011;


            // ---------- BranchZ ----------
            // Use subtraction to compare R0 and Ri
            // If (R0 - Ri == 0) then Zero flag will be asserted
            4'b0100: ALUControl = 3'b001;


            // ---------- Load / Store / Jump ----------
            // ALU is not really used for computation here
            // We simply pass the input value through
            4'b0000,            // Load
            4'b0001,            // Store
            4'b0010:            // Jump
                ALUControl = 3'b101; // Pass In1


            // ---------- Type-C Instructions ----------
            // Opcode = 1000, actual operation determined by Func field
            4'b1000: begin
                case (Func)

                    // MoveTo Ri: Ri <- R0
                    // ALU passes R0 (In1), destination is Ri
                    9'b000000001: begin
                        ALUControl = 3'b101; // Pass In1
                        isMoveTo   = 1'b1;
                    end

                    // MoveFrom Ri: R0 <- Ri
                    // ALU passes Ri (In2)
                    9'b000000010: ALUControl = 3'b110;

                    // Add Ri: R0 <- R0 + Ri
                    9'b000000100: ALUControl = 3'b000;

                    // Sub Ri: R0 <- R0 - Ri
                    9'b000001000: ALUControl = 3'b001;

                    // And Ri: R0 <- R0 AND Ri
                    9'b000010000: ALUControl = 3'b010;

                    // Or Ri: R0 <- R0 OR Ri
                    9'b000100000: ALUControl = 3'b011;

                    // Not Ri: R0 <- NOT R0
                    9'b001000000: ALUControl = 3'b100;

                    // NOP: No operation
                    // isNop disables RegWrite in the Control Unit
                    9'b010000000: begin
                        ALUControl = 3'b101; // Pass In1 (harmless)
                        isNop      = 1'b1;
                    end

                    // Default safe case
                    default: ALUControl = 3'b000;
                endcase
            end

            // ---------- Default ----------
            default: ALUControl = 3'b000;
        endcase
    end
endmodule

