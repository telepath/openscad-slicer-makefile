THIS_FILE := $(lastword $(MAKEFILE_LIST))

# directories
STL=stl
IMG=img
GCODE=gcode
DEPS=build
REPO=`pwd`

# executables
OPENSCAD=openscad-nightly
SLICER=slicer

# explicit wildcard expansion suppresses errors when no files are found
include $(wildcard $(DEPS)/*.deps)

# config
DEF_MAT=PET
SLICER_CONFIG=conf/0.2mm_MAT_MK3.ini
CENTER=125x105
VER:=`git log -n 1 --pretty=format:%h .`

.PHONY: all stl gcode png clean %.stl %.png %.gcode

all: gcode

stl: $(patsubst %.scad, $(stl)/%.stl, $(wildcard *.scad))

png: $(patsubst %.scad, $(img)/%.png, $(wildcard *.scad))

gcode: $(patsubst %.scad, $(GCODE)/%.gcode, $(wildcard *.scad))

clean:
	rm -f *.stl *.gcode *.png $(DEPS)/* $(STL)/* $(GCODE)/*

$(STL)/%.stl: %.scad
	mkdir -p $(STL)
	mkdir -p $(DEPS)
	$(OPENSCAD) -m make -o $@ \
	-D MAT=\"`cat ${@:$(STL)/%.stl=%.mat} || \
	echo $(DEF_MAT)`\" \
	-D VER=\"$(VER)\" \
	-D FILE=\"$@\" \
	-D ACTION=\"print\" \
	-d $(DEPS)/`basename $@`.deps $<
	sleep 3
	$(MAKE) -f $(THIS_FILE) $(IMG)/`basename $@ .stl`.png &

$(IMG)/%.png: %.scad
	mkdir -p $(IMG)
	$(OPENSCAD) -m make -o $(@:.png=-$(VER).png) \
	-D MAT=\"`cat ${@:$(IMG)/%.png=%.mat} || \
	echo $(DEF_MAT)`\" \
	-D VER=\"$(VER)\" \
	-D FILE=\"$@\" \
	-D ACTION=\"print\" \
	--imgsize=2048,2048 --render \
	-d $(DEPS)/`basename $@`.deps $< &
	$(OPENSCAD) -m make -o $(@:.png=-$(VER)-preview.png) \
	-D MAT=\"`cat ${@:$(IMG)/%.png=%.mat} || \
	echo $(DEF_MAT)`\" \
	-D VER=\"$(VER)\" \
	-D FILE=\"$@\" \
	--imgsize=2048,2048 -d $(DEPS)/`basename $@`.deps $< &

$(GCODE)/%.gcode: $(STL)/%.stl
	@echo $@: $<
	mkdir -p $(GCODE)
	$(SLICER) --no-gui --load $(subst MAT,`cat ${@:$(GCODE)/%.gcode=%.mat} || echo $(DEF_MAT)`,$(SLICER_CONFIG)) --print-center $(CENTER) $(shell cat ${@:$(GCODE)/%.gcode=%.slice}) -o $(GCODE)/ $< || $(SLICER) --gui --load $(subst MAT,`cat ${@:$(GCODE)/%.gcode=%.mat} || echo $(DEF_MAT)`,$(SLICER_CONFIG)) $(shell cat ${@:$(GCODE)/%.gcode=%.slice}) -o $(GCODE)/ $< &

$(PWD)/lib/%:
	./submodules.sh lib/$<

lib/%:
	./submodules.sh lib/$<

%.stl: $(STL)/%.stl
	@#

%.scad: $(STL)/%.stl
	@#

%.gcode: $(GCODE)/%.gcode
	@#

%.scad: $(STL)/%.stl
	@#
