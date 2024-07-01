package fgmt;
	localparam integer WIDTH = 32;
    localparam integer THREAD_POOL_SIZE = 4 ;
    localparam integer  TID_bits = 2;
    typedef logic [WIDTH*4-1:0] line;
    typedef logic [WIDTH-1:0] word; 
    parameter set  = 1;
    parameter clear = 0;
    //L1 cache parameters
    parameter no_of_l1_blocks=1;                        // No. of lines in L1 Cache... as one line contains 1 block...it is equal to no. of blocks
    localparam integer block_size = 4;                  //each block has 4 word
    typedef logic [block_size-1:0] [WIDTH-1:0] block;
    //CTID parameters
    localparam logic [1:0] CTID_T0 = 2'b00;
    localparam logic [1:0] CTID_T1 = 2'b01;
    localparam logic [1:0] CTID_T2 = 2'b10;
    localparam logic [1:0] CTID_T3 = 2'b11;
    //fetch stage parameters
    localparam logic [3:0] PC_T0 = 4'b0001;     //active thread 0
    localparam logic [3:0] PC_T1 = 4'b0010;     //active thread 1
    localparam logic [3:0] PC_T2 = 4'b0100; 	//active thread 2
    localparam logic [3:0] PC_T3 = 4'b1000; 	//active thread 3
    localparam word 	   bubble  = 32'b0;     



endpackage