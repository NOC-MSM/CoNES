.. _introduction:

=====================
Introduction to CoNES
=====================

.. _eCSE: https://www.archer2.ac.uk/ecse/
.. _`ARCHER2 HPC service`: www.archer2.ac.uk
.. _Singularity: sylabs.io
.. _NEMO: www.nemo-ocean.eu

Containerisation of NEMO Employing Singularity (CoNES) is an eCSE_
funded project to develop and document methods of containerisation for the NEMO 
Ocean General Circulation Model the on `ARCHER2 HPC service`_, 
using Singularity_.

----
NEMO
----

The Nucleus for European Modelling of the Ocean (NEMO_) is a 
framework for ocean and climate modelling. 
The ocean component of NEMO is a primitive equation model employed
for a range of idealised, regional and global ocean circulation studies. 
It provides a flexible tool for studying the ocean and the wider earth 
climate system over a wide range of space and time scales. 

-----------
Singularity
-----------

Singularity is a *container* that allows the creation and execution
of software in a way that is portable and reproducible. 
It can be built on a laptop/desktop, and then run on a HPC service, 
local cluster, a single server, in the cloud, and most workstations. 
A Singularity container is a single file, containing all the software 
needed to run a scientific experiment on a vast array of different 
operating systems.

Why use containers?
===================

 *  Runtime environment is independent of the host.

 *  Highly configurable.

 *  Removes the setup and compilation issues faced by the user.

Why use Singularity?
======================

 *  Singularity can run complex applications on HPC clusters.

 *  Open source.

 *  Widely used in many areas of academia.

 *  Portability, reproducibility and secure.

 *  Easily make use of GPUs, high speed
    networks, parallel filesystems on a cluster or server by default.

Developing work-flows for research can be a complicated and
iterative process, and even more so on a shared and somewhat
rigid production environment. Singularity provides a flexible 
working environment for development and production. It can even
be used as distributed tool for teaching, removing the overhead 
of setting up software in new environments.

--------------------
Reproducible science
--------------------

Singularity containers can provide all the tools, programs and scripts
to enable end-to-end science no matter what environment the user is
running. Data centres currently procure and archive data, journals curate 
scientific discourse, but there is a disconnect between the two. 
By encapsulating the methods in a container and publishing them,
the science can be archived, distributed and replicated (or built upon)
by others.
