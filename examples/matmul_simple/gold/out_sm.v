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
    input go, clk, rst_n
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
localparam SM0_8 = 8;
localparam SM0_9 = 9;
localparam SM0_10 = 10;
localparam SM0_11 = 11;
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
reg [MEM_DW-1:0] acc, acc_nxt;
reg [PREC-1:0] a, a_nxt;
reg  ret, ret_nxt;
reg  mem_write, mem_write_nxt;
reg  mem_req, mem_req_nxt;
reg [MEM_AW-1:0] mem_addr, mem_addr_nxt;
reg [MEM_DW-1:0] mem_wdata, mem_wdata_nxt;
// SmBegin ff decl end
reg [3:0] state0, state0_nxt;

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
    acc_nxt = acc;
    a_nxt = a;
    ret_nxt = ret;
    mem_write_nxt = mem_write;
    mem_req_nxt = mem_req;
    mem_addr_nxt = mem_addr;
    mem_wdata_nxt = mem_wdata;
    // set defaults for next state vars end
    state0_nxt = state0;
    // SmForever
    case (state0)
        SM0_0: begin
                ret_nxt = 0;
                state0_nxt = SM0_5;
        end
        SM0_1: begin
                {mem_wdata_nxt, mem_addr_nxt, mem_write_nxt, mem_req_nxt} = {acc_nxt, c_ij_nxt, 1'b1, 1'b1};
                b_0j_nxt=b_0j_nxt+1'b1;
                c_ij_nxt=c_ij_nxt+1'b1;
                j_nxt=j_nxt+1'b1;
                state0_nxt = SM0_2;
        end
        SM0_2: begin
                mem_req_nxt = 1'b0;
                if (j_nxt != bCOLS) begin
                    a_ik_nxt = a_i0_nxt;
                    b_kj_nxt = b_0j_nxt;
                    acc_nxt = 0;
                    k_nxt = 0;
                    state0_nxt = SM0_7;
                end
                else begin
                    a_i0_nxt = a_i0_nxt + aSTRIDE;
                    c_i0_nxt = c_i0_nxt + cSTRIDE;
                    i_nxt=i_nxt+1'b1;
                    state0_nxt = SM0_3;
                end
        end
        SM0_3: begin
                if (i_nxt != aROWS) begin
                    b_0j_nxt = bBASE;
                    c_ij_nxt = c_i0_nxt;
                    j_nxt = 0;
                    state0_nxt = SM0_6;
                end
                else begin
                    ret_nxt = 1;
                    state0_nxt = SM0_4;
                end
        end
        SM0_4: begin
                state0_nxt = SM0_0;
        end
        SM0_5: begin
                if (~(go)) begin
                    // stay
                end
                else begin
                    a_i0_nxt = aBASE;
                    c_i0_nxt = cBASE;
                    i_nxt = 0;
                    state0_nxt = SM0_3;
                end
        end
        SM0_6: begin
                if (j_nxt != bCOLS) begin
                    a_ik_nxt = a_i0_nxt;
                    b_kj_nxt = b_0j_nxt;
                    acc_nxt = 0;
                    k_nxt = 0;
                    state0_nxt = SM0_7;
                end
                else begin
                    a_i0_nxt = a_i0_nxt + aSTRIDE;
                    c_i0_nxt = c_i0_nxt + cSTRIDE;
                    i_nxt=i_nxt+1'b1;
                    state0_nxt = SM0_3;
                end
        end
        SM0_7: begin
                {mem_addr_nxt, mem_write_nxt, mem_req_nxt} = {a_ik_nxt, 1'b0, 1'b1};
                a_ik_nxt=a_ik_nxt+1'b1;
                state0_nxt = SM0_8;
        end
        SM0_8: begin
                {mem_addr_nxt, mem_write_nxt, mem_req_nxt} = {b_kj_nxt, 1'b0, 1'b1};
                b_kj_nxt = b_kj_nxt + bSTRIDE;
                if (k_nxt != aCOLS) begin
                    state0_nxt = SM0_9;
                end
                else begin
                    mem_req_nxt = 1'b0;
                    state0_nxt = SM0_1;
                end
        end
        SM0_9: begin
                k_nxt=k_nxt+1'b1;
                state0_nxt = SM0_10;
        end
        SM0_10: begin
                a_nxt = mem_rdata[PREC-1:0];
                {mem_addr_nxt, mem_write_nxt, mem_req_nxt} = {a_ik_nxt, 1'b0, 1'b1};
                a_ik_nxt=a_ik_nxt+1'b1;
                state0_nxt = SM0_11;
        end
        SM0_11: begin
                acc_nxt = acc_nxt + a_nxt[PREC-1:0] * mem_rdata[PREC-1:0];
                {mem_addr_nxt, mem_write_nxt, mem_req_nxt} = {b_kj_nxt, 1'b0, 1'b1};
                b_kj_nxt=b_kj_nxt+bSTRIDE;
                if (k_nxt != aCOLS) begin
                    state0_nxt = SM0_9;
                end
                else begin
                    mem_req_nxt = 1'b0;
                    state0_nxt = SM0_1;
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
        acc <= 0;
        a <= 0;
        ret <= 0;
        mem_write <= 0;
        mem_req <= 0;
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
        acc <= acc_nxt;
        a <= a_nxt;
        ret <= ret_nxt;
        mem_write <= mem_write_nxt;
        mem_req <= mem_req_nxt;
        mem_addr <= mem_addr_nxt;
        mem_wdata <= mem_wdata_nxt;
        // Update ffs with next state vars end
        state0 <= state0_nxt;
    end
end
// end dstate0

endmodule
