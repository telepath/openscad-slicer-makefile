THIS_FILE := $(lastword $(MAKEFILE_LIST))

# directories
STL=stl
IMG=img
GCODE=gcode
DEPS=build
ASSY=assembly

# executables
OPENSCAD=openscad-nightly
SLICER=prusa-slicer

# explicit wildcard expansion suppresses errors when no files are found
include $(wildcard $(DEPS)/*.deps)

# config
DEF_MAT=PET
SLICER_CONFIG=conf/0.2mm_MAT_MINI.ini
CENTER=125x105
STATUS := $(shell git diff --no-ext-diff --quiet || echo \\\*)
VER := $(shell git log -n 1 --pretty=format:%h .)$(STATUS)

.PHONY: all stl gcode png clean %.stl %.png %.gcode

.PRECIOUS: $(STL)/%.stl

all: gcode

stl: $(patsubst %.scad, $(stl)/%.stl, $(wildcard *.scad))

assy: $(patsubst %.scad, $(ASSY)/%.stl, $(wildcard *.scad))

png: $(patsubst %.scad, $(img)/%.png, $(wildcard *.scad))

gcode: $(patsubst %.scad, $(GCODE)/%.gcode, $(wildcard *.scad))

clean:
	rm -f *.stl *.gcode *.png $(DEPS)/* $(STL)/* $(GCODE)/*

$(abspath .)/%: %
	@echo $@: $<

$(STL)/%.stl: %.scad
	@echo $@: $<
	mkdir -p $(STL)
	mkdir -p $(DEPS)
	$(OPENSCAD) -m make -o $@ \
	-D MAT=\"`cat ${@:$(STL)/%.stl=%.mat} || \
	echo $(DEF_MAT)`\" \
	-D VER=\"$(VER)\" \
	-D FILE=\"${@:$(STL)/%=%}\" \
	-D ACTION=\"print\" \
	-d $(DEPS)/`basename $@`.deps $<
	$(MAKE) -f $(THIS_FILE) $(IMG)/`basename $@ .stl`.png

$(ASSY)/%.stl: %.scad
	@echo $@: $<
	mkdir -p $(ASSY)
	mkdir -p $(DEPS)
	$(OPENSCAD) -m make -o $@ \
	-D MAT=\"`cat ${@:$(ASSY)/%.stl=%.mat} || \
	echo $(DEF_MAT)`\" \
	-D VER=\"$(VER)\" \
	-D FILE=\"${@:$(ASSY)/%=%}\" \
	-D ACTION=\"assembly\" \
	-d $(DEPS)/`basename $@`.deps $<

$(IMG)/%.png: %.scad
	@echo $@: $<
	mkdir -p $(IMG)
	$(OPENSCAD) -m make -o $(@:.png=-$(VER).png) \
	-D MAT=\"`cat ${@:$(IMG)/%.png=%.mat} || \
	echo $(DEF_MAT)`\" \
	-D VER=\"$(VER)\" \
	-D FILE=\"${@:$(IMG)/%=%}\" \
	-D ACTION=\"print\" \
	--imgsize=2048,2048 --render 1 $< &
	$(OPENSCAD) -m make -o $(@:.png=-$(VER)-preview.png) \
	-D MAT=\"`cat ${@:$(IMG)/%.png=%.mat} || \
	echo $(DEF_MAT)`\" \
	-D VER=\"$(VER)\" \
	-D FILE=\"${@:$(IMG)/%=%}\" \
	--imgsize=2048,2048 $< &

$(GCODE)/%.gcode: $(STL)/%.stl
	@echo $@: $<
	mkdir -p $(GCODE)
	$(SLICER) --load $(subst MAT,`cat ${@:$(GCODE)/%.gcode=%.mat} || echo $(DEF_MAT)`,$(SLICER_CONFIG)) --center $(CENTER) $(shell cat ${@:$(GCODE)/%.gcode=%.slice}) -o $(GCODE)/ --slice $<

lib/%:
	./submodules.sh lib/$(dir $<)

%.stl: $(STL)/%.stl
	@echo $@: $<

%.scad: $(STL)/%.stl
	@echo $@: $<

%.gcode: $(GCODE)/%.gcode
	@echo $@: $<

%.scad: $(STL)/%.stl
	@echo $@: $<
