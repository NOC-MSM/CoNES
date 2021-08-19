
Running a container
===================

In its simplest form to run a SIF:

.. code-block:: sh

    singularity run nemo.sif nemo EXP00

Running on the ARCHER2 HPC facility using ``mpirun``:

.. code-block:: sh

    mpirun --oversubscribe -rf rankfile --report-bindings -v -np 1 --bind-to core \
           -np 1  --bind-to core singularity run nemo.sif xios EXP00 : \
           -mca orte_base_help_aggregate 0 --mca btl_vader_single_copy_mechanim none --mca btl ^sm --mca btl_openib_allow_ib true \
           -np 95 --bind-to core singularity run -B /etc/libibverbs.d nemo.sif nemo EXP00 

Running on a HPC cluster using ``srun``:


.. code-block:: sh

    sruni  --oversubscribe -rf rankfile --report-bindings -v -np 1 --bind-to core \
           -np 1  --bind-to core singularity run nemo.sif xios EXP00 : \
           -mca orte_base_help_aggregate 0 --mca btl_vader_single_copy_mechanim none --mca btl ^sm --mca btl_openib_allow_ib true \
           -np 95 --bind-to core singularity run -B /etc/libibverbs.d nemo.sif nemo EXP00 

Any example of a complete runscript in the AMM7 repo can be found here

Discuss Hybrid versus Bind approaches to MPI
