Notes:
  - the build is done in sh, not bash - and so bash specific parameters (e.g. $_) are not available, hence creating and cd-ing separately all the way through 
  - I currently change branch in the nemo singularity repo rather than use master

Unresolved issues / future work:
  - significant testing needed - does OpenMPI version on Cirrus need to the same as version in this def file?
  - do we _need_ to (should we) run all available `make [check|test]` for dependencies?
  - did I waste a lot of time working out how to compile dependencies from source? (David H suggested that some apt binaries might work, despite my comment below!)
  - we could change the workflow of all of this by creating individual docker files of all the dependencies (with same base OS image, probably something minimal? alpine?), doing a multistage build, and creating the singularity container from the final resultant docker container. Singularity doensn't (yet) allow multistage builds
    - however, it's not possible to pull multiple docker images in 1 recipe, so would need to do an incremental build which is probably too much effort for any benefit it would provide  
  - one of the issues I had running `make check` for hdf5 was with running it as root - mpiexec complains about this. I created the nemo user to run (with the side effect that it created a useful location - the home directory - to store some of the dependencies!). But I then had issues with adding the hdf5 libraries to search paths used by NetCDF, nemo, and xios, so changed --prefix from /home/nemo/hdf5 to /usr/local, but you can't install stuff to there without being root (or sudo, which isn't directly supported in a container). Way round it would be build in /home/nemo as nemo, then install as root, and switch back to nemo user? Is it worth it? But only need to worry about this if we want to run `make check`. Also had similar issues with NCDIR and NFDIR for NetCDF install directories (changed from /home/nemo/netcdf/install to /usr/local). If there's a way round it (and there's a reason to do it), then LD_LIBRARY_PATH and PATH will need to be set and updated
  - I also thought it would be useful to keep all the 3rd party dependencies in a separate place, rather than /usr/local, but maybe that's just being a bit OCD...
  - the nemo-singularity repo is currently private, so need to supply a username/password or git SSH
  - I keep the def file in a different repo to the singularity nemo build because it is a different thing - someone running `singularity build` doesn't need the whole singularity-nemo repo (apart from inside the container)
