.. _introduction:

=====================
Introduction to CoNES
=====================

Containerisation of NEMO Employing Singularity (CoNES) is an [eCSE](eCSE)
funded project to develop and document methods of containerisation for the NEMO 
Ocean General Circulation Model the on [ARCHER2 HPC service](www.archer2.ac.uk], 
using [Singularity](sylabs.io).

The Nucleus for European Modelling of the Ocean (NEMO) is a 
framework for ocean and climate modelling ([www.nemo-ocean.eu](www.nemo-ocean.eu)). 
The ocean component of NEMO is a primitive equation model employed
for a range of idealised, regional and global ocean circulation studies. 
It provides a flexible tool for studying the ocean and the wider earth 
climate system over a wide range of space and time scales. 

Singularity is a *container* that allows you to create and run
pieces of software in a way that is portable and reproducible. 
_You can build a container using Singularity
on your laptop, and then run it on many of the largest HPC clusters in
the world, local university or company clusters, a single server, in
the cloud, or on a workstation down the hall_. A Singularity container
is a single file, containing all the software needed to run a
scientific experiment on a vast array of different operating systems.


Why use Singularity?
======================

  - Singularity can run complex applications on HPC clusters.
  - Open source
  - Widely used in many areas of academia
  - Portability, reproducibility and secure
  - Easily make use of GPUs, high speed
    networks, parallel filesystems on a cluster or server by default.

Why use containers?
===================

  - Runtime environment is independant of the host
  - Highly configurable
  - Removes the setup and compilation issues faced by the user

Work-flows for research can be a complicated and
iterative process, and even more so on a shared and somewhat
rigid production environment. Singularity provides a flexible 
working environment for development and production. It can even
be used as distributed tool for teaching, abstracting the overhead 
of setting up software in new environments.

--------------------
Reproducible science
--------------------

Singularity containers can provide all the tools, programs and scripts
to enable end-to-end science no matter what environment the user is
running. Data centres currently procure and archive data, journals curate 
scientific discourse, but there is a disconnect between the two. 
By encapsulating the methods in a container and pubishing them,
the science can be archived, distributed and replicated (or built upon)
by others.
