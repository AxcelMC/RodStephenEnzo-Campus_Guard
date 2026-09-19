`default_nettype none
`timescale 1ns/1ps

module tb;

    // Tiny Tapeout inputs
    reg  [7:0] ui_in;
    reg  [7:0] uio_in;
    reg        ena;
    reg        clk;
    reg        rst_n;

    // Tiny Tapeout outputs
    wire [7:0] uo_out;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;

    // Device Under Test
    tt_um_AxcelMC_campus_sentinel dut (
        .ui_in(ui_in),
        .uo_out(uo_out),
        .uio_in(uio_in),
        .uio_out(uio_out),
        .uio_oe(uio_oe),
        .ena(ena),
        .clk(clk),
        .rst_n(rst_n)
    );

    // Waveform dump
    initial begin
        $dumpfile("tb.fst");
        $dumpvars(0, tb);
    end

endmodule

`default_nettype wire
