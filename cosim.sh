#!/bin/bash

# Wrap the CIRCT HW dialect with the CIRCT ESI dialect and services.
export PYTHONPATH=/workspace/circt/build/tools/circt/python_packages/pycde:/workspace/circt/build/tools/circt/python_packages/circt_core

python wrap-esi.py

# Compile the design and cosim DPI library into a simulator with Verilator.
verilator \
  --cc --top-module Top -sv --build --exe --assert --trace -DTRACE -DINIT_RANDOM_PROLOG_='' \
  /workspace/circt/include/circt/Dialect/ESI/cosim/Cosim_DpiPkg.sv \
  /workspace/circt/include/circt/Dialect/ESI/cosim/Cosim_Endpoint.sv \
  /workspace/circt/include/circt/Dialect/ESI/ESIPrimitives.sv \
  /workspace/circt/build/lib/libEsiCosimDpiServer.so \
  verilator-driver.cpp \
  PyCDESystem/*.sv

# Run the simulator in a separate process.
rm cosim.cfg
./obj_dir/VTop &

# Run a Python script to connect to the simulator and wait for input.
python -i -m cosim

# Clean up the simulator process.
kill $!
