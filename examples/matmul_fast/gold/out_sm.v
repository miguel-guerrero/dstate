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

// begin dstate0
localparam SM0_0 = 0;
localparam SM0_1 = 1;
localparam SM0_2 = 2;
localparam SM0_3 = 3;
localparam SM0_4 = 4;
localparam SM0_5 = 5;
localparam SM0_6 = 6;
localparam SM0_7 = 7;
// SmBegin ff decl begin
reg [DIM_BITS-1:0] i, i_nxt;
reg [DIM_BITS-1:0] j, j_nxt;
reg [DIM_BITS-1:0] k, k_nxt;
reg [MEM_AW-1:0] a_i0, a_i0_nxt;
reg [MEM_AW-1:0] a_ik, a_ik_nxt;
reg [MEM_AW-1:0] b_0j, b_0j_nxt;
reg [MEM_AW-1:0] b_kj, b_kj_nxt;
reg [MEM_AW-1:0] c_i0, c_i0_nxt;
reg [MEM_AW-1:0] c_ij, c_ij_nxt;
reg  ret, ret_nxt;
reg  mem_write, mem_write_nxt;
reg  mem_req, mem_req_nxt;
reg  row_end, row_end_nxt;
reg [MEM_AW-1:0] mem_addr, mem_addr_nxt;
reg [MEM_DW-1:0] mem_wdata, mem_wdata_nxt;
// SmBegin ff decl end
reg [2:0] state0, state0_nxt;

always @* begin : dstate0_combo
    // set defaults for next state vars begin
    i_nxt = i;
    j_nxt = j;
    k_nxt = k;
    a_i0_nxt = a_i0;
    a_ik_nxt = a_ik;
    b_0j_nxt = b_0j;
    b_kj_nxt = b_kj;
    c_i0_nxt = c_i0;
    c_ij_nxt = c_ij;
    ret_nxt = ret;
    mem_write_nxt = mem_write;
    mem_req_nxt = mem_req;
    row_end_nxt = row_end;
    mem_addr_nxt = mem_addr;
    mem_wdata_nxt = mem_wdata;
    // set defaults for next state vars end
    state0_nxt = state0;
    // SmForever
    case (state0)
        SM0_0: begin
                ret_nxt = 0;
                state0_nxt = SM0_1;
        end
        SM0_1: begin
                if (~(~go)) begin
                    // stay
                end
                else begin
                    a_i0_nxt = aBASE;
                    c_i0_nxt = cBASE;
                    i_nxt = 0;
                    c_ij_nxt = c_i0_nxt;
                    b_0j_nxt = bBASE;
                    j_nxt = 0;
                    a_ik_nxt = a_i0_nxt;
                    b_kj_nxt = b_0j_nxt;
                    k_nxt = 0;
                    state0_nxt = SM0_2;
                end
        end
        SM0_2: begin
                {mem_addr_nxt, mem_write_nxt, mem_req_nxt} = {a_ik_nxt, 1'b0, 1'b1};
                a_ik_nxt = a_ik_nxt + 1'b1;
                state0_nxt = SM0_3;
        end
        SM0_3: begin
                {mem_addr_nxt, mem_write_nxt, mem_req_nxt} = {b_kj_nxt, 1'b0, 1'b1};
                b_kj_nxt = b_kj_nxt + bSTRIDE;
                k_nxt = k_nxt + 1'b1;
                if (k_nxt != aCOLS) begin
                    state0_nxt = SM0_2;
                end
                else begin
                    state0_nxt = SM0_4;
                end
        end
        SM0_4: begin
                mem_req_nxt = 1'b0;
                row_end_nxt=1;
                state0_nxt = SM0_5;
        end
        SM0_5: begin
                if (~(acc_rdy)) begin
                    // stay
                end
                else begin
                    {mem_wdata_nxt, mem_addr_nxt, mem_write_nxt, mem_req_nxt} = {acc, c_ij_nxt, 1'b1, 1'b1};
                    b_0j_nxt = b_0j_nxt + 1'b1;
                    c_ij_nxt = c_ij_nxt + 1'b1;
                    row_end_nxt=0;
                    state0_nxt = SM0_6;
                end
        end
        SM0_6: begin
                j_nxt = j_nxt + 1'b1;
                if (j_nxt != bCOLS) begin
                    a_ik_nxt = a_i0_nxt;
                    b_kj_nxt = b_0j_nxt;
                    k_nxt = 0;
                    state0_nxt = SM0_2;
                end
                else begin
                    mem_req_nxt = 1'b0;
                    c_i0_nxt = c_i0_nxt + cSTRIDE;
                    a_i0_nxt = a_i0_nxt + aSTRIDE;
                    state0_nxt = SM0_7;
                end
        end
        SM0_7: begin
                i_nxt = i_nxt + 1'b1;
                if (i_nxt != aROWS) begin
                    c_ij_nxt = c_i0_nxt;
                    b_0j_nxt = bBASE;
                    j_nxt = 0;
                    a_ik_nxt = a_i0_nxt;
                    b_kj_nxt = b_0j_nxt;
                    k_nxt = 0;
                    state0_nxt = SM0_2;
                end
                else begin
                    ret_nxt = 1;
                    state0_nxt = SM0_0;
                end
        end
    endcase
    // SmEnd
end // dstate0_combo


always @(posedge clk or negedge rst_n) begin : dstate0
    if (~rst_n) begin
        // SmBegin ff init begin
        i <= 0;
        j <= 0;
        k <= 0;
        a_i0 <= 0;
        a_ik <= 0;
        b_0j <= 0;
        b_kj <= 0;
        c_i0 <= 0;
        c_ij <= 0;
        ret <= 0;
        mem_write <= 0;
        mem_req <= 0;
        row_end <= 0;
        mem_addr <= 0;
        mem_wdata <= 0;
        // SmBegin ff init end
        state0 <= SM0_0;
    end
    else begin
        // Update ffs with next state vars begin
        i <= i_nxt;
        j <= j_nxt;
        k <= k_nxt;
        a_i0 <= a_i0_nxt;
        a_ik <= a_ik_nxt;
        b_0j <= b_0j_nxt;
        b_kj <= b_kj_nxt;
        c_i0 <= c_i0_nxt;
        c_ij <= c_ij_nxt;
        ret <= ret_nxt;
        mem_write <= mem_write_nxt;
        mem_req <= mem_req_nxt;
        row_end <= row_end_nxt;
        mem_addr <= mem_addr_nxt;
        mem_wdata <= mem_wdata_nxt;
        // Update ffs with next state vars end
        state0 <= state0_nxt;
    end
end
// end dstate0


// begin dstate1
localparam SM1_0 = 0;
localparam SM1_1 = 1;
localparam SM1_2 = 2;
localparam SM1_3 = 3;
// SmBegin ff decl begin
reg [PREC-1:0] a, a_nxt;
reg [PREC-1:0] b, b_nxt;
reg [MEM_DW-1:0] acc, acc_nxt;
reg  acc_rdy, acc_rdy_nxt;
// SmBegin ff decl end
reg [1:0] state1, state1_nxt;

always @* begin : dstate1_combo
    // set defaults for next state vars begin
    a_nxt = a;
    b_nxt = b;
    acc_nxt = acc;
    acc_rdy_nxt = acc_rdy;
    // set defaults for next state vars end
    state1_nxt = state1;
    // SmForever
    case (state1)
        SM1_0: begin
                acc_nxt=0;
                acc_rdy_nxt=0;
                state1_nxt = SM1_1;
        end
        SM1_1: begin
                if (~(mem_rdata_vld)) begin
                    // stay
                end
                else begin
                    a_nxt = mem_rdata;
                    state1_nxt = SM1_2;
                end
        end
        SM1_2: begin
                if (~(mem_rdata_vld)) begin
                    // stay
                end
                else begin
                    b_nxt = mem_rdata;
                    acc_nxt = acc_nxt + a_nxt[PREC-1:0]*b_nxt[PREC-1:0];
                    if (~row_end) begin
                        state1_nxt = SM1_1;
                    end
                    else begin
                        state1_nxt = SM1_3;
                    end
                end
        end
        SM1_3: begin
                acc_rdy_nxt=1;
                state1_nxt = SM1_0;
        end
    endcase
    // SmEnd
end // dstate1_combo


always @(posedge clk or negedge rst_n) begin : dstate1
    if (~rst_n) begin
        // SmBegin ff init begin
        a <= 0;
        b <= 0;
        acc <= 0;
        acc_rdy <= 0;
        // SmBegin ff init end
        state1 <= SM1_0;
    end
    else begin
        // Update ffs with next state vars begin
        a <= a_nxt;
        b <= b_nxt;
        acc <= acc_nxt;
        acc_rdy <= acc_rdy_nxt;
        // Update ffs with next state vars end
        state1 <= state1_nxt;
    end
end
// end dstate1

endmodule
