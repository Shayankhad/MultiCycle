module TopModule (
    input  wire clk,
    input  wire reset,

    output wire [3:0] Op,
    output wire [8:0] Func,
    output wire Zero
);

    wire AdrSrc;
    wire MemWrite;
    wire IRWrite;
    wire RegWrite;

    wire [1:0] ALUSrcA;
    wire [1:0] ALUSrcB;
    wire [1:0] ImmSrc;

    wire [2:0] ALUControl;

    wire A3Src;
    wire ResultSrc;

    wire [1:0] PCSrc;
    wire PCWrite_ctrl;
    wire Branch;

    wire OldPCWrite;
    wire MDRWrite;

    wire noOp;
    wire moveTo;

    wire PCWrite_final = PCWrite_ctrl | (Branch & Zero);

    // Controller
    CpuController U_CTRL (
        .clk(clk),
        .rst(reset),

        .opcode(Op),
        .func(Func),
        .Zero(Zero),

        .AdrSrc(AdrSrc),
        .MemWrite(MemWrite),
        .IRWrite(IRWrite),
        .RegWrite(RegWrite),

        .ALUSrcA(ALUSrcA),
        .ALUSrcB(ALUSrcB),
        .ImmSrc(ImmSrc),
        .ALUControl(ALUControl),

        .ResultSrc(ResultSrc),
        .A3Src(A3Src),

        .PCSrc(PCSrc),
        .PCWrite(PCWrite_ctrl),
        .Branch(Branch),

        .OldPCWrite(OldPCWrite),
        .MDRWrite(MDRWrite),

        .noOp(noOp),
        .moveTo(moveTo)
    );

    // Datapath
    Datapath U_DP (
        .clk(clk),
        .reset(reset),

        .AdrSrc(AdrSrc),
        .MemWrite(MemWrite),
        .IRWrite(IRWrite),
        .RegWrite(RegWrite),

        .ALUSrcA(ALUSrcA),
        .ALUSrcB(ALUSrcB),
        .ImmSrc(ImmSrc),
        .ALUControl(ALUControl),

        .A3Src(A3Src),
        .PCWrite(PCWrite_final),
        .PCSrc(PCSrc),
        .OldPCWrite(OldPCWrite),
        .MDRWrite(MDRWrite),

        .ResultSrc(ResultSrc),

        .Op(Op),
        .Func(Func),
        .Zero(Zero)
    );

endmodule
