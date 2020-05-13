//////////////////////////////////////////////////////////////////
///
/// Project Name: 	aes_encryptor
///
/// File Name: 		aes_encryptor.sv
///
//////////////////////////////////////////////////////////////////
///
/// Author: 		Yuval shpiro
///
/// Date Created: 	26.4.2020
///
/// Company: 		B"B
///
//////////////////////////////////////////////////////////////////
///
/// Description: 	this file is the main file of a model that encrypting avalon_st msg in aes method.
///
//////////////////////////////////////////////////////////////////




module aes_encryptor 
(
	input logic clk,
	input logic rst,
	

	avalon_st_if.master  	msg_out, 
	avalon_st_if.slave 		msg_in,
	dvr_key_if.slave        key_and_sync,

	output logic double_sync

);
 
//////////////////////////////////////////
//// Imports /////////////////////////////
//////////////////////////////////////////
import aes_model_pack::*;

//////////////////////////////////////////
//// Typedefs ////////////////////////////
//////////////////////////////////////////
typedef enum logic { // setting up the sm states
	WAIT_FOR_KEY_AND_SYNC,
	ENCRYPTION_PROCESS,
	WAIT_FOR_MSG
} aes_encryptor_sm_t;



//////////////////////////////////////////
//// Declarations ////////////////////////
//////////////////////////////////////////
aes_encryptor_sm_t    current_state; //the sm
logic 				  deliver_msg; // signals that control whether to deliver the msg on or not(depdent on whtever encrypted or not)
int 			 	  counter;
data_block 			  msg_key,round_key, expanded_key;
data_block 			  msg_sync,round_sync, encrypted_block,encrypted_sync; 
data_block 			  sasb,sasr,samc; // three help signals that represnt the sync after all the encrypting levels in round
//////////////////////////////////////////
//// Logic ///////////////////////////////
//////////////////////////////////////////



//this handles the state_machine moudle
always_ff @(posedge clk or negedge rst) begin : state_machine_logic
	if(~rst) begin
		current_state <= WAIT_FOR_KEY_AND_SYNC;
	end else begin
	    unique case (current_state)
				WAIT_FOR_KEY_AND_SYNC: begin //when we the system has been load and we wait for key and sync
					if (key_and_sync.valid) begin
						current_state <= ENCRYPTION_PROCESS;
					end
				end
				ENCRYPTION_PROCESS: begin // when we got the key and the sync and we are in the middle of ecrypting it
					if (counter == 11 ) begin
						current_state <= WAIT_FOR_MSG;
					end
				end	
				WAIT_FOR_MSG: begin //when we finshed encrytping and waiting for a msg to encrypt it
					if (msg_in.valid & msg_out.rdy & !msg_in.eop) begin
						current_state <= ENCRYPTION_PROCESS;
					end
					else if (msg_in.eop & msg_out.rdy & msg_in.valid) begin
						current_state <= WAIT_FOR_KEY_AND_SYNC;
					end
				end
		endcase
	end
end

// this process handles the outpus of the sm_signals 
always_ff @(posedge clk ) begin : state_machine_outpus_sequintional_logic
	case(current_state)
	  WAIT_FOR_KEY_AND_SYNC: begin //when the module iwaiting for sync sn key he will shout down msg transefrecy and the rdy for key and sync will be up
		key_and_sync.rdy 	<= 1;
		counter 			<= 0;
		deliver_msg 		<= 0;
		msg_in.rdy 			<= 0;
		msg_sync 			<= key_and_sync.sync;
		msg_key 			<= key_and_sync.key;
		round_sync			<= '0;
	end	
	 ENCRYPTION_PROCESS : begin // when the moudle is in the middle of encrypting he will block any new data(msg,sync,key) and will track on the encrypting rounds.
		counter				<= counter +1;
		msg_in.rdy 			<= 0;
		key_and_sync.rdy	<= 0;
		deliver_msg 		<= 0;
		encrypted_block		<= round_sync;

		// handling the specail rounds(first round' and las round)
		if(counter == 0) begin
			round_sync  <= msg_key^msg_sync; // at the "first" round just xoring the sync and key
			round_key	<= msg_key;
		end
		else begin
			round_key <= expanded_key;
		 	if(counter == 10)begin
				round_sync <= round_key^sasr; // in the last round avoding the mix_col
			end
			else begin
				round_sync <= encrypted_sync; // regular round
			end
		end
	  WAIT_FOR_MSG :begin // when the module finish creating the encrypted block he will wait for a msg to encrypit it and then he will go back to encryption(or to the statrt if msg has ended)
		deliver_msg <=1;
		counter <=0;
		msg.rdy <= msg_out.rdy;
	  end
    endcase // current_state
end

// the encrypted_round module
assign	sasb	 	   = rst? '0: subbytes(round_sync);
assign	sasr 		   = rst? '0: shift_rows(sasb);
assign	samc 		   = rst? '0: mix_colums(sasr);
assign	expanded_key   = rst? '0: key_expand(round_key,counter);
assign	encrypted_sync = rst? '0: samc^expanded_key;
end




// handle with the forwarding of the msg
always_comb begin : sm_msg_handling
	msg_out.data 	= msg_in.data^encrypted_block;
	msg_out.rdy		= msg_in.rdy;
	msg_out.sop		= msg_in.sop;
	msg_out.eop 	= msg_in.eop;
	msg_out.empty 	= msg_in.empty;
	msg_in.valid 	= msg_out.valid^deliver_msg;
end

endmodule 