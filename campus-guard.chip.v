`default_nettype none

module wokwi (
    input  wire VCC,
    input  wire GND,
    input  wire CLK,

    input  wire Smoke,
    input  wire Motion,
    input  wire Door,
    input  wire Panic,

    input  wire Reset,
    input  wire Ack,

    output wire Safe,
    output wire Warning,
    output wire Critical,
    output wire Evacuate,

    output wire Buzzer,

    output reg  RouteA,
    output reg  RouteB,
    output reg  RouteC
);

    // ============================================================
    // CAMPUS SENTINEL 2.0
    // Multi-Hazard Emergency Management Controller
    //
    // 00 = SAFE
    // 01 = WARNING
    // 10 = CRITICAL
    // 11 = EVACUATE
    // ============================================================

    localparam STATE_SAFE     = 2'b00;
    localparam STATE_WARNING  = 2'b01;
    localparam STATE_CRITICAL = 2'b10;
    localparam STATE_EVAC     = 2'b11;

    reg [1:0] current_state;
    reg [1:0] next_state;

    // ============================================================
    // HAZARD DETECTION
    // ============================================================

    wire AnyHazard;
    wire CriticalHazard;

    // One or more normal hazards
    assign AnyHazard =
        Smoke |
        Motion |
        Door;

    // Any two normal hazards = critical condition
    assign CriticalHazard =
        (Smoke & Motion) |
        (Smoke & Door) |
        (Motion & Door);

    // ============================================================
    // STATE REGISTER
    // ============================================================

    always @(posedge CLK) begin

        if (Reset)
            current_state <= STATE_SAFE;
        else
            current_state <= next_state;

    end

    // ============================================================
    // NEXT-STATE LOGIC
    // ============================================================

    always @(*) begin

        // Default: remain in current state
        next_state = current_state;

        case (current_state)

            // ----------------------------------------------------
            // SAFE
            // ----------------------------------------------------

            STATE_SAFE: begin

                if (Panic)
                    next_state = STATE_EVAC;

                else if (CriticalHazard)
                    next_state = STATE_CRITICAL;

                else if (AnyHazard)
                    next_state = STATE_WARNING;

            end

            // ----------------------------------------------------
            // WARNING
            // ----------------------------------------------------

            STATE_WARNING: begin

                if (Panic)
                    next_state = STATE_EVAC;

                else if (CriticalHazard)
                    next_state = STATE_CRITICAL;

                else if (!AnyHazard)
                    next_state = STATE_SAFE;

            end

            // ----------------------------------------------------
            // CRITICAL
            //
            // This state is latched.
            // Removing the hazards does not immediately clear it.
            // ----------------------------------------------------

            STATE_CRITICAL: begin

                if (Panic)
                    next_state = STATE_EVAC;

                else if (Ack && !AnyHazard)
                    next_state = STATE_SAFE;

            end

            // ----------------------------------------------------
            // EVACUATE
            //
            // This state is also latched.
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
            // FAIL-SAFE DEFAULT
            // ----------------------------------------------------

            default: begin
                next_state = STATE_SAFE;
            end

        endcase

    end

    // ============================================================
    // STATUS OUTPUTS
    // ============================================================

    assign Safe =
        (current_state == STATE_SAFE);

    assign Warning =
        (current_state == STATE_WARNING);

    assign Critical =
        (current_state == STATE_CRITICAL);

    assign Evacuate =
        (current_state == STATE_EVAC);

    // ============================================================
    // BUZZER
    // ============================================================

    assign Buzzer =
        Warning |
        Critical |
        Evacuate;

    // ============================================================
    // SMART EVACUATION ROUTING
    //
    // Panic          -> EXIT A
    // Smoke + Door   -> EXIT C
    // Smoke          -> EXIT B
    // Door           -> EXIT A
    // Other critical -> EXIT A
    // ============================================================

    always @(*) begin

        // Default: no evacuation route
        RouteA = 1'b0;
        RouteB = 1'b0;
        RouteC = 1'b0;

        if (Critical || Evacuate) begin

            // Highest priority: panic
            if (Panic) begin

                RouteA = 1'b1;

            end

            // Smoke + Door
            else if (Smoke && Door) begin

                RouteC = 1'b1;

            end

            // Smoke-related emergency
            else if (Smoke) begin

                RouteB = 1'b1;

            end

            // Door-related emergency
            else if (Door) begin

                RouteA = 1'b1;

            end

            // Default emergency route
            else begin

                RouteA = 1'b1;

            end

        end

    end

endmodule

`default_nettype wire