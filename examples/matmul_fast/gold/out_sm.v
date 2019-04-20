// Useful macro definitions
// To abstract memory read/write operations
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

// begin dstate0
localparam SM0_0 = 0;
localparam SM0_1 = 1;
localparam SM0_2 = 2;
localparam SM0_3 = 3;
localparam SM0_4 = 4;
localparam SM0_5 = 5;
localparam SM0_6 = 6;
localparam SM0_7 = 7;
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
	reg  ret_r, ret;
	reg  mem_write_r, mem_write;
	reg  mem_req_r, mem_req;
	reg  row_end_r, row_end;
	reg [MEM_AW-1:0] mem_addr_r, mem_addr;
	reg [MEM_DW-1:0] mem_wdata_r, mem_wdata;
	// SmBegin ff local end
	reg [2:0] state0_r, state0;
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
		ret_r <= 0;
		mem_write_r <= 0;
		mem_req_r <= 0;
		row_end_r <= 0;
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
		ret = ret_r;
		mem_write = mem_write_r;
		mem_req = mem_req_r;
		row_end = row_end_r;
		mem_addr = mem_addr_r;
		mem_wdata = mem_wdata_r;
		// set defaults for next state vars end
		state0 = state0_r;
		// SmForever
		case (state0_r)
			SM0_0: begin
				ret = 0;
				state0 = SM0_1;
			end
			SM0_1: begin
				if (~(~go)) begin
					// stay
				end
				else begin
					a_i0 = aBASE;
					c_i0 = cBASE;
					i = 'b0;
					/// rows loop
					c_ij = c_i0;
					b_0j = bBASE;
					j = 'b0;
					/// cols loop
					a_ik = a_i0;
					b_kj = b_0j;
					k = 'b0;
					/// dot product loop
					state0 = SM0_2;
				end
			end
			SM0_2: begin
				{mem_addr, mem_write, mem_req} = {a_ik, 1'b0, 1'b1};
				a_ik = a_ik + 1'b1;
				state0 = SM0_3;
			end
			SM0_3: begin
				{mem_addr, mem_write, mem_req} = {b_kj, 1'b0, 1'b1};
				b_kj = b_kj + bSTRIDE;
				k = k + 1'b1;
				if (k != aCOLS) begin
					/// dot product loop
					state0 = SM0_2;
				end
				else begin
					state0 = SM0_4;
				end
			end
			SM0_4: begin
				mem_req = 1'b0;
				row_end=1;
				state0 = SM0_5;
			end
			SM0_5: begin
				if (~(acc_rdy)) begin
					// stay
				end
				else begin
					{mem_wdata, mem_addr, mem_write, mem_req} = {acc, c_ij, 1'b1, 1'b1};
					b_0j = b_0j + 1'b1;
					c_ij = c_ij + 1'b1;
					row_end=0;
					state0 = SM0_6;
				end
			end
			SM0_6: begin
				j = j + 1'b1;
				if (j != bCOLS) begin
					/// cols loop
					a_ik = a_i0;
					b_kj = b_0j;
					k = 'b0;
					/// dot product loop
					state0 = SM0_2;
				end
				else begin
					mem_req = 1'b0;
					c_i0 = c_i0 + cSTRIDE;
					a_i0 = a_i0 + aSTRIDE;
					state0 = SM0_7;
				end
			end
			SM0_7: begin
				i = i + 1'b1;
				if (i != aROWS) begin
					/// rows loop
					c_ij = c_i0;
					b_0j = bBASE;
					j = 'b0;
					/// cols loop
					a_ik = a_i0;
					b_kj = b_0j;
					k = 'b0;
					/// dot product loop
					state0 = SM0_2;
				end
				else begin
					ret = 1;
					state0 = SM0_0;
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
		ret_r <= ret;
		mem_write_r <= mem_write;
		mem_req_r <= mem_req;
		row_end_r <= row_end;
		mem_addr_r <= mem_addr;
		mem_wdata_r <= mem_wdata;
		// Update ffs with next state vars end
		state0_r <= state0;
	end
end
// drop_suffix begin
wire  ret = dstate0.ret_r;
wire  mem_write = dstate0.mem_write_r;
wire  mem_req = dstate0.mem_req_r;
wire  row_end = dstate0.row_end_r;
wire [MEM_AW-1:0] mem_addr = dstate0.mem_addr_r;
wire [MEM_DW-1:0] mem_wdata = dstate0.mem_wdata_r;
// drop_suffix end
// end dstate0

// dot product block

// begin dstate1
localparam SM1_0 = 0;
localparam SM1_1 = 1;
localparam SM1_2 = 2;
localparam SM1_3 = 3;
always @(posedge clk or negedge rst_n) begin : dstate1
	// SmBegin ff local begin
	reg [PREC-1:0] a_r, a;
	reg [PREC-1:0] b_r, b;
	reg [MEM_DW-1:0] acc_r, acc;
	reg  acc_rdy_r, acc_rdy;
	// SmBegin ff local end
	reg [1:0] state1_r, state1;
	if (~rst_n) begin
		// SmBegin ff init begin
		a_r <= 0;
		b_r <= 0;
		acc_r <= 0;
		acc_rdy_r <= 0;
		// SmBegin ff init end
		state1_r <= SM1_0;
	end
	else begin
		// set defaults for next state vars begin
		a = a_r;
		b = b_r;
		acc = acc_r;
		acc_rdy = acc_rdy_r;
		// set defaults for next state vars end
		state1 = state1_r;
		// SmForever
		case (state1_r)
			SM1_0: begin
				acc=0;
				acc_rdy=0;
				state1 = SM1_1;
			end
			SM1_1: begin
				if (~(mem_rdata_vld)) begin
					// stay
				end
				else begin
					a = mem_rdata;
					state1 = SM1_2;
				end
			end
			SM1_2: begin
				if (~(mem_rdata_vld)) begin
					// stay
				end
				else begin
					b = mem_rdata;
					acc = acc + a[PREC-1:0]*b[PREC-1:0];
					if (~row_end) begin
						state1 = SM1_1;
					end
					else begin
						state1 = SM1_3;
					end
				end
			end
			SM1_3: begin
				acc_rdy=1;
				state1 = SM1_0;
			end
		endcase
		// SmEnd
		// Update ffs with next state vars begin
		a_r <= a;
		b_r <= b;
		acc_r <= acc;
		acc_rdy_r <= acc_rdy;
		// Update ffs with next state vars end
		state1_r <= state1;
	end
end
// drop_suffix begin
wire [MEM_DW-1:0] acc = dstate1.acc_r;
wire  acc_rdy = dstate1.acc_rdy_r;
// drop_suffix end
// end dstate1

endmodule
