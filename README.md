
## NB-LDPC ECC For Processing-in-Memory

## Introduction

Non-Binary LDPC error correcting code (NBLDPC ECC) is a novel arithmetic coding method for Processing-in-Memory (PIM).
It aims at correcting Multi-Bit and Multi-Level errors that possibly occur in the computing results of the PIM paradigm without interruption of the computing dataflow.
This project features:

➡️ An efficient and reliable error correcting method for PIM technology. 
The NB-LDPC long-code-word ECC scheme is capable of correcting arbitrarily multiple bit errors (depending on the iterative loops) without interrupting PIM computing.
NB-LDPC Python algorithm implementation can be found in ``./NBLDPC_Software``.

➡️ Full hardware implementation of NB-LDPC ECC algorithm. We tape out an RRAM-based PIM prototype chip monolithically integrated with the proposed NB-LDPC ECC algorithm. 
NB-LDPC decoder Verilog HDL implementation can be found in ``./NBLDPC_Verilog``.

➡️ Code for Design Space Exploration can be found in the file ``DesignExp.py``.

## Quickstart

The coding method can be found in ``./NBLDPC_Software``.
You can launch ``./NBLDPC_Software/NBLDPC_TEST_CN&VN.py`` to evaluate the NB-LDPC ECC method.

```bash
python ./NBLDPC_Software/NBLDPC_TEST_CN&VN.py
```
The default information codelength, code rate and variable degree is 512, 0.88 and 2, respectively.
If you want to change the matrices setup, change the variable InfoLength and CodeRate in the main function.
It should be noticed that when these variables are changed, corresponding parity and generative matrices also need to be produced.

If you are interested in hardware implementation, you can find the Verilog code under ``./NBLDPC_Verilog``.
You may use the testbench under ``./NBLDPC_Verilog/testbench`` for a quick start.

```bash
iverilog -o ./ECC_TOP_TB.o ./NBLDPC_Verilog/ECC_TOP_TB.v
./ECC_TOP_TB.o
```
The wave file will be generated under ``./NBLDPC_Verilog``

If you want to reproduce the Design Space Exploration results, you may use the DesignExp.py
```bash
python ./NBLDPC_Software/NBLDPC_TEST_CN&VN.py
```
The default generated figure corresponding to the Fig.6(a)(b)(c)(d)(i)

## Citation

This work is not published yet.
