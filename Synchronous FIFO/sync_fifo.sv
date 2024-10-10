// Synchronous FIFO

module sync_fifo(clk,reset,wdata,rdata,wr_en,rd_en,empty,full,wr_error,rd_error);

parameter WIDTH = 8;
parameter DEPTH = 16;
parameter PTR_WIDTH = $clog2(DEPTH);

input clk,reset,wr_en,rd_en;
input [WIDTH-1:0] wdata;

output reg [WIDTH-1:0] rdata;
output reg empty,full,wr_error,rd_error;

// Internal variables
reg [PTR_WIDTH-1:0] wr_ptr, rd_ptr;
reg wr_toggle_f, rd_toggle_f;

reg [WIDTH-1:0] buffer [DEPTH-1:0];

// Reset always block
always @(posedge clk) begin
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
	for (int i=0;i<DEPTH;i=i+1) buffer[i] <= 0;
	end
end 

// Write and Read operation
always @(posedge clk) begin
	if (!reset) begin	
		wr_error <= 0;
		rd_error <= 0;
		if (wr_en) begin
			if (full==1) begin
				wr_error <= 1;
			end
			else begin
				buffer[wr_ptr] <= wdata;					// Write
				if (wr_ptr == DEPTH-1) wr_toggle_f <= ~wr_toggle_f;
				wr_ptr = wr_ptr+1;
			end
		end
		if (rd_en) begin
			if (empty==1) begin
				rd_error <= 1;
			end
			else begin
				rdata <= buffer[rd_ptr];					// Read
				if (rd_ptr == DEPTH-1) rd_toggle_f <= ~rd_toggle_f;
				rd_ptr <= rd_ptr+1;
			end
		end
	end
end

// Rollover logic
// When only write ptr roll overs - FULL i.e no location available to write
// When both read and write ptrs roll over - EMPTY i.e no location available to read from.
	
  assign full  = (wr_ptr==rd_ptr && wr_toggle_f != rd_toggle_f) ? 1 : 0;
  assign empty = (wr_ptr==rd_ptr && wr_toggle_f == rd_toggle_f) ? 1 : 0;
endmodule