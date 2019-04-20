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
always @(posedge clk or negedge rst_n) begin : dstate0
	// SmBegin ff local begin
	reg  motor_up_q, motor_up;
	reg  motor_dn_q, motor_dn;
	// SmBegin ff local end
	reg [2:0] state0_q, state0;
	if (~rst_n) begin
		// SmBegin ff init begin
		motor_up_q <= 0;
		motor_dn_q <= 0;
		// SmBegin ff init end
		state0_q <= SM0_0;
	end
	else begin
		// set defaults for next state vars begin
		motor_up = motor_up_q;
		motor_dn = motor_dn_q;
		// set defaults for next state vars end
		state0 = state0_q;
		// SmForever
		case (state0_q)
			SM0_0: begin
				if (up_limit) begin
					state0 = SM0_1;
				end
				else begin
					state0 = SM0_3;
				end
			end
			SM0_1: begin
				if (~(activate)) begin
					// stay
				end
				else begin
					motor_dn = 1;
					state0 = SM0_2;
				end
			end
			SM0_2: begin
				if (~(dn_limit)) begin
					// stay
				end
				else begin
					motor_dn = 0;
					state0 = SM0_0;
				end
			end
			SM0_3: begin
				if (~(activate)) begin
					// stay
				end
				else begin
					motor_up = 1;
					state0 = SM0_4;
				end
			end
			SM0_4: begin
				if (~(up_limit)) begin
					// stay
				end
				else begin
					motor_up = 0;
					state0 = SM0_0;
				end
			end
		endcase
		// SmEnd
		// Update ffs with next state vars begin
		motor_up_q <= motor_up;
		motor_dn_q <= motor_dn;
		// Update ffs with next state vars end
		state0_q <= state0;
	end
end
// drop_suffix begin
wire  motor_up = dstate0.motor_up_q;
wire  motor_dn = dstate0.motor_dn_q;
// drop_suffix end
// end dstate0

endmodule
