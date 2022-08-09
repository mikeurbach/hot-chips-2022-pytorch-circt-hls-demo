# Using

## Load the Docker image

```sh
docker load --input hotchips-2022-pytorch-circt-hls-demo.tar.gz
```

## Run the Docker image

```sh
docker run hotchips-2022-pytorch-circt-hls-demo:latest
```

# Developing

## Initialize or Update the CIRCT git repository

```sh
git submodule update --init --recursive
```

## Build a Docker imag with Python, Torch, Torch-MLIR, MLIR, and CIRCT installed

```sh
docker build -t hotchips-2022-pytorch-circt-hls-demo:latest .
```

## Save the Docker image

```sh
docker save hotchips-2022-pytorch-circt-hls-demo:latest | gzip > hotchips-2022-pytorch-circt-hls-demo.tar.gz
```
