FROM python:3.9-bullseye

WORKDIR /workspace

################################################################################
### Install Torch and Torch-MLIR packages.
################################################################################

RUN pip install https://github.com/llvm/torch-mlir/releases/download/snapshot-20220809.559/torch-1.13.0.dev20220809+cpu-cp39-cp39-linux_x86_64.whl

RUN pip install https://github.com/llvm/torch-mlir/releases/download/snapshot-20220809.559/torch_mlir-20220809.559-cp39-cp39-linux_x86_64.whl

################################################################################
### Install LLVM build tools.
################################################################################

RUN apt-get update && \
    apt-get install -y ninja-build

RUN wget https://github.com/Kitware/CMake/releases/download/v3.23.2/cmake-3.23.2-linux-x86_64.sh; \
    chmod +x cmake-3.23.2-linux-x86_64.sh; \
    ./cmake-3.23.2-linux-x86_64.sh --skip-license --prefix=/usr

RUN pip install pybind11

################################################################################
### Build MLIR and CIRCT.
################################################################################

ADD circt circt

RUN cd circt && \
    mkdir build && \
    cmake -B build -G Ninja llvm/llvm \
      -DCMAKE_BUILD_TYPE=Release \
      -DLLVM_ENABLE_PROJECTS=mlir \
      -DLLVM_ENABLE_ASSERTIONS=ON \
      -DLLVM_EXTERNAL_PROJECTS=circt \
      -DLLVM_EXTERNAL_CIRCT_SOURCE_DIR=. \
      -DMLIR_ENABLE_BINDINGS_PYTHON=ON \
      -DCIRCT_BINDINGS_PYTHON_ENABLED=ON \
      -DCIRCT_ENABLE_FRONTENDS=PyCDE && \
    cd -

RUN ninja -C circt/build mlir-opt circt-opt PyCDE

RUN ninja -C circt/build install-mlir-opt install-circt-opt install-PyCDE

################################################################################
### Set up the demo as the entrypoint.
################################################################################

ADD demo.py demo.py

ENTRYPOINT ["python", "demo.py"]
