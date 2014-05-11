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

LBFGSB := Lbfgsb

LBFGSBS := lbfgsb timer
MODULES := optimize_lib
TESTS := optimize_lib_test

LBFGSB_FS := $(LBFGSBS:%=%.f)
LBFGSB_OS := $(LBFGSBS:%=%.o)
MODULE_OS := $(MODULES:%=%.o)
MODULE_MODS := $(MODULES:%=%.mod)
TEST_EXES := $(TESTS:%=%.exe)
TEST_DONES := $(TESTS:%=%.done)

# Tasks
.PHONY: all test clean
all:

test: $(TEST_DONES)

clean:
	rm -f $(TEST_EXES) $(TEST_DONES) $(LBFGSB_FS) $(LBFGSB_OS) $(MODULE_OS) $(MODULE_MODS)

# Files
optimize_lib_test.exe: $(LBFGSB_OS) $(MODULE_OS) optimize_lib_test.F90 | $(MODULE_MODS)
	$(FC) $(FFLAGS) -o $@ $^

define CP_LBFGSB_TEMPLATE =
$(1): dep/$(LBFGSB)/$(1)
	cp -f $$< $$@
endef
$(foreach f,$(LBFGSB_FS),$(eval $(call CP_LBFGSB_TEMPLATE,$(f))))

# Rules
%.done: %.exe
	$(<D)/$(<F)
	touch $@

%.o %.mod: %.F90
	$(FC) $(FFLAGS) -o $(@:%.mod=%.o) -c $<

%.o: %.f
	$(FC) $(FFLAGS) -o $@ -c $<

dep/$(LBFGSB)/%.f: .git/modules/dep/$(LBFGSB)/HEAD
	git submodule update --init --recursive

.git/modules/dep/%/HEAD:
	git submodule init
