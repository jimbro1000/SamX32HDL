`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    07:27:08 06/08/2025 
// Design Name: 
// Module Name:    DataSelectPath 
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
module DataSelectPath(
		input AnG,
		input AnS,
		input [2:0] GM,
		output Divider,
		output selAlpha,
		output selSemi
    );

	assign Divider = AnG && (GM[0] == 1'b0) ? 1'b1 : 1'b0;
	assign selSemi = !AnG && AnS ? 1'b1 : 1'b0;
	assign selAlpha = !AnG && !AnS ? 1'b1 : 1'b0;
endmodule