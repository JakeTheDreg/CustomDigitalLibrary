//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Jake Bramhall
// 
// Create Date: 01/18/2026 08:37:58 PM
// Design Name: blinky
// Module Name: blinky
// Project Name: blinky
// Target Devices: SEA Board
// Tool Versions: 2025.2
// Description: Blinks about 1 time a second
// 
// Dependencies: clk_wiz_0_clk_wiz
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module blinky(
    input clk,
    input rst_n,
    output led
    );
    
    wire local_clk;
    reg [21:0] divider;
    
    clk_wiz_0 clk_div1(
      .clk_out1(local_clk),
      .resetn(rst_n),
      .locked(),
      .clk_in1(clk)
   );
   
   always @(posedge local_clk) begin
       if(!rst_n) begin
           divider <= 'b0;
       end else begin
           divider = divider + 1'b1;
       end
   end
   
   assign led = divider[21];
    
endmodule
