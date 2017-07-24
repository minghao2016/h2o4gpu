# the R header dir, and the R shared library dir on your system
R_PATH := $(shell R RHOME)
R_INC := $(shell R CMD config --cppflags)
R_LIB := $(shell R CMD config --ldflags)

# replace these three lines with
# CUDA_HOME := <path to your cuda install>
ifndef CUDA_HOME
    CUDA_HOME := /usr/local/cuda
endif

ARCH := $(shell uname -m)

# replace these five lines with
# CUDA_LIB := <path to your cuda shared libraries>
ifeq ($(ARCH), i386)
    CUDA_LIB := $(CUDA_HOME)/lib64
else
    CUDA_LIB := $(CUDA_HOME)/lib64
endif

OS := $(shell uname -s)
ifeq ($(OS), Darwin)
    ifeq ($(ARCH), x86_64)
        DEVICEOPTS := -m64
    endif
    CUDA_LIB := $(CUDA_HOME)/lib64
    R_FRAMEWORK := -F$(R_PATH)/.. -framework R
    RPATH := -rpath $(CUDA_LIB)
endif

################################################################################
############################# H2OGPUML specific begin ##############################
################################################################################

#compiler/preprocessor options
HDR=-Iinclude $(R_INC) -I$(CUDA_HOME)/include

#linker options
CXXFLAGS+=$(DEVICEOPTS)  -DH2OGPUML_SINGLE=0

ifeq ($(TARGET), gpulib)

    LD_FLAGS=$(R_LIB) -L"$(CUDA_LIB)" -lcudart -lcudadevrt -lcublas -lcusparse -lcusolver
	TARGETPATH=gpu
	BUILDPATH=build/gpu/

ifeq ($(USENVTX), 1)
LD_FLAGS+=-lnvToolsExt
endif
ifeq ($(USENCCL), 1)
LD_FLAGS+=-lnccl
endif

else
    LD_FLAGS=blas2cblas.cpp $(shell R CMD config BLAS_LIBS)
	TARGETPATH=cpu
	BUILDPATH=build/cpu
endif
LD_FLAGS+=$(R_FRAMEWORK)

$(BUILDPATH)/h2ogpuml.so: $(BUILDPATH)/h2ogpuml_r.o ../R/h2ogpuml.R $(BUILDPATH)/blas2cblas.o $(BUILDPATH)/h2ogpuml_r.o
	mkdir -p $(BUILDPATH)
	$(CXX) -o $@ -shared $(BUILDPATH)/h2ogpuml_r.o ../../../$(OBJDIR)/$(TARGETPATH)/h2ogpuml.a \
	$(RPATH) $(LD_FLAGS) $(CXXFLAGS)
	ln -sf $(BUILDPATH)/h2ogpuml.so .


$(BUILDPATH)/blas2cblas.o: blas2cblas.cpp config.mk Makefile
	mkdir -p $(BUILDPATH)
	$(CXX) $(CXXFLAGS) $< -c -o $@

$(BUILDPATH)/h2ogpuml_r.o: h2ogpuml_r.cpp config.mk Makefile
	mkdir -p $(BUILDPATH)
	$(CXX) $(HDR) $(CXXFLAGS) $< -c -o $@

################################################################################
############################## H2OGPUML specific end ###############################
################################################################################