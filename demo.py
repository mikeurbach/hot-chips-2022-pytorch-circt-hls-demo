################################################################################
### Define a simple dot-product Torch module.
################################################################################

import torch


class DotModule(torch.nn.Module):
    def forward(self, a, b):
        return torch.matmul(a, b)


################################################################################
### Compile the Torch module to the MLIR Linalg dialect with Torch-MLIR.
################################################################################

import torch_mlir

shape = torch_mlir.TensorPlaceholder([5], torch.int32)

module = torch_mlir.compile(
    DotModule(), [shape, shape], output_type="linalg-on-tensors"
)

print("################################################################################")
print("### Linalg dialect")
print("################################################################################")
print(module)
