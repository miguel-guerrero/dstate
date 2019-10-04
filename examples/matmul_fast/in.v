// Useful macro definitions
`define wait1(cond) `tick; while(~(cond)) `tick 
`define incr(x, amnt)  x = x + amnt
`define loop(var)  var = 0; do begin
`define next(var, limit) var = var + 1'b1; end while(var != limit)

// To abstract memory read/write operations
`define MEM_write(addr, wdata)   {mem_wdata, mem_addr, mem_write, mem_req} = {wdata, addr, 1'b1, 1'b1}
`define MEM_read(addr)           {mem_addr, mem_write, mem_req} = {addr, 1'b0, 1'b1}
`define MEM_done                  mem_req = 1'b0

//----------------------------------------------------------------------------
// memory to memory matrix multiplication
//----------------------------------------------------------------------------
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

// Control/address generation block
SmBegin
   local reg [DIM_BITS-1:0] i=0, j=0, k=0;
   local reg [MEM_AW-1:0] a_i0=0, a_ik=0, b_0j=0, b_kj=0, c_i0=0, c_ij=0;
   reg ret=0, mem_write=0, mem_req=0, row_end=0;
   reg [MEM_AW-1:0] mem_addr=0;
   reg [MEM_DW-1:0] mem_wdata=0;
SmForever
    ret = 0;
    `wait1(~go);
    a_i0 = aBASE;
    c_i0 = cBASE;
    `loop(i)
        /// rows loop
        c_ij = c_i0;
        b_0j = bBASE;
        `loop(j)
            /// cols loop
            a_ik = a_i0;
            b_kj = b_0j;
            `loop(k)
                /// dot product loop
                `tick; `MEM_read(a_ik); `incr(a_ik, 1'b1);
                `tick; `MEM_read(b_kj); `incr(b_kj, bSTRIDE); 
            `next(k, aCOLS);
            `tick;
            `MEM_done;
            row_end=1;
            `wait1(acc_rdy);
            `MEM_write(c_ij, acc); `incr(b_0j, 1'b1); `incr(c_ij, 1'b1); row_end=0;
            `tick;
        `next(j, bCOLS);
        `MEM_done;
        `incr(c_i0, cSTRIDE);
        `incr(a_i0, aSTRIDE);
        `tick;
    `next(i, aROWS);
    ret = 1;
SmEnd

// dot product block
SmBegin
   local reg [PREC-1:0] a=0, b=0;
   reg [MEM_DW-1:0] acc=0;
   reg acc_rdy=0;
SmForever
    acc=0;
    acc_rdy=0;
    do begin
        `wait1(mem_rdata_vld);
        a = mem_rdata;
        `wait1(mem_rdata_vld);
        b = mem_rdata;
        `incr(acc, a[PREC-1:0]*b[PREC-1:0]);
    end while (~row_end);
    `tick;
    acc_rdy=1;
SmEnd

endmodule
