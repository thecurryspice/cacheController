`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/09/2019 09:54:14 AM
// Design Name: 
// Module Name: ramInterface
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


module ramInterface(
    input [31:0] address,
    inout [63:0] data,
    input r_w,
    input ram_gate,
    output reg ack,
    input clk,
    input reset
    );

// 128 bytes, 32 words, byte addressable
reg [7:0] ram_mem [127:0];
reg [3:0] counter = 4'b0000;

// assert 64 bit data only if ack is ready and read request is received
assign data = (ack && r_w) ? {ram_mem[address+7], ram_mem[address+6], ram_mem[address+5], ram_mem[address+4], ram_mem[address+3], ram_mem[address+2], ram_mem[address+1], ram_mem[address]} : 'bz;

always@(posedge clk)
begin
    // only activate on ram_gate
    if(ram_gate == 1)
    begin
        if(r_w == 0)    // write request, update mem
        begin
            ram_mem[address] = data;
        end
        
        if(r_w == 1)    // read request, 
        ;// asserting data is handled by assign statement above        
    end
end

always@(negedge clk)
begin
    // end acknowledgement if sent before
    if(ack == 1)
        ack = 1'b0;
    
    if(ram_gate == 1)
    begin
        // assert acknowledgement signal when counter is 9
        if(counter == 9)
            ack = 1'b1;
        // keep data valid for 1 clock
        //if(counter == 1)
          //  ack = 1'b0;
        
        // increment
        counter = counter + 1;            
        
        // reset counter if value is 10
        if(counter == 10)
            counter = 0;
    end
end

always@(negedge ack)
begin
    counter = 0;
end

always@(negedge reset)
begin
    $readmemh("ramMem256.mem", ram_mem);
    $display("Init Mem");
    ack = 1'b0;
end    

endmodule