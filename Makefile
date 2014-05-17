ROOT_DIR := $(abspath .)

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

FFLAGS := -ffree-line-length-none -fmax-identifier-length=63 -pipe -Wall -fbounds-check -O0 -fbacktrace -ggdb -pg -DDEBUG -Wrealloc-lhs-all $(LIBS)
# FFLAGS := -ffree-line-length-none -fmax-identifier-length=63 -pipe -Wall -O3 -march=native -flto -fwhole-program -ftree-parallelize-loops=$(shell nproc) -fopenmp $(LIBS)

# FFLAGS := -fpp -warn -assume realloc_lhs -no-ftz -mkl -check nouninit -trace -O0 -p -g -DDEBUG -debug all $(LIBS)
# FFLAGS := -fpp -warn -assume realloc_lhs -no-ftz -mkl -lpthread -openmp -ip -ipo -parallel -O3 -xHost $(LIBS)

LBFGSB := Lbfgsb

DEPS := Lbfgsb bin

SCRIPTS := $(addprefix script/,to_normal.sh rand.sh dawk.sh)

SEED ?= 1
N_ROW ?= 2000
N_COL ?= 1000
TEST_PARAMS := $(SEED)_$(N_ROW)_$(N_COL)
RAND_NORMAL_DAT := test/rand_normal_$(TEST_PARAMS).dat

LBFGSBS := lbfgsb timer
MODULES := optimize_lib
TESTS := optimize_lib_test

LBFGSB_FS := $(LBFGSBS:%=%.f)
LBFGSB_OS := $(LBFGSBS:%=%.o)
MODULE_OS := $(MODULES:%=%.o)
MODULE_MODS := $(MODULES:%=%.mod)
TEST_EXES := $(TESTS:%=%.exe)
TEST_DONES := $(TESTS:%=test/%_$(TEST_PARAMS).done)

# Tasks
.PHONY: all test clean deps
all: deps

deps: $(DEPS:%=dep/%.timestamp)

test: deps $(TEST_DONES)

clean:
	rm -f $(TEST_EXES) $(LBFGSB_FS) $(LBFGSB_OS) $(MODULE_OS) $(MODULE_MODS)

# Files
optimize_lib_test.exe: $(LBFGSB_OS) $(MODULE_OS) optimize_lib_test.F90 | $(MODULE_MODS)
	$(FC) $(FFLAGS) -o $@ $^

test/optimize_lib_test_$(TEST_PARAMS).done: optimize_lib_test.exe $(RAND_NORMAL_DAT)
	{
	   echo $(N_ROW) $(N_COL)
	   cat $(RAND_NORMAL_DAT)
	} | $(<D)/$(<F) >| $@ 2>| $@.error

$(RAND_NORMAL_DAT): $(addprefix script/,rand.sh to_normal.sh dawk.sh)
	mkdir -p $(@D)
	set +o pipefail # `head` -> `SIGPIPE`
	script/rand.sh $(SEED) | script/to_normal.sh | head -n"$$(($(N_ROW)*$(N_COL)))" >| $@

$(LBFGSB_FS): %: dep/$(LBFGSB)/%
	cp -f $< $@

$(SCRIPTS): script/%: dep/bin/%
	mkdir -p $(@D)
	cp -f $< $@

# Rules
%.o %.mod: %.F90
	$(FC) $(FFLAGS) -o $(@:%.mod=%.o) -c $<

%.o: %.f
	$(FC) $(FFLAGS) -o $@ -c $<

define DEPS_RULE_TEMPLATE =
dep/$(1)/%: | dep/$(1).timestamp ;
endef
$(foreach f,$(DEPS),$(eval $(call DEPS_RULE_TEMPLATE,$(f))))

dep/%.timestamp: .git/modules/dep/%/HEAD
	git submodule update --init --recursive
	touch $@

.git/modules/dep/%/HEAD:
	git submodule init
