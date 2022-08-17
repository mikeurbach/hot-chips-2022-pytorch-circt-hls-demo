#!/bin/bash

# Show Torch dot product module.

echo "################################################################################"
echo "### Torch module"
echo "################################################################################"
echo
cat dot.py
echo

# Compile Torch dot product module into MLIR Linalg dialect.

echo "################################################################################"
echo "### Linalg dialect"
echo "################################################################################"
echo
cat dot-linalg.mlir

# Compile MLIR Linalg dialect to MLIR Affine dialect with some custom transforms.

$HOME/alloy/build/bin/mlir-opt dot-linalg.mlir \
  -one-shot-bufferize='allow-return-allocs bufferize-function-boundaries' \
  -convert-linalg-to-affine-loops |
$HOME/circt-hls/Polygeist/build/bin/polygeist-opt \
  -detect-reduction |
$HOME/alloy/build/bin/mlir-opt \
  -affine-scalrep |
$HOME/circt-hls/build/bin/hls-opt \
  -affine-scalrep > dot-affine.mlir

echo "################################################################################"
echo "### Affine dialect"
echo "################################################################################"
echo
cat dot-affine.mlir

# Compile MLIR Affine dialect to MLIR ControlFlow dialect.

$HOME/alloy/build/bin/mlir-opt dot-affine.mlir \
  -lower-affine \
  -convert-scf-to-cf > dot-cf.mlir			   

echo "################################################################################"
echo "### ControlFlow dialect"
echo "################################################################################"
echo
cat dot-cf.mlir

# Compile MLIR ControlFlow dialect to CIRCT Handshake dialect.

$HOME/alloy/build/bin/circt-opt dot-cf.mlir \
  -lower-std-to-handshake \
  -canonicalize > dot-handshake.mlir

echo "################################################################################"
echo "### Handshake dialect"
echo "################################################################################"
echo
cat dot-handshake.mlir

# Compile CIRCT Handshake dialect to CIRCT HW dialect via FIRRTL.
$HOME/alloy/build/bin/circt-opt dot-handshake.mlir \
  -handshake-materialize-forks-sinks \
  -canonicalize \
  -handshake-insert-buffers=strategy=all \
  -lower-handshake-to-firrtl |
$HOME/alloy/build/bin/firtool \
  -format=mlir \
  -ir-hw > dot-hw.mlir

# Wrap the CIRCT HW dialect with the CIRCT ESI dialect and services.
export PYTHONPATH=$HOME/alloy/build/tools/circt/python_packages/pycde:$HOME/alloy/build/tools/circt/python_packages/circt_core

python wrap-esi.py

# Compile the design and cosim DPI library into a simulator with Verilator.
$HOME/alloy/external/circt/ext/bin/verilator \
  --cc --top-module Top -sv --build --exe --assert --trace -DTRACE -DINIT_RANDOM_PROLOG_='' \
  $HOME/alloy/external/circt/include/circt/Dialect/ESI/cosim/Cosim_DpiPkg.sv \
  $HOME/alloy/external/circt/include/circt/Dialect/ESI/cosim/Cosim_Endpoint.sv \
  $HOME/alloy/external/circt/include/circt/Dialect/ESI/ESIPrimitives.sv \
  $HOME/alloy/build/lib/libEsiCosimDpiServer.so \
  verilator-driver.cpp \
  PyCDESystem/*.sv

# Run the simulator in a separate process.
rm -f cosim.cfg
LD_LIBRARY_PATH=$HOME/alloy/build/lib ./obj_dir/VTop &

# Run a Python script to connect to the simulator and wait for input.
python -i -m cosim

# Clean up the simulator process.
kill $!
