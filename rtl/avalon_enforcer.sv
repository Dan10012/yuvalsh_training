




module avalon_enforcer 
(
	input logic clk,
	input logic rst,
	

	avalon_st_if.master  	untrusted_msg, 
	avalon_st_if.slave 		trusted_msg,

	output logic packet_didnt_started,
	output logic packet_in_packet
	
);

import enforcer_pack::*;

enforcer_sm_t    current_state;


always_ff @(posedge clk or negedge rst) begin
	if(~rst) begin
		current_state <= WAIT_FOR_SOP;
	end else begin
		case (current_state)
			WAIT_FOR_SOP: begin
				if (trusted_msg.rdy & untrusted_msg.valid & untrusted_msg.sop & untrusted_msg.eop = 0) begin
					current_state <= WAIT_FOR_EOP;
				end
			end
			WAIT_FOR_EOP: begin
				if (trusted_msg.rdy & untrusted_msg.eop & untrusted_msg.valid ) begin
					current_state <= WAIT_FOR_SOP;
				end
			end	
		endcase
	end
end


always_comb begin
	untrusted_msg.CLEAR_MASTER();


	if (current_state = WAIT_FOR_SOP) begin
		packet_in_packet = 0;
		packet_didnt_started = (not untrusted_msg.sop) & untrusted_msg.valid;
		

	end



endmodule