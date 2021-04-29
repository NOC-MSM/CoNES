# HPC_Scaling_AMM7
Processor Scaling on HPC for the AMM7 configuration. Ensemble experiments should be over a model year? 

## Decompostion

| ni x nj | nproc | jpi x jpj |
|:-------:|------:|:---------:|
|  5x6    |   25  | 61x65     |
|  7x8    |   47  | 45x49     |
| 11x11   |   95  | 29x36     |
| 14x16   |  184  | 22x26     |
| 22x23   |  370  | 16x19     |

## XIOS

- Using 1 node: 1, 2 servers
- Using 2 nodes: 1 server per node
- Possibly Attached/Detached mode?

## I/O

- single and multi file
- heavy (1h, 1d, 1mo), medium (1d, 1mo) and light (1mo) output

## Analysis 

To be reported as:
See analysis directory

## Platforms

Currently set up for:

- [x] ~~ARCHER~~
- [x] CIRRUS
- [ ] _offspring_ of MOBILIS
- [x] ARCHER2

## Quick Start

```
git clone git@github.com:NOC-MSM/HPC_Scaling_AMM7.git
HPC_Scaling_AMM7/scripts/setup/amm7_setup_archer2 -w $PWD/test -x $PWD/test \
                                                  -s $PWD/HPC_Scaling_AMM7 \
                                                  -m archer2 -v 4.0.4 -c gnu
```

The job submissions can be daisy-chained by uncommenting the `sbatch` command at the end of the runscripts. The `namelist_cfg_template` is currently set up to run 288 timesteps (1day). For true testing this should be extended.

NB. Only tested with NEMO 4.0.4, and archer2 [with gnu and cray compilers]




