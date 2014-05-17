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
   FFLAGS := -fpp -warn -assume realloc_lhs -no-ftz -check nouninit -module src -mkl
   FFLAGS += -trace -O0 -p -g -DDEBUG -debug all
   # FFLAGS += -lpthread -openmp -ip -ipo -parallel -O3 -xHost
else
   FFLAGS := -ffree-line-length-none -fmax-identifier-length=63 -pipe -Wall -Wrealloc-lhs-all -Jsrc -lblas -llapack
   FFLAGS += -fbounds-check -O0 -fbacktrace -ggdb -pg -DDEBUG
   # FFLAGS += -O3 -march=native -flto -fwhole-program -ftree-parallelize-loops=$(shell nproc) -fopenmp
endif

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

LBFGSB_FS := $(LBFGSBS:%=src/%.f)
LBFGSB_OS := $(LBFGSBS:%=src/%.o)
MODULE_OS := $(MODULES:%=src/%.o)
MODULE_MODS := $(MODULES:%=src/%.mod)
TEST_EXES := $(TESTS:%=test/%.exe)
TEST_DONES := $(TESTS:%=test/%_$(TEST_PARAMS).done)

# Tasks
.PHONY: all test clean
all:

test: $(TEST_DONES)

clean:
	rm -f $(TEST_EXES) $(LBFGSB_FS) $(LBFGSB_OS) $(MODULE_OS) $(MODULE_MODS)

# Files
test/optimize_lib_test.exe: $(LBFGSB_OS) $(MODULE_OS) src/optimize_lib_test.F90 | $(MODULE_MODS)
	mkdir -p $(@D)
	$(FC) $(FFLAGS) -o $@ $^

test/optimize_lib_test_$(TEST_PARAMS).done: test/optimize_lib_test.exe $(RAND_NORMAL_DAT)
	{
	   echo $(N_ROW) $(N_COL)
	   cat $(RAND_NORMAL_DAT)
	} | $(<D)/$(<F) >| $@ 2>| $@.error

$(RAND_NORMAL_DAT): $(addprefix script/,rand.sh to_normal.sh dawk.sh)
	mkdir -p $(@D)
	set +o pipefail # `head` -> `SIGPIPE`
	script/rand.sh $(SEED) | script/to_normal.sh | head -n"$$(($(N_ROW)*$(N_COL)))" >| $@

$(LBFGSB_FS): src/%: dep/$(LBFGSB)/%
	mkdir -p $(@D)
	cp -f $< $@

$(SCRIPTS): script/%: dep/bin/%
	mkdir -p $(@D)
	cp -f $< $@

# Rules
%.o %.mod: %.F90
	mkdir -p $(@D)
	$(FC) $(FFLAGS) -o $(@:%.mod=%.o) -c $<

%.o: %.f
	mkdir -p $(@D)
	$(FC) $(FFLAGS) -o $@ -c $<

define DEPS_RULE_TEMPLATE =
dep/$(1)/%: | dep/$(1).timestamp ;
endef
$(foreach f,$(DEPS),$(eval $(call DEPS_RULE_TEMPLATE,$(f))))

dep/%.timestamp: dep/%.ref dep/%.remote
	cd $(@D)/$*
	git fetch origin
	git merge "$$(cat ../$(<F))"
	cd -
	touch $@

dep/%.remote: dep/%.uri | dep/%
	cd $(@D)/$*
	git remote rm origin
	git remote add origin "$$(cat ../$(<F))"
	cd -
	touch $@

$(DEPS:%=dep/%): dep/%:
	git init $@
	cd $@
	git remote add origin "$$(cat ../$*.uri)"
