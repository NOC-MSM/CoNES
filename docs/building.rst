.. _building:

=========================
Building a NEMO Container
=========================

This guide is intended for bulding/running a NEMO Singularity Image File (SIF) 
on a HPC cluster or Linux machine that has Singularty installed. It should also 
be possible to build and run a NEMO SIF on MacOS/Windows machines. For further 
information on installing and using Singularity on different architecture 
please refer to the `Sylabs instalation guides <https://sylabs.io/guides/>`.

This section provides an overview of downloading and running a NEMO SIF on the
ARCHER2 HPC service. The methods here should be widely applicatable to other HPC
systems.

In this example we will make use of a pre-build NEMO SIF and
The simplest way to get up and running is to download a pre-build NEMO SIF.
You will need a Linux system that is has an up-to-date Singularity installation



Definition File
===============

.. code-block:: singularity

    Bootstrap: library
    From: ubuntu:20.04

    ############################
    # NEMO Singularity Container
    ############################      
 
    %files
        input_files/NEMO_in /input_files/NEMO_in
        input_files/MY_SRC.tar.gz /input_files/MY_SRC.tar.gz
        input_files/setup_nemo /input_files/setup_nemo
        input_files/arch_files /input_files/arch/nemo/arch-files


.. code-block:: singularity

%post

    ##
    #
    # Compilation from source necessary where apt-get binaries weren't compiled with necessary dependencies for XIOS and NEMO
    #
    ##

    ##
    # install basic stuff
    ##

    apt install -y locales #locales-all
    locale-gen en_GB en_GB.UTF-8 # en_US en_US.UTF-8

    apt install -y software-properties-common
    add-apt-repository universe
    apt update

    # n.b.
    #   - libcurl4-openssl-dev also installs libcurl4 (as does curl, if not already installed)
    #   - zlib already installed
    apt install -y python \
                   subversion \
                   wget \
                   git \
                   make \
                   m4 \
                   gcc-10 \
                   gfortran-10 \
                   g++-10 \
                   liburi-perl \
                   libcurl4-openssl-dev \
                   curl \
                   zlib1g-dev \
                   libibverbs-dev \
                   libpmix-dev \
                   libslurm-dev \
                   crudini

    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-10 100 --slave /usr/bin/g++ g++ /usr/bin/g++-10
    update-alternatives --install /usr/bin/gfortran gfortran /usr/bin/gfortran-10 100
    ln -s /usr/bin/cpp-10 /usr/bin/cpp

    # this decreases the size of the container
    apt clean

    ##
    # make user `nemo` - mpiexec in hdf5 `make check` complains if run as root (although we're not running it at the moment)
    ##

    adduser --disabled-password --gecos "" nemo

    ###
    # softlink gmake to make
    ###

    ln -s /usr/bin/make /usr/bin/gmake

    ##
    # compiling openmpi
    ##

    # MPI=`crudini --get /input_files/NEMO_in DEFAULT MPI` # For some reason this yanks the whole line including comments

    . /input_files/NEMO_in

    if [ -z "$MPI" ] && [ "$MPI_SWAP" = "MPICH" ]
    then
        MPI="MPICH"
    elif [ -z "$MPI" ] && [ "$MPI_SWAP" = "OMPI" ]
    then
        MPI="OMPI"
    fi

    MPI_DIR=/opt/mpi
    mkdir -p $MPI_DIR
    cd $MPI_DIR
    mkdir mpi

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

        wget https://download.open-mpi.org/release/open-mpi/v4.1/openmpi-4.1.1.tar.bz2
        tar -xvjf openmpi-4.1.1.tar.bz2 -C mpi --strip-components 1
        rm openmpi-4.1.1.tar.bz2
        cd mpi

        ./configure CC=gcc CXX=g++ FC=gfortran --enable-mpi1-compatibility --prefix=/opt/mpi/install --with-verbs --with-slurm --with-pmix
        make
        make install
    else
       echo "No MPI implementation specified"
       exit 1
    fi

    cd /opt/mpi
    rm -r mpi # removes the 303 mb directory

    ##
    # compile HDF5 libraries
    ##

    HDF_DIR=/opt/hdf5
    mkdir -p $HDF_DIR
    cd $HDF_DIR
    wget -O hdf5.tar.bz2 "https://www.hdfgroup.org/package/hdf5-1-12-0-tar-bz2/?wpdmdl=14584&refresh=60be563cf137e1623086652"
    mkdir hdf
    tar xjvf hdf5.tar.bz2 -C hdf --strip-components 1
    rm hdf5.tar.bz2

    H5DIR=/opt/hdf5/install
    cd hdf

    # n.b. --enable-fortran specifically not needed (https://www.unidata.ucar.edu/software/netcdf/docs/getting_and_building_netcdf.html#build_default)
    CC=/opt/mpi/install/bin/mpicc ./configure --prefix=${H5DIR} --enable-hl --enable-parallel --with-default-api-version=v18
    make
    # maybe we shouldn't bother with make check - it complains about a lot and we're not actually building on a parallel file system
    # so some of the checks are totally irrelevant
    # make check -i RUNPARALLEL='-oversubscribe'
    make install
    cd ..
    rm -r hdf # removes the 212 mb directory

    ##
    # compile NetCDF libraries
    ##

    NETCDF_DIR=/opt/netcdf
    mkdir -p $NETCDF_DIR
    cd $NETCDF_DIR

    # C libraries...
    wget -O netcdf.tar.gz https://github.com/Unidata/netcdf-c/archive/v4.8.0.tar.gz
    mkdir netcdf
    tar xzvf netcdf.tar.gz -C netcdf --strip-components 1
    rm netcdf.tar.gz

    cd netcdf
    NCDIR=/opt/netcdf/install

    CC=/opt/mpi/install/bin/mpicc FC=/opt/mpi/install/bin/mpifort CPPFLAGS="-I${H5DIR}/include" LDFLAGS="-L${H5DIR}/lib" ./configure --disable-shared --prefix=$NCDIR
    make
    # make check fails; maybe we should avoid running it (only 1 response from a question on the netcdf mailing list, saying it is really finicky)
    # make check
    make install
    cd ..
    rm -r netcdf # removes the 125 mb directory

    # ...and the fortran libraries
    wget https://github.com/Unidata/netcdf-fortran/archive/v4.5.3.tar.gz
    mkdir netcdf
    tar xzvf v4.5.3.tar.gz -C netcdf --strip-components 1
    rm v4.5.3.tar.gz
    cd netcdf
    NFDIR=/opt/netcdf/install

    CC=/opt/mpi/install/bin/mpicc FC=/opt/mpi/install/bin/mpifort CPPFLAGS="-I${NCDIR}/include -I${H5DIR}/include" LDFLAGS="-L${NCDIR}/lib -L${H5DIR}/lib" LIBS="-lhdf5 -lhdf5_hl -lcurl" ./configure --prefix=$NFDIR --disable-shared
    make
    make install
    cd ..
    rm -r netcdf # removes the 18 mb directory

    ##
    # Now we can install NEMO
    ##

    ln -s /opt/mpi/install/bin/mpif90 /usr/bin/mpif90

    WORK_DIR=/nemo >> $SINGULARITY_ENVIRONMENT
    mkdir $WORK_DIR
    cd $WORK_DIR
    chown nemo:nemo -R $WORK_DIR

    PATH=$PATH:/opt/mpi/install/bin:/opt/hdf5/install/bin
    LD_LIBRARY_PATH=/opt/hdf5/install/lib:$LD_LIBRARY_PATH

    cd $WORK_DIR

    . /input_files/NEMO_in

    chmod u+x /input_files/setup_nemo
    /input_files/setup_nemo -x /nemo -w /nemo -s /nemo/AMM7_lite -m singularity -v $NEMO_VERSION -c gnu

    cd /nemo/nemo/cfgs/NEMO/EXP00

    # Need to put in here if TOP include top namelist etc
    ln -s ../../SHARED/namelist_ref namelist_ref
    ln -s ../../SHARED/namelist_ice_ref namelist_ice_ref
    ln -s ../../SHARED/grid_def_nemo.xml grid_def_nemo.xml
    ln -s ../../SHARED/field_def_nemo-oce.xml field_def_nemo-oce.xml
    ln -s ../../SHARED/field_def_nemo-ice.xml field_def_nemo-ice.xml
    ln -s ../../SHARED/domain_def_nemo.xml domain_def_nemo.xml
    ln -s ../../SHARED/axis_def_nemo.xml axis_def_nemo.xml

    cd $WORK_DIR

    mkdir /opt/nemo
    mv /nemo/nemo/cfgs/NEMO/EXP00/nemo /opt/nemo/

    mkdir /opt/xios
    mv /nemo/nemo/cfgs/NEMO/EXP00/xios_server.exe /opt/xios/xios

    # make everything we've built be owned by `nemo`
    chown -Rv nemo:nemo /opt

    # minimal possible permissions: directories executable; binaries read + executable (need to be readable to that library headers can be read!); everything else only readable for g+o
    chmod -Rv 644 /opt
    find /opt -type d -print0 | xargs -0 chmod -v 511
    find /opt -type f -exec file -i {} + | grep ":[^:]*binary[^:]*$" |  sed 's/^\(.*\):[^:]*$/\1/' | xargs chmod -v 555


    rm -rf /var/lib/apt/lists/* /var/lib/dpkg/info/*
    #echo $LD_LIBRARY_PATH
    #ls /opt/hdf5/install/lib
    #echo "export LD_LIBRARY_PATH=/opt/hdf5/install/lib:\"${LD_LIBRARY_PATH}\"" >> $SINGULARITY_ENVIRONMENT
    #echo $SINGULARITY_ENVIRONMENT

%environment

    # this is needed - nemo is built dynamically (and openmpi, the other library needed, is dealt with in the wrapper script automagically)
    export LD_LIBRARY_PATH=/opt/hdf5/install/lib:$LD_LIBRARY_PATH

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

%labels
    Author jdha@noc.ac.uk
    Author c.wood@epcc.ed.ac.uk
    Version v0.0.1

%help

    Useful information




Build Environment
=================


Fake Root
=========


GitHub Builds
=============

--------
Overview
--------

If building locally is not an option then it is also possible to build and 
release Singularity containers on `GitHub <http://www.github.com>`_. 
`Singularity Deploy <https://github.com/singularityhub/singularity-deploy>`_
developed by `Vanessa Sochat <https://github.com/vsoch>`_ has been modified 
to allow users to fork the `GitHub CoNES repository <https://github.com/NOC-MSM/CoNES>`_
and, using `GitHub Actions <https://github.com/features/actions>`_, build and 
release a *bespoke* NEMO singularity container in much the same manner as
described previously.

------
Inputs
------


--------------
How to develop
--------------

-----------
How to Pull
-----------

--------------
GitHub Actions
--------------


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


-------------------------
Build images from scratch
-------------------------

.. _sec:buildimagesfromscratch:

{Singularity} v3.0 and above produces immutable images in the Singularity Image File (SIF)
format. This ensures reproducible and verifiable images and allows for many
extra benefits such as the ability to sign and verify your containers.

However, during testing and debugging you may want an image format that is
writable. This way you can ``shell`` into the image and install software and
dependencies until you are satisfied that your container will fulfill your
needs. For these scenarios, {Singularity} also supports the ``sandbox`` format
(which is really just a directory).

Sandbox Directories
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
