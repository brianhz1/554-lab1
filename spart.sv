//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:   
// Design Name: 
// Module Name:    spart 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module spart(
    input clk,
    input rst,
    input iocs,
    input iorw,
    output rda,
    output tbr,
    input [1:0] ioaddr,
    inout [7:0] databus,
    output txd,
    input rxd
);
    // spart transfer
    spart_tx iSPART_TX(.clk(clk), .rst_n(rst), .enable(enable), .addr(ioaddr), .tx_data(tx_data), .iorw(iorw), .TBR(tbr), .TX(txd));

    // spart receive

    // baud generator
    baud_gen iBAUD_GEN(.clk(clk), .rst_n(rst), .iorw(iorw), .addr(ioaddr), .db_data(db_data), .enable(enable));

    // bus interface
    
endmodule
