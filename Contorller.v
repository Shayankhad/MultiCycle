module CpuController (
    input  wire        clk,
    input  wire        rst,
    input  wire [3:0]  opcode,
    input  wire [8:0]  func,
    input  wire        Zero,     // not used directly here (TopModule gates PCWrite with Branch&Zero)

    output reg         AdrSrc,
    output reg         MemWrite,
    output reg         IRWrite,
    output reg         RegWrite,

    output reg  [1:0]  ALUSrcA,
    output reg  [1:0]  ALUSrcB,
    output reg  [1:0]  ImmSrc,
    output wire [2:0]  ALUControl,

    output reg         ResultSrc,
    output reg         A3Src,

    output reg  [1:0]  PCSrc,
    output reg         PCWrite,
    output reg         Branch,

    output reg         OldPCWrite,
    output reg         MDRWrite,

    output wire        noOp,
    output wire        moveTo
);

    // ------------------------------------------------------------
    // State encoding
    // ------------------------------------------------------------
    localparam [3:0]
        ST_IF         = 4'd0,
        ST_ID         = 4'd1,

        ST_BRANCH     = 4'd2,

        ST_C_ALU      = 4'd3,
        ST_C_WB       = 4'd4,

        ST_JUMP       = 4'd5,

        // ✅ STORE must be 2 cycles because address comes from ALUOut reg
        ST_STORE_EX   = 4'd6,
        ST_STORE_MEM  = 4'd7,

        ST_LOAD_EX    = 4'd8,
        ST_LOAD_MEM   = 4'd9,
        ST_LOAD_WB    = 4'd10,

        ST_IMM_EX     = 4'd11,
        ST_IMM_WB     = 4'd12;

    reg [3:0] ps, ns;
    reg [2:0] aluOp;

    // ------------------------------------------------------------
    // ALU controller (kept exactly like your architecture)
    // aluOp != 111 => direct ALU op
    // aluOp == 111 => decode func for Type-C
    // ------------------------------------------------------------
    AluController U_ALUCTRL (
        .aluOp  (aluOp),
        .func   (func),
        .aluOpc (ALUControl),
        .noOp   (noOp),
        .moveTo (moveTo)
    );

    // ------------------------------------------------------------
    // State register
    // ------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) ps <= ST_IF;
        else     ps <= ns;
    end

    // ------------------------------------------------------------
    // Next-state logic
    // ------------------------------------------------------------
    always @(*) begin
        ns = ST_IF;
        case (ps)

            ST_IF: ns = ST_ID;

            ST_ID: begin
                case (opcode)
                    4'b0100: ns = ST_BRANCH;     // BranchZ
                    4'b1000: ns = ST_C_ALU;      // Type-C ALU (func)
                    4'b0010: ns = ST_JUMP;       // Jump

                    4'b0001: ns = ST_STORE_EX;   // Store  (✅ 2-cycle)
                    4'b0000: ns = ST_LOAD_EX;    // Load   (already multi-cycle)

                    4'b1100,
                    4'b1101,
                    4'b1110,
                    4'b1111: ns = ST_IMM_EX;     // Addi/Subi/Andi/Ori

                    default: ns = ST_IF;
                endcase
            end

            ST_BRANCH:    ns = ST_IF;

            ST_C_ALU:     ns = ST_C_WB;
            ST_C_WB:      ns = ST_IF;

            ST_JUMP:      ns = ST_IF;

            ST_STORE_EX:  ns = ST_STORE_MEM;
            ST_STORE_MEM: ns = ST_IF;

            ST_LOAD_EX:   ns = ST_LOAD_MEM;
            ST_LOAD_MEM:  ns = ST_LOAD_WB;
            ST_LOAD_WB:   ns = ST_IF;

            ST_IMM_EX:    ns = ST_IMM_WB;
            ST_IMM_WB:    ns = ST_IF;

            default:      ns = ST_IF;
        endcase
    end

    // ------------------------------------------------------------
    // Control outputs
    // ------------------------------------------------------------
    always @(*) begin
        // defaults (safe)
        AdrSrc     = 1'b0;
        MemWrite   = 1'b0;
        IRWrite    = 1'b0;
        RegWrite   = 1'b0;

        ALUSrcA    = 2'b00;
        ALUSrcB    = 2'b00;
        ImmSrc     = 2'b00;
        aluOp      = 3'b000;

        ResultSrc  = 1'b0;
        A3Src      = 1'b0;

        PCSrc      = 2'b00;
        PCWrite    = 1'b0;
        Branch     = 1'b0;

        OldPCWrite = 1'b0;
        MDRWrite   = 1'b0;

        case (ps)

            // ----------------------------------------------------
            // IF: Fetch instruction @ PC, PC <- PC+1, OldPC <- PC
            // ----------------------------------------------------
            ST_IF: begin
                AdrSrc     = 1'b0;     // Adr = PC
                IRWrite    = 1'b1;     // IR <- Mem[PC]

                ALUSrcA    = 2'b00;    // SrcA = PC
                ALUSrcB    = 2'b01;    // SrcB = 1
                aluOp      = 3'b000;   // ADD => PC+1 (ALUResult)

                PCSrc      = 2'b00;    // PCNext = ALUResult[11:0]
                PCWrite    = 1'b1;

                OldPCWrite = 1'b1;     // OldPC <- PC (for branch target concat)
            end

            // ----------------------------------------------------
            // BranchZ Ri, adr9: if (R0 == Ri) PC <- {OldPC[11:9], adr9}
            // Datapath: A = R0, B = Ri
            // ----------------------------------------------------
            ST_BRANCH: begin
                ALUSrcA = 2'b10;       // SrcA = A (R0)
                ALUSrcB = 2'b00;       // SrcB = B (Ri)
                aluOp   = 3'b001;      // SUB => Zero when equal

                PCSrc   = 2'b10;       // PCNext = BranchTarget
                Branch  = 1'b1;        // TopModule: PCWrite_final = PCWrite | (Branch & Zero)
            end

            // ----------------------------------------------------
            // Jump adr12: PC <- adr12
            // ----------------------------------------------------
            ST_JUMP: begin
                PCSrc   = 2'b01;       // PCNext = JumpTarget
                PCWrite = 1'b1;
            end

            // ----------------------------------------------------
            // STORE adr12: M[adr12] <- R0
            // IMPORTANT: address must be in ALUOut BEFORE MemWrite
            // ----------------------------------------------------
            ST_STORE_EX: begin
                ImmSrc  = 2'b00;       // use adr-12 immediate
                ALUSrcB = 2'b10;       // SrcB = ImmExt
                aluOp   = 3'b110;      // Pass In2 => ALUResult = ImmExt => ALUOut <= adr12
            end

            ST_STORE_MEM: begin
                AdrSrc   = 1'b1;       // Adr = ALUOut[11:0]
                MemWrite = 1'b1;       // Mem[Adr] <- A (A holds R0)
            end

            // ----------------------------------------------------
            // LOAD adr12: R0 <- M[adr12]
            // ----------------------------------------------------
            ST_LOAD_EX: begin
                ImmSrc  = 2'b00;       // adr-12
                ALUSrcB = 2'b10;       // ImmExt
                aluOp   = 3'b110;      // Pass In2 => ALUOut <= adr12
            end

            ST_LOAD_MEM: begin
                AdrSrc   = 1'b1;       // Adr = ALUOut
                MDRWrite = 1'b1;       // MDR <- Mem[Adr]
            end

            ST_LOAD_WB: begin
                ResultSrc = 1'b1;      // Result = MDR
                A3Src     = 1'b0;      // write to R0
                RegWrite  = 1'b1;
            end

            // ----------------------------------------------------
            // Type-C: (func determines operation and special cases)
            // ----------------------------------------------------
            ST_C_ALU: begin
                ALUSrcA = 2'b10;       // A (R0)
                ALUSrcB = 2'b00;       // B (Ri)
                aluOp   = 3'b111;      // decode by func in AluController
            end

            ST_C_WB: begin
                ResultSrc = 1'b0;                     // Result = ALUOut
                A3Src     = moveTo ? 1'b1 : 1'b0;     // MoveTo writes Ri, else write R0
                RegWrite  = noOp   ? 1'b0 : 1'b1;     // NOP disables write
            end

            // ----------------------------------------------------
            // Immediate ALU ops: R0 <- R0 op Imm12
            // ----------------------------------------------------
            ST_IMM_EX: begin
                ImmSrc  = 2'b00;
                ALUSrcA = 2'b10;       // A (R0)
                ALUSrcB = 2'b10;       // ImmExt

                case (opcode)
                    4'b1100: aluOp = 3'b000; // ADDI
                    4'b1101: aluOp = 3'b001; // SUBI
                    4'b1110: aluOp = 3'b010; // ANDI
                    4'b1111: aluOp = 3'b011; // ORI
                    default: aluOp = 3'b000;
                endcase
            end

            ST_IMM_WB: begin
                ResultSrc = 1'b0;      // Result = ALUOut
                A3Src     = 1'b0;      // write R0
                RegWrite  = 1'b1;
            end

            default: ;
        endcase
    end

endmodule
