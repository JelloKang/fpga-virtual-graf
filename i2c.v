`default_nettype none
`define 126M_PLL // correct for 25mhz vga clock
module top (
	input  clk,
	output LED1,
	output LED2,
	output LED3,
	output LED4,
	output LED5,
    output pixartclk,
    output i2c_sda,
    input i2c_sda_in,
    output i2c_scl,
    input button,
    output [7:0] PIO0,
    output [7:0] PMOD
);
    
    reg slow_clk;
    reg i2c_start = 1;
    wire debounced;
    reg deb1;
	reg [8:0] counter = 0;

    reg[9:0] x;
    reg[9:0] y;

    wire reset = 0;

    //debounce db1(.clk (slow_clk), .button (button), .debounced (debounced));

    camera cam(.clk (slow_clk), .reset (reset), .i2c_scl(i2c_scl), .i2c_sda_in(i2c_sda_in), .i2c_sda(i2c_sda), .start(i2c_start), .debug(PIO0), .x(x), .y(y)); //, .debug(PIO0)); 

   xy_leds leds(.x(x), .y(y), .LED1(LED1), .LED2(LED2),.LED3(LED3),.LED4(LED4),.LED5(LED5));

    //PLL details http://www.latticesemi.com/view_document?document_id=47778
    SB_PLL40_CORE #(
        .FEEDBACK_PATH("SIMPLE"),
        .PLLOUT_SELECT("GENCLK"),
        `ifdef 50M_PLL
        .DIVR(4'b0000),
        .DIVF(7'b1000010),
        .DIVQ(3'b100),
        .FILTER_RANGE(3'b001)
        `endif
        `ifdef 126M_PLL
        .DIVR(4'b0000),
        .DIVF(7'b1010011),
        .DIVQ(3'b011),
        .FILTER_RANGE(3'b001)
        `endif
        `ifdef 200M_PLL
        .DIVR(4'b0000),
        .DIVF(7'b1000010),
        .DIVQ(3'b010),
        .FILTER_RANGE(3'b001)
        `endif
    ) uut (
//        .LOCK(lock),
        .RESETB(1'b1),
        .BYPASS(1'b0),
        .REFERENCECLK(clk),
        .PLLOUTCORE(clkx5)
    );

//    assign LED1 = debounced;
//    assign LED3 = i2c_start;

  // make a pulse from the button to trigger the i2c comms
  // think there are issues with the clock freqs, slw clock is much slower so can miss a pulse
  always@(posedge slow_clk) begin
      deb1 <= debounced;
      if(debounced & ~ deb1)
        i2c_start <= 1;
      else
        i2c_start <= 0;
  end
    
    // generate the slow clock for the i2c bus & button debounce
	always@(posedge clk) begin
		counter <= counter + 1;
        if(counter > 60) begin
            slow_clk <= ~ slow_clk;
            counter <= 0;
        end
	end

    wire clkx5;
  wire hsync;
  wire vsync;
  wire blank;
  wire [2:0] red;
  wire [2:0] green;
  wire [2:0] blue;
    wire vga_clk;

    clk_divn clockdiv(.clk(clkx5), .clk_out(vga_clk));
    vga vga_test(.x(x), .y(y), .clk(vga_clk), .hsync(hsync), .vsync(vsync), .blank(blank), .red(red), .green(green), .blue(blue));

    dvid dvid_test(.clk(vga_clk), .clkx5(clkx5), .hsync(hsync), .vsync(vsync), .blank(blank), .red(red), .green(green), .blue(blue), .hdmi_p(PMOD[0:3]), .hdmi_n(PMOD[4:7]));


endmodule
