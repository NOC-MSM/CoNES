.. _building:

.. role:: bash(code)
   :language: bash
   :class: highlight

.. role:: singularity(code)
   :language: singularity
   :class: highlight

=========================
Building a NEMO Container
=========================

.. _CoNES: https://github.com/NOC-MSM/CoNES/

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


The :singularity:`%files` section lists the external files on the host system required to build the SIF. 
The first of these is a simple *namelist* file :file:`NEMO_in`, which provides a handlful of 
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


In addtion, there are several other input files: :file:`MY_SRC.tar.gz` contains any updated source files 
required to build NEMO; :file:`setup_nemo` is the NEMO/XIOS build script, which checks out the source 
code and builds NEMO/XIOS using the :file:`arch_files` compiler directives for the container environment.

In the :singularity:`%post` section, the base OS is defined along with mandatory binaries. Any relevant
dependencies not available via :bash:`apt-get` (MPI, HDF5 and netCDF) are built from source. Finally, NEMO 
and XIOS are compiled using the previously imported setup script from :singularity:`%files`. The following is 
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

Next the :singularity:`%environment` section defines the path to the HDF libraries required by the container at runtime.

.. code-block:: singularity

    %environment

        export LD_LIBRARY_PATH=/opt/hdf5/install/lib:$LD_LIBRARY_PATH

And :singularity:`%runscript` defines the action taken when the container is executed. As both NEMO and XIOS
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

.. code-block:: bash

     sudo singularity build nemo.sif Singularity.nemo

The command requires :bash:`sudo` just as installing software on your local machine requires root privileges.
If this is not an option the SIF can either be built as *fakeroot* on the host system, or via a GitHub
repository.

Fake Root
=========

To build a SIF, root privilege is required. If the user does not have root access the *fakeroot* feature can
be used. An unprivileged user can build or run a container as a *fakeroot* user. This feature is granted by
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
  
* :file:`.github/workflows/builder.yml` for the container release

* :file:`.github/workflows/test.yml` for the testing of builds

An individual NEMO SIF build can be created using the following steps: 

#. Fork the `CoNES`_ repository into :bash:`$FORKED_CoNES_ID`
#. Create a new branch in :bash:`$FORKED_CoNES_ID`
#. Edit the :file:`VERSION` file to something approprate (e.g. 0.0.1)
#. Edit the :file:`NEMO_in` namelist for NEMO version number, MPI choice etc. (see `above <nemo_in>`_ for more information)
#. Create a *Pull Request* from that branch to main (at this point a test build will be triggered (this can take ~45 minutes per MPI build requested)
#. If successful the *merge* will be available. Click merge and a NEMO SIF will be built and released under the *version* specified. (again this can take ~45 minutes per MPI build requested)

The branch can now either be deleted or held open for further changes to :file:`NEMO_in` and subsequent releases.

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

The definition meta data is stored in a SIF file and can be access using the :bash:`inspect`
command:
.. code-block:: bash

    $ singularity inspect --deffile nemo.sif > nemo.def

The resulting file can in turn be edited and used to build subsequent container files.

Interogating a SIF
------------------

Once the :file:`nemo.sif` is on the local system, it can accessed via the
`shell <https://www.sylabs.io/guides/3.8/user-guide/cli/singularity_shell.html>`_
command. It is then possible to traverse the directory structure of the SIF in the
same manner as any other OS:

.. code-block:: bash

    $ singularity shell nemo.sif

    Singularity> cd /nemo/nemo/cfgs/NEMO/EXP00


To leave the container simply type :bash:`exit` as with any other system.

Sandbox/Writable Container
--------------------------

If root or *fakeroot* access is available it is possible to build a :bash:`sandbox`
(container in a directory) using the following command:

.. code-block:: bash

    $ sudo singularity build --sandbox nemo_sandbox nemo.def

This command creates a directory called nemo_sandbox that is writable:

.. code-block:: bash

    $ sudo singularity shell --writable nemo_sandbox

This can be helpful when first constructing the container.

Converting images from one format to another
============================================

In addtion to building from a definition file the :bash:`build` command allows 
for the conversion of containers. For example:

.. code-block:: none

    $ singularity build nemo.sif nemo_sandbox

converts the :file:`nemo_sandbox` directory into an immutable SIF.

.. note::

   More information on there and other methods can be found
   in the `Singularity User Guide <https://www.sylabs.io/guides/3.8/user-guide/>`_.

