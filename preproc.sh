#!/bin/bash

if [ "$1" = "clean" ]; then
  export CLEAN=1
fi

ruby preproc.rb test/test_json.tcl
ruby preproc.rb lexer.tcl
ruby preproc.rb parser.tcl
ruby preproc.rb codegen.tcl
