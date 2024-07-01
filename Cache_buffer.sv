/*
* Description: Level 1 cache 
* Author: Dat
*/
import fgmt::*;
module L1_cache #(
    parameter CTID = 0) 
    (
    //input from processor
    input logic clock,        
    input logic reset,      
    input word  PCF,                        //Program Counter
    input word addr_rst,                    //reset address              
    input logic [TID_bits-1:0] tid_fetch,   //the index of active thread 
    input word br_target,                   //address of branch instruction
    input logic [TID_bits-1:0] tid_br,      //the index of branch thread
    //input from L2 cache
    input word l2addr,                      //l2 address response
    input logic [TID_bits-1:0] l2_tid,      //l2 thread ID response
    input line l2_line,                     //data coming from l2
    input logic l2_valid_rsp,               //valid response from l2
    //output to L2 cache
    output logic br_req,                    //the branch request
    output logic req_spec,                  //prefetching request 
    output logic req_refill,                //refill request. If 1 -> threre is a miss, 0 -> threre is a hit
    //output to processor
    output word instr                       //instruction output port -> to processor decode stage
    );


    // ----------
    // Registers
    // ----------
    logic active;                    //thread active
    word  i_addr, instr_required;    //instruction address 
    
    line  cache_line;                //l2 line response storage
    logic cache_update_valid;


    logic   br_valid;
    word    tag_bit;                 //{[31:4] l2addr, 4'b0} 
    integer icount;           

    block   l1_block_memory;         //icache 


    // output assignments of internal registers
    assign cache_update_valid   = l2_valid_rsp && (l2_tid == CTID);
    

    // FUNCTIONS
    function block line_to_word(input line data);
        automatic block instr;
        for (int i = 0; i < block_size; i++) begin
            instr[i] = data[i * WIDTH +: WIDTH];
        end
        return instr;
    endfunction : line_to_word

    function integer offset_selector(input [3:0] sel);
        automatic integer instr_sl;
            case(sel)
                4'b0000: instr_sl = 0;
                4'b0100: instr_sl = 1;
                4'b1000: instr_sl = 2;
                4'b1100: instr_sl = 3;
            endcase
        return instr_sl;
    endfunction

    function word instr_selector(input integer sel, input block data);
        return data[sel];
    endfunction
    
    /************************************************************************************************************************************/
    ///////////////////////////////////////////////////////////// MAIN BODY //////////////////////////////////////////////////////////////

    // state parameters
    // typedef enum {read, update} State;
    // State state;    
    logic read = 1'b1;
    logic update = 1'b0;
    logic state = active;


    always_comb begin : cache_buffer
        {tag_bit, cache_line} = cache_update_valid ? {l2addr, l2_line} : {tag_bit, cache_line};
        l1_block_memory       = line_to_word(cache_line);
        instr_required        = instr_selector(icount, l1_block_memory);
        br_valid              = (tid_br == CTID); 
        i_addr                = active ? PCF : br_valid ? br_target : clear;
        case (state)
            // when active
            read: begin
                    br_req = clear;
                    //hit
                    if (i_addr[31:4]==tag_bit[31:4]) begin
                        icount = offset_selector(PCF[3:0]);
                        instr = instr_required;
                        req_spec = (icount == 3);
                        req_refill = clear;
                    end
                    // miss
                    else begin
                        icount = clear;
                        instr = bubble;
                        req_spec = clear;
                        req_refill = set;
                    end
                end 
            // when inactive
            update: begin
                instr = bubble;
                req_spec = clear;
                req_refill = clear;
                if (br_valid) begin
                    br_req = (i_addr[31:4]!=tag_bit[31:4]) ? set : clear;       //set: new branch taken

                end
                else begin
                    // if we didn't get the required acknowledge keep the branch request stable
                    br_req = (i_addr[31:4]!=tag_bit[31:4]) ? br_req : clear;    
                end
            end
            default: state = read;
        endcase
    end

    always_ff @(posedge clock ) begin 
        if (tid_fetch == CTID)
            active <= set;
        else
            active <= clear;
    end

endmodule
                
