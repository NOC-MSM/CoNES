
Running a container
===================

{Singularity} containers contain :ref:`runscripts <runscript>`. These are user
defined scripts that define the actions a container should perform when someone
runs it. The runscript can be triggered with the `run <https://www.sylabs.io/guides/\{version\}/user-guide/cli/singularity_run.html>`_
command, or simply by calling the container as though it were an executable.

.. code-block:: none

    $ singularity run lolcow_latest.sif
     _____________________________________
    / You have been selected for a secret \
    \ mission.                            /
     -------------------------------------
            \   ^__^
             \  (oo)\_______
                (__)\       )\/\
                    ||----w |
                    ||     ||

    $ ./lolcow_latest.sif
     ____________________________________
    / Q: What is orange and goes "click, \
    \ click?" A: A ball point carrot.    /
     ------------------------------------
            \   ^__^
             \  (oo)\_______
                (__)\       )\/\
                    ||----w |
                    ||     ||


``run`` also works with the ``library://``, ``docker://``, and ``shub://`` URIs.
This creates an ephemeral container that runs and then disappears.

.. code-block:: none

    $ singularity run library://sylabsed/examples/lolcow
     ____________________________________
    / Is that really YOU that is reading \
    \ this?                              /
     ------------------------------------
            \   ^__^
             \  (oo)\_______
                (__)\       )\/\
                    ||----w |
                    ||     ||
