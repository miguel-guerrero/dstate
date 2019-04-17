
`ifdef BEHAV
   `include "out_beh.v"
`else
   `ifdef GLS
      `include "out_sm.vg"
   `else
      `include "out_sm.v"
   `endif
`endif


module tb;

`ifdef BEHAV
   initial $display("#RUNNING BEHAVIORAL code");
`else
   `ifdef GLS
      initial $display("#RUNNING GLS code");
   `else
      initial $display("#RUNNING RTL code");
   `endif
`endif

parameter PW=8, H_BITS=12, V_BITS=12;
wire hs_q;
wire vs_q;
wire [3*PW-1:0] rgb;
wire vld_q;
wire [H_BITS-1:0] tHS_START = 10;
wire [H_BITS-1:0] tHS_END = 20;
wire [H_BITS-1:0] tHACT_START = 40;
wire [H_BITS-1:0] tHACT_END = 50;
wire [H_BITS-1:0] tH_END =60;
wire [V_BITS-1:0] tVS_START = 11;
wire [V_BITS-1:0] tVS_END = 21;
wire [V_BITS-1:0] tVACT_START = 25;
wire [V_BITS-1:0] tVACT_END = 35;
wire [H_BITS-1:0] tV_END = 40;
reg clk;
reg rst_n;

tpg 
#(.PW(PW), .H_BITS(H_BITS), .V_BITS(V_BITS)) 
i_dut(.*);

initial begin
    clk = 0;
    forever begin
        #10;
        clk = ~clk;
    end
end

initial begin
   #1;
   $display($time, " TEST starts");
   $display($time, " Reseting");
   rst_n = 0;
   #30;
   rst_n = 1;
   #500;
   $display($time, " Reseting");
   rst_n = 0;
   #30;
   rst_n = 1;
end

always @(negedge clk) begin
   $display($time, " hs=", hs_q, " vs=", vs_q, " vld=", vld_q, " rgb=%x", rgb);
end

initial begin
`ifdef BEHAV
   $dumpfile("tb_beh.vcd");
`else
   `ifdef GLS
       $dumpfile("tb_gls.vcd");
   `else
       $dumpfile("tb.vcd");
   `endif
`endif
   $dumpvars;
end

initial begin
   #1000;
   repeat(1000 + (1+tH_END)*(1+tV_END)) 
      @(posedge clk);
   $display($time, " ending");
   $finish;
end

endmodule
