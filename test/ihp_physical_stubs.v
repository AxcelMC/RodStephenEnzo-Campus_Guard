// Temporary gate-level simulation stubs for IHP physical-only cells.
//
// These cells are inserted during physical implementation and do not
// implement Campus Guard functional logic.
//
// REMOVE this workaround once the GLS/PDK environment correctly
// provides or excludes these physical-only cells.

`timescale 1ns/1ps

`ifdef GL_TEST

module sg13g2_decap_8 ();
endmodule

module sg13g2_fill_2 ();
endmodule

module sg13g2_fill_1 ();
endmodule

`endif
