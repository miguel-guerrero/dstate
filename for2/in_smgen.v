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

SmgBegin
   reg hs = 1'b0, vs = 1'b0, vld = 1'b0, y_active = 1'b0;
   reg [PW-1:0] cnt = 8'b0;
   reg [H_BITS-1:0] x = 0;
   reg [V_BITS-1:0] y = 0;
   reg [2:0] z = 0;
SmgForever
    cnt=0;
    while(1) begin
        z=0;
        do begin
            y=0;
            do begin
                x=0;
                do  begin
                    cnt = cnt+1;
                    `tick;
                    x=x+1;
                end while (x != 15);
                y=y+1;
            end while (y != 10);
            z=z+1;
        end while (z != 5);
    end
SmgEnd

assign rgb={cnt_q, cnt_q, cnt_q};

endmodule
