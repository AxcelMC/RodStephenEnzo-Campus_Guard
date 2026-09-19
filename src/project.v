/*
 * Campus Sentinel 2.0
 * Multi-Hazard Emergency Detection and Evacuation Controller
 *
 * Author: Rod Geryk Navarro
 *
 * Tiny Tapeout / IHP SG13G2 version
 */

`default_nettype none

module tt_um_AxcelMC_campus_sentinel (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    // ============================================================
    // INPUT MAPPING
    // ============================================================
    //
    // ui_in[0] = Smoke
    // ui_in[1] = Motion
    // ui_in[2] = Door
    // ui_in[3] = Panic
    // ui_in[4] = Manual/System Reset
    // ui_in[5] = Acknowledge
    // ui_in[6] = Reserved
    // ui_in[7] = Reserved
    //
    // clk      = Dedicated system clock
    // rst_n    = Dedicated active-low hardware reset
    // ============================================================

    wire Smoke;
    wire Motion;
    wire Door;
    wire Panic;
    wire Reset;
    wire Ack;

    assign Smoke  = ui_in[0];
    assign Motion = ui_in[1];
    assign Door   = ui_in[2];
    assign Panic  = ui_in[3];
    assign Reset  = ui_in[4];
    assign Ack    = ui_in[5];


    // ============================================================
    // FSM STATE DEFINITIONS
    // ============================================================

    localparam STATE_SAFE     = 2'b00;
    localparam STATE_WARNING  = 2'b01;
    localparam STATE_CRITICAL = 2'b10;
    localparam STATE_EVAC     = 2'b11;

    reg [1:0] current_state;
    reg [1:0] next_state;


    // ============================================================
    // HAZARD FUSION
    // ============================================================

    wire AnyHazard;
    wire CriticalHazard;

    // At least one normal hazard is active.
    assign AnyHazard =
        Smoke |
        Motion |
        Door;

    // Two or more normal hazards indicate a critical condition.
    assign CriticalHazard =
        (Smoke & Motion) |
        (Smoke & Door)   |
        (Motion & Door);


    // ============================================================
    // STATE REGISTER
    // ============================================================
    //
    // rst_n is the Tiny Tapeout active-low hardware reset.
    //
    // Reset is also available on ui_in[4] as a user-controlled
    // synchronous reset.
    // ============================================================

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n)
            current_state <= STATE_SAFE;

        else if (Reset)
            current_state <= STATE_SAFE;

        else
            current_state <= next_state;

    end


    // ============================================================
    // NEXT-STATE LOGIC
    // ============================================================

    always @(*) begin

        // By default, remain in the current state.
        next_state = current_state;

        case (current_state)

            // ----------------------------------------------------
            // SAFE
            // ----------------------------------------------------

            STATE_SAFE: begin

                // Panic has highest priority.
                if (Panic)
                    next_state = STATE_EVAC;

                // Two or more normal hazards.
                else if (CriticalHazard)
                    next_state = STATE_CRITICAL;

                // One normal hazard.
                else if (AnyHazard)
                    next_state = STATE_WARNING;

            end


            // ----------------------------------------------------
            // WARNING
            // ----------------------------------------------------

            STATE_WARNING: begin

                // Panic immediately escalates to evacuation.
                if (Panic)
                    next_state = STATE_EVAC;

                // Multiple hazards escalate to critical.
                else if (CriticalHazard)
                    next_state = STATE_CRITICAL;

                // Warning automatically clears when the
                // single hazard disappears.
                else if (!AnyHazard)
                    next_state = STATE_SAFE;

            end


            // ----------------------------------------------------
            // CRITICAL
            // ----------------------------------------------------
            //
            // CRITICAL is latched.
            //
            // Removing the hazard does not automatically
            // return the system to SAFE.
            //
            // ACK is required after hazards are gone.
            // ----------------------------------------------------

            STATE_CRITICAL: begin

                if (Panic)
                    next_state = STATE_EVAC;

                else if (Ack && !AnyHazard)
                    next_state = STATE_SAFE;

            end


            // ----------------------------------------------------
            // EVACUATE
            // ----------------------------------------------------
            //
            // EVACUATE is also latched.
            //
            // Panic must be released, all normal hazards must
            // be clear, and ACK must be asserted before the
            // system can return to SAFE.
            // ----------------------------------------------------

            STATE_EVAC: begin

                if (
                    Ack &&
                    !Panic &&
                    !AnyHazard
                )
                    next_state = STATE_SAFE;

            end


            // ----------------------------------------------------
            // DEFAULT / RECOVERY
            // ----------------------------------------------------

            default: begin
                next_state = STATE_SAFE;
            end

        endcase

    end


    // ============================================================
    // STATE OUTPUT DECODER
    // ============================================================

    wire Safe;
    wire Warning;
    wire Critical;
    wire Evacuate;

    assign Safe =
        (current_state == STATE_SAFE);

    assign Warning =
        (current_state == STATE_WARNING);

    assign Critical =
        (current_state == STATE_CRITICAL);

    assign Evacuate =
        (current_state == STATE_EVAC);


    // ============================================================
    // AUDIBLE ALARM
    // ============================================================

    wire Buzzer;

    assign Buzzer =
        Warning |
        Critical |
        Evacuate;


    // ============================================================
    // EVACUATION ROUTING
    // ============================================================
    //
    // Routing demonstration policy:
    //
    // Panic          -> Route A
    // Smoke + Door   -> Route C
    // Smoke          -> Route B
    // Door           -> Route A
    // Other critical -> Route A
    //
    // Routes are enabled only during CRITICAL or EVACUATE.
    // ============================================================

    reg RouteA;
    reg RouteB;
    reg RouteC;

    always @(*) begin

        RouteA = 1'b0;
        RouteB = 1'b0;
        RouteC = 1'b0;

        if (Critical || Evacuate) begin

            // Highest priority route for panic.
            if (Panic) begin

                RouteA = 1'b1;

            end

            // Smoke and door condition.
            else if (Smoke && Door) begin

                RouteC = 1'b1;

            end

            // Smoke-related critical event.
            else if (Smoke) begin

                RouteB = 1'b1;

            end

            // Door-related critical event.
            else if (Door) begin

                RouteA = 1'b1;

            end

            // Default critical route.
            else begin

                RouteA = 1'b1;

            end

        end

    end


    // ============================================================
    // TINY TAPEOUT OUTPUT MAPPING
    // ============================================================
    //
    // uo_out[0] = Safe
    // uo_out[1] = Warning
    // uo_out[2] = Critical
    // uo_out[3] = Evacuate
    // uo_out[4] = Buzzer
    // uo_out[5] = RouteA
    // uo_out[6] = RouteB
    // uo_out[7] = RouteC
    // ============================================================

    assign uo_out[0] = Safe;
    assign uo_out[1] = Warning;
    assign uo_out[2] = Critical;
    assign uo_out[3] = Evacuate;
    assign uo_out[4] = Buzzer;
    assign uo_out[5] = RouteA;
    assign uo_out[6] = RouteB;
    assign uo_out[7] = RouteC;


    // ============================================================
    // BIDIRECTIONAL I/O
    // ============================================================
    //
    // Campus Sentinel currently does not require bidirectional
    // pins. All uio pins are therefore configured as inputs and
    // are not driven.
    // ============================================================

    assign uio_out = 8'b00000000;
    assign uio_oe  = 8'b00000000;


    // ============================================================
    // UNUSED SIGNAL HANDLING
    // ============================================================

    wire _unused;

    assign _unused =
        &{
            ena,
            uio_in,
            ui_in[7:6],
            1'b0
        };

endmodule

`default_nettype wire
