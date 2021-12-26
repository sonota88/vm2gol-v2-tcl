#!/bin/bash

docker run --rm -it \
  -v"$(pwd):/home/${USER}/work" \
  vm2gol-v2-tcl:0.0.1 "$@"
