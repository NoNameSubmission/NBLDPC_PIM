
## NB LDPC ECC For Processing-in-Memory

## Introduction

Non-Binary LDPC error correcting code (NBLDPC ECC) is a novel arithmetic coding method for Processing-in-Memory (PIM).
It is capable of correcting Multi-Bit and Multi-Level errors that possibly occur in the computing results of the PIM paradigm without interruption of the computing dataflow.
This project features:

➡️ Efficient and reliable error correcting for PIM technology.

➡️ Full hardware implementation of NBLDPC ECC algorithm.


## Quickstart

The coding method can be found in ``./NBLDPC_Software``


```bash
pip install pytorch
```

If you are interested in hardware implementation, you can find the Verilog code under ``./NBLDPC_Verilog``.
For hardware explorers, you may use the testbench in ``./NBLDPC_Verilog/testbench``.
A quick 

```bash
iverilog -o ./ECC_TOP_TB.o ./NBLDPC_Verilog/ECC_TOP_TB.v
./ECC_TOP_TB.o
```

## Citation

This work is not published yet.
