// Usefull macros
`define wait1(cond) `tick; while(~(cond)) `tick 
`define incr(x) x=x+1'b1

// To abstract memory access
`define MEM_write(addr, wdata)   {mem_wdata, mem_addr, mem_write, mem_req} = {wdata, addr, 1'b1, 1'b1}
`define MEM_read(addr)           {mem_addr, mem_write, mem_req} = {addr, 1'b0, 1'b1}
`define MEM_done                  mem_req = 1'b0

module matmul 
#(parameter MEM_AW=16, MEM_DW=32, DIM_BITS=16, PREC=16)
(
    // memory interface
    output mem_write, mem_req,
    output [MEM_AW-1:0] mem_addr,
    output [MEM_DW-1:0] mem_wdata, 
    input mem_rdata_vld,
    input [MEM_DW-1:0] mem_rdata,

    // mattrix parameters
    input [MEM_AW-1:0] aBASE, bBASE, cBASE,
    input [DIM_BITS-1:0] aSTRIDE, bSTRIDE, cSTRIDE,
    input [DIM_BITS-1:0] aROWS, aCOLS, bCOLS,

    // control
    output ret,
    input go, clk, rst_n
);

SmBegin
   reg [DIM_BITS-1:0] i=0, j=0, k=0;
   reg [MEM_AW-1:0] a_i0=0, a_ik=0, b_0j=0, b_kj=0, c_i0=0, c_ij=0;
   reg [MEM_DW-1:0] acc=0;
   reg [PREC-1:0] a=0;
   reg ret=0, mem_write=0, mem_req=0;
   reg [MEM_AW-1:0] mem_addr=0;
   reg [MEM_DW-1:0] mem_wdata=0;
SmForever
    ret = 0;

    `wait1(go);
    a_i0 = aBASE;
    c_i0 = cBASE;
    i = 0;
    `tick;
    while (i != aROWS) begin
        b_0j = bBASE;
        c_ij = c_i0;
        j = 0;
        `tick;
        while (j != bCOLS) begin
            a_ik = a_i0;
            b_kj = b_0j;
            acc = 0;
            k = 0;
            `tick; `MEM_read(a_ik); `incr(a_ik);
            `tick; `MEM_read(b_kj); b_kj = b_kj + bSTRIDE; 
            while (k != aCOLS) begin
                `tick; `incr(k);
                `tick; `MEM_read(a_ik); `incr(a_ik);        a = mem_rdata[PREC-1:0];            
                `tick; `MEM_read(b_kj); b_kj=b_kj+bSTRIDE;  acc = acc + a[PREC-1:0] * mem_rdata[PREC-1:0];
            end
            `MEM_done;
            `tick; `MEM_write(c_ij, acc); `incr(b_0j); `incr(c_ij); `incr(j);
            `tick; `MEM_done;
        end
        a_i0 = a_i0 + aSTRIDE;
        c_i0 = c_i0 + cSTRIDE;
        `incr(i);
        `tick;
    end
    ret = 1;
    `tick;
SmEnd

endmodule
