`timescale 1ns/1ps

module tb_top_sum10;

  reg clk;
  reg reset;

  wire [3:0] Op;
  wire [8:0] Func;
  wire Zero;

  TopModule uut (
    .clk(clk),
    .reset(reset),
    .Op(Op),
    .Func(Func),
    .Zero(Zero)
  );

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  task finish_with(input [1023:0] msg);
    begin
      $display("\n==================================================");
      $display("%s", msg);
      $display("==================================================\n");
      $finish;
    end
  endtask

  integer cycles;
  reg [15:0] result_word;

  localparam [15:0] EXPECTED_SUM = 16'h0037;
  localparam [11:0] RESULT_ADDR  = 12'h110;

  initial begin
    $dumpfile("tb_top_sum10.vcd");
    $dumpvars(0, tb_top_sum10);

    reset = 1'b1;
    cycles = 0;
    repeat (3) @(posedge clk);
    reset = 1'b0;

    for (cycles = 0; cycles < 500; cycles = cycles + 1) begin
      @(posedge clk);

      result_word = uut.U_DP.mem.ram[RESULT_ADDR];

      if (result_word === EXPECTED_SUM) begin
        $display("PASS: sum stored at ram[0x%0h] = 0x%04h (%0d) after %0d cycles",RESULT_ADDR, result_word, result_word, cycles);
        finish_with("TEST PASSED !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
      end

    end

    result_word = uut.U_DP.mem.ram[RESULT_ADDR];
    $display("FAIL: timeout. ram[0x%0h] = 0x%04h (expected 0x%04h)",
             RESULT_ADDR, result_word, EXPECTED_SUM);
    finish_with("TEST FAILED !!!!!!!!!!!!!!!!!!");
  end

endmodule
