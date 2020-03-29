//////////////////////////////////////////////////////////////////
///
/// Project Name: 	avalon_enforcer
///
/// File Name: 		tb_avalon_enforcer.sv
///
//////////////////////////////////////////////////////////////////
///
/// Author: 		Yuval shpiro
///
/// Date Created: 	25.3.2020
///
/// Company: 		B"B
///
//////////////////////////////////////////////////////////////////
///
/// Description: 	a model that fix up a avalon st type msg
///
//////////////////////////////////////////////////////////////////


module avalon_enforcer_tb();

	localparam int DATA_WIDTH_IN_BYTES = 16;

	logic clk;
	logic rst;

	avalon_st_if #(.DATA_WIDTH_IN_BYTES(DATA_WIDTH_IN_BYTES)) untrusted_msg();
	avalon_st_if #(.DATA_WIDTH_IN_BYTES(DATA_WIDTH_IN_BYTES)) trusted_msg();


	logic packet_didnt_started; 
	logic packet_in_packet; 

	avalon_enforcer #(
		
	)
	avalon_enforcer_inst
	(
		.clk(clk),
		.rst(rst),
		.untrusted_msg(untrusted_msg.slave),
		.trusted_msg(trusted_msg.master),
		.packet_didnt_started(packet_didnt_started),
		.packet_in_packet(packet_in_packet)
	);

	always #5 clk = ~clk;

	initial begin 
		clk 				= 1'b0;
		rst 				= 1'b0;

		untrusted_msg.valid = 1'b0;
		untrusted_msg.sop = 1'b0;
		untrusted_msg.eop = 1'b0;
		untrusted_msg.data = 0;
		untrusted_msg.empty = 0;
		trusted_msg.rdy = 1'b1;

		#50
		rst 				= 1'b1;

// starting a msg that get a couple of valid sop's and a non valid eop after

		@(posedge clk);
		#0
		rst 					= 1'b0;
		untrusted_msg.valid 	= 1'b1;
		untrusted_msg.data 		= {DATA_WIDTH_IN_BYTES{8'd34}};
		untrusted_msg.sop 		= 1'b1;
		@(posedge clk);
		@(posedge clk);
		#0
		untrusted_msg.sop = 1'b1;
		@(posedge clk);
		#0
		untrusted_msg.sop = 1'b1;
		untrusted_msg.valid 	= 1'b0;
		@(posedge clk);
		#0
		untrusted_msg.eop = 1'b1;
		untrusted_msg.valid 	= 1'b1;
		@(posedge clk);
		#0
		untrusted_msg.valid = 1'b0;
		untrusted_msg.sop = 1'b0;
		untrusted_msg.eop = 1'b0;
		untrusted_msg.data = '0;
		untrusted_msg.empty = 0;

		#15;
//end of msg

// statrt of msg that has bigger data but run smoothly

		@(posedge clk);
		#0
		rst 					= 1'b1;
		untrusted_msg.valid 	= 1'b1;
		untrusted_msg.data 		= {DATA_WIDTH_IN_BYTES{8'd34}};
		untrusted_msg.sop 		= 1'b1;
		@(posedge clk);
		@(posedge clk);
		#0
		untrusted_msg.sop = 1'b0;
		@(posedge clk);
		@(posedge clk);
		#0
		untrusted_msg.eop = 1'b1;
		@(posedge clk);
		#0
		untrusted_msg.valid = 1'b0;
		untrusted_msg.sop = 1'b0;
		untrusted_msg.eop = 1'b0;
		untrusted_msg.data = '0;
		untrusted_msg.empty = 0;

		#15;
//end of mesaage

// statrt of msg thae valid is droping in the middle

		@(posedge clk);
		#0
		untrusted_msg.valid 	= 1'b1;
		untrusted_msg.data 		= {DATA_WIDTH_IN_BYTES{8'd34}};
		untrusted_msg.sop 		= 1'b1;
		@(posedge clk);
		@(posedge clk);
		#0
		untrusted_msg.sop = 1'b0;
		@(posedge clk);
		untrusted_msg.valid = 1'b0;
		@(posedge clk);
		#0
		untrusted_msg.eop = 1'b1;
		@(posedge clk);
		#0
		untrusted_msg.valid = 1'b0;
		untrusted_msg.sop = 1'b0;
		untrusted_msg.eop = 1'b0;
		untrusted_msg.data = '0;
		untrusted_msg.empty = 0;

		#15;
//end of mesaage
	end

endmodule