`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/09/2019 01:17:33 PM
// Design Name: 
// Module Name: testbench
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


module testbench(
    );
    
wire h_m_cache, h_m_proc, from_ram_ack, ram_gate, to_cache_ack, r_w_cache, r_w_ram;
reg r_w_proc;
reg clk, reset; 
wire [31:0] address_cache_to_ram, data_proc;
wire [63:0] data_ram;
reg [31:0] address_proc;

reg [31:0] address_list [9:0];  // stores the input addresses  
reg [3:0] instruction;          // acts like an instruction pointer

controller cache_controller(h_m_cache, h_m_proc, r_w_proc, r_w_cache, r_w_ram, from_ram_ack, ram_gate, to_cache_ack, clk, reset);
cacheInterface cache_interface(address_proc, data_proc, address_cache_to_ram, data_ram, h_m_cache, r_w_cache, to_cache_ack, clk, reset);
ramInterface ram_interface(address_cache_to_ram, data_ram, r_w_ram, ram_gate, from_ram_ack, clk, reset);

initial begin
instruction='bz;
clk = 0;
r_w_proc = 1'b1;
#10;
repeat(1000)
    begin
    // following block is positive edge, update address here.
    address_proc = address_list[instruction];
        //if(instruction == 10)
          //  instruction=0;
    // miss will keep sending the same addresses
    clk = ~(clk); #5;
    
    // following block is negative edge
    //  instruction should be updated only if the hit was signalled.
    if(h_m_proc == 1)
        instruction = (instruction + 1);
    clk = ~(clk); #5;
    if (instruction == 11)
        $finish;
    end
end

initial begin
reset =1'b1;
#2 reset =1'b0;
instruction=0;
$readmemh("addresses.mem", address_list);
#18;
end

endmodule
