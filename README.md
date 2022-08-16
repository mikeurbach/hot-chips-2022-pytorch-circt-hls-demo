# Build the Docker image used for running PyTorch and Verilator.

```sh
docker build --platform linux/amd64 -t hotchips-2022-pytorch-circt-hls-demo:latest .
```

# Run the demo script.

```sh
docker save hotchips-2022-pytorch-circt-hls-demo:latest | gzip > hotchips-2022-pytorch-circt-hls-demo.tar.gz
```
