#!/bin/bash
#SBATCH --job-name=2Xg_25N
#SBATCH --time=00:20:00
#SBATCH --account=n01
#SBATCH --partition=standard
#SBATCH --qos=short
#SBATCH --reservation=shortqos

#SBATCH --partition=standard
#SBATCH --nodes=1
#SBATCH --ntasks=27
#SBATCH --ntasks-per-node=27
#SBATCH --ntasks-per-core=1

# Created by: mkslurm_hetjob -S 2 -s 16 -m 2 -C 25 -g 2 -N 128 -t 00:10:00 -a n01 -j nemo_test -v False
module -s restore /work/ecseab13/ecseab13/jhcones/cfgs/HPC_Scaling_AMM7/scripts/env/ucx_env_archer2_cray
export OMP_NUM_THREADS=1

cat > myscript_wrapper.sh << EOFB
#!/bin/ksh
#
set -A map ./xios_server.exe ./nemo
exec_map=( 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 )
#
exec \${map[\${exec_map[\$SLURM_PROCID]}]}
##
EOFB
chmod u+x ./myscript_wrapper.sh

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
sed "s/XXX_JPNI_XXX/5/g" namelist_cfg_template > tmp_out
sed "s/XXX_JPNJ_XXX/6/g"               tmp_out > namelist_cfg

rm file_def_nemo-oce.xml
ln -s file_def_nemo-oce-M.xml file_def_nemo-oce.xml

srun --mem-bind=local \
 --cpu-bind=v,mask_cpu:0x1,0x10000,0x100000000,0x400000000,0x1000000000,0x4000000000,0x10000000000,0x40000000000,0x100000000000,0x400000000000,0x1000000000000,0x4000000000000,0x10000000000000,0x40000000000000,0x100000000000000,0x400000000000000,0x1000000000000000,0x4000000000000000,0x10000000000000000,0x40000000000000000,0x100000000000000000,0x400000000000000000,0x1000000000000000000,0x4000000000000000000,0x10000000000000000000,0x40000000000000000000,0x100000000000000000000 ./myscript_wrapper.sh

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

# sbatch runscript_2Xg_47N.slurm
