// Simple video test pattern generator example
// t* inputs are timings for sync in clock cycles
// pixel data is just a set of grayscale ramps
module tpg 
#(parameter PW=8, H_BITS=12, V_BITS=12)
(
   output hs_q,           // horizontal sync
   output vs_q,           // vertical sync
   output [3*PW-1:0] rgb, // data output
   output vld_q,          // valid data
   input [H_BITS-1:0] tHS_START,
   input [H_BITS-1:0] tHS_END,
   input [H_BITS-1:0] tHACT_START,
   input [H_BITS-1:0] tHACT_END,
   input [H_BITS-1:0] tH_END,
   input [V_BITS-1:0] tVS_START,
   input [V_BITS-1:0] tVS_END,
   input [V_BITS-1:0] tVACT_START,
   input [V_BITS-1:0] tVACT_END,
   input [H_BITS-1:0] tV_END,
   input clk,
   input rst_n
);

// begin dstate0
localparam SM0_S0 = 0;
localparam SM0_S1 = 1;
localparam SM0_S2 = 2;
// SmBegin ff decl begin
reg  hs_q;
reg  vs_q;
reg  vld_q;
reg  y_active_q;
reg [PW-1:0] cnt_q;
reg [H_BITS-1:0] x_q;
reg [V_BITS-1:0] y_q;
// SmBegin ff decl end
always @(posedge clk or negedge rst_n) begin : dstate0
	// SmBegin ff local begin
	reg  hs;
	reg  vs;
	reg  vld;
	reg  y_active;
	reg [PW-1:0] cnt;
	reg [H_BITS-1:0] x;
	reg [V_BITS-1:0] y;
	// SmBegin ff local end
	reg [1:0] state0_q, state0;
	if (~rst_n) begin
		// SmBegin ff init begin
		hs_q <= #1 1'b0;
		vs_q <= #1 1'b0;
		vld_q <= #1 1'b0;
		y_active_q <= #1 1'b0;
		cnt_q <= #1 8'b0;
		x_q <= #1 0;
		y_q <= #1 0;
		// SmBegin ff init end
		state0_q <= #1 SM0_S0;
	end
	else begin
		// set defaults for next state vars begin
		hs = hs_q;
		vs = vs_q;
		vld = vld_q;
		y_active = y_active_q;
		cnt = cnt_q;
		x = x_q;
		y = y_q;
		// set defaults for next state vars end
		state0 = state0_q;
		// SmForever
		case (state0_q)
			SM0_S0: begin
				y = 0;
				x = 0;
				if (x == tHS_START) begin
					hs = 1;
				end
				else begin
					if (x == tHS_END) begin
						hs = 0;
					end
				end
				if (x == tHACT_START) begin
					vld = y_active;
				end
				else begin
					if (x == tHACT_END) begin
						vld = 1'b0;
					end
				end
				if (vld) begin
					cnt = cnt + 1;
				end
				x = x + 1'b1;
				state0 = SM0_S1;
			end
			SM0_S1: begin
				if (x != tH_END) begin
					if (x == tHS_START) begin
						hs = 1;
					end
					else begin
						if (x == tHS_END) begin
							hs = 0;
						end
					end
					if (x == tHACT_START) begin
						vld = y_active;
					end
					else begin
						if (x == tHACT_END) begin
							vld = 1'b0;
						end
					end
					if (vld) begin
						cnt = cnt + 1;
					end
					x = x + 1'b1;
					// stay
				end
				else begin
					if (y == tVS_START) begin
						vs = 1;
					end
					else begin
						if (y == tVS_END) begin
							vs = 0;
						end
					end
					if (y == tVACT_START) begin
						y_active = 1'b1;
					end
					else begin
						if (y == tVACT_END) begin
							y_active = 1'b0;
						end
					end
					y = y + 1'b1;
					state0 = SM0_S2;
				end
			end
			SM0_S2: begin
				if (y != tV_END) begin
					x = 0;
					if (x == tHS_START) begin
						hs = 1;
					end
					else begin
						if (x == tHS_END) begin
							hs = 0;
						end
					end
					if (x == tHACT_START) begin
						vld = y_active;
					end
					else begin
						if (x == tHACT_END) begin
							vld = 1'b0;
						end
					end
					if (vld) begin
						cnt = cnt + 1;
					end
					x = x + 1'b1;
					state0 = SM0_S1;
				end
				else begin
					state0 = SM0_S0;
				end
			end
		endcase
		// SmEnd
		// Update ffs with next state vars begin
		hs_q <= #1 hs;
		vs_q <= #1 vs;
		vld_q <= #1 vld;
		y_active_q <= #1 y_active;
		cnt_q <= #1 cnt;
		x_q <= #1 x;
		y_q <= #1 y;
		// Update ffs with next state vars end
		state0_q <= #1 state0;
	end
end
// end dstate0

assign rgb={cnt_q, cnt_q, cnt_q};
endmodule
