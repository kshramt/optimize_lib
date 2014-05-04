# Constants
MY_FORTRAN ?= gfortran -ffree-line-length-none -fmax-identifier-length=63 -pipe -cpp -C -Wall -fbounds-check -O0 -fbacktrace -ggdb -pg -DDEBUG -Wrealloc-lhs-all
# MY_FORTRAN ?= gfortran -ffree-line-length-none -fmax-identifier-length=63 -pipe -cpp -C -Wall -O3 -march=native -flto -fwhole-program -ftree-parallelize-loops=2 -fopenmp
# MY_FORTRAN ?= -fpp -warn -assume realloc_lhs -no-ftz -mkl -check -trace -O0 -p -g -DDEBUG -debug all
# MY_FORTRAN ?= ifort -fpp -warn -assume realloc_lhs -no-ftz -mkl -lpthread -openmp -ip -ipo -parallel -O3 -xHost
FC = $(MY_FORTRAN)
FFLAGS = -Jsrc

# Configurations
.SUFFIXES:
.DELETE_ON_ERROR:
.ONESHELL:
.SECONDARY:
.PRECIOUS:
export SHELL := /bin/bash
export SHELLOPTS := pipefail:errexit:nounset:noclobber

# Tasks
.PHONY: default
default:

# Files

# Rules
src/%.o: src/%.F90
	$(FC) $(FFLAGS) -o $@ -c $<

src/%.o: src/%.f
	$(FC) $(FFLAGS) -o $@ -c $<
