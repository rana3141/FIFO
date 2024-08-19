//Asynchronous FIFO Testbench
module tb;

parameter WIDTH = 8;
parameter DEPTH = 16;
parameter PTR_WIDTH = $clog2(DEPTH);

reg wr_clk,rd_clk,reset,wr_en,rd_en;
reg [WIDTH-1:0] wdata;

wire [WIDTH-1:0] rdata;
wire empty,full,wr_error,rd_error;


async_fifo #(.WIDTH(WIDTH), .DEPTH(DEPTH), .PTR_WIDTH(PTR_WIDTH)) dut (wr_clk,rd_clk,reset,wdata,rdata,wr_en,rd_en,full,empty,wr_error,rd_error);


always #5  wr_clk = ~wr_clk;
always #10 rd_clk = ~rd_clk;

initial begin
	reset = 1;
	rst();
	#30;
	reset = 0;
	write_fifo(0, DEPTH);
	read_fifo(0, DEPTH);
	#200;
	$finish();
end

task rst();
	wr_clk = 0;
	rd_clk = 0;
	wr_en = 0;
	rd_en = 0;
	wdata = 0;
endtask

task write_fifo(input int start_loc, input int end_loc);
 	for (int i=start_loc;i<start_loc+end_loc;i++) begin
 		@(posedge wr_clk);
		wr_en = 1;
		wdata = $random;
 	end
 	@(posedge wr_clk)
	wr_en = 0;
	wdata = 0;
endtask

task read_fifo(input int start_loc, input int end_loc);
	for (int i=start_loc;i<start_loc+end_loc;i++) begin
		@(posedge rd_clk)
		rd_en = 1;
	end
	@(posedge rd_clk)
	rd_en = 0;
endtask


 initial begin
    $dumpfile("fifo.vcd");
   $dumpvars(0, tb);
 end

  initial begin
    $monitor ("%0t wdata=%0h , rdata=%0h, empty=%0b, full=%0b, wr_en =%0d rd_en=%0d",$time, wdata,rdata,empty,full, wr_en, rd_en);
  end

endmodule

