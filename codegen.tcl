source lib/utils.tcl
source lib/types.tcl
source lib/json.tcl

# --------------------------------

proc asm_prologue {} {
    puts "  push bp"
    puts "  cp sp bp"
}

proc asm_epilogue {} {
    puts "  cp bp sp"
    puts "  pop bp"
}

# --------------------------------

proc lvar_disp {lvars name} {
    set i [lsearch $lvars $name]
    if {$i == -1} {
        error "must not happen"
    }
    return [expr 0 - ($i + 1)]
}

proc fn_arg_disp {fn_args name} {
    set i [lsearch $fn_args $name]
    if {$i == -1} {
        error "must not happen"
    }
    return [expr $i + 2]
}

proc next_label_id {} {
    global g_label_id
    incr g_label_id

    return $g_label_id
}

# --------------------------------

set g_label_id 0

proc _gen_expr_add {} {
    puts "  pop reg_b"
    puts "  pop reg_a"

    puts "  add_ab"
}

proc _gen_expr_mult {} {
    puts "  pop reg_b"
    puts "  pop reg_a"

    puts "  mult_ab"
}

proc _gen_expr_eq {} {
    set label_id [next_label_id]

    set label_end [format "end_eq_%d" $label_id]
    set label_then [format "then_%d" $label_id]

    puts "  pop reg_b"
    puts "  pop reg_a"
    puts "  compare"
    puts [format "  jump_eq %s" $label_then]
    puts "  cp 0 reg_a"
    puts [format "  jump %s" $label_end]
    puts [format "label %s" $label_then]
    puts "  cp 1 reg_a"
    puts [format "label %s" $label_end]
}

proc _gen_expr_neq {} {
    set label_id [next_label_id]

    set label_end [format "end_neq_%d" $label_id]
    set label_then [format "then_%d" $label_id]

    puts "  pop reg_b"
    puts "  pop reg_a"
    puts "  compare"
    puts [format "  jump_eq %s" $label_then]
    puts "  cp 1 reg_a"
    puts [format "  jump %s" $label_end]
    puts [format "label %s" $label_then]
    puts "  cp 0 reg_a"
    puts [format "label %s" $label_end]
}

proc _gen_expr_binary {fn_args lvars expr_node} {
    set expr_list [Node_get_val $expr_node]
    set op [Node_get_val [lindex $expr_list 0]]
    set expr_l [lindex $expr_list 1]
    set expr_r [lindex $expr_list 2]

    gen_expr $fn_args $lvars $expr_l
    puts "  push reg_a"
    gen_expr $fn_args $lvars $expr_r
    puts "  push reg_a"

    switch $op {
        "+"  { _gen_expr_add  }
        "*"  { _gen_expr_mult }
        "==" { _gen_expr_eq   }
        "!=" { _gen_expr_neq  }
        default {
            error [format "_gen_expr_binary: (%s)" $expr_node]
        }
    }

}

proc gen_expr {fn_args lvars expr_node} {
    set type [Node_get_type $expr_node]

    switch $type {
        "int" {
            set val [Node_get_val $expr_node]
            puts [format "  cp %d reg_a" $val]
        }
        "str" {
            set val [Node_get_val $expr_node]
            if {0 <= [lsearch $lvars $val]} {
                set disp [lvar_disp $lvars $val]
                puts [format "  cp \[bp:%d\] reg_a" $disp]
            } elseif {0 <= [lsearch $fn_args $val]} {
                set disp [fn_arg_disp $fn_args $val]
                puts [format "  cp \[bp:%d\] reg_a" $disp]
            } else {
                puts_kv_e fn_args $fn_args
                puts_kv_e lvars $lvars
                puts_kv_e val $val
                error "no such function argument or local varible"
            }
        }
        "list" {
            _gen_expr_binary $fn_args $lvars $expr_node
        }
        default {
            error [format "invalid type (%s)" $expr_node]
        }
    }
}

proc _gen_set {fn_args lvars dest expr_node} {
    gen_expr $fn_args $lvars $expr_node

    if {0 <= [lsearch $lvars $dest]} {
        set disp [lvar_disp $lvars $dest]
        puts [format "  cp reg_a \[bp:%d\]" $disp]
    }
}

proc gen_set {fn_args lvars stmt} {
    set var_name [Node_get_val [lindex $stmt 1]]
    set expr_node [lindex $stmt 2]
    _gen_set $fn_args $lvars $var_name $expr_node
}

proc _gen_funcall {fn_args lvars funcall} {
    set fn_name [Node_get_val [lindex $funcall 0]]
    set args [List_rest $funcall 1]

    foreach arg [lreverse $args] {
        gen_expr $fn_args $lvars $arg
        puts "  push reg_a"
    }

    _gen_vm_comment [format "call  %s" $fn_name]
    puts [format "  call %s" $fn_name]

    set num_args [llength $args]
    puts [format "  add_sp %d" $num_args];
}

proc gen_call {fn_args lvars stmt} {
    set funcall [List_rest $stmt 1]
    _gen_funcall $fn_args $lvars $funcall
}

proc gen_call_set {fn_args lvars stmt} {
    set lvar_name [Node_get_val [lindex $stmt 1]]
    set funcall [Node_get_val [lindex $stmt 2]]

    _gen_funcall $fn_args $lvars $funcall

    set disp [lvar_disp $lvars $lvar_name]
    puts [format "  cp reg_a \[bp:%d\]" $disp]
}

proc gen_return {fn_args lvars stmt} {
    set expr_node [lindex $stmt 1]
    gen_expr $fn_args $lvars $expr_node
}

proc gen_while {fn_args lvars stmt} {
    set expr_node [lindex $stmt 1]
    set stmts [Node_get_val [lindex $stmt 2]]

    set label_id [next_label_id]

    set label_begin [format "while_%d" $label_id]
    set label_end [format "end_while_%d" $label_id]

    puts [format "label %s" $label_begin]

    gen_expr $fn_args $lvars $expr_node

    puts "  cp 0 reg_b"
    puts "  compare"
    puts [format "  jump_eq %s" $label_end]

    gen_stmts $fn_args $lvars $stmts
    
    puts [format "  jump %s" $label_begin]

    puts [format "label %s" $label_end]
}

proc gen_case {fn_args lvars stmt} {
    set label_id [next_label_id]

    set label_end [format "end_case_%d" $label_id]
    set label_end_when_head [format "end_when_%d" $label_id]

    set i 1
    while {$i < [llength $stmt]} {
        set when_clause [Node_get_val [lindex $stmt $i]]

        set when_idx [expr $i - 1]
        set expr_node [lindex $when_clause 0]
        set stmts [List_rest $when_clause 1]

        gen_expr $fn_args $lvars $expr_node
        puts "  cp 0 reg_b"
        puts "  compare"
        puts [format "  jump_eq %s_%d" $label_end_when_head $when_idx]

        gen_stmts $fn_args $lvars $stmts
        
        puts [format "  jump %s" $label_end]

        puts [format "label %s_%d" $label_end_when_head $when_idx]

        incr i
    }

    puts [format "label %s" $label_end]
}

proc _gen_vm_comment {cmt} {
    puts [format "  _cmt %s" [string map {" " "~"} $cmt]]
}

proc gen_vm_comment {stmt} {
    set cmt [Node_get_val [lindex $stmt 1]]
    _gen_vm_comment $cmt
}

proc gen_debug {} {
    puts "  _debug"
}

proc gen_stmt {fn_args lvars stmt} {
    set stmt_head [head_val $stmt]

    switch $stmt_head {
        "set"      { gen_set      $fn_args $lvars $stmt }
        "call"     { gen_call     $fn_args $lvars $stmt }
        "call_set" { gen_call_set $fn_args $lvars $stmt }
        "return"   { gen_return   $fn_args $lvars $stmt }
        "while"    { gen_while    $fn_args $lvars $stmt }
        "case"     { gen_case     $fn_args $lvars $stmt }
        "_cmt"     { gen_vm_comment $stmt }
        "_debug"   { gen_debug }
        default {
            puts_kv_e stmt $stmt
            error [format "gen_stmts: unsupported statement (%s)" $stmt_head]
        }
    }
}

proc head_val {xs} {
    return [Node_get_val [lindex $xs 0]]
}

proc gen_stmts {fn_args lvars stmts} {
    foreach stmt_node $stmts {
        set stmt [Node_get_val $stmt_node]
        gen_stmt $fn_args $lvars $stmt
    }
}

proc gen_var {fn_args lvars stmt} {
    puts "  sub_sp 1"

    if {[llength $stmt] == 3} {
        set var_name [Node_get_val [lindex $stmt 1]]
        set expr_node [lindex $stmt 2]
        _gen_set $fn_args $lvars $var_name $expr_node
    }
}

proc to_fn_args {_list} {
    set fn_args {}
    foreach node $_list {
        lappend fn_args [Node_get_val $node]
    }
    return $fn_args
}

proc gen_fn_def {fn_def} {
    set fn_name [Node_get_val [lindex $fn_def 1]]
    set fn_args [to_fn_args [Node_get_val [lindex $fn_def 2]]]
    set stmts   [Node_get_val [lindex $fn_def 3]]

    set lvars {}

    puts [format "label %s" $fn_name]
    asm_prologue

    foreach stmt_node $stmts {
        set stmt [Node_get_val $stmt_node]
        set stmt_head [head_val $stmt]
        if {$stmt_head == "var"} {
            set name [Node_get_val [lindex $stmt 1]]
            lappend lvars $name
            gen_var $fn_args $lvars $stmt
        } else {
            gen_stmt $fn_args $lvars $stmt
        }
    }

    asm_epilogue
    puts "  ret"
}

proc gen_top_stmts {top_stmts} {
    foreach top_stmt $top_stmts {
        gen_fn_def [Node_get_val $top_stmt]
    }
}

proc gen_builtin_set_vram {} {
    puts "label set_vram"
    asm_prologue
    puts "  set_vram \[bp:2\] \[bp:3\]"
    asm_epilogue
    puts "  ret"
}

proc gen_builtin_get_vram {} {
    puts "label get_vram"
    asm_prologue
    puts "  get_vram \[bp:2\] reg_a"
    asm_epilogue
    puts "  ret"
}

proc codegen {ast} {
    puts "  call main"
    puts "  exit"

    set top_stmts [List_rest $ast 1]
    gen_top_stmts $top_stmts

    puts "#>builtins"
    gen_builtin_set_vram
    gen_builtin_get_vram
    puts "#<builtins"
}

set src [read_stdin_all]
set ast [json_parse $src]
codegen $ast
