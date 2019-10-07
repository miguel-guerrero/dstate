module motor(
    input clk, activate, up_limit, dn_limit, rst_n,
    output motor_up, motor_dn
);

// begin dstate0
localparam SM0_0 = 0;
localparam SM0_1 = 1;
localparam SM0_2 = 2;
localparam SM0_3 = 3;
localparam SM0_4 = 4;
// SmBegin ff decl begin
reg  motor_up, motor_up_nxt;
reg  motor_dn, motor_dn_nxt;
// SmBegin ff decl end
reg [2:0] state0, state0_nxt;

always @* begin : dstate0_combo
    // set defaults for next state vars begin
    motor_up_nxt = motor_up;
    motor_dn_nxt = motor_dn;
    // set defaults for next state vars end
    state0_nxt = state0;
    // SmForever
    case (state0)
        SM0_0: begin
                if (up_limit) begin
                    state0_nxt = SM0_1;
                end
                else begin
                    state0_nxt = SM0_3;
                end
        end
        SM0_1: begin
                if (~(activate)) begin
                    // stay
                end
                else begin
                    motor_dn_nxt = 1;
                    state0_nxt = SM0_2;
                end
        end
        SM0_2: begin
                if (~(dn_limit)) begin
                    // stay
                end
                else begin
                    motor_dn_nxt = 0;
                    state0_nxt = SM0_0;
                end
        end
        SM0_3: begin
                if (~(activate)) begin
                    // stay
                end
                else begin
                    motor_up_nxt = 1;
                    state0_nxt = SM0_4;
                end
        end
        SM0_4: begin
                if (~(up_limit)) begin
                    // stay
                end
                else begin
                    motor_up_nxt = 0;
                    state0_nxt = SM0_0;
                end
        end
    endcase
    // SmEnd
end // dstate0_combo

always @(posedge clk or negedge rst_n) begin : dstate0
    if (~rst_n) begin
        // SmBegin ff init begin
        motor_up <= 0;
        motor_dn <= 0;
        // SmBegin ff init end
        state0 <= SM0_0;
    end
    else begin
        // Update ffs with next state vars begin
        motor_up <= motor_up_nxt;
        motor_dn <= motor_dn_nxt;
        // Update ffs with next state vars end
        state0 <= state0_nxt;
    end
end
// end dstate0

endmodule
