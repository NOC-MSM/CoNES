.. _quick-start:

===========
Quick Start
===========

.. _eCSE: https://www.archer2.ac.uk/ecse/
.. _`ARCHER2 HPC service`: www.archer2.ac.uk
.. _Singularity: sylabs.io
.. _`Singularity Guide`: https://sylabs.io/guides/
.. _NEMO: www.nemo-ocean.eu
.. _CoNES: https://github.com/NOC-MSM/CoNES/releases/latest

This guide is intended for running a NEMO Singularity Image File (SIF) 
on a HPC cluster or Linux machine that has Singularty installed. A summary of
how to *build* a NEMO SIF is given in the next :ref:`section <building>`. It should also 
be possible to build and run a NEMO SIF on MacOS/Windows machines. For further 
information on installing and using Singularity on different architectures 
please refer to the `Singularity Guide`_.

By way of example, an outline of how to setup, download and run a NEMO SIF using the
`ARCHER2 HPC Service`_ follows. This makes use of the pre-built NEMO SIFs released under
`CoNES`_. For this example the `NEMO AMM7 
configuration <https://github.com/NOC-MSM/HPC_Scaling_AMM7>`_ is used. 

--------------------------
Setting up the environment
--------------------------

Log in to ARCHER2 using the ``login.archer2.ac.uk`` address:

.. code-block:: sh

   ssh [userID]@login.archer2.ac.uk

.. hint::

   More information on connecting to ARCHER2 is available at:
   `Connecting to ARCHER2 <https://docs.archer2.ac.uk/user-guide/connecting/>`_.

Next, navigate to a suitable directory on ``/work`` to clone the AMM7 configuration repository 
by issuing the following:

.. code-block:: sh

   WORK_DIR=$PWD
   RUN_DIR=$WORK_DIR/singularity
   git clone git@github.com:NOC-MSM/HPC_Scaling_AMM7.git
   ./HPC_Scaling_AMM7/scripts/setup/amm7_setup_archer2 -w $RUN_DIR \
                                                       -r $WORK_DIR/HPC_Scaling_AMM7 \
                                                       -m archer2 -S -O -v 4.0.4

This will create a run directory, ``$RUN_DIR``, where the configuration files, runscripts
and nemo SIF will be installed. On ARCHER2 singularity is available by default so there is no
need to load it into the environment. However, there are several other module files required
to run a SIF. These are automatically loaded at runtime via the runscripts in the installation folder.
Within ``$RUN_DIR`` a directory called ``EXP00`` will be created. 
This serves as the mount point for the SIF to read and write data. Any NEMO input files (netcdf,
namelists etc) need to be in this directory. All output from the simulation will also be written to 
this directory.

The above example sets up an openMPI ``-O`` configuration of NEMO. ARCHER2 also has the MPICH libraries 
available which can be accessed using the following:

.. code-block:: bash

   WORK_DIR=$PWD
   RUN_DIR=$WORK_DIR/singularity
   git clone git@github.com:NOC-MSM/HPC_Scaling_AMM7.git
   ./HPC_Scaling_AMM7/scripts/setup/amm7_setup_archer2 -w $RUN_DIR \
                                                       -r $WORK_DIR/HPC_Scaling_AMM7 \
                                                       -m archer2 -S -v 4.0.4

For a full set of options available in the ``amm7_setup_archer2`` issue the command:

.. code-block:: bash

   ./HPC_Scaling_AMM7/scripts/setup/amm7_setup_archer2 -h

Or visit the `HPC_Scaling_AMM7 GitHub repository <https://github.com:NOC-MSM/HPC_Scaling_AMM7>`_.


-----------------------------
Download a pre-built NEMO SIF
-----------------------------

If you are not running on the ARCHER2 HPC service you can either clone the 
`NEMO AMM7 configuration setup <https://github.com/NOC-MSM/HPC_Scaling_AMM7>`_
and adapt the setup script or directly download the pre-built NEMO SIF. There 
are several ways in which to achive this:

For the openMPI build

.. code-block:: bash

    wget -c https://github.com/NOC-MSM/CoNES/releases/download/0.0.1/NOC-MSM-CoNES.nemo-ompi.sif -o nemo.sif

For the MPICH build

.. code-block:: bash

    wget -c https://github.com/NOC-MSM/CoNES/releases/download/0.0.1/NOC-MSM-CoNES.nemo-mpich.sif -o nemo.sif

Singularity can also *pull* just knowing the URL. For example:

.. code-block:: bash

    singularity pull https://github.com/NOC-MSM/CoNES/releases/download/0.0.1/NOC-MSM-CoNES.nemo.sif

.. 
    There are also other tools under development that can achieve similar results. The *singularity-hpc* tool is 
    designed to be able to parse and handle container URIs automatically. For the NEMO SIFs, you could do:

    .. code-block:: bash

        shpc pull gh://NOC-MSM/CoNES/0.0.1:nemo

    or even write the container URI into a registry entry:

    .. code-block:: bash

        gh: NOC-MSM/CoNES
        latest:
          nemo: "0.0.1"
        tags:
          "nemo": "0.0.1"
        maintainer: "@jdha"
        url: https://github.com/NOC-MSM/CoNES

    .. note::

       More information on these last two methods can be found at:
       `Singularity HPC <https://github.com/singularityhub/singularity-hpc>`_.

.. note::

   More information on other methods can be found at:
   `Singularity HPC <https://github.com/singularityhub/singularity-hpc>`_.

----------------
Submitting a Job
----------------

The NEMO SIF contains information about the executables avalailable, so the user
can choose to either run NEMO or XIOS within the container. In the AMM7 example,
several runscripts are copied to the installation directory as part of the setup
process. To submit one of these runscripts to the queue, simply issue the following:

.. code-block:: bash

    cd $RUN_DIR
    sbatch runscript_1Xg_95N.slurm # Change project code accordingly

Depending on which MPI option is chosen, the runscript will use either ``mpirun`` or ``srun`` 
to distribute *NEMO*/ *XIOS* containers accordingly.


-----------
Output Data
-----------

The ``sbatch`` command is issued from the ``$RUN_DIR``. However, the inputs and outputs are handled in
the sub-directory ``EXP00``. Standard NEMO input files must reside in this directory to be accessed
by the container. At runtime the ``EXP00`` directory is *mounted* within the container and used
by the NEMO and XIOS executables. Any output from the simulation will also be written to this 
directory. ``stdout`` and ``stderr`` are written to ``$RUN_DIR`` and not ``EXP00``. Note the last few 
lines of the runscript move data from ``EXP00`` to various sub-directories under ``$RUN_DIR``.
