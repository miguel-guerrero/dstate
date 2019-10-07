module tpg 
#(parameter PW=8, H_BITS=12, V_BITS=12)
(
   output hs_q,            
   output vs_q,            
   output [3*PW-1:0] rgb,  
   output vld_q,           
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
// SmBegin ff local begin
reg  hs_nxt;
reg  vs_nxt;
reg  vld_nxt;
reg  y_active_nxt;
reg [PW-1:0] cnt_nxt;
reg [H_BITS-1:0] x_nxt;
reg [V_BITS-1:0] y_nxt;
// SmBegin ff local end
reg [1:0] state0_q, state0_nxt;
always @* begin : dstate0_combo
    // set defaults for next state vars begin
    hs_nxt = hs_q;
    vs_nxt = vs_q;
    vld_nxt = vld_q;
    y_active_nxt = y_active_q;
    cnt_nxt = cnt_q;
    x_nxt = x_q;
    y_nxt = y_q;
    // set defaults for next state vars end
    state0_nxt = state0_q;
    // SmForever
    case (state0_q)
        SM0_S0: begin
                y_nxt = 0;
                x_nxt = 0;
                if (x_nxt == tHS_START) begin
                    hs_nxt = 1;
                end
                else begin
                    if (x_nxt == tHS_END) begin
                        hs_nxt = 0;
                    end
                end
                if (x_nxt == tHACT_START) begin
                    vld_nxt = y_active_nxt;
                end
                else begin
                    if (x_nxt == tHACT_END) begin
                        vld_nxt = 1'b0;
                    end
                end
                if (vld_nxt) begin
                    cnt_nxt = cnt_nxt + 1;
                end
                x_nxt = x_nxt + 1'b1;
                state0_nxt = SM0_S1;
        end
        SM0_S1: begin
                if (x_nxt != tH_END) begin
                    if (x_nxt == tHS_START) begin
                        hs_nxt = 1;
                    end
                    else begin
                        if (x_nxt == tHS_END) begin
                            hs_nxt = 0;
                        end
                    end
                    if (x_nxt == tHACT_START) begin
                        vld_nxt = y_active_nxt;
                    end
                    else begin
                        if (x_nxt == tHACT_END) begin
                            vld_nxt = 1'b0;
                        end
                    end
                    if (vld_nxt) begin
                        cnt_nxt = cnt_nxt + 1;
                    end
                    x_nxt = x_nxt + 1'b1;
                    // stay
                end
                else begin
                    if (y_nxt == tVS_START) begin
                        vs_nxt = 1;
                    end
                    else begin
                        if (y_nxt == tVS_END) begin
                            vs_nxt = 0;
                        end
                    end
                    if (y_nxt == tVACT_START) begin
                        y_active_nxt = 1'b1;
                    end
                    else begin
                        if (y_nxt == tVACT_END) begin
                            y_active_nxt = 1'b0;
                        end
                    end
                    y_nxt = y_nxt + 1'b1;
                    state0_nxt = SM0_S2;
                end
        end
        SM0_S2: begin
                if (y_nxt != tV_END) begin
                    x_nxt = 0;
                    if (x_nxt == tHS_START) begin
                        hs_nxt = 1;
                    end
                    else begin
                        if (x_nxt == tHS_END) begin
                            hs_nxt = 0;
                        end
                    end
                    if (x_nxt == tHACT_START) begin
                        vld_nxt = y_active_nxt;
                    end
                    else begin
                        if (x_nxt == tHACT_END) begin
                            vld_nxt = 1'b0;
                        end
                    end
                    if (vld_nxt) begin
                        cnt_nxt = cnt_nxt + 1;
                    end
                    x_nxt = x_nxt + 1'b1;
                    state0_nxt = SM0_S1;
                end
                else begin
                    state0_nxt = SM0_S0;
                end
        end
    endcase
    // SmEnd
end // dstate0_combo


always @(posedge clk or negedge rst_n) begin : dstate0
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
        // Update ffs with next state vars begin
        hs_q <= #1 hs_nxt;
        vs_q <= #1 vs_nxt;
        vld_q <= #1 vld_nxt;
        y_active_q <= #1 y_active_nxt;
        cnt_q <= #1 cnt_nxt;
        x_q <= #1 x_nxt;
        y_q <= #1 y_nxt;
        // Update ffs with next state vars end
        state0_q <= #1 state0_nxt;
    end
end
// end dstate0

assign rgb={cnt_q, cnt_q, cnt_q};
endmodule
