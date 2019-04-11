`define wait1(cond) `tick; while(~(cond)) `tick 
`define wait0(cond)        while(~(cond)) `tick 
`define incr(x, val)  x = x + val

module matmul 
#(parameter MEM_AW=16, MEM_DW=32, DIM_BITS=16, PREC=16)
(
    output mem_write, mem_req,
    output [MEM_AW-1:0] mem_addr,
    output [MEM_DW-1:0] mem_wdata, 
    input mem_rdata_vld,
    input [MEM_DW-1:0] mem_rdata,

    input [MEM_AW-1:0] aBASE, bBASE, cBASE,
    input [DIM_BITS-1:0] aSTRIDE, bSTRIDE, cSTRIDE,
    input [DIM_BITS-1:0] aROWS, aCOLS, bCOLS,

    output ret,
    input go,
    input clk,
    input rst_n
);

SmBegin
    reg mem_write = 0;
    reg mem_req = 0;
    reg [MEM_AW-1:0] mem_addr = 0;
    reg [MEM_DW-1:0] mem_wdata = 0; 
    reg [DIM_BITS-1:0] i = 0;
    reg [DIM_BITS-1:0] j = 0;
    reg ret <= 0;
SmForever
    j_ = 0;
    i_ = 0;
    `wait0(go);

    `tick;
    while (i_ != aROWS) begin
        MEM_write(aBASE+i_+1, ~(i_+1)); 
        `tick;
        MEM_done;
        `incr(i_, 1);
    end
    ret_ = 1;
    `tick;
SmEnd

task MEM_write;
    input [MEM_AW-1:0] addr;
    input [MEM_DW-1:0] wdata;
    begin
        {mem_wdata_, mem_addr_, mem_write_} = {wdata, addr, 1'b1};
        mem_req_ = 1'b1;
    end
endtask

task MEM_read;
    input [MEM_AW-1:0] addr;
    begin
        {mem_addr_, mem_write_} = {addr, 1'b0};
        mem_req_ = 1'b1;
    end
endtask

task MEM_done;
    mem_req_ = 1'b0;
endtask

endmodule
