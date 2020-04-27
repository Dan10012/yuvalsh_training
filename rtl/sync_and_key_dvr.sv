//////////////////////////////////////////////////////////////////
///
/// Project Name: 	unknown_project
///
/// File Name: 		avalon_st_if.sv
///
//////////////////////////////////////////////////////////////////
///
/// Author: 		Yael Karisi
///
/// Date Created: 	19.3.2020
///
/// Company: 		----
///
//////////////////////////////////////////////////////////////////
///
/// Description: 	Defines dvr Stream interface 
///
//////////////////////////////////////////////////////////////////

import general_pack::*;

interface dvr_st_if #(parameter DATA_WIDTH_IN_BYTES = 16);
	logic 	[(DATA_WIDTH_IN_BYTES*$bits(byte)) - 1 : 0] key;
	logic 	[(DATA_WIDTH_IN_BYTES*$bits(byte)) - 1 : 0] sync;
	logic 												valid;
	logic 												rdy;

	modport slave 	(input key, input sync, input valid, output rdy);

	modport master 	(output key, output sync, output vaild, input rdy);


endinterface