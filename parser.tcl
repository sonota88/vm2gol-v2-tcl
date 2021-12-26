# -*- comment-start: "#" -*-

#include lib/utils.tcl
#end_include

#include lib/types.tcl
#end_include

#include lib/json.tcl
#end_include

set tokens {}
set pos 0

# --------------------------------

proc Token_get_kind {t} {
    set node [lindex $t 1]
    return [Node_get_val $node]
}

proc Token_get_val {t} {
    set node [lindex $t 2]
    return [Node_get_val $node]
}

# --------------------------------

proc read_tokens {} {
    global tokens
    set i 0

    while true {
        set line [gets stdin]
        if {$line == ""} {
            break
        }

        set token [json_parse $line]
        lappend tokens $token
    }
}

proc peek {i} {
    global tokens
    global pos
    return [lindex $tokens [expr $pos + $i]]
}

proc peek_val {i} {
    set t [peek $i]
    set node [lindex $t 2]
    return [Node_get_val $node]
}

proc incr_pos {} {
    global pos
    incr pos
}

proc consume {exp} {
    set val [peek_val 0]
    if {$val == $exp} {
        incr_pos
    } else {
        error [format "consume: exp (%s) act (%s)" $exp $val]
    }
}

# --------------------------------


proc _parse_expr_factor {} {
    set t [peek 0]
    set kind [Token_get_kind $t]

    if {$kind == "int"} {
        incr_pos
        set val [Token_get_val $t]
        return [Node_new_int $val]
    } elseif {$kind == "ident"} {
        incr_pos
        set val [Token_get_val $t]
        return [Node_new_str $val]
    } elseif {$kind == "sym"} {
        consume "("
        set expr_node [parse_expr]
        consume ")"
        return $expr_node
    } else {
        error [format "parse_expr: unsupported kind (%s)" $t]
    }
}

proc is_binop {val} {
    if {
        $val == "+"
        || $val == "*"
        || $val == "=="
        || $val == "!="
    } {
        return true
    } else {
        return false
    }
}

proc parse_expr {} {
    set _expr [_parse_expr_factor]

    while {[is_binop [peek_val 0]]} {
        set op [peek_val 0]
        incr_pos
        set expr_r [_parse_expr_factor]

        set _expr_temp {}
        lappend _expr_temp [Node_new_str $op]
        lappend _expr_temp $_expr
        lappend _expr_temp $expr_r

        set _expr [Node_new_list $_expr_temp]
    }

    return $_expr
}

proc parse_set {} {
    consume "set"

    set var_name [peek_val 0]
    incr_pos

    consume "="

    set _expr [parse_expr]

    consume ";"

    set stmt {}
    lappend stmt [Node_new_str "set"]
    lappend stmt [Node_new_str $var_name]
    lappend stmt $_expr

    return $stmt
}

proc _parse_arg {} {
    set t [peek 0]
    set kind [Token_get_kind $t]
    set val  [Token_get_val $t]
    incr_pos

    if {$kind == "ident"} {
        return [Node_new_str $val]
    } elseif {$kind == "int"} {
        return [Node_new_int $val]
    } else {
        error [format "PANIC 372 (%s)" $kind]
    }
}

proc parse_args {} {
    set args {}
    set val [peek_val 0]

    if {$val == ")"} {
        return $args
    }

    lappend args [_parse_arg]

    while {[peek_val 0] == ","} {
        consume ","
        lappend args [_parse_arg]
    }

    return $args
}

proc _parse_funcall {} {
    set fn_name [peek_val 0]
    incr_pos

    consume "("
    set args [parse_args]
    consume ")"

    set funcall {}
    lappend funcall [Node_new_str $fn_name]
    foreach arg $args {
        lappend funcall $arg
    }

    return $funcall
}

proc parse_call {} {
    consume "call"

    set funcall [_parse_funcall]

    consume ";"

    set stmt {}
    lappend stmt [Node_new_str "call"]
    foreach node $funcall {
        lappend stmt $node
    }

    return $stmt
}

proc parse_call_set {} {
    consume "call_set"

    set var_name [peek_val 0]
    incr_pos

    consume "="

    set funcall [_parse_funcall]

    consume ";"

    set stmt {}
    lappend stmt [Node_new_str "call_set"]
    lappend stmt [Node_new_str $var_name]
    lappend stmt [Node_new_list $funcall]
    return $stmt
}

proc parse_return {} {
    consume "return"

    set stmt {}
    lappend stmt [Node_new_str "return"]

    if {[peek_val 0] != ";"} {
        lappend stmt [parse_expr]
    }

    consume ";"

    return $stmt
}

proc parse_while {} {
    consume "while"

    consume "("
    set expr_node [parse_expr]
    consume ")"

    consume "\{"
    set stmts [parse_stmts]
    consume "\}"

    set stmt {}
    lappend stmt [Node_new_str "while"]
    lappend stmt $expr_node
    lappend stmt [Node_new_list $stmts]

    return $stmt
}

proc _parse_when_clause {} {
    consume "when"

    set when_clause {}

    consume "("
    lappend when_clause [parse_expr]
    consume ")"

    consume "\{"
    set stmts [parse_stmts]
    consume "\}"

    foreach stmt_node $stmts {
        lappend when_clause $stmt_node
    }

    return $when_clause
}

proc parse_case {} {
    consume "case"

    set stmt {}
    lappend stmt [Node_new_str "case"]

    while {[peek_val 0] == "when"} {
        lappend stmt [Node_new_list [_parse_when_clause]]
    }

    return $stmt
}

proc parse_vm_comment {} {
    consume "_cmt"
    consume "("

    set cmt [peek_val 0]
    incr_pos

    consume ")"
    consume ";"

    set stmt {}
    lappend stmt [Node_new_str "_cmt"]
    lappend stmt [Node_new_str $cmt]

    return $stmt
}

proc parse_debug {} {
    consume "_debug"
    consume "("
    consume ")"
    consume ";"

    set stmt {}
    lappend stmt [Node_new_str "_debug"]

    return $stmt
}

proc parse_stmt {} {
    set t [peek 0]
    set val [peek_val 0]

    if {$val == "set"} {
        parse_set
    } elseif {$val == "call"} {
        parse_call
    } elseif {$val == "call_set"} {
        parse_call_set
    } elseif {$val == "return"} {
        parse_return
    } elseif {$val == "while"} {
        parse_while
    } elseif {$val == "case"} {
        parse_case
    } elseif {$val == "_cmt"} {
        parse_vm_comment
    } elseif {$val == "_debug"} {
        parse_debug
    } else {
        error [format "parse_stmt: unsupported stmt (%s)" $t]
    }
}

proc parse_stmts {} {
    set stmts {}

    while {[peek_val 0] != "\}"} {
        lappend stmts [Node_new_list [parse_stmt]]
    }

    return $stmts
}

proc parse_var {} {
    consume "var"

    set var_name [peek_val 0]
    incr_pos

    set _expr ""
    if {[peek_val 0] == "="} {
        consume "="
        set _expr [parse_expr]
    }
    consume ";"

    set stmt {}
    lappend stmt [Node_new_str "var"]
    lappend stmt [Node_new_str $var_name]
    if {$_expr != ""} {
        lappend stmt $_expr
    }

    return $stmt
}

proc parse_func_def {} {
    consume "func"

    set fn_name [peek_val 0]
    incr_pos

    consume "("
    set fn_args [parse_args]
    consume ")"

    consume "\{"

    set stmts {}
    while {[peek_val 0] != "\}"} {
        if {[peek_val 0] == "var"} {
            set stmt [parse_var]
        } else {
            set stmt [parse_stmt]
        }
        lappend stmts [Node_new_list $stmt]
    }

    consume "\}"

    set fn {}
    lappend fn [Node_new_str "func"]
    lappend fn [Node_new_str $fn_name]
    lappend fn [Node_new_list $fn_args]
    lappend fn [Node_new_list $stmts]

    return $fn
}

proc parse_top_stmts {} {
    set top_stmts {}

    while {[peek_val 0] == "func"} {
        set fn_def [parse_func_def]
        lappend top_stmts [Node_new_list $fn_def]
    }

    return $top_stmts
}

proc parse {} {
    set root {}
    lappend root [Node_new_str "top_stmts"]

    set top_stmts [parse_top_stmts]
    foreach top_stmt $top_stmts {
        lappend root $top_stmt
    }

    return $root
}

read_tokens
set ast [parse]
json_print $ast
