.. _quick-start:

===========
Quick Start
===========

.. _eCSE: https://www.archer2.ac.uk/ecse/
.. _`ARCHER2 HPC service`: www.archer2.ac.uk
.. _Singularity: sylabs.io
.. _`Singularity Guide`: https://sylabs.io/guides/
.. _NEMO: www.nemo-ocean.eu

This guide is intended for running a NEMO Singularity Image File (SIF) 
on a HPC cluster or Linux machine that has Singularty installed. It should also 
be possible to build and run a NEMO SIF on MacOS/Windows machines. For further 
information on installing and using Singularity on different architecture 
please refer to the `Singularity Guide`_.

An outline how to setup, download and run a NEMO SIF on the
`ARCHER2 HPC Service`_ follows. This example uses the `NEMO AMM7 
configuration <https://github.com/NOC-MSM/HPC_Scaling_AMM7>`_. 



as the example on ARCHER2
The config files for this make use of HPC_Scaling_AMM7

The simplest way to get up and running is to download a pre-build NEMO SIF.
You will need a Linux system that is has an up-to-date Singularity installation


Options for
using {Singularity} on Mac and Windows machines, along with alternate
Linux installation optionrs are discussed in the `installation section of the
admin guide
<https://sylabs.io/guides/e\{adminversion\}/admin-guide/installation.html>`__.


The following example is for ARCHER2

--------------------------
Setting up the environment
--------------------------

.. code-block:: none

   git clone https://github.com/NOC-MSM/HPC_Scaling_AMM7
   HPC_Scaling_AMM7/scripts/setup/amm7_setup -w $PWD/rundir -x $PWD/test \
                                             -s $PWD/HPC_Scaling_AMM7 \
                                             -m archer2 -v sing -c gnu


------------------------
Download pre-built image
------------------------

You must first install development libraries to your host. Assuming Ubuntu
(apply similar to RHEL derivatives):

.. code-block:: none

    wget -c https://github.com/NOC-MSM/CoNES/releases/download/0.0.1/NOC-MSM-CoNES.nemo.sif -o nemo.sif

--------------------
Interact with images
--------------------

You can interact with images in several ways, each of which can accept image URIs
in addition to a local image path.

For demonstration, we will use a ``lolcow_latest.sif`` image that can be pulled
from the Container Library:

.. code-block:: none

    $ singularity pull library://sylabsed/examples/lolcow

Shell
=====

The `shell <https://www.sylabs.io/guides/\{version\}/user-guide/cli/singularity_shell.html>`_
command allows you to spawn a new shell within your container and interact with
it as though it were a small virtual machine.

.. code-block:: none

    $ singularity shell lolcow_latest.sif

    {Singularity} lolcow_latest.sif:~>


The change in prompt indicates that you have entered the container (though you
should not rely on that to determine whether you are in container or not).

Once inside of a {Singularity} container, you are the same user as you are on the
host system.

.. code-block:: none

    {Singularity} lolcow_latest.sif:~> whoami
    david

    {Singularity} lolcow_latest.sif:~> id
    uid=1000(david) gid=1000(david) groups=1000(david),4(adm),24(cdrom),27(sudo),30(dip),46(plugdev),116(lpadmin),126(sambashare)

``shell`` also works with the ``library://``, ``docker://``, and ``shub://``
URIs. This creates an ephemeral container that disappears when the shell is
exited.

.. code-block:: none

    $ singularity shell library://sylabsed/examples/lolcow

Executing Commands
==================


Running a container
===================

{Singularity} containers contain :ref:`runscripts <runscript>`. These are user
defined scripts that define the actions a container should perform when someone
runs it. The runscript can be triggered with the `run <https://www.sylabs.io/guides/\{version\}/user-guide/cli/singularity_run.html>`_
command, or simply by calling the container as though it were an executable.

.. code-block:: none

    $ singularity run lolcow_latest.sif


-------------------
Working with Files
-------------------


Converting images from one format to another
============================================

The ``build`` command allows you to build a container from an existing
container. This means that you can use it to convert a container from one format
to another. For instance, if you have already created a sandbox (directory) and
want to convert it to the default immutable image format (squashfs) you can do
so:

.. code-block:: none

    $ singularity build new-sif sandbox

Doing so may break reproducibility if you have altered your sandbox outside of
the context of a definition file, so you are advised to exercise care.

{Singularity} Definition Files
==============================

For a reproducible, verifiable and production-quality container you should
build a SIF file using a {Singularity} definition file. This also makes it easy to
add files, environment variables, and install custom software, and still start
from your base of choice (e.g., the Container Library).

A definition file has a header and a body. The header determines the base
container to begin with, and the body is further divided into sections that
perform things like software installation, environment setup, and copying files
into the container from host system, etc.

Here is an example of a definition file:

.. code-block:: singularity

    BootStrap: library
    From: ubuntu:16.04

    %post
        apt-get -y update
        apt-get -y install fortune cowsay lolcat

    %environment
        export LC_ALL=C
        export PATH=/usr/games:$PATH

    %runscript
        fortune | cowsay | lolcat

    %labels
        Author GodloveD


To build a container from this definition file (assuming it is a file
named lolcow.def), you would call build like so:

.. code-block:: none

    $ sudo singularity build lolcow.sif lolcow.def

In this example, the header tells {Singularity} to use a base Ubuntu 16.04 image
from the Container Library.

- The ``%post`` section executes within the container at build time after the base OS has been installed. The ``%post`` section is therefore the place to perform installations of new applications.

- The ``%environment`` section defines some environment variables that will be available to the container at runtime.

- The ``%runscript`` section defines actions for the container to take when it is executed.

- And finally, the ``%labels`` section allows for custom metadata to be added to the container.

This is a very small example of the things that you can do with a :ref:`definition file <definition-files>`.
In addition to building a container from the Container Library, you can start
with base images from Docker Hub and use images directly from official
repositories such as Ubuntu, Debian, CentOS, Arch, and BusyBox.  You can also
use an existing container on your host system as a base.

If you want to build {Singularity} images but you don't have administrative (root)
access on your build system, you can build images using the `Remote Builder <https://cloud.sylabs.io/builder>`_.

This quickstart document just scratches the surface of all of the things you can
do with {Singularity}!

If you need additional help or support, contact the Sylabs team:
https://www.sylabs.io/contact/


.. _installation-request:

{Singularity} on a shared resource
----------------------------------

Perhaps you are a user who wants a few talking points and background to share
with your administrator.  Or maybe you are an administrator who needs to decide
whether to install {Singularity}.

This document, and the accompanying administrator documentation provides answers
to many common questions.

If you need to request an installation you may decide to draft a message similar
to this:

.. code-block:: none

    Dear shared resource administrator,

    We are interested in having {Singularity} (https://www.sylabs.io/docs/)
    installed on our shared resource. {Singularity} containers will allow us to
    build encapsulated environments, meaning that our work is reproducible and
    we are empowered to choose all dependencies including libraries, operating
    system, and custom software. {Singularity} is already in use on many of the
    top HPC centers around the world. Examples include:

        Texas Advanced Computing Center
        GSI Helmholtz Center for Heavy Ion Research
        Oak Ridge Leadership Computing Facility
        Purdue University
        National Institutes of Health HPC
        UFIT Research Computing at the University of Florida
        San Diego Supercomputing Center
        Lawrence Berkeley National Laboratory
        University of Chicago
        McGill HPC Centre/Calcul Québec
        Barcelona Supercomputing Center
        Sandia National Lab
        Argonne National Lab

    Importantly, it has a vibrant team of developers, scientists, and HPC
    administrators that invest heavily in the security and development of the
    software, and are quick to respond to the needs of the community. To help
    learn more about {Singularity}, I thought these items might be of interest:

        - Security: A discussion of security concerns is discussed at
        https://www.sylabs.io/guides/{adminversion}/admin-guide/admin_quickstart.html

        - Installation:
        https://www.sylabs.io/guides/{adminversion}/admin-guide/installation.html

    If you have questions about any of the above, you can contact the open
    source list (https://groups.google.com/g/singularity-ce), join the open
    source slack channel (singularityce.slack.com), or contact the organization
    that supports {Singularity} directly (sylabs.io/contact). I can do my best
    to facilitate this interaction if help is needed.

    Thank you kindly for considering this request!

    Best,

    User
