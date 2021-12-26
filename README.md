Tclでかんたんな自作言語のコンパイラを書いた  
https://qiita.com/sonota88/items/988d9cb4ba2077c49d64

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
  381 codegen.tcl
  129 lexer.tcl
  438 parser.tcl
  109 lib/json.tcl
   42 lib/types.tcl
   92 lib/utils.tcl
 1191 total
```
