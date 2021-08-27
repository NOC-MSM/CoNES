.. _building:

=========================
Building a NEMO Container
=========================

.. _CoNES: https://github.com/NOC-MSM/CoNES/releases/latest

In this section an overview of how a NEMO SIF is built under the `CoNES`_ project is presented.
Using a definition file, a SIF can be built on the command line or using GitHub actions. 
Sandbox builds, allowing the user to shell/read/write access to the container,
converting image files and producing definition files from existing SIFs will also be touched on.
First the definiation file used in the various builds is summarised: 

Definition File
===============

The Singularity definition file provides a recipe to build the reporoducible SIF. It contains information
about the base OS, software to compile and environment setup. The following stripped
down example of how to build a NEMO/XIOS SIF describes the process used in the `CoNES`_ project. 
The full definition file can be found `here <https://github.com/NOC-MSM/CoNES/blob/main/Singularity.nemo>`_.

.. code-block:: singularity

    Bootstrap: library
    From: ubuntu:20.04

    ##############################
    # NEMO Singularity Container #
    ##############################    
 
    %files
        input_files/NEMO_in /input_files/NEMO_in
        input_files/MY_SRC.tar.gz /input_files/MY_SRC.tar.gz
        input_files/setup_nemo /input_files/setup_nemo
        input_files/arch_files /input_files/arch/nemo/arch-files


The ``%files`` section lists the external files on the host system required to build the SIF. 
The first of these is a simple *namelist* file ``NEMO_in``, which provides a handlful of 
variables that allow the user to customise the build process:

.. _nemo_in:

.. code-block:: sh

    MY_SRC=                        # If blank no need to do anything
    NEMO_VERSION=4.0.4             # Check that VERSION is 4.0.[2-6], 4.0_HEAD or trunk
    XIOS_REVISION=                 # Use default value if empty
    NEMO_COMPONENTS='OCE'          # Which NEMO components to build OCE/ICE/TOP etc
    CPP_KEYS=                      # Any additional compiler keys to include? 
    MPI=                           # Which MPI implementation to use MPICH | OMPI
                                   # If empty and using GH actions, both will be built 
                                   # If empty and building on the commandline, the build terminate


In addtion, there are several other input files: ``MY_SRC.tar.gz`` contains any updated source files 
required to build NEMO; ``setup_nemo`` is the NEMO/XIOS build script, which checks out the source 
code and builds NEMO/XIOS using the ``arch_files`` compiler directives for the container environment.

In the ``%post`` section, the base OS is defined along with mandatory binaries. Any relevant
dependencies not available via ``apt-get`` (MPI, HDF5 and netCDF) are built from source. Finally, NEMO 
and XIOS are compiled using the previously imported setup script from ``%files``. The following is 
truncated for brevity:

.. code-block:: singularity

    %post

        ##
        # Install apt-get binaries, build necessary dependencies, compile NEMO/XIOS
        ##

        apt install -y locales #locales-all
        locale-gen en_GB en_GB.UTF-8 # en_US en_US.UTF-8

        apt install -y software-properties-common
        add-apt-repository universe
        apt update

        apt install -y python \
    ...
        if [ "$MPI" = "MPICH" ]
        then

             apt install -y libfabric-dev

             wget http://www.mpich.org/static/downloads/3.4.2/mpich-3.4.2.tar.gz
             tar -xvzf mpich-3.4.2.tar.gz -C mpi --strip-components 1
             rm mpich-3.4.2.tar.gz
             cd mpi

             ./configure CC=gcc CXX=g++ FC=gfortran --prefix=/opt/mpi/install FFLAGS=-fallow-argument-mismatch
             make
             make install

        elif [ "$MPI" = "OMPI" ]
        then
    ...
        /input_files/setup_nemo -x /nemo -w /nemo -m singularity -v $NEMO_VERSION -c gnu

Next the ``%environment`` section defines the path to the HDF libraries required by the container at runtime.

.. code-block:: singularity

    %environment

        export LD_LIBRARY_PATH=/opt/hdf5/install/lib:$LD_LIBRARY_PATH

And ``%runtime`` defines the action taken when the container is executed. As both NEMO and XIOS
have been built, there are checks to see which is required.

.. code-block:: singularity

    %runscript
        #!/bin/bash

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

        if [[ $1 == 'nemo' ]]
        then
            /opt/nemo/nemo
        else
            /opt/xios/xios
        fi


The Build
=========

Using the NEMO definition file, `Singularity.nemo <SIF https://github.com/NOC-MSM/CoNES/blob/main/Singularity.nemo>`_,
a SIF can be built issuing the following:

.. code-block:: sh

     sudo singularity build nemo.sif Singularity.nemo

The command requires ``sudo`` just as installing software on your local machine requires root privileges.
If this is not an option the SIF can either be built as *fakeroot* on the host system, or via a GitHub
repository.

Fake Root
=========

To build a SIF, root privilege is required. If the user does not have root access the *fakeroot* feature can
be used. An unprivileged user can build or run a container as a *fake root* user. This feature is granted by
the system admin of the host system. See Sylabs guide on 
`fakeroot <https://sylabs.io/guides/3.8/user-guide/fakeroot.html#fakeroot>`_ access for more details.

GitHub Builds
=============

If building locally is not an option then it is also possible to build and 
release Singularity containers on `GitHub <http://www.github.com>`_. 
`Singularity Deploy <https://github.com/singularityhub/singularity-deploy>`_
developed by `Vanessa Sochat <https://github.com/vsoch>`_ has been modified 
to allow users to fork the `GitHub CoNES repository <https://github.com/NOC-MSM/CoNES>`_
and, using `GitHub Actions <https://github.com/features/actions>`_, build and 
release a *bespoke* NEMO singularity container in much the same manner as
described previously.

The `CoNES`_ repository has been set up such that:

* the container is updated/developed via a branch

* the container build will be tested on a pull request

* a release will be triggered on merge into main
  
This workflow can easily be modified by altering:
  
* `.github/workflows/builder.yml` for the container release

* `.github/workflows/test.yml` for the testing of builds

An individual NEMO SIF build can be created using the following steps: 

#. Fork the `CoNES`_ repository into `$FORKED_CoNES_ID`
#. Create a new branch in `$FORKED_CoNES_ID`
#. Edit the :code:`VERSION` file to something approprate (e.g. 0.0.1)
#. Edit the `NEMO_in` namelist for NEMO version number, MPI choice etc. (see `above <nemo_in>`_ for more information)
#. Create a *Pull Request* from that branch to main (at this point a test build will be triggered (this can take ~45 minutes per MPI build requested)
#. If successful the *merge* will be available. Click merge and a NEMO SIF will be built and released under the *version* specified. (again this can take ~45 minutes per MPI build requested)

The branch can now either be deleted or held open for further changes to `NEMO_in` and subsequent releases.

.. note::
   
    If the tag in the `VERSION` file is not incremented then a new release is not built.

As previously outlined in the Quick Start guide, to download the released NEMO SIF either use:

.. code-block:: bash

    wget -c https://github.com/$FORKED_CoNES_ID/releases/download/$VERSION/$FORKED_CoNES_ID.nemo.sif -o nemo.sif

or Singularity can also *pull* just knowing the URL. For example:

.. code-block:: bash

    singularity pull https://github.com/$FORKED_CoNES_ID/CoNES/releases/download/$VERSION/$FORKED_CoNES_ID.nemo.sif

.. hint::
  
    You can also build the download of the new NEMO SIF into a setup script such as the one used in the `Quick Start Guide <quick_start>`_.


Further Features
================

Listed here a few things of use. For the full capapbility the user is referred to 
Overview of the {Singularity} Interface

Generating a .def file from a SIF
---------------------------------

Interogating a SIF
------------------

Sandbox/Writable Container
--------------------------


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

The `exec <https://www.sylabs.io/guides/\{version\}/user-guide/cli/singularity_exec.html>`_
command allows you to execute a custom command within a container by specifying
the image file. For instance, to execute the ``cowsay`` program within the
``lolcow_latest.sif`` container:

.. code-block:: none

    $ singularity exec lolcow_latest.sif cowsay moo
     _____
    < moo >
     -----
            \   ^__^
             \  (oo)\_______
                (__)\       )\/\
                    ||----w |
                    ||     ||

``exec`` also works with the ``library://``, ``docker://``, and ``shub://``
URIs. This creates an ephemeral container that executes a command and
disappears.

.. code-block:: none

    $ singularity exec library://sylabsed/examples/lolcow cowsay "Fresh from the library!"
     _________________________
    < Fresh from the library! >
     -------------------------
            \   ^__^
             \  (oo)\_______
                (__)\       )\/\
                    ||----w |
                    ||     ||


===================

To build into a ``sandbox`` (container in a directory) use the
``build --sandbox`` command and option:

.. code-block:: none

    $ sudo singularity build --sandbox ubuntu/ library://ubuntu

This command creates a directory called ``ubuntu/`` with an entire Ubuntu
Operating System and some {Singularity} metadata in your current working
directory.

You can use commands like ``shell``, ``exec`` , and ``run`` with this directory
just as you would with a {Singularity} image. If you pass the ``--writable``
option when you use your container you can also write files within the sandbox
directory (provided you have the permissions to do so).

.. code-block:: none

    $ sudo singularity exec --writable ubuntu touch /foo

    $ singularity exec ubuntu/ ls /foo
    /foo

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
