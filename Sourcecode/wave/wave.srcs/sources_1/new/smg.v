`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/03/09 21:20:49
// Design Name: 
// Module Name: smg
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


module smg(
input  clk,
input  rst_n,
input  [3:0]cnts1,
input  [3:0]cnts2,
input  [3:0]cntm1,
input  [3:0]cntm2,
input  [3:0]cnth1,
input  [3:0]cnth2,
input  [3:0]cntd1,
input  [3:0]cntd2,
output sclk,
output rclk,
output dio
    );

reg [7:0] cnt_s;
reg [31:0]cnt;
reg [2:0]cnt_n;
reg dio;
reg rclk;
reg sclk;
wire clk_f;
wire sclk_n;
wire rclk_n;

reg [7:0] addr;
reg [7:0] time_n;
reg [31:0]cnt1;
reg [7:0] cnt_s1;
reg [7:0] cnt_s2;



always@(posedge clk or negedge rst_n)
if(rst_n)
    cnt <= 32'd0;
else
    if(cnt == 32'd36)
        cnt <= 32'd0;
    else
        cnt <= cnt +1'b1;
            
always@(posedge clk or negedge rst_n)
        if(rst_n)
            cnt_n <= 3'd0;
        else
            if(cnt == 32'd36)
                if(cnt_n == 3'd7)
                   cnt_n <= 3'd0;
                else
                   cnt_n <= cnt_n +1'b1;     
            else
                cnt_n <= cnt_n ;

always@(posedge clk or negedge rst_n)
                                if(rst_n)
                                    addr <= 8'd0;
                                else
                                    case(cnt_n)
                                    3'd0:addr<=8'h80;
                                    3'd1:addr<=8'h40;
                                    3'd2:addr<=8'h20;
                                    3'd3:addr<=8'h10;
                                    3'd4:addr<=8'h08;
                                    3'd5:addr<=8'h04;
                                    3'd6:addr<=8'h02;
                                    3'd7:addr<=8'h01;
                                    
                                    endcase
always@(posedge clk or negedge rst_n)
                                                                    if(rst_n)
                                                                        time_n <= 8'd0;
                                                                    else
                                                                        case(cnt_n)
                                                                        3'd7:time_n<=cntd2;
                                                                        3'd0:time_n<=cntd1;
                                                                        3'd1:time_n<=cnth2;
                                                                        3'd2:time_n<=cnth1;
                                                                        3'd3:time_n<=cntm2;
                                                                        3'd4:time_n<=cntm1;
                                                                       3'd5:time_n<=cnts2;
                                                                       3'd6:time_n<=cnts1;
 //                                                                       3'd5:time_n<=8'd10;
 //                                                                       3'd6:time_n<=8'd10;
                                                                        
                                                                        
                                                                        endcase



//always@(posedge clk_f or negedge rst_n)
//        if(rst_n)
//            cnt1 <= 32'd0;
//        else
//            if(cnt1 == 32'd5_000_00)
//                cnt1 <= 32'd0;
//            else
//                cnt1 <= cnt1 +1'b1; 
//always@(posedge clk_f or negedge rst_n)
//                        if(rst_n)
//                            cnt_s1 <= 32'd0;
//                        else
//                            if(cnt1 == 32'd5_000_00)
//                            if(cnt_s1 == 8'd9)
//                                cnt_s1 <= 32'd0;
//                            else
//                                cnt_s1 <= cnt_s1 +1'b1; 
//                            else
//                                cnt_s1 <= cnt_s1;



always@(posedge clk or negedge rst_n)
                                if(rst_n)
                                    cnt_s2 <= 8'd0;
                                else
                                    case(time_n)
                                    8'd0:cnt_s2<=8'hc0;
                                    8'd1:cnt_s2<=8'hf9;
                                    8'd2:cnt_s2<=8'ha4;
                                    8'd3:cnt_s2<=8'hb0;
                                    8'd4:cnt_s2<=8'h99;
                                    8'd5:cnt_s2<=8'h92;
                                    8'd6:cnt_s2<=8'h82;
                                    8'd7:cnt_s2<=8'hf8;
                                    8'd8:cnt_s2<=8'h80;
                                    8'd9:cnt_s2<=8'h90;
                                    8'd10:cnt_s2<=8'hff;
                                    endcase


always@(posedge clk or negedge rst_n)
if(rst_n)
    cnt_s <= 8'h00;
else
    if(cnt == 32'd1)
        cnt_s <=cnt_s2;   
    else if(cnt == 32'd18)
        cnt_s <= addr;
    else if(dio_n)
        cnt_s = cnt_s <<1;
     else
      cnt_s <=  cnt_s ;    





assign dio_n =  (cnt == 32'd2 || cnt == 32'd4 ||cnt == 32'd6 ||cnt == 32'd8 ||cnt == 32'd10 ||cnt == 32'd12 ||cnt == 32'd14 ||cnt == 32'd16 ||cnt == 32'd19 ||cnt == 32'd21 ||cnt == 32'd23 ||cnt == 32'd25 ||cnt == 32'd27 ||cnt == 32'd29 ||cnt == 32'd31 ||cnt == 32'd33)
                 ? 1'b1:1'b0;
assign sclk_n =  (cnt == 32'd3 || cnt == 32'd5 ||cnt == 32'd7 ||cnt == 32'd9 ||cnt == 32'd11 ||cnt == 32'd13 ||cnt == 32'd15 ||cnt == 32'd17 ||cnt == 32'd20 ||cnt == 32'd22 ||cnt == 32'd24 ||cnt == 32'd26 ||cnt == 32'd28 ||cnt == 32'd30 ||cnt == 32'd32 ||cnt == 32'd34)
                 ? 1'b1:1'b0;

always@(posedge clk or negedge rst_n)
if(rst_n)begin
    dio <= 1'b0;
end
else 
     if(dio_n)begin
        if(cnt_s[7])
          dio <= 1'b1;
       else
          dio <= 1'b0;         
    end    
    else
        dio <= 1'b0;  

always@(posedge clk or negedge rst_n)
if(rst_n)
    sclk <= 1'b0;
else if(sclk_n)
         sclk <= 1'b1;     
else
    sclk <= 1'b0;  

always@(posedge clk or negedge rst_n)
if(rst_n)
    rclk <= 1'b0;
else
    if(cnt == 32'd35)
        rclk <= 1'b1;
    else
        rclk <= 1'b0; 


endmodule
