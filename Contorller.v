module CpuController (
    input  wire clk,
    input  wire rst,
    input  wire [3:0] opcode,
    input  wire [8:0] func,
    input  wire  Zero,

    output reg AdrSrc,
    output reg MemWrite,
    output reg IRWrite,
    output reg RegWrite,

    output reg  [1:0] ALUSrcA,
    output reg  [1:0] ALUSrcB,
    output reg  [1:0] ImmSrc,
    output wire [2:0] ALUControl,

    output reg ResultSrc,
    output reg A3Src,

    output reg  [1:0]  PCSrc,
    output reg PCWrite,
    output reg Branch,

    output reg OldPCWrite,
    output reg MDRWrite,

    output wire noOp,
    output wire moveTo
);

    localparam [3:0]
        ST_IF  = 4'd0,
        ST_ID  = 4'd1,
        ST_BRANCH = 4'd2,
        ST_C_ALU = 4'd3,
        ST_C_WB = 4'd4,
        ST_JUMP = 4'd5,
        ST_STORE = 4'd6,
        ST_LOAD_EX = 4'd7,
        ST_LOAD_MEM = 4'd8,
        ST_LOAD_WB = 4'd9,
        ST_IMM_EX = 4'd10,
        ST_IMM_WB = 4'd11;

    reg [3:0] ps, ns;
    reg [2:0] aluOp;

    AluController U_ALUCTRL (
        .aluOp(aluOp),
        .func(func),
        .aluOpc(ALUControl),
        .noOp(noOp),
        .moveTo(moveTo)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) ps <= ST_IF;
        else     ps <= ns;
    end

    always @(*) begin
        ns = ST_IF;
        case (ps)
            ST_IF: ns = ST_ID;

            ST_ID: begin
                case (opcode)
                    4'b0100: ns = ST_BRANCH;
                    4'b1000: ns = ST_C_ALU;
                    4'b0010: ns = ST_JUMP;
                    4'b0001: ns = ST_STORE;
                    4'b0000: ns = ST_LOAD_EX;
                    4'b1100,
                    4'b1101,
                    4'b1110,
                    4'b1111: ns = ST_IMM_EX;
                    default: ns = ST_IF;
                endcase
            end

            ST_BRANCH: ns = ST_IF;
            ST_C_ALU: ns = ST_C_WB;
            ST_C_WB: ns = ST_IF;
            ST_JUMP: ns = ST_IF;

            ST_STORE: ns = ST_IF;

            ST_LOAD_EX: ns = ST_LOAD_MEM;
            ST_LOAD_MEM:ns = ST_LOAD_WB;
            ST_LOAD_WB:  ns = ST_IF;

            ST_IMM_EX: ns = ST_IMM_WB;
            ST_IMM_WB: ns = ST_IF;

            default:ns = ST_IF;
        endcase
    end

    always @(*) begin
        AdrSrc = 1'b0;
        MemWrite = 1'b0;
        IRWrite = 1'b0;
        RegWrite = 1'b0;

        ALUSrcA = 2'b00;
        ALUSrcB = 2'b00;
        ImmSrc = 2'b00;
        aluOp  = 3'b000;

        ResultSrc = 1'b0;
        A3Src = 1'b0;

        PCSrc = 2'b00;
        PCWrite = 1'b0;
        Branch = 1'b0;

        OldPCWrite = 1'b0;
        MDRWrite   = 1'b0;

        case (ps)

            ST_IF: begin
                AdrSrc = 1'b0;
                IRWrite = 1'b1;

                ALUSrcA = 2'b00;
                ALUSrcB = 2'b01;
                aluOp = 3'b000;

                PCSrc = 2'b00;
                PCWrite = 1'b1;

                OldPCWrite = 1'b1;
            end

            ST_BRANCH: begin
                ALUSrcA = 2'b10;
                ALUSrcB = 2'b00;
                aluOp = 3'b100;

                PCSrc = 2'b10;
                Branch = 1'b1;
            end

            ST_JUMP: begin
                PCSrc = 2'b01;
                PCWrite = 1'b1;
            end

            ST_STORE: begin
                ImmSrc = 2'b00;
                ALUSrcB = 2'b10;
                aluOp = 3'b100;

                AdrSrc = 1'b1;
                MemWrite = 1'b1;
            end

            ST_LOAD_EX: begin
                ImmSrc  = 2'b00;
                ALUSrcB = 2'b10;
                aluOp   = 3'b100;
            end

            ST_LOAD_MEM: begin
                AdrSrc   = 1'b1;
                MDRWrite = 1'b1;
            end

            ST_LOAD_WB: begin
                ResultSrc = 1'b1;
                A3Src = 1'b0;
                RegWrite  = 1'b1;
            end

            ST_C_ALU: begin
                ALUSrcA = 2'b10;
                ALUSrcB = 2'b00;
                aluOp   = 3'b100;
            end

            ST_C_WB: begin
                ResultSrc = 1'b0;
                A3Src = moveTo ? 1'b1 : 1'b0;
                RegWrite = noOp ? 1'b0 : 1'b1;
            end

            ST_IMM_EX: begin
                ImmSrc  = 2'b00;
                ALUSrcA = 2'b10;
                ALUSrcB = 2'b10;

                case (opcode)
                    4'b1100: aluOp = 3'b000;
                    4'b1101: aluOp = 3'b001;
                    4'b1110: aluOp = 3'b010;
                    4'b1111: aluOp = 3'b011;
                    default: aluOp = 3'b000;
                endcase
            end

            ST_IMM_WB: begin
                ResultSrc = 1'b0;
                A3Src     = 1'b0;
                RegWrite  = 1'b1;
            end

            default: ;
        endcase
    end

endmodule

