/*
Asynchronous FIFO
Two clocks - wr_clk, rd_clk
1-bit synchonizer to synchronize pointers to generate full & Empty conditions
*/

module async_fifo(wr_clk,rd_clk,reset,wdata,rdata,wr_en,rd_en,full,empty,wr_error,rd_error);

parameter WIDTH = 8;
parameter DEPTH = 16;
parameter PTR_WIDTH = $clog2(DEPTH);

input wr_clk,rd_clk,reset,wr_en,rd_en;
input [WIDTH-1:0] wdata;

output reg [WIDTH-1:0] rdata;
output reg empty,full,wr_error,rd_error;

// Internal signals
reg [PTR_WIDTH-1:0] wr_ptr, rd_ptr;
reg wr_toggle_f, rd_toggle_f; 

reg [WIDTH-1:0] buffer [DEPTH-1:0];

// Internal signals for synchronizer
reg [PTR_WIDTH-1:0] rd_ptr_wr_clk,wr_ptr_rd_clk;
reg rd_toggle_f_wr_clk,wr_toggle_f_rd_clk;

//gray write & read pointers
reg [PTR_WIDTH-1:0] g_wr_ptr;
reg [PTR_WIDTH-1:0] g_rd_ptr;

// Reset always block
always @(posedge wr_clk) begin
	if(reset) begin
		rdata <= 0;
		empty <= 1;
		full <= 0;
		wr_error <= 0;
		rd_error <= 0;
		wr_ptr <= 0;
		rd_ptr <= 0;
		wr_toggle_f <= 0;
		rd_toggle_f <= 0;
		rd_ptr_wr_clk <= 0; 
		wr_ptr_rd_clk <= 0;
		rd_toggle_f_wr_clk <= 0;
		wr_toggle_f_rd_clk <= 0;
		g_rd_ptr <= 0;
      	g_wr_ptr <= 0;
	for (int i=0;i<DEPTH;i=i+1) buffer[i] <= 0;
	end
end
 
//Write Operation
always @(posedge wr_clk) begin
    if (!reset) begin
		wr_error <= 0;
		if (wr_en) begin
			if (full==1) begin
				wr_error <= 1;
			end
			else begin
				buffer[wr_ptr] <= wdata;
				if (wr_ptr == DEPTH-1) wr_toggle_f <= ~wr_toggle_f;
				wr_ptr <= wr_ptr+1;
				// Gray code conversion
  				g_wr_ptr <= (wr_ptr >> 1) ^ wr_ptr;
			end
		end
	end
end

//Read operation
always @(posedge rd_clk) begin
	if(reset!=1) begin
      	rd_error <= 0;
		if (rd_en) begin
			if (empty==1) begin
				rd_error <= 1;
			end
			else begin
				rdata <= buffer[rd_ptr];
				//rollover
				if (rd_ptr == DEPTH-1) rd_toggle_f <= ~rd_toggle_f;
				rd_ptr <= rd_ptr+1;
				// Gray code conversion
				g_rd_ptr <= (rd_ptr >> 1) ^ rd_ptr;
			end
		end
	end
end

// 1-bit synchronizer to generate synchronized pointers to generate Full & empty signals
// Synchronizing rd_ptr signal with write clock 
always @(posedge wr_clk) begin
	// Synchronization
	rd_ptr_wr_clk <= g_rd_ptr;
	rd_toggle_f_wr_clk <= rd_toggle_f;
end

// Synchronizing wr_ptr signal with read clock 
always @(posedge rd_clk) begin
	// Synchronization
	wr_ptr_rd_clk <= g_wr_ptr;
	wr_toggle_f_rd_clk <= wr_toggle_f;
end

// Rollover logic - To generate FULL & EMPTY conditions
always @(*) begin
	full = 0;
	empty = 0;
  	if (g_wr_ptr==rd_ptr_wr_clk && wr_toggle_f != rd_toggle_f_wr_clk) full = 1;
	else full = 0;
  	if (wr_ptr_rd_clk==g_rd_ptr && wr_toggle_f_rd_clk == rd_toggle_f) empty = 1;
	else empty = 0;
end

endmodule