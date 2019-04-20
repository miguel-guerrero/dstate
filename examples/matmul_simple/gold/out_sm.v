// Usefull macros
// To abstract memory access
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
always @(posedge clk or negedge rst_n) begin : dstate0
	// SmBegin ff local begin
	reg [DIM_BITS-1:0] i_r, i;
	reg [DIM_BITS-1:0] j_r, j;
	reg [DIM_BITS-1:0] k_r, k;
	reg [MEM_AW-1:0] a_i0_r, a_i0;
	reg [MEM_AW-1:0] a_ik_r, a_ik;
	reg [MEM_AW-1:0] b_0j_r, b_0j;
	reg [MEM_AW-1:0] b_kj_r, b_kj;
	reg [MEM_AW-1:0] c_i0_r, c_i0;
	reg [MEM_AW-1:0] c_ij_r, c_ij;
	reg [MEM_DW-1:0] acc_r, acc;
	reg [PREC-1:0] a_r, a;
	reg  ret_r, ret;
	reg  mem_write_r, mem_write;
	reg  mem_req_r, mem_req;
	reg [MEM_AW-1:0] mem_addr_r, mem_addr;
	reg [MEM_DW-1:0] mem_wdata_r, mem_wdata;
	// SmBegin ff local end
	reg [3:0] state0_r, state0;
	if (~rst_n) begin
		// SmBegin ff init begin
		i_r <= 0;
		j_r <= 0;
		k_r <= 0;
		a_i0_r <= 0;
		a_ik_r <= 0;
		b_0j_r <= 0;
		b_kj_r <= 0;
		c_i0_r <= 0;
		c_ij_r <= 0;
		acc_r <= 0;
		a_r <= 0;
		ret_r <= 0;
		mem_write_r <= 0;
		mem_req_r <= 0;
		mem_addr_r <= 0;
		mem_wdata_r <= 0;
		// SmBegin ff init end
		state0_r <= SM0_0;
	end
	else begin
		// set defaults for next state vars begin
		i = i_r;
		j = j_r;
		k = k_r;
		a_i0 = a_i0_r;
		a_ik = a_ik_r;
		b_0j = b_0j_r;
		b_kj = b_kj_r;
		c_i0 = c_i0_r;
		c_ij = c_ij_r;
		acc = acc_r;
		a = a_r;
		ret = ret_r;
		mem_write = mem_write_r;
		mem_req = mem_req_r;
		mem_addr = mem_addr_r;
		mem_wdata = mem_wdata_r;
		// set defaults for next state vars end
		state0 = state0_r;
		// SmForever
		case (state0_r)
			SM0_0: begin
				ret = 0;
				state0 = SM0_5;
			end
			SM0_1: begin
				{mem_wdata, mem_addr, mem_write, mem_req} = {acc, c_ij, 1'b1, 1'b1};
				b_0j=b_0j+1'b1;
				c_ij=c_ij+1'b1;
				j=j+1'b1;
				state0 = SM0_2;
			end
			SM0_2: begin
				mem_req = 1'b0;
				if (j != bCOLS) begin
					a_ik = a_i0;
					b_kj = b_0j;
					acc = 0;
					k = 0;
					state0 = SM0_7;
				end
				else begin
					a_i0 = a_i0 + aSTRIDE;
					c_i0 = c_i0 + cSTRIDE;
					i=i+1'b1;
					state0 = SM0_3;
				end
			end
			SM0_3: begin
				if (i != aROWS) begin
					b_0j = bBASE;
					c_ij = c_i0;
					j = 0;
					state0 = SM0_6;
				end
				else begin
					ret = 1;
					state0 = SM0_4;
				end
			end
			SM0_4: begin
				state0 = SM0_0;
			end
			SM0_5: begin
				if (~(go)) begin
					// stay
				end
				else begin
					a_i0 = aBASE;
					c_i0 = cBASE;
					i = 0;
					state0 = SM0_3;
				end
			end
			SM0_6: begin
				if (j != bCOLS) begin
					a_ik = a_i0;
					b_kj = b_0j;
					acc = 0;
					k = 0;
					state0 = SM0_7;
				end
				else begin
					a_i0 = a_i0 + aSTRIDE;
					c_i0 = c_i0 + cSTRIDE;
					i=i+1'b1;
					state0 = SM0_3;
				end
			end
			SM0_7: begin
				{mem_addr, mem_write, mem_req} = {a_ik, 1'b0, 1'b1};
				a_ik=a_ik+1'b1;
				state0 = SM0_8;
			end
			SM0_8: begin
				{mem_addr, mem_write, mem_req} = {b_kj, 1'b0, 1'b1};
				b_kj = b_kj + bSTRIDE;
				if (k != aCOLS) begin
					state0 = SM0_9;
				end
				else begin
					mem_req = 1'b0;
					state0 = SM0_1;
				end
			end
			SM0_9: begin
				k=k+1'b1;
				state0 = SM0_10;
			end
			SM0_10: begin
				{mem_addr, mem_write, mem_req} = {a_ik, 1'b0, 1'b1};
				a_ik=a_ik+1'b1;
				a = mem_rdata[PREC-1:0];
				state0 = SM0_11;
			end
			SM0_11: begin
				{mem_addr, mem_write, mem_req} = {b_kj, 1'b0, 1'b1};
				b_kj=b_kj+bSTRIDE;
				acc = acc + a[PREC-1:0] * mem_rdata[PREC-1:0];
				if (k != aCOLS) begin
					state0 = SM0_9;
				end
				else begin
					mem_req = 1'b0;
					state0 = SM0_1;
				end
			end
		endcase
		// SmEnd
		// Update ffs with next state vars begin
		i_r <= i;
		j_r <= j;
		k_r <= k;
		a_i0_r <= a_i0;
		a_ik_r <= a_ik;
		b_0j_r <= b_0j;
		b_kj_r <= b_kj;
		c_i0_r <= c_i0;
		c_ij_r <= c_ij;
		acc_r <= acc;
		a_r <= a;
		ret_r <= ret;
		mem_write_r <= mem_write;
		mem_req_r <= mem_req;
		mem_addr_r <= mem_addr;
		mem_wdata_r <= mem_wdata;
		// Update ffs with next state vars end
		state0_r <= state0;
	end
end
// drop_suffix begin
wire [DIM_BITS-1:0] i = dstate0.i_r;
wire [DIM_BITS-1:0] j = dstate0.j_r;
wire [DIM_BITS-1:0] k = dstate0.k_r;
wire [MEM_AW-1:0] a_i0 = dstate0.a_i0_r;
wire [MEM_AW-1:0] a_ik = dstate0.a_ik_r;
wire [MEM_AW-1:0] b_0j = dstate0.b_0j_r;
wire [MEM_AW-1:0] b_kj = dstate0.b_kj_r;
wire [MEM_AW-1:0] c_i0 = dstate0.c_i0_r;
wire [MEM_AW-1:0] c_ij = dstate0.c_ij_r;
wire [MEM_DW-1:0] acc = dstate0.acc_r;
wire [PREC-1:0] a = dstate0.a_r;
wire  ret = dstate0.ret_r;
wire  mem_write = dstate0.mem_write_r;
wire  mem_req = dstate0.mem_req_r;
wire [MEM_AW-1:0] mem_addr = dstate0.mem_addr_r;
wire [MEM_DW-1:0] mem_wdata = dstate0.mem_wdata_r;
// drop_suffix end
// end dstate0

endmodule
