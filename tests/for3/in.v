`define ASSERT(c)  if (~(c)) begin $display("ERROR: ASSERT failure %m"); $finish(); end
`define loop(init)  init; do begin
`define next(cond,incr) incr; end while(cond)

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

SmBegin
   reg hs = 1'b0, vs = 1'b0, vld = 1'b0, y_active = 1'b0;
   reg [PW-1:0] cnt = 8'b0;
   reg [H_BITS-1:0] x = 0;
   reg [V_BITS-1:0] y = 0;
   reg [2:0] z = 0;
SmForever
    cnt=0;
    while(1) begin
        `loop(z=0)
            `loop(y=0)
                `loop(x=0)
                    cnt = cnt+1;
                    tick;
                `next(x != 15, x=x+1);
            `next(y != 10, y=y+1);
        `next(z!=5, z=z+1);
    end
SmEnd

assign rgb={cnt_q, cnt_q, cnt_q};

endmodule
