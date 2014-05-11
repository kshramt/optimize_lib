# Configurations
.SUFFIXES:
.DELETE_ON_ERROR:
.ONESHELL:
.SECONDARY:
.PRECIOUS:
export SHELL := /bin/bash
export SHELLOPTS := pipefail:errexit:nounset:noclobber

# Constants
FC := gfortran
# FC := ifort

ifeq ($(FC),ifort)
   LIBS := -mkl
else
   LIBS := -lblas -llapack
endif

FFLAGS := -ffree-line-length-none -fmax-identifier-length=63 -pipe -cpp -C -Wall -fbounds-check -O0 -fbacktrace -ggdb -pg -DDEBUG -Wrealloc-lhs-all $(LIBS)
# FFLAGS := -ffree-line-length-none -fmax-identifier-length=63 -pipe -cpp -C -Wall -O3 -march=native -flto -fwhole-program -ftree-parallelize-loops=$(shell nproc) -fopenmp $(LIBS)

# FFLAGS := -fpp -warn -assume realloc_lhs -no-ftz -mkl -check nouninit -trace -O0 -p -g -DDEBUG -debug all $(LIBS)
# FFLAGS := -fpp -warn -assume realloc_lhs -no-ftz -mkl -lpthread -openmp -ip -ipo -parallel -O3 -xHost $(LIBS)

LBFGSB := Lbfgsb.3.0

FUNCTIONS := lbfgsb timer
MODULES := optimize_lib
TESTS := optimize_lib_test

FUNCTION_OS := $(FUNCTIONS:%=%.o)
MODULE_OS := $(MODULES:%=%.o)
MODULE_MODS := $(MODULES:%=%.mod)
TEST_EXES := $(TESTS:%=%.exe)
TEST_DONES := $(TESTS:%=%.done)

# Tasks
.PHONY: all test clean
all:

test: $(TEST_DONES)

clean:
	rm -f $(TEST_EXES) $(TEST_DONES) $(FUNCTION_OS) $(MODULE_OS) $(MODULE_MODS)

# Files
optimize_lib_test.exe: $(FUNCTION_OS) $(MODULE_OS) optimize_lib_test.F90 | $(MODULE_MODS)
	$(FC) $(FFLAGS) -o $@ $^

dep/$(LBFGSB): dep/$(LBFGSB).tar.gz
	cd $(<D)
	tar -mxf $(<F)

dep/$(LBFGSB).tar.gz:
	mkdir -p $(@D)
	cd $(@D)
	wget http://www.ece.northwestern.edu/~nocedal/Software/$(@F)

# Rules
%.done: %.exe
	$(<D)/$(<F)
	touch $@

%.o %.mod: %.F90
	$(FC) $(FFLAGS) -o $(@:%.mod=%.o) -c $<

%.o: %.f
	$(FC) $(FFLAGS) -o $@ -c $<

%.f: dep/$(LBFGSB)/%.f
	cp -f $< $@

dep/$(LBFGSB)/%.f: | dep/$(LBFGSB)
	@
