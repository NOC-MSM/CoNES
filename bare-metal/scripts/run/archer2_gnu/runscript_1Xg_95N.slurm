#!/bin/bash
#SBATCH --job-name=1Xg_95N
#SBATCH --time=00:20:00
#SBATCH --account=ecseab13
#SBATCH --partition=standard
#SBATCH --qos=short
#SBATCH --reservation=shortqos

#SBATCH --partition=standard
#SBATCH --nodes=2
#SBATCH --ntasks=128
#SBATCH --ntasks-per-core=1

module -s restore /work/ecseab13/ecseab13/jhcones/cfgs/HPC_Scaling_AMM7/scripts/env/ucx_env_archer2_gnu
export LD_LIBRARY_PATH=/work/ecseab13/shared/install/lib:${LD_LIBRARY_PATH}
export LD_LIBRARY_PATH=/opt/cray/pe/libsci/20.10.1.2/GNU/9.1/x86_64/lib:${LD_LIBRARY_PATH}
export OMP_NUM_THREADS=1

#===============================================================
# LAUNCH JOB
#===============================================================
#    5x6        25      61x65
#    7x8        47      45x49
#  11x11        95      29x36
#  14x16        184     22x26
#  22x23        370     16x19
#===============================================================
echo `date` : Launch Job
numactl --hardware

sed "s/XXX_JPNI_XXX/11/g" namelist_cfg_template > tmp_out
sed "s/XXX_JPNJ_XXX/11/g"               tmp_out > namelist_cfg

rm file_def_nemo-oce.xml
ln -s file_def_nemo-oce-M.xml file_def_nemo-oce.xml 

srun hostname -s > hostfile
./build_rankfile -S 1 -s 16 -m 1 -C 95 -c 8 -H 2 -v > rankfile

mpirun --oversubscribe  -rf rankfile --report-bindings -v  -np 1 --bind-to core ./xios_server.exe : -np 95 --bind-to core ./nemo

# Tidy up

if [ ! -d TIMINGS ]; then
  mkdir TIMINGS
fi
mv timing.output TIMINGS/timing.output.$SLURM_JOB_NAME
mv ocean.output meta_out/ocean.output.$SLURM_JOB_NAME
if [ ! -d meta_out/"$SLURM_JOB_NAME" ]; then
  mkdir meta_out/$SLURM_JOB_NAME
fi
mv slurm-* meta_out/$SLURM_JOB_NAME
if [ ! -d RESTARTS/"$SLURM_JOB_NAME" ]; then
  mkdir RESTARTS/$SLURM_JOB_NAME
fi
mv *restart* RESTARTS/$SLURM_JOB_NAME
if [ ! -d OUTPUTS/"$SLURM_JOB_NAME" ]; then
  mkdir OUTPUTS/$SLURM_JOB_NAME
fi
mv *_grid_* OUTPUTS/$SLURM_JOB_NAME

# Daisy-chain?

# sbatch runscript_2Xg_184N.slurm
