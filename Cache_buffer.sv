/*
* Description: Level 1 cache 
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
    assign br_valid             = (tid_br == CTID);
    

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
					default: instr_sl = 0;
            endcase
        return instr_sl;
    endfunction

    function word instr_selector(input integer sel, input block data);
        return data[sel];
    endfunction
    
    /************************************************************************************************************************************/
    ///////////////////////////////////////////////////////////// MAIN BODY //////////////////////////////////////////////////////////////
    parameter read = 1'b1;
    parameter update = 1'b0;
    

    always_comb begin : cache_buffer
        //update l1 cache
        l1_block_memory       = cache_update_valid ? line_to_word(l2_line) : line_to_word(cache_line);
        //update required instruction
        i_addr                = active ? PCF : br_valid ? br_target : 1'b0;
        icount                = offset_selector(i_addr[3:0]);
        instr_required        = instr_selector(icount, l1_block_memory);
        //defautl 
        br_req     = 1'b0;
        instr      = 1'b0;
        req_spec   = 1'b0;
        req_refill = 1'b0;
        case(active)
            // when active
            read: begin
                br_req = 1'b0;
                //hit
                if (i_addr[31:4]==tag_bit[31:4]) begin
                    instr = instr_required;
                    req_spec = (icount == 3);
                    req_refill = 1'b0;
                end
                // miss
                else begin
                    instr = bubble;
                    req_spec = 1'b0;
                    req_refill = 1'b1;        
                end
            end 
            // when inactive
            update: begin
                instr = bubble;
                req_spec = 1'b0;
                req_refill = 1'b0;
                if (i_addr[31:4]==tag_bit[31:4]) begin
                    br_req = 1'b0;       //clear
                end
                else begin
                    //if we didn't get the required acknowledge keep the branch request stable
                    br_req = (br_valid) ? 1'b1 : br_req;   //set: new branch taken
                end
            end
            default: active = read;
        endcase

    end

    always_ff @(posedge clock ) begin 
	if (reset)  {tag_bit, cache_line} <= 140'h0;
        //update data
        else if(cache_update_valid) {tag_bit, cache_line} <= {l2addr, l2_line};
        else                        {tag_bit, cache_line} <= {tag_bit, cache_line};
        //cache status
        if (tid_fetch == CTID) active <= read;
        else                   active <= update;
    end

endmodule
                
