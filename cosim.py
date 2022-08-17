import numpy as np

from esi_cosim import HandshakeCosimBase, get_cosim_port


class Cosim(HandshakeCosimBase):

  def run(self, a, b):
    self.memories[0] = a
    self.memories[1] = b
    self.go()
    return self.read_result()

  def run_checked(self, a, b):
    print(f"Computing dot product of {a} and {b}")
    result = self.run(a, b)
    dot = np.dot(np.array(a), np.array(b))
    print(f"from cosim: {result}, from numpy: {dot}")


def rand_vec():
  return [np.random.randint(0, 100) for _ in range(5)]


cosim = Cosim(get_cosim_port())

cosim.run_checked(rand_vec(), rand_vec())
