# # $File$
# 
# Summary: Makefile for all components of flt, including tests
# Standard: Fortran 90, ELF90 subset
# Preprocessor: none
# Author: Ben Trettel (<http://trettel.us/>)
# Last updated: $Date$
# Revision: $Revision$
# Project: [flt](https://github.com/btrettel/flt)
# License: [GPLv3](https://www.gnu.org/licenses/gpl-3.0.en.html)

# TODO: Add code coverage.
# TODO: Add linters before compilation. Lint each file before compiling it.
# TODO: Valgrind to detect uninitialized variables. https://stackoverflow.com/a/52455413
# TODO: Check other Makefiles to see which flags you use there.

.POSIX:

# non-POSIX
# <https://innolitics.com/articles/make-delete-on-error/>
.DELETE_ON_ERROR:
MAKEFLAGS = --warn-undefined-variables

#############
# Compilers #
#############

# gfortran

FC        = gfortran
FFLAGS    = -Wall -Wextra -Werror -pedantic-errors -std=f95 -Wconversion -Wconversion-extra -fimplicit-none -fmax-errors=1 -fno-unsafe-math-optimizations -finit-real=snan -finit-integer=-2147483647 -finit-logical=true -finit-derived -Wimplicit-interface -Wunused -ffree-line-length-132
DBGFLAGS  = -Og -g -fcheck=all -fbacktrace -ffpe-trap=invalid,zero,overflow,underflow,denormal
# --coverage
# -fsanitize=leak doesn't work on trident for some reason. It does work on bison.
BINEXT    = 
RUN       = ./
RM        = rm -rfv
OFLAG     = -o 
OBJEXT    = o
OBJFLAGS  = -c -o 
DBGOBJEXT = -dbg.$(OBJEXT)

ELF90RM  = *.exe *.lib *.map *.mod modtable.txt test/*.obj
SUNF95RM = *.dbg

FAILDBGOBJ = src/fail$(DBGOBJEXT)

###############
# Boilerplate #
###############

.PHONY: all
all:
	$(MAKE) test
	$(MAKE) clean
	$(MAKE) elf90
	$(MAKE) clean
	$(MAKE) ifort
	$(MAKE) clean
	$(MAKE) ifx
	$(MAKE) clean
	$(MAKE) sunf95
	$(MAKE) clean
	$(MAKE) flang-7
	$(MAKE) clean
	@echo "***************************************"
	@echo "* All tests passed for all compilers. *"
	@echo "***************************************"

.SUFFIXES:
.SUFFIXES: .f90 .$(OBJEXT) $(DBGOBJEXT)

.PHONY: clean
clean:
	$(RM) *.jsonl *.mod test_* src/*.$(OBJEXT) src/*$(DBGOBJEXT) $(ELF90RM) $(SUNF95RM)

.f90$(DBGOBJEXT):
	$(FC) $(OBJFLAGS)$@ $(FFLAGS) $(DBGFLAGS) $<

.PHONY: test
test: asserts.jsonl dimmod.jsonl ga.jsonl logging.jsonl prec.jsonl unittest.jsonl
	@echo "*********************"
	@echo "* All tests passed. *"
	@echo "*********************"
	@echo "Compiler: $(FC)"

###################
# Other compilers #
###################

.PHONY: elf90
elf90:
	$(MAKE) test FC='wine elf90' FFLAGS='-npause -fullwarn -winconsole' DBGFLAGS='' BINEXT='.exe' RUN='wine ' OFLAG='-out ' OBJEXT='lib' OBJFLAGS='' DBGOBJEXT='.lib' FAILDBGOBJ='src/fail_elf.lib'

# `-init=snan,arrays` leads to false positives. Probably of no consequence as ifort is being retired. There is no problem with ifx.
.PHONY: ifort
ifort:
	$(MAKE) test FC=ifort FFLAGS='-warn errors -warn all -diag-error=remark,warn,error -fltconsistency -stand f90 -diag-error-limit=1' DBGFLAGS='-O0 -g -traceback -debug full -check all -fpe0'

.PHONY: ifx
ifx:
	$(MAKE) test FC=ifx FFLAGS='-warn errors -warn all -diag-error=remark,warn,error -fltconsistency -stand:f90 -diag-error-limit=1 -init=snan,arrays' DBGFLAGS='-O0 -g -traceback -debug full -check all -fpe0'

# The ability of this compiler to use case-sensitive variable names is unique.
.PHONY: sunf95
sunf95:
	$(MAKE) test FC=sunf95 FFLAGS='-w4 -errwarn=%all -e -stackvar -ansi -C -U' DBGFLAGS='-g -fpover -xcheck=%all -fnonstd'

.PHONY: flang-7
flang-7:
	$(MAKE) test FC=flang-7 FFLAGS='-Wdeprecated' DBGFLAGS='-g'

################
# Dependencies #
################

src/checks$(DBGOBJEXT): src/logging$(DBGOBJEXT) src/prec$(DBGOBJEXT)

src/dimmod$(DBGOBJEXT): src/prec$(DBGOBJEXT)

src/fail$(DBGOBJEXT):

src/logging$(DBGOBJEXT): src/prec$(DBGOBJEXT)

src/prec$(DBGOBJEXT):

src/unittest$(DBGOBJEXT): src/checks$(DBGOBJEXT) $(FAILDBGOBJ) src/logging$(DBGOBJEXT) src/prec$(DBGOBJEXT)

##########
# checks #
##########

TEST_CHECKS_DEPS = src/checks$(DBGOBJEXT) $(FAILDBGOBJ) src/prec$(DBGOBJEXT) src/logging$(DBGOBJEXT) src/unittest$(DBGOBJEXT) test/test_checks.f90

test_checks$(BINEXT): $(TEST_CHECKS_DEPS)
	$(FC) $(OFLAG)test_checks$(BINEXT) $(FFLAGS) $(DBGFLAGS) $(TEST_CHECKS_DEPS)

asserts.jsonl: test_checks$(BINEXT)
	$(RUN)test_checks$(BINEXT)
	python3 test/passed.py $@
	python3 test/test_checks.py
	test ! -e fort.*

############
# dimcheck #
############

TEST_DIMMOD_DEPS = src/checks$(DBGOBJEXT) src/dimmod$(DBGOBJEXT) $(FAILDBGOBJ) src/prec$(DBGOBJEXT) src/logging$(DBGOBJEXT) src/unittest$(DBGOBJEXT) test/test_dimmod.f90

test_dimmod$(BINEXT): $(TEST_DIMMOD_DEPS)
	$(FC) $(OFLAG)test_dimmod$(BINEXT) $(FFLAGS) $(DBGFLAGS) $(TEST_DIMMOD_DEPS)

dimmod.jsonl: test_dimmod$(BINEXT)
	$(RUN)test_dimmod$(BINEXT)
	python3 test/passed.py $@
	test ! -e fort.*

######
# ga #
######

TEST_GA_DEPS = src/checks$(DBGOBJEXT) $(FAILDBGOBJ) src/ga$(DBGOBJEXT) src/prec$(DBGOBJEXT) src/logging$(DBGOBJEXT) src/unittest$(DBGOBJEXT) test/test_ga.f90

test_ga$(BINEXT): $(TEST_GA_DEPS)
	$(FC) $(OFLAG)test_ga$(BINEXT) $(FFLAGS) $(DBGFLAGS) $(TEST_GA_DEPS)

ga.jsonl: test_ga$(BINEXT)
	$(RUN)test_ga$(BINEXT)
	python3 test/passed.py $@
	test ! -e fort.*

###########
# logging #
###########

TEST_LOGGING_DEPS = src/checks$(DBGOBJEXT) $(FAILDBGOBJ) src/dimmod$(DBGOBJEXT) src/prec$(DBGOBJEXT) src/logging$(DBGOBJEXT) src/unittest$(DBGOBJEXT) test/test_logging.f90

test_logging$(BINEXT): $(TEST_LOGGING_DEPS)
	$(FC) $(OFLAG)test_logging$(BINEXT) $(FFLAGS) $(DBGFLAGS) $(TEST_LOGGING_DEPS)

logging.jsonl: test_logging$(BINEXT)
	-$(RUN)test_logging$(BINEXT)
	python3 test/passed.py $@
	python3 test/test_logging.py
	test ! -e fort.*

########
# prec #
########

TEST_PREC_DEPS = src/checks$(DBGOBJEXT) $(FAILDBGOBJ) src/dimmod$(DBGOBJEXT) src/prec$(DBGOBJEXT) src/logging$(DBGOBJEXT) src/unittest$(DBGOBJEXT) test/test_prec.f90

test_prec$(BINEXT): $(TEST_PREC_DEPS)
	$(FC) $(OFLAG)test_prec$(BINEXT) $(FFLAGS) $(DBGFLAGS) $(TEST_PREC_DEPS)

prec.jsonl: test_prec$(BINEXT)
	-$(RUN)test_prec$(BINEXT)
	python3 test/passed.py $@
	test ! -e fort.*
	test ! -e fort.*

############
# unittest #
############

TEST_unittest_DEPS = src/checks$(DBGOBJEXT) $(FAILDBGOBJ) src/prec$(DBGOBJEXT) src/logging$(DBGOBJEXT) src/unittest$(DBGOBJEXT) test/test_unittest.f90

test_unittest$(BINEXT): $(TEST_unittest_DEPS)
	$(FC) $(OFLAG)test_unittest$(BINEXT) $(FFLAGS) $(DBGFLAGS) $(TEST_unittest_DEPS)

unittest.jsonl: test_unittest$(BINEXT)
	$(RUN)test_unittest$(BINEXT)
	python3 test/passed.py $@
	python3 test/test_unittest.py
	test ! -e fort.*
