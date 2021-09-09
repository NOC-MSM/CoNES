.. _running:

Running a container
===================

.. role:: bash(code)
   :language: bash
   :class: highlight

.. role:: singularity(code)
   :language: singularity
   :class: highlight

The NEMO SIF is constructed in such a way that both *NEMO* and *XIOS* are available within the container. The SIF is an
instance of *NEMO/XIOS* as specified by the :file:`NEMO_in` file. This will be version specific, and may have been
modified with *user* specified :bash:`MY_SRC` code, additional components (e.g. ICE, TOP etc) and/or compiler keys. What the 
container does not contain is the configuration specific files to run a simulation. As eluded to in the :ref:`Quick Start Guide <quick_start>`_
within the :bash:`$RUNDIR` a directory called :bash:`EXP00` must be created. This behaves in much the same way as in a *traditional*
NEMO simulation. In this case it serves as the mount point for the SIF to read and write data. Any NEMO input files 
(netcdf, namelists etc) must be located in this directory. All output from the simulation will also be written to :bash:`EXP00`.

.. note:

   At runtime the SIF will mount EXP00 and symbolically link all the namelists and XML files in the :bash:`SHARED` directory within
   the container. If any namelist structures have been modified through the addition of :bash:`MY_SRC` these will have to updated
   host-side for the simulation to run.

In its simplest form to run a NEMO SIF on a single core without an XIOS server (binding host directory :bash:`EXP00`):

.. code-block:: bash

    singularity run nemo.sif nemo EXP00

def file set up for MPICH and openMPI

Runscripts from the exmaple AMM7 repo set up to use mpirun adn slurm (Any example of a complete runscript in the AMM7 repo can be found here)
. Example of current Running on the ARCHER2 HPC facility using :bash:`mpirun`:

.. code-block:: bash

    mpirun --oversubscribe -rf rankfile --report-bindings -v -np 1 --bind-to core \
           -np 1  --bind-to core singularity run nemo.sif xios EXP00 : \
           --mca btl_vader_single_copy_mechanism none --mca btl ^sm --mca btl_openib_allow_ib true \
           -np 95 --bind-to core singularity run nemo.sif nemo EXP00 

likewise for :bash:`srun`:


.. code-block:: bash

    srun --mem-bind=local --pack-group=0  --cpu-bind=v,mask_cpu:0x1,0x10000 ...
         ...
         --hint=nomultithread \
         -np 1 --bind-to core singularity run nemo.sif xios EXP00 : \
         -np 95 --bind-to core singularity run nemo.sif nemo EXP00

Singularity MPI flags used in the above examples:

btl: Byte transfer layer (point-to-point byte movement)
 Modular Component Architecture (MCA) is the backbone for much of Open MPI's functionality

* :bash:`--mca btl_vader_single_copy_mechanism none`: Explain
* :bash:`--mca btl ^sm`: Explain
* :bash:`--mca btl_openib_allow_ib true`: Explain

other flags are associated with ARCHER2 system:

* :bash:`--oversubscribe`: force whole node availablilty.
* :bash:`-rf rankfile`: distribution map.
* :bash:`--report-bindings`: report core/process layout.
* :bash:`-v`: verbose.
* :bash:`-np`: number of processes.
* :bash:`--bind-to core`: one process per specified core.

On the ARCHER2 HPC service the distribution of two executables is handled using a :bash:`rankfile` when using openMPI 
and :bash:`mpirun`, and :bash:`--pack-group` with cpu addesses when using :bash:`srun` and MPICH.

Hybrid versus Bind methods
--------------------------

The above examples make use of both the host and container MPI libraries. This is the *Hybrid* method of running a 
container. It is possible to use a *Bind* method, relying of the host MPI implentation. Whilst the container is built
using same (or similiar) MPI libraries as those present on the host, they are removed from the container as part of
the build process. At runtime the host MPI libraries are then mounted into the container e.g.:

.. code-block:: bash

    srun --mem-bind=local --pack-group=0  --cpu-bind=v,mask_cpu:0x1,0x10000 ...
         ...
         --hint=nomultithread \
         -np 1 --bind-to core singularity --bind <PATH/TO/HOST/MPI/DIRECTORY>:<PATH/IN/CONTAINER> run nemo.sif xios EXP00 : \
         -np 95 --bind-to core singularity --bind <PATH/TO/HOST/MPI/DIRECTORY>:<PATH/IN/CONTAINER> run nemo.sif nemo EXP00


More information about the methods is available `here <https://sylabs.io/guides/3.5/user-guide/mpi.html>`_.
