module Memory (
    input clk,
    input MemWrite,
    input [11:0] Address,
    input [15:0] WriteData,
    output [15:0] ReadData
);

    reg [15:0] ram [4095:0];
    integer i;
    reg [8*256:1] hexfile;   // 256-char string

    always @(posedge clk) begin
        if (MemWrite)
            ram[Address] <= WriteData;
    end

    assign ReadData = ram[Address];

    initial begin
        // optional: clear RAM to known value (avoids X if file missing)
        for (i = 0; i < 4096; i = i + 1)
            ram[i] = 16'h0000;

        // allow: vsim ... +HEX=path/to/program.hex
        if (!$value$plusargs("HEX=%s", hexfile))
            hexfile = "program.hex";

        $display("MEM INIT: loading hex from: %0s", hexfile);
        $readmemh(hexfile, ram);
    end
endmodule
