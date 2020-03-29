//////////////////////////////////////////////////////////////////
///
/// Project Name: 	avalon_enforcer
///
/// File Name: 		avalon_enforcer.sv
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



module avalon_enforcer 
(
	input logic clk,
	input logic rst,
	

	avalon_st_if.master  	trusted_msg, 
	avalon_st_if.slave 		untrusted_msg,

	output logic packet_didnt_started, // this indicats thats that a data has sent witho a valud sop.
	output logic packet_in_packet // this indicate that a couple of valid sops has sent without a valid eop in the middle.	
);
 

//////////////////////////////////////////
//// Imports /////////////////////////////
//////////////////////////////////////////
import enforcer_pack::*;

//////////////////////////////////////////
//// Typedefs ////////////////////////////
//////////////////////////////////////////
typedef enum logic { // setting up the sm states
	WAIT_FOR_SOP,
	WAIT_FOR_EOP
} enforcer_sm_t;



//////////////////////////////////////////
//// Declarations ////////////////////////
//////////////////////////////////////////
enforcer_sm_t    		current_state; //the sm
logic					save_data = 1'b0; // have the responsibility to save or throw the data according to the sm


//////////////////////////////////////////
//// Logic ///////////////////////////////
//////////////////////////////////////////
assign 	untrusted_msg.rdy = trusted_msg.rdy; // setting up the untrusted rdy for the sm



//this handles the state_machine moudle
always_ff @(posedge clk or negedge rst) begin : state_machine_logic
	if(~rst) begin
		current_state <= WAIT_FOR_SOP;
	end else begin
	    unique case (current_state)
				WAIT_FOR_SOP: begin //when we got a valid sop(only sop without eop) we move on
					if (trusted_msg.rdy & untrusted_msg.valid & untrusted_msg.sop & !untrusted_msg.eop) begin
						current_state <= WAIT_FOR_EOP;
					end
				end
				WAIT_FOR_EOP: begin // when the packet ended(got valid eop) we move back to the begining
					if (trusted_msg.rdy & untrusted_msg.eop & untrusted_msg.valid ) begin
						current_state <= WAIT_FOR_SOP;
					end
				end	
		endcase
	end
end



// this process handles the outpus of the sm_signals 
always_comb begin : state_machine_outpus_combinational_logic
	unique if(current_state == WAIT_FOR_SOP) begin
		packet_in_packet 		= 0; // this indication will be always down because the packet hasnt started so it cant be a packet in packet
		packet_didnt_started 	=  !untrusted_msg.sop & untrusted_msg.valid; // when we dont got valid sop it will rise up the indication of the eror beacause a packent didnt started
		trusted_msg.sop 		= untrusted_msg.sop & untrusted_msg.valid; // the output sop is the same as the save data and will be up just for an valid eop
		save_data 				= untrusted_msg.sop & untrusted_msg.valid; // to make sure we  dont save the data because the packent hasent started is up
	end
	else if(current_state == WAIT_FOR_EOP) begin
		packet_in_packet 		= untrusted_msg.sop & untrusted_msg.valid; // when we got a valid eop it will rise up the inidctio of the eror
		packet_didnt_started 	= 0; // this indication will be always down because th packet has already started and now the moudle wit for the eop
		trusted_msg.sop 		= 0;// the output sop will be always down because if the module get a valid up he will revert it
		save_data 				= 1; // because the packet didnt staret indication is down' we keep the data as it is and dont throwing it awat
	end
end


// this process setting the valuse of to the "outputs" of the enforcer
always_comb begin : enforcer_outputs_combinational_logic
	// translate the output of the sm to the whole module, when the sm ordering on throwing data(packet_didnt started up) you "throw the data"
	unique if(save_data == 0) begin 
		trusted_msg.eop   	= 1'b0;
		trusted_msg.empty 	= 0;
		trusted_msg.data  	= '0;
		trusted_msg.valid 	= 1'b0;
	end
	// the other option of the sm outpus that means to save the data as is(in cade the packet hasnt started is dwon)
	else if(save_data == 1)begin 
		trusted_msg.eop 	= untrusted_msg.eop;
		trusted_msg.empty 	= untrusted_msg.empty & trusted_msg.eop; // we add the valid sop be cause an empty is valid only at the last packet
		trusted_msg.data 	= untrusted_msg.data;
		trusted_msg.valid 	= untrusted_msg.valid;
	end 
end

endmodule