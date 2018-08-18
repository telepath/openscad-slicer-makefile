THIS_FILE := $(lastword $(MAKEFILE_LIST))
# explicit wildcard expansion suppresses errors when no files are found

# directories
STL=stl
IMG=img
GCODE=gcode
DEPS=build

# executables
OPENSCAD=openscad-nightly
SLICER=slicer

include $(wildcard $(DEPS)/*.deps)

# config
DEF_MAT=PET
SLICER_CONFIG=conf/0.2mm_MAT_MK3.ini

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
	$(OPENSCAD) -m make -o $@ -D MAT=`cat ${@:$(STL)/%.stl=%.mat} || echo \"$(DEF_MAT)\"` -d $(DEPS)/`basename $@`.deps $<
	$(MAKE) -f $(THIS_FILE) $(IMG)/`basename $@ .stl`.png &

$(IMG)/%.png: %.scad
	mkdir -p $(IMG)
	$(OPENSCAD) -m make -o $(@:.png=-`date '+%y-%m-%d-%H-%M-%S'`.png) --D MAT=`cat ${@:$(IMG)/%.png=%.mat} || echo \"$(DEF_MAT)\"` --imgsize=2048,2048 --render -d $(DEPS)/`basename $@`.deps $< &
	$(OPENSCAD) -m make -o $(@:.png=-`date '+%y-%m-%d-%H-%M-%S'-preview`.png) -D MAT=`cat ${@:$(IMG)/%.png=%.mat} || echo \"$(DEF_MAT)\"` --imgsize=2048,2048 -d $(DEPS)/`basename $@`.deps $< &

$(GCODE)/%.gcode: $(STL)/%.stl
	@echo $@: $<
	mkdir -p $(GCODE)
	$(SLICER) --no-gui --load $(subst MAT,`cat ${@:$(GCODE)/%.gcode=%.mat} || echo $(DEF_MAT)`,$(SLICER_CONFIG)) "$(shell cat ${@:$(GCODE)/%.gcode=%.slice})" -o $(GCODE)/ $< &

%.stl: $(STL)/%.stl
	@#

%.scad: $(STL)/%.stl
	@#

%.gcode: $(GCODE)/%.gcode
	@#

%.scad: $(STL)/%.stl
	@#
