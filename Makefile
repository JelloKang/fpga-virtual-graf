PROJ = i2c
PIN_DEF = blackice.pcf
DEVICE = hx8k

SRC = i2c_master.v camera.v xy_leds.v dvid.v vga.v clockdiv.v sram.v pixel_buffer.v write_buffer.v bresenham.v map_cam.v pulse.v

all: $(PROJ).bin $(PROJ).rpt 
svg: $(patsubst %.v,%.svg,$(SRC))

%.blif: %.v $(SRC)
	yosys -p "synth_ice40 -top top -blif $@" $^

#%.blif: %.v $(SRC)
#	yosys -p 'synth_ice40 -top top -blif $@' $<  i2c_master.v camera.v button.v xy_leds.v

# $@ The file name of the target of the rule.rule
# $< first pre requisite
# $^ names of all preerquisites

%.svg: %.v
	yosys -p "read_verilog $<; proc; opt; show -colors 2 -width -signed -format svg -prefix $(basename $@)"

%.asc: $(PIN_DEF) %.blif
	#arachne-pnr -d $(subst hx,,$(subst lp,,$(DEVICE))) -o $@ -p $^
	arachne-pnr --device 8k --package tq144:4k -o $@ -p $^

%.bin: %.asc
	icepack $< $@

%.rpt: %.asc
	icetime -d $(DEVICE) -mtr $@ $<

debug-sram-vga-line:
	iverilog -o sram_vga_line sram_vga_line_tb.v sram.v vga.v bresenham.v pixel_buffer.v write_buffer.v
	vvp sram_vga_line -fst
	gtkwave test.vcd gtk-sram_vga_line.gtkw

debug-bresenham:
	iverilog -o bresenham bresenham_tb.v bresenham.v
	vvp bresenham -fst
	gtkwave test.vcd gtk-bresenham.gtkw

debug-sram:
	iverilog -o sram sram_tb.v sram.v
	vvp sram -fst
	gtkwave test.vcd gtk-sram.gtkw

debug-clockdiv:
	iverilog -o clock clockdiv_tb.v clockdiv.v
	vvp clock -fst
	gtkwave test.vcd gtk-clock.gtkw

debug-vga:
	iverilog -o vga vga_tb.v vga.v
	vvp vga -fst
	gtkwave test.vcd gtk-vga.gtkw

debug-sram-vga:
	iverilog -o vga-sram sram_vga_tb.v sram.v vga.v pixel_buffer.v
	vvp vga-sram -fst
	gtkwave test.vcd gtk-vga-sram.gtkw

debug-i2c:
	iverilog -o i2c i2c_tb.v camera.v i2c_master.v button.v xy_leds.v
	vvp i2c -fst
	gtkwave test.vcd gtk-i2c.gtkw

debug-leds:
	iverilog -o leds xy_leds_tb.v xy_leds.v
	vvp leds -fst
	gtkwave test.vcd gtk-leds.gtkw

debug-master:
	iverilog -o i2c i2c_master_tb.v i2c_master.v 
	vvp i2c -fst
	gtkwave test.vcd gtk-master.gtkw

debug-camera:
	iverilog -o camera camera_tb.v camera.v i2c_master.v 
	vvp camera -fst
	gtkwave test.vcd gtk-camera.gtkw

#prog: $(PROJ).bin
#	iceprog $<

prog: $(PROJ).bin
	bash -c "cat $< > /dev/ttyUSB1"

sudo-prog: $(PROJ).bin
	@echo 'Executing prog as root!!!'
	sudo iceprog $<

clean:
	rm -f $(PROJ).blif $(PROJ).asc $(PROJ).rpt $(PROJ).bin

.SECONDARY:
.PHONY: all prog clean svg
