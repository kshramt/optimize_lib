# Constants
FC := gfortran
FFLAGS := -ffree-line-length-none -fmax-identifier-length=63 -pipe -cpp -C -Wall -fbounds-check -O0 -fbacktrace -ggdb -pg -DDEBUG -Wrealloc-lhs-all
# FFLAGS := -ffree-line-length-none -fmax-identifier-length=63 -pipe -cpp -C -Wall -O3 -march=native -flto -fwhole-program -ftree-parallelize-loops=$(shell nproc) -fopenmp

# FC := ifort
# FFLAGS := -fpp -warn -assume realloc_lhs -no-ftz -mkl -check nouninit -trace -O0 -p -g -DDEBUG -debug all
# FFLAGS := -fpp -warn -assume realloc_lhs -no-ftz -mkl -lpthread -openmp -ip -ipo -parallel -O3 -xHost

ifeq ($(FC),ifort)
   FFLAGS += -mkl
endif

LBFGSB := Lbfgsb.3.0

FUNCTIONS := lbfgsb timer linpack
ifneq ($(FC),ifort)
   FUNCTIONS += blas
endif
MODULES := optimize_lib
TESTS := optimize_lib_test

FUNCTION_OS := $(FUNCTIONS:%=%.o)
MODULE_OS := $(MODULES:%=%.o)
MODULE_MODS := $(MODULES:%=%.mod)
TEST_EXES := $(TESTS:%=%.exe)
TEST_DONES := $(TESTS:%=%.done)

# Configurations
.SUFFIXES:
.DELETE_ON_ERROR:
.ONESHELL:
.SECONDARY:
.PRECIOUS:
export SHELL := /bin/bash
export SHELLOPTS := pipefail:errexit:nounset:noclobber

# Tasks
.PHONY: all test clean
all:

test: $(TEST_DONES)

clean:
	rm -f $(TEST_EXES) $(TEST_DONES) $(FUNCTION_OS) $(MODULE_OS) $(MODULE_MODES)

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
	$(FC) $(FFLAGS) -o $@ -c $<

%.o: %.f
	$(FC) $(FFLAGS) -o $@ -c $<

%.f: dep/$(LBFGSB)/%.f
	cp -f $< $@

dep/$(LBFGSB)/%.f: | dep/$(LBFGSB)
	@
