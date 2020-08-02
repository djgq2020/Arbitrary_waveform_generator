`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/07/31 22:50:18
// Design Name: 
// Module Name: DDS
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


module DDS(
input  da_clk,
input  rst_n,
output daclk,
output da_data,
output sclk,
output rclk,
output dio,
input  uart_rx,
output uart_tx,
	input[7:0]                  ad_data,
	output                      ad_clk,
    output                      TMDS_clk_p,
    output                      TMDS_clk_n,
    output[2:0]                 TMDS_data_p,       //rgb
    output[2:0]                 TMDS_data_n,        //rgb
    output [0:0]                hdmi_oen
    );
    
wire ad_clk;

wire      [11:0] rom_addr; 
 reg      [11:0] da_data;   
 reg      [11:0] da_data0;
 reg      [19:0] da_data00;
wire      [11:0] da_data1;
wire      [11:0] da_data2;
wire      [11:0] da_data3;
wire      [11:0] da_data4;

reg        [31:0] f_cnt;
reg        [11:0] p_cnt = 0;

reg[31:0]      frequency = 32'd65535;
reg[15:0]      phase = 8'h0;
reg[7:0]       amplitude = 8'h0;
reg[7:0]       waveform = 8'h1;

parameter                       CLK_FRE = 125;//Mhz
localparam                       IDLE =  0;
localparam                       SEND =  1;   //send HELLO ALINX\r\n
localparam                       WAIT =  2;   //wait 1 second and send uart received data
reg[7:0]                         tx_data;
reg[7:0]                         tx_str;
reg                              tx_data_valid;
wire                             tx_data_ready;
reg[7:0]                         tx_cnt;
reg[7:0]                         rx_cnt;
wire[7:0]                        rx_data;
wire                             rx_data_valid;
wire                             rx_data_ready;
reg[31:0]                        wait_cnt;
reg[3:0]                         state;


assign daclk = da_clk;

//Frequency accumulation word
always@(posedge da_clk or negedge rst_n)
if(rst_n)
	f_cnt <= 32'd0;
else
	f_cnt <= f_cnt + 32'd34 * frequency;

//address
assign rom_addr = f_cnt[31:20] + p_cnt;	

//waveform data    
Sin Sin (
  .clka(da_clk),    
  .addra(rom_addr),  
  .douta(da_data1)  
);
Square Square (
  .clka(da_clk),    
  .addra(rom_addr),  
  .douta(da_data2)  
);
Triangle Triangle (
  .clka(da_clk),    
  .addra(rom_addr), 
  .douta(da_data3)  
);
sawtooth sawtooth (
  .clka(da_clk),    
  .addra(rom_addr), 
  .douta(da_data4)  
);   

//waveform select
always@(posedge da_clk or negedge rst_n)
if(rst_n)
da_data0 <= da_data1;
else if(waveform == 8'd0)
da_data0 <= da_data1;
else if(waveform == 8'd1)
da_data0 <= da_data2;
else if(waveform == 8'd2)
da_data0 <= da_data3;
else if(waveform == 8'd3)
da_data0 <= da_data4;
else
da_data0 <= da_data0;	

//wire [12:0]c = 2048 - 8 * amplitude;
//adjust range
always@(posedge da_clk or negedge rst_n)
if(rst_n)
da_data00 <= da_data0;
else 
//da_data00 <= (da_data0* amplitude)>>8;
case(amplitude)
5'd1:da_data00 <= da_data0* 19 / 20 + 12'd102;
5'd2:da_data00 <= da_data0* 18 / 20 + 12'd205;
5'd3:da_data00 <= da_data0* 17 / 20 + 12'd307;
5'd4:da_data00 <= da_data0* 16 / 20 + 12'd410;
5'd5:da_data00 <= da_data0* 15 / 20 + 12'd512;
5'd6:da_data00 <= da_data0* 14 / 20 + 12'd614;
5'd7:da_data00 <= da_data0* 13 / 20 + 12'd717;
5'd8:da_data00 <= da_data0* 12 / 20 + 12'd819;
5'd9:da_data00 <=  da_data0* 11 / 20 + 12'd922;
5'd10:da_data00 <= da_data0* 10 / 20 + 12'd1024;
5'd11:da_data00 <= da_data0* 9 / 20 + 12'd1126;
5'd12:da_data00 <= da_data0* 8 / 20 + 12'd1229;
5'd13:da_data00 <= da_data0* 7 / 20 + 12'd1331;
5'd14:da_data00 <= da_data0*  6/ 20 + 12'd1434;
5'd15:da_data00 <= da_data0* 5 / 20 + 12'd1536;
5'd16:da_data00 <= da_data0* 4 / 20 + 12'd1638;
5'd17:da_data00 <= da_data0* 3 / 20 + 12'd1741;
5'd18:da_data00 <= da_data0* 2 / 20 + 12'd1843;
5'd19:da_data00 <= da_data0* 1 / 20 + 12'd1946;
default:da_data00 <= da_data0;
endcase

always@(posedge da_clk)
da_data = da_data00[11:0];

assign rx_data_ready = 1'b1;//always can receive data,
							
//uart collol FSM
always@(posedge da_clk or negedge rst_n)
begin
	if(rst_n == 1'b1)
	begin
		wait_cnt <= 32'd0;
		tx_data <= 8'd0;
		state <= IDLE;
		tx_cnt <= 8'd0;
		rx_cnt <= 8'd0;
		tx_data_valid <= 1'b0;
	end
	else
	case(state)
		IDLE:
			state <= SEND;
		SEND:
		begin
			wait_cnt <= 32'd0;
			tx_data <= tx_str;

			if(tx_data_valid == 1'b1 && tx_data_ready == 1'b1 && tx_cnt < 8'd7)//Send 8 bytes data
			begin
				tx_cnt <= tx_cnt + 8'd1; //Send data counter
			end
			else if(tx_data_valid && tx_data_ready)//last byte sent is complete
			begin
				tx_cnt <= 8'd0;
				tx_data_valid <= 1'b0;
				state <= WAIT;
			end
			else if(~tx_data_valid)
			begin
				tx_data_valid <= 1'b1;
			end
		end
		WAIT:
		begin
			wait_cnt <= wait_cnt + 32'd1;
			if(rx_data_valid == 1'b1 && rx_cnt < 8'd4)//Receive 4 bytes data
			begin
			    frequency <= {frequency[23:0],rx_data};
				rx_cnt <= rx_cnt + 8'd1; //Receive data counter
			end
		    else if(rx_data_valid == 1'b1 && rx_cnt < 8'd6)//Receive 2 bytes data
			begin
			    phase <= {phase[7:0],rx_data};
				rx_cnt <= rx_cnt + 8'd1; //Receive data counter
			end
		    else if(rx_data_valid == 1'b1 && rx_cnt < 8'd7)//Receive 1 bytes data
			begin
			    amplitude <= rx_data;
				rx_cnt <= rx_cnt + 8'd1; //Receive data counter
			end
			else if(rx_data_valid == 1'b1 && rx_cnt < 8'd8)//Receive 1 bytes data
			begin
			    waveform <= rx_data;
				rx_cnt <= rx_cnt + 8'd1; //Receive data counter
			end
			else if(rx_cnt >= 8'd8)//Receive 8 bytes data
				rx_cnt <= 8'd0; //Receive data counter clear	
			else if(tx_data_valid && tx_data_ready)
			begin
				tx_data_valid <= 1'b0;
			end			
			else if(wait_cnt >= CLK_FRE * 1000000) // wait for 1 second
				state <= SEND;
		end
		default:
			state <= IDLE;
	endcase
end

//report information
always@(*)
begin
	case(tx_cnt)
		8'd0 :  tx_str <= frequency[31:24];
		8'd1 :  tx_str <= frequency[23:16];
		8'd2 :  tx_str <= frequency[15:8];
		8'd3 :  tx_str <= frequency[7:0];
		8'd4 :  tx_str <= phase[15:8];
		8'd5 :  tx_str <= phase[7:0];
		8'd6 :  tx_str <= amplitude;
		8'd7 :  tx_str <= waveform;
		default:tx_str <= 8'd0;
	endcase
end

//uart rx
uart_rx#
(
	.CLK_FRE(CLK_FRE),
	.BAUD_RATE(115200)
) uart_rx_inst
(
	.clk                        (da_clk                  ),
	.rst_n                      (~rst_n                    ),
	.rx_data                    (rx_data                  ),
	.rx_data_valid              (rx_data_valid            ),
	.rx_data_ready              (rx_data_ready            ),
	.rx_pin                     (uart_rx                  )
);

//uart tx
uart_tx#
(
	.CLK_FRE(CLK_FRE),
	.BAUD_RATE(115200)
) uart_tx_inst
(
	.clk                        (da_clk                  ),
	.rst_n                      (~rst_n                    ),
	.tx_data                    (tx_data                  ),
	.tx_data_valid              (tx_data_valid            ),
	.tx_data_ready              (tx_data_ready            ),
	.tx_pin                     (uart_tx                  )
);


wire clk_5m;
wire clk_50m;
wire [3:0] cnts1;
wire  [3:0]cnts2;
wire  [3:0]cntm1;
wire  [3:0]cntm2;
wire  [3:0]cnth1;
wire  [3:0]cnth2;
wire  [3:0]cntd1;
wire  [3:0]cntd2;
wire  adc_clk;

clk_wiz_0 instance_name
   (
    .clk_out1(clk_5m),     //5m
    .clk_out2(clk_50m),     // output clk_out2
    .reset(rst_n), 
    .clk_in1(da_clk));  


assign ad_clk = clk_50m;

//display
assign cntd2 = frequency/10_000_000;
assign cntd1 = frequency%10_000_000/1_000_000;
assign cnth2 = frequency%1_000_000/100_000;
assign cnth1 = frequency%100_000/10_000;
assign cntm2 = frequency%10_000/1_000;
assign cntm1 = frequency%1_000/100;
assign cnts2 = frequency%100/10;
assign cnts1 = frequency%10;

smg  smg(
.clk(clk_5m),
.rst_n(rst_n),
.cnts1(cnts1),
.cnts2(cnts2),
.cntm1(cntm1),
.cntm2(cntm2),
.cnth1(cnth1),
.cnth2(cnth2),
.cntd1(cntd1),
.cntd2(cntd2),
.sclk(sclk),
.rclk(rclk),
.dio(dio)
    );    

wire                            video_clk;
wire                            video_clk5x;
wire                            video_hs;
wire                            video_vs;
wire                            video_de;
wire[7:0]                       video_r;
wire[7:0]                       video_g;
wire[7:0]                       video_b;

wire                            hdmi_hs;
wire                            hdmi_vs;
wire                            hdmi_de;
wire[7:0]                       hdmi_r;
wire[7:0]                       hdmi_g;
wire[7:0]                       hdmi_b;

wire                            grid_hs;
wire                            grid_vs;
wire                            grid_de;
wire[7:0]                       grid_r;
wire[7:0]                       grid_g;
wire[7:0]                       grid_b;

wire                            wave0_hs;
wire                            wave0_vs;
wire                            wave0_de;
wire[7:0]                       wave0_r;
wire[7:0]                       wave0_g;
wire[7:0]                       wave0_b;

wire                            adc0_buf_wr;
wire[10:0]                      adc0_buf_addr;
wire[7:0]                       adc0_buf_data;

//generate video pixel clock
video_pll video_pll_m0
 (
	.clk_in1                    (da_clk                  ),
	.clk_out1                   (video_clk                ),
	.clk_out2                   (video_clk5x              ),
	.reset                      (1'b0                     )
 );

rgb2dvi_0 rgb2dvi_0 (
  .TMDS_Clk_p(TMDS_clk_p),    // output wire TMDS_Clk_p
  .TMDS_Clk_n(TMDS_clk_n),    // output wire TMDS_Clk_n
  .TMDS_Data_p(TMDS_data_p),  // output wire [2 : 0] TMDS_Data_p
  .TMDS_Data_n(TMDS_data_n),  // output wire [2 : 0] TMDS_Data_n
  .oen(hdmi_oen),                  // output wire oen
  .aRst_n(1'b1),            // input wire aRst_n
  .vid_pData({hdmi_r,hdmi_g,hdmi_b}),      // input wire [23 : 0] vid_pData
  .vid_pVDE(),        // input wire vid_pVDE
  .vid_pHSync(),    // input wire vid_pHSync
  .vid_pVSync(),    // input wire vid_pVSync
  .PixelClk(video_clk),        // input wire PixelClk
  .SerialClk(video_clk5x)      // input wire SerialClk
);

color_bar color_bar_m0(
	.clk                        (video_clk                ),
	.rst                        (rst_n                   ),
	.hs                         (video_hs                 ),
	.vs                         (video_vs                 ),
	.de                         (video_de                 ),
	.rgb_r                      (video_r                  ),
	.rgb_g                      (video_g                  ),
	.rgb_b                      (video_b                  )
);


grid_display  grid_display_m0(
	.rst_n                 (~rst_n                      ),
	.pclk                  (video_clk                  ),
	.i_hs                  (video_hs                   ),
	.i_vs                  (video_vs                   ),
	.i_de                  (video_de                   ),
	.i_data                ({video_r,video_g,video_b}  ),
	.o_hs                  (grid_hs                    ),
	.o_vs                  (grid_vs                    ),
	.o_de                  (grid_de                    ),
	.o_data                ({grid_r,grid_g,grid_b}     )
);

ad_sample ad_sample_m0(
	.adc_clk               (ad_clk                    ),
	.rst                   (rst_n                     ),
	.adc_data              (ad_data                ),
	.adc_data_valid        (1'b1                       ),
	.adc_buf_wr            (adc0_buf_wr                ),
	.adc_buf_addr          (adc0_buf_addr              ),
	.adc_buf_data          (adc0_buf_data              )
);

//display 50khz - 1Mhz
wav_display wav_display_m0(
	.rst_n                 (~rst_n                      ),
	.pclk                  (video_clk                  ),
	.wave_color            (24'hff0000                 ),
	.adc_clk               (ad_clk                    ),
	.adc_buf_wr            (adc0_buf_wr                ),
	.adc_buf_addr          (adc0_buf_addr              ),
	.adc_buf_data          (adc0_buf_data              ),
	.i_hs                  (grid_hs                    ),
	.i_vs                  (grid_vs                    ),
	.i_de                  (grid_de                    ),
	.i_data                ({grid_r,grid_g,grid_b}     ),
	.o_hs                  (wave0_hs                   ),
	.o_vs                  (wave0_vs                   ),
	.o_de                  (wave0_de                   ),
	.o_data                ({wave0_r,wave0_g,wave0_b}  )
);

endmodule
