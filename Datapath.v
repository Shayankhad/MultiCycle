module Datapath (
    input clk,
    input reset,

    input AdrSrc,
    input MemWrite,
    input IRWrite,
    input RegWrite,

    input [1:0]  ALUSrcA,
    input [1:0]  ALUSrcB,
    input [1:0]  ImmSrc,
    input [2:0]  ALUControl,

    input A3Src,
    input PCWrite,
    input [1:0] PCSrc,
    input OldPCWrite,
    input MDRWrite,

    input ResultSrc,

    output [3:0] Op,
    output [8:0] Func,
    output  Zero
);

    wire [11:0] PC, PCNext, Adr, OldPC;
    wire [15:0] Instr, ReadData, Data;
    wire [15:0] RD1, RD2, A, B;
    wire [15:0] ImmExt, SrcA, SrcB, ALUResult, ALUOut, Result;
    wire [2:0]  A3;

    wire [11:0] JumpTarget;
    wire [11:0] BranchTarget;
    wire [11:0] PCPlus1;

    PC_Register pc_reg (
        .clk(clk),
        .reset(reset),     
        .PCWrite(PCWrite),
        .PCNext(PCNext),
        .PC(PC)
    );


    assign Adr = (AdrSrc) ? Instr[11:0] : PC;

    Memory mem (
        .clk(clk),
        .MemWrite(MemWrite),
        .Address(Adr),
        .WriteData(A),
        .ReadData(ReadData)
    );

    IR_Register ir (
        .clk(clk),
        .reset(reset),     
        .IRWrite(IRWrite),
        .InstrIn(ReadData),
        .Instr(Instr)
    );

    MDR_Register mdr (
        .clk(clk),
        .reset(reset),     
        .en(MDRWrite),  
        .DataIn(ReadData),
        .DataOut(Data)
    );

    GenericReg #(12) oldpc_reg_en (
        .clk(clk),
        .reset(reset),     
        .en(OldPCWrite),
        .d(PC),
        .q(OldPC)
    );

    assign Op   = Instr[15:12];
    assign Func = Instr[8:0];

    assign A3 = (A3Src) ? Instr[11:9] : 3'b000;

    RegisterFile rf (
        .clk(clk),
        .RegWrite(RegWrite),
        .A1(3'b000),
        .A2(Instr[11:9]),
        .A3(A3),
        .WD3(Result),
        .RD1(RD1),
        .RD2(RD2)
    );

    GenericReg #(16) regA (
        .clk(clk),
        .en(1'b1),    
        .d(RD1),
        .q(A)
    );

    GenericReg #(16) regB (
        .clk(clk),
        .en(1'b1),     
        .d(RD2),
        .q(B)
    );

    ImmExtend imm_ext (
        .Instr(Instr),
        .ImmSrc(ImmSrc),
        .ImmExt(ImmExt)
    );

    Mux3 #(16) mux_srcA (
        .d0({4'b0, PC}),
        .d1({4'b0, OldPC}),
        .d2(A),
        .s(ALUSrcA),
        .y(SrcA)
    );

    Mux3 #(16) mux_srcB (
        .d0(B),
        .d1(16'd1),
        .d2(ImmExt),
        .s(ALUSrcB),
        .y(SrcB)
    );

    ALU alu_inst (
        .In1(SrcA),
        .In2(SrcB),
        .ALUControl(ALUControl),
        .ALUResult(ALUResult),
        .Zero(Zero)
    );

    ALUOutReg alu_out_reg (
        .clk(clk),
        .reset(reset),     
        .alu_result_wire(ALUResult),
        .alu_out_reg(ALUOut)
    );

    Mux2 #(16) mux_res (
        .d0(ALUOut),
        .d1(Data),
        .s(ResultSrc),
        .y(Result)
    );

    assign JumpTarget   = Instr[11:0];
    assign BranchTarget = {OldPC[11:9], Instr[8:0]};
    assign PCPlus1      = ALUResult[11:0];

    Mux3 #(12) mux_pcnext (
        .d0(PCPlus1),
        .d1(JumpTarget),
        .d2(BranchTarget),
        .s(PCSrc),
        .y(PCNext)
    );

endmodule
