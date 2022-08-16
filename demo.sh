#!/bin/bash

# Show Torch dot product module.

echo "################################################################################"
echo "### Torch module"
echo "################################################################################"
echo
cat dot.py
echo

# Compile Torch dot product module into MLIR Linalg dialect.

docker run -it --platform linux/amd64 -v $PWD:/workspace \
  hotchips-2022-pytorch-circt-hls-demo:latest \
  python /workspace/compile-pytorch.py > dot-linalg.mlir

echo "################################################################################"
echo "### Linalg dialect"
echo "################################################################################"
echo
cat dot-linalg.mlir

# Compile MLIR Linalg dialect to MLIR Affine dialect with some custom transforms.

$HOME/circt/build/bin/mlir-opt dot-linalg.mlir \
  -one-shot-bufferize='allow-return-allocs bufferize-function-boundaries' \
  -convert-linalg-to-affine-loops |
$HOME/circt-hls/Polygeist/build/bin/polygeist-opt \
  -detect-reduction |
$HOME/circt/build/bin/mlir-opt \
  -affine-scalrep |
$HOME/circt-hls/build/bin/hls-opt \
  -affine-scalrep > dot-affine.mlir

echo "################################################################################"
echo "### Affine dialect"
echo "################################################################################"
echo
cat dot-affine.mlir

# Compile MLIR Affine dialect to MLIR ControlFlow dialect.

$HOME/circt/build/bin/mlir-opt dot-affine.mlir \
  -lower-affine \
  -convert-scf-to-cf > dot-cf.mlir			   

echo "################################################################################"
echo "### ControlFlow dialect"
echo "################################################################################"
echo
cat dot-cf.mlir

# Compile MLIR ControlFlow dialect to CIRCT Handshake dialect.

$HOME/circt/build/bin/circt-opt dot-cf.mlir \
  -lower-std-to-handshake \
  -canonicalize > dot-handshake.mlir

echo "################################################################################"
echo "### Handshake dialect"
echo "################################################################################"
echo
cat dot-handshake.mlir

# Compile CIRCT Handshake dialect to CIRCT HW dialect via FIRRTL.
$HOME/circt/build/bin/circt-opt dot-handshake.mlir \
  -handshake-materialize-forks-sinks \
  -canonicalize \
  -handshake-insert-buffers=strategy=all \
  -lower-handshake-to-firrtl |
$HOME/circt/build/bin/firtool \
  -format=mlir \
  -ir-hw > dot-hw.mlir

# Wrap the design with ESI services, then compile and run co-simulation with Verilator and Python.

docker run -it --platform linux/amd64 --entrypoint bash -v $PWD:/app \
  hotchips-2022-pytorch-circt-hls-demo:latest \
  /app/cosim.sh
