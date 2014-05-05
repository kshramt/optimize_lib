# Constants
MY_FORTRAN ?= gfortran -ffree-line-length-none -fmax-identifier-length=63 -pipe -cpp -C -Wall -fbounds-check -O0 -fbacktrace -ggdb -pg -DDEBUG -Wrealloc-lhs-all
# MY_FORTRAN ?= gfortran -ffree-line-length-none -fmax-identifier-length=63 -pipe -cpp -C -Wall -O3 -march=native -flto -fwhole-program -ftree-parallelize-loops=2 -fopenmp
# MY_FORTRAN ?= -fpp -warn -assume realloc_lhs -no-ftz -mkl -check -trace -O0 -p -g -DDEBUG -debug all
# MY_FORTRAN ?= ifort -fpp -warn -assume realloc_lhs -no-ftz -mkl -lpthread -openmp -ip -ipo -parallel -O3 -xHost
FC := $(MY_FORTRAN)

LBFGSB := Lbfgsb.3.0

FUNCTIONS := lbfgsb linpack blas timer
MODULES := optimize_lib
TESTS := optimize_lib_test

FUNCTION_OS := $(addsuffix .o,$(FUNCTIONS))
MODULE_OS := $(addsuffix .o,$(MODULES))
MODULE_MODS := $(addsuffix .mod,$(MODULES))
TEST_EXES := $(addsuffix .exe,$(TESTS))
TEST_DONES := $(addsuffix .done,$(TESTS))

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
optimize_lib_test.exe:  $(FUNCTION_OS) $(MODULE_OS) optimize_lib_test.F90 | $(MODULE_MODS)
	$(FC) -o $@ $^

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
	$(FC) -o $@ -c $<

%.o: %.f
	$(FC) -o $@ -c $<

%.f: dep/$(LBFGSB)/%.f
	cp -f $< $@

dep/$(LBFGSB)/%.f: | dep/$(LBFGSB)
	@
