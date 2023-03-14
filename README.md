# Containerisation of NEMO Employing Singularity (CoNES)
[![Documentation Status](https://readthedocs.org/projects/cones/badge/?version=latest)](https://cones.readthedocs.io/en/latest/?badge=latest)

## Getting Started
The CoNES repository was templated from [Singularity Deploy](https://github.com/singularityhub/singularity-deploy)

To generate a NEMO/XIOS Singularity Container please read the [documentaion](https://cones.readthedocs.io/en/latest/?badge=latest). What follows is a simplified quick-start guide:

If building locally is not an option then it is also possible to build and 
release Singularity containers using [GitHub Actions](https://github.com/features/actions). 
[Singularity Deploy](https://github.com/singularityhub/singularity-deploy)
developed by [Vanessa Sochat](https://github.com/vsoch) has been modified 
to allow users to fork the [GitHub CoNES repository](https://github.com/NOC-MSM/CoNES)
and, using [GitHub Actions](https://github.com/features/actions), build and 
release a _bespoke_ NEMO singularity container.


The `CoNES` repository has been set up such that:

- the container is updated/developed via a branch
- the container build will be tested on a pull request
- a release will be triggered on merge into main
  
This workflow can easily be modified by altering:
  
- `.github/workflows/test.yml` for the testing of builds
- `.github/workflows/builder.yml` for the container release

An individual NEMO SIF build can be created using the following steps: 

1. Fork the `CoNES` repository under `USER` account (main branch only is fine) \
   Under the `Actions` tab enable workflows \
   Under the `Settings` tab click through `actions` -> `general` and set `workflow permissions` to r+w and save \
   Return to the `code` tab
2. Create a new branch
3. Edit the `VERSION` file to something approprate (e.g. 0.0.3)\
   [Optional] Edit the `inputs/NEMO_in` namelist for NEMO version number, MPI choice etc.
4. Create a _Pull Request_ from that branch to main. **Make sure this is from `USER/branch` to `USER/main` and not to `NOC-MSM/main`.**\
   At this point a test build will be triggered, which can take ~15 minutes per MPI build requested
5. If successful the _merge_ will be available. Click merge and ...
6. A NEMO SIF will be built and released under the _version_ specified (again this can take ~15 minutes per MPI build requested).
7. The NEMO SIF and asscoiated assets will appear under the `Releases` tab. 

The branch can now either be deleted or held open for further changes to `NEMO_in` and subsequent releases.

_Note:_
   
If the tag in the `VERSION` file is not incremented then a new release is not built.

To download the released NEMO SIF either use:

```
    wget -c https://github.com/MY_CoNES/releases/download/$VERSION/MY_CoNES.nemo.sif -o nemo.sif
```

or Singularity can also _pull_ just knowing the URL. For example:

```
    singularity pull https://github.com/MY_CONES/releases/download/$VERSION/MY_CONES.nemo.sif
```
