```
$ echo 'puts $tcl_version' | tclsh
8.6
```

```
git clone --recursive https://github.com/sonota88/vm2gol-v2-tcl.git
cd vm2gol-v2-tcl

docker build \
  --build-arg USER=$USER \
  --build-arg GROUP=$(id -gn) \
  -t vm2gol-v2-tcl:0.0.1 .

./test.sh all
```

```
wc -l *.tcl lib/*.tcl
  388 codegen.tcl
  126 lexer.tcl
  444 parser.tcl
  109 lib/json.tcl
   47 lib/types.tcl
   92 lib/utils.tcl
 1206 total
```
