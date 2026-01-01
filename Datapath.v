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
    input AWrite,
    input BWrite,

    output [3:0] Op,
    output [8:0] Func,
    output Zero
);

    // =======================
    // Internal wires/regs
    // =======================
    wire [11:0] PC, PCNext, Adr, OldPC;
    wire [15:0] Instr, ReadData, Data;
    wire [15:0] RD1, RD2, A, B;
    wire [15:0] ImmExt, SrcA, SrcB, ALUResult, ALUOut, Result;
    wire [2:0]  A3;

    wire [11:0] JumpTarget;
    wire [11:0] BranchTarget;
    wire [11:0] PCPlus1;

    integer cycle;

    // =======================
    // Program Counter
    // =======================
    PC_Register pc_reg (
        .clk(clk),
        .reset(reset),
        .PCWrite(PCWrite),
        .PCNext(PCNext),
        .PC(PC)
    );

    // =======================
    // Address mux
    // (you currently use Instr[11:0] for data access)
    // =======================
    assign Adr = (AdrSrc) ? Instr[11:0] : PC;

    // =======================
    // Memory
    // =======================
    Memory mem (
        .clk(clk),
        .MemWrite(MemWrite),
        .Address(Adr),
        .WriteData(A),
        .ReadData(ReadData)
    );

    // =======================
    // Instruction Register
    // =======================
    IR_Register ir (
        .clk(clk),
        .reset(reset),
        .IRWrite(IRWrite),
        .InstrIn(ReadData),
        .Instr(Instr)
    );

    // =======================
    // Memory Data Register
    // =======================
    MDR_Register mdr (
        .clk(clk),
        .reset(reset),
        .en(MDRWrite),
        .DataIn(ReadData),
        .DataOut(Data)
    );

    // =======================
    // OldPC register (for branch target)
    // =======================
    GenericReg #(12) oldpc_reg_en (
        .clk(clk),
        .reset(reset),
        .en(OldPCWrite),
        .d(PC),
        .q(OldPC)
    );

    // Decode fields
    assign Op   = Instr[15:12];
    assign Func = Instr[8:0];

    // write address (either R0 or Ri)
    assign A3 = (A3Src) ? Instr[11:9] : 3'b000;

    // =======================
    // Register file
    // A1 is hardwired to R0 in your design
    // =======================
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

    // =======================
    // A/B pipeline regs
    // IMPORTANT: connect reset (your GenericReg has reset port now)
    // =======================
    GenericReg #(16) regA (
        .clk(clk),
        .reset(reset),
        .en(AWrite),
        .d(RD1),
        .q(A)
    );

    GenericReg #(16) regB (
        .clk(clk),
        .reset(reset),
        .en(BWrite),
        .d(RD2),
        .q(B)
    );

    // =======================
    // Immediate extend
    // =======================
    ImmExtend imm_ext (
        .Instr(Instr),
        .ImmSrc(ImmSrc),
        .ImmExt(ImmExt)
    );

    // =======================
    // ALU input muxes
    // =======================
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

    // =======================
    // ALU
    // =======================
    ALU alu_inst (
        .In1(SrcA),
        .In2(SrcB),
        .ALUControl(ALUControl),
        .ALUResult(ALUResult),
        .Zero(Zero)
    );

    // =======================
    // ALUOut reg
    // =======================
    ALUOutReg alu_out_reg (
        .clk(clk),
        .reset(reset),
        .alu_result_wire(ALUResult),
        .alu_out_reg(ALUOut)
    );

    // =======================
    // Result mux (ALUOut vs MDR)
    // =======================
    Mux2 #(16) mux_res (
        .d0(ALUOut),
        .d1(Data),
        .s(ResultSrc),
        .y(Result)
    );

    // =======================
    // PCNext mux inputs
    // =======================
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

    // ============================================================
    // DEBUG PRINTS
    // ============================================================
    initial cycle = 0;

    always @(posedge clk) begin
        if (reset) begin
            cycle <= 0;
        end else begin
            cycle <= cycle + 1;

            // Print a compact line EVERY cycle (good for state/timing bugs)
            $display(
                "C%0d | PC=%03h PCNext=%03h | AdrSrc=%b Adr=%03h | IRW=%b Instr=%04h Op=%h Ri=%0d Imm12=%03h | "  //
                , cycle, PC, PCNext, AdrSrc, Adr, IRWrite, Instr, Op, Instr[11:9], Instr[11:0]
            );

            $display(
                "     AWrite=%b BWrite=%b | A(R0)=%04h B(Ri)=%04h RD1=%04h RD2=%04h | "
                , AWrite, BWrite, A, B, RD1, RD2
            );

            $display(
                "     ALUSrcA=%b ALUSrcB=%b ImmSrc=%b ImmExt=%04h | ALUC=%b ALURes=%04h ALUOut=%04h Zero=%b | "
                , ALUSrcA, ALUSrcB, ImmSrc, ImmExt, ALUControl, ALUResult, ALUOut, Zero
            );

            $display(
                "     ResultSrc=%b Result=%04h | RegW=%b A3=%0d WD3=%04h | MemW=%b WData(A)=%04h MDRW=%b MDR=%04h | "
                , ResultSrc, Result, RegWrite, A3, Result, MemWrite, A, MDRWrite, Data
            );

            // Show the target result location every cycle
            $display("     RAM[110]=%04h", mem.ram[12'h110]);

            // Extra highlight when key events happen
            if (MemWrite) begin
                $display("  >>> MEMWRITE: M[%03h] <= %04h", Adr, A);
            end
            if (RegWrite) begin
                $display("  >>> REGWRITE: R[%0d] <= %04h", A3, Result);
            end
            if (IRWrite) begin
                $display("  >>> IRWRITE: IR <= M[%03h] (%04h)", Adr, ReadData);
            end

            $display("------------------------------------------------------------");
        end
    end

endmodule
