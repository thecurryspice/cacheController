`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/09/2019 09:54:14 AM
// Design Name: 
// Module Name: cacheInterface
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module cacheInterface(
    input [31:0] address_proc,
    inout [31:0] data_proc,
    output reg [31:0] address_ram,
    inout [63:0] data_ram,
    output reg h_m,
    input r_w,
    input ram_ack,
    input clk,
    input reset
    );

/*
The LRU is implemented as a vector of 4 bits.
Each bit determines the least recently used position.
Since there are 2 positions only (2 ways), only 1 bit per way suffices.
The position of the bit refers to the set.
*/

//reg address [31:0];
// need 4 sets of 2 way, 2 word long blocks
reg [63:0] cache_mem [7:0];
reg [26:0] cache_tags [7:0];
// need valid bits for each block
reg [7:0] cache_valid;

// this will be generated from the address
reg [2:0] block_offset;
reg [1:0] index;
reg [26:0] tag;

// need 4 variables here. 0 and 1, for each set, correspond to which block
// is most recently used in each set.
reg last_used [3:0];
reg [1:0] set;
reg indexReg, cache_block;
integer i;

// handle inouts gracefully. Assign data_proc bus as high impedance on a miss.
// On a write request from proc, assign high impedance,
// otherwise assert the corresponding block.
assign data_proc = (r_w & h_m) ? ( (block_offset[2]) ? {cache_mem[set][63:32]} : {cache_mem[set][31:0]}) : 32'bz;

// reset everything
always@(negedge reset)
begin
    // invalidate all blocks
    for (i = 0; i < 8; i = i+1)
    begin
       cache_valid[i] = 1'b0;
    end
    // reset LRU
    for (i = 0; i < 4; i = i+1)
    begin
      last_used[i] = 1'b0;
    end
    $display("init h_m 0");
    h_m <= 1'b0;
end

// generate output only at posedge
always@(posedge clk)
begin
	case (index)
    2'b00  : set <= 0;
    2'b01  : set <= 1;
    2'b10  : set <= 2;
    2'b11  : set <= 3;
    default: set <= 0;
    endcase
    // load address bus for RAM, ram_gate will make sure RAM responds only when necessary
    address_ram = address_proc;
	if( h_m == 0 && ram_ack)	// Requires eviction or mem-access
	begin
	    $display("Request Address: %b, Block Offset: %b, Index: %b, Tag: %b, Set: %d", address_proc, block_offset, index, tag, set);
		
//		if(cache_valid[(set*2+1) -: 1] == 2'b11)		// both locations are valid, implement LRU
        if(cache_valid[(set*2+1)] == 1'b1 && cache_valid[(set*2)] == 1'b1)
		begin
			if(ram_ack == 1)
			begin
				if( last_used[set] == 1 )	   // 2nd block was used last, replace 1st
				begin
				    $display("Replacing first block");	
					cache_mem[set*2] = data_ram;
					cache_tags[set*2] = tag;       // update corresponding tag
					last_used[set] = 0;	           // update LRU
					cache_valid[set*2] = 1'b1;      // update cache block as valid
					h_m <= 1'b1;                    // update the hit/miss signal
				end
				else
				begin
				    $display("Replacing second block");
					cache_mem[set*2+1] = data_ram;
					cache_tags[set*2+1] = tag;     // update corresponding tag
					cache_valid[set*2+1] = 1'b1;      // update cache block as valid
					last_used[set] = 1;	           // update LRU
					h_m <= 1'b1;                    // update the hit/miss signal
				end
			end
		end
//		else if(cache_valid[(set*2+1) -: 1] == 2'b10)    // one location is invalid
        else if(cache_valid[(set*2+1)] == 1'b0 && cache_valid[(set*2)] == 1'b1)
		begin
			$display("Second row is still invalid; filling");
			cache_mem[set*2+1] = data_ram;
			cache_tags[set*2+1] = tag;             // update corresponding tag
			cache_valid[set*2+1] = 1'b1;              // update cache block as valid
			last_used[set] = 1;
			h_m <= 1'b1;                          // update the hit/miss signal
		end
//		else if(cache_valid[(set*2+1) -: 1] == 2'b01)    // one location is invalid
        else if(cache_valid[(set*2+1)] == 1'b1 && cache_valid[(set*2)] == 1'b0)
        begin
			$display("First row is still invalid; filling");
			cache_mem[set*2] = data_ram;
			cache_tags[set*2] = tag;             // update corresponding tag
			cache_valid[set*2] = 1'b1;              // update cache block as valid
			last_used[set] = 0;                  // update LRU
			h_m <= 1'b1;                          // update the hit/miss signal
        end
		else      // fill any location, both are invalid
        begin
            $display("All invalid; filling first row");
			cache_mem[set*2] = data_ram;
			cache_tags[set*2] = tag;             // update corresponding tag
			cache_valid[set*2] = 1'b1;
			last_used[set] = 0;
			h_m <= 1'b1;                          // update the hit/miss signal
        end	
	end

	if( h_m == 1 )       // hit, just forward the data
	begin
	   if(block_offset[2] == 1'b1)
	      ; // handled from assign statement at the start
            // data_proc = {cache_mem[set][63:32]};
	   else
	       ;// handled from assign statement at the start
            // data_proc = [31:0] cache_mem [set];
	end
end

// check tags everytime the address_proc bus changes
always@(address_proc)
begin
    // calculate everything
    // block = 2 words * (4 bytes/word) = 8 bytes
    for(i = 0; i < 3; i = i+1)
        block_offset[i] = address_proc[i];
    // index = log(4 sets)
    for(i = 0; i < 2; i = i+1)
    begin
        index[i] = {address_proc[3+i]};
        //$display("%x %x", index[i], address_proc[3+i]);
    end
    // remaining bits are tag
    for(i = 0; i < 27; i = i+1)
        tag[i] = address_proc[5+i];
    //$display(tag);
    
    // emulate comparators for the 8 blocks (tags)
    // check for the index, then check for tag
    case(index)
        2'b00 : begin
                case (tag)
                    cache_tags[0] : h_m <= 1;
                    cache_tags[1] : h_m <= 1;
                endcase
                end
        2'b01 : begin
                case (tag)
                    cache_tags[2] : h_m <= 1;
                    cache_tags[3] : h_m <= 1;
                endcase
                end
        2'b10 : begin
                case (tag)
                    cache_tags[4] : h_m <= 1;
                    cache_tags[5] : h_m <= 1;
                endcase
                end
        2'b11 : begin
                case (tag)
                    cache_tags[6] : h_m <= 1;
                    cache_tags[7] : h_m <= 1;
                endcase
                end
        // assert a miss otherwise
        default: begin
                    //cache_block <= 8'b0;
                    h_m <= 0;
                 end
    endcase
end

// remove hit signal and get ready for receiving next address
always@(negedge clk)
begin
    if( h_m == 1'b1)
        h_m = 1'b0;
end

endmodule