`timescale 1ns/1ps

module tb_top_sum10;

  // --- DUT inputs ---
  reg clk;
  reg reset;

  // --- DUT outputs (optional debug) ---
  wire [3:0] Op;
  wire [8:0] Func;
  wire Zero;

  // Instantiate your TopModule
  TopModule uut (
    .clk(clk),
    .reset(reset),
    .Op(Op),
    .Func(Func),
    .Zero(Zero)
  );

  // Clock: 10ns period
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  // Helper task to end sim with message
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

  // Expected sum of 1..10 = 55 = 0x0037
  localparam [15:0] EXPECTED_SUM = 16'h0037;
  localparam [11:0] RESULT_ADDR  = 12'h110;

  initial begin
    // VCD dump for waveform debugging
    $dumpfile("tb_top_sum10.vcd");
    $dumpvars(0, tb_top_sum10);

    // Reset sequence
    reset = 1'b1;
    cycles = 0;
    repeat (3) @(posedge clk);
    reset = 1'b0;

    // Run until result is written or timeout
    // (Multi-cycle CPU => we allow plenty of cycles)
    for (cycles = 0; cycles < 500; cycles = cycles + 1) begin
      @(posedge clk);

      // Read result directly from unified memory inside Memory.v
      // Path: TopModule -> Datapath instance U_DP -> Memory instance mem -> ram[]
      result_word = uut.U_DP.mem.ram[RESULT_ADDR];

      // As soon as it becomes the expected value, pass
      if (result_word === EXPECTED_SUM) begin
        $display("PASS: sum stored at ram[0x%0h] = 0x%04h (%0d) after %0d cycles",
                 RESULT_ADDR, result_word, result_word, cycles);
        finish_with("TEST PASSED ✅");
      end

      // Optional: if it becomes something else non-zero early, you can print progress
      // if (result_word !== 16'h0000) $display("INFO: result now = 0x%04h at cycle %0d", result_word, cycles);
    end

    // If we reach here, timed out
    result_word = uut.U_DP.mem.ram[RESULT_ADDR];
    $display("FAIL: timeout. ram[0x%0h] = 0x%04h (expected 0x%04h)",
             RESULT_ADDR, result_word, EXPECTED_SUM);
    finish_with("TEST FAILED ❌ (timeout)");
  end

endmodule
