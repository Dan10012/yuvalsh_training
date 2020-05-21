////////////////////////////////////////////////////////////////////////////////
//
// File name    : serial_data_converter_data_in_sequence_item.sv
// Project name : Serial Data Converter
//
////////////////////////////////////////////////////////////////////////////////
//
// Description: sequence for the project serial_data_converter.
//
////////////////////////////////////////////////////////////////////////////////
//
// Comments: 
//
////////////////////////////////////////////////////////////////////////////////

`ifndef __SERIAL_DATA_CONVERTER_DATA_IN_SEQ
`define __SERIAL_DATA_CONVERTER_DATA_IN_SEQ

class serial_data_converter_data_in_sequence extends uvm_sequence #(dvr_sequence_item #(serial_data_converter_verification_pack::DATA_WIDTH_IN_IN_BITS));
    /*-------------------------------------------------------------------------------
    -- UVM Macros - Factory register.
    -------------------------------------------------------------------------------*/
    // Provides implementations of virtual methods such as get_name and create.
    `uvm_object_utils(serial_data_converter_data_in_sequence)
    `uvm_declare_p_sequencer(dvr_sequencer #(serial_data_converter_verification_pack::DATA_WIDTH_IN_IN_BITS))

    /*------------------------------------------------------------------------------
    -- Parameters.
    ------------------------------------------------------------------------------*/
    serial_data_converter_generation_parameters parameters = null;

    /*------------------------------------------------------------------------------
    -- Sizes Constraints.
    ------------------------------------------------------------------------------*/

    /*-------------------------------------------------------------------------------
    -- Tasks & Functions.
    -------------------------------------------------------------------------------*/
    /*-------------------------------------------------------------------------------
    -- Constructor.
    -------------------------------------------------------------------------------*/
    function new (string name = "serial_data_converter_data_in_sequence");
        super.new(name);

    endfunction

    /*-------------------------------------------------------------------------------
    -- Pre Start.
    -------------------------------------------------------------------------------*/
    virtual task pre_start ();
        if ((get_parent_sequence() == null) && (starting_phase != null)) begin
            starting_phase.raise_objection(this);
        end
    endtask

    /*-------------------------------------------------------------------------------
    -- Body.
    -------------------------------------------------------------------------------*/
    virtual task body ();
      bit [serial_data_converter_verification_pack::DATA_WIDTH_IN_IN_BITS - 1 : 0 ] data_in_bytes[$] = {};
      bit [55:0]sync1,sync2;
      bit [7:0] B1,B2;
      int num1;
      
      std::randomize(sync1)with{ sync1 dist {'hdead0deaf0beef:=5, 'h299123:=9, 'h52f3752:=4, 'h7b4753ff0f0:=3};}; // randomizing a sync from the options 
      

      std::randomize(num1)with {10000> num1; num1 >1000;}; //randoming how many bytes before the sync
        
        for (int i = 0; i < 7; i++) begin// inserting the sync to the packet
          data_in_bytes.insert(0, sync1[(8*(i+1))-1 -: 7]);   
        end
      
        for (int i = 0; i < num1; i++) begin
          std::randomize(B1)with {'hff>= B1; B1 >='h00;};
          data_in_bytes.insert(6, B1);
        end
         
     
      std::randomize(sync2)with{ sync2 dist {'hdead0deaf0beef:=5, 'h299123:=9, 'h52f3752:=4, 'h7b4753ff0f0:=3};}; // randomizing another sync from the options  
      
      for (int i = 0; i < 7; i++) begin// inserting the sync in the last bits of any optionoal sync
        data_in_bytes.insert(521, sync2[(8*(i+1))-1 -: 7]);
        data_in_bytes.insert(499, sync2[(8*(i+1))-1 -: 7]);
        data_in_bytes.insert(858, sync2[(8*(i+1))-1 -: 7]);
        data_in_bytes.insert(964, sync2[(8*(i+1))-1 -: 7]);
      end

        send_msg(data_in_bytes);
    endtask

    /*------------------------------------------------------------------------------
    -- Pre randomize.
    ------------------------------------------------------------------------------*/
    function void pre_randomize();
        // Get the parameters from the test.
        if(!uvm_config_db #(serial_data_converter_generation_parameters)::get(null, this.get_full_name(), "parameters", this.parameters)) begin
            `uvm_fatal(this.get_name().toupper(), "Couldn't find the generation parameters")
        end

    endfunction

    /*-------------------------------------------------------------------------------
    -- Post Start.
    -------------------------------------------------------------------------------*/
    virtual task post_start ();
        if ((get_parent_sequence() == null) && (starting_phase != null)) begin
            starting_phase.drop_objection(this);
        end
    endtask

    /*-------------------------------------------------------------------------------
    -- Send message.
    -------------------------------------------------------------------------------*/
    task send_msg(bit [serial_data_converter_verification_pack::DATA_WIDTH_IN_IN_BITS - 1 : 0 ] data_in_bytes[$]);
        foreach (data_in_bytes[i]) begin
            `uvm_do_on_with(req, p_sequencer, {
                data == data_in_bytes[i];
            })
        end
    endtask
endclass

`endif // __SERIAL_DATA_CONVERTER_VIRTUAL_SEQ