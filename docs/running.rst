
Running a container
===================


Short discussion about Hybrid vs Bind and the role of MPI in running


Need to explain the following flags that go into the srun/mpirun command

.. code-block:: none

    mpirun --oversubscribe -rf rankfile --report-bindings -v -np 1 --bind-to core singularity run /work/ecseab13/ecseab13/jhcones/testing/sing/nemo.sif xios output : -np 95 --bind-to core -mca orte_base_help_aggregate 0 --mca btl_vader_single_copy_mechanim none --mca btl ^sm --mca btl_openib_allow_ib true --bind-to core singularity run -B /etc/libibverbs.d /work/ecseab13/ecseab13/jhcones/testing/sing/nemo.sif nemo output 


Need to summarise %runscript

.. code-block:: singularity

    %runscript
    #!/bin/bash

    # This runscript will take 2 arguments: program to run (NEMO or XIOS), and an output directory. By default, the output directory will be the job id (passed using $SLURM_JOB_ID).    

    # create directory so we can symlink to /nemo/nemo/cfgs/GYRE_PISCES/EXP00/
    # we should allow an output directory, and manage this in a cleanup section of the batch script, before deleting the symlinked directory there

    # Improvements:
    #   - update when we use a generic cfg directory
    #   - is using $SLURM_JOB_ID directly here best, or should we pass it as the 2nd argument to the script and use a more generic variable here?
    #   - we could make the arguments a bit more intelligent; e.g.
    #       - if only 1 argument, check whether it's nemo or xios; if neither then it's an output directory (and run nemo in attached mode)
    #       - does the output directory need to be set for both 

    if ! [[ $1 == "nemo" || $1 == "xios" ]]    
    then
      echo "The program argument should be either 'nemo' or 'xios'"
      exit 1
    fi

    results_dir=$2

    if [[ -z $2 ]]
    then
      results_dir=$SLURM_JOB_ID
    fi

    if [[ -z $results_dir ]]
    then
        echo "Please supply an output directory"
        exit 1
    fi

    if [[ ! -d $results_dir ]]
    then
        mkdir $results_dir
    fi 

    cd $results_dir

    for file in /nemo/nemo/cfgs/NEMO/EXP00/*
    do
    
        # check if the file is already symlinked to prevent lots of spurious error messages
        # but, we have to create this linkfile variable: some of the nemo files are themselves symlinks, so the 
        # if statement will fail to create a symlink for those if we just use the base path
        
        linkfile=`basename $file`

        if ! [[ -L $linkfile ]]
        then
            ln -s $file $linkfile
        fi
    done
    

    if [[ $1 == 'nemo' ]]
    then
        /opt/nemo/nemo
    else
        /opt/xios/xios
    fi

    # do some checking here to make sure the job has finished (to do), and then delete the symlinks:

    #find . -type l | while read linkname
    #do
    #    rm $linkname
    #done

