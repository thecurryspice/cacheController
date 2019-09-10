`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/09/2019 09:54:14 AM
// Design Name: 
// Module Name: controller
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


module controller(
    input h_m_cache,
    output wire h_m_proc,
    input r_w_proc,
    output wire r_w_cache,
    output wire r_w_ram,
    input ram_ack,
    output wire ram_gate,
    output wire cache_ack,
    input clk,
    input reset
    );

assign h_m_proc = h_m_cache;
assign cache_ack = ram_ack;
assign r_w_cache = r_w_proc;
assign r_w_ram = r_w_proc;
// ram should only be active on a miss
assign ram_gate = ~(h_m_cache);

//always@(negedge clk)
//begin
//    // forward the signals synchronously
//    cache_ack <= ram_ack;
//    //h_m_proc <= h_m_cache;
//    r_w_cache <= r_w_proc;
//    r_w_ram <= r_w_proc;
//    // ram should only be active on a miss
//    ram_gate <= ~(h_m_cache);
//end

//always@(negedge reset)
//begin
//    {r_w_cache, r_w_ram, cache_ack, ram_gate} = 4'b0000;
//end

endmodule
