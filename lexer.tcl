source lib/utils.tcl

proc sym_size {rest} {
    set cc [substring $rest 0 2]

    if {
        $cc == "=="
        || $cc == "!="
    } {
        return 2
    }

    set c [substring $rest 0 1]
    if {
        $c == "("
        || $c == ")"
        || $c == "\{"
        || $c == "\}"
        || $c == ";"
        || $c == "="
        || $c == ","
        || $c == "+"
        || $c == "*"
    } {
        return 1
    }

    return 0
}

proc is_kw {s} {
    if {
        $s == "func"
        || $s == "set"
        || $s == "var"
        || $s == "call"
        || $s == "call_set"
        || $s == "return"
        || $s == "case"
        || $s == "when"
        || $s == "while"
        || $s == "_cmt"
        || $s == "_debug"
    } {
        return true
    } else {
        return false
    }
}

proc comment_size {str} {
    if {[substring $str 0 2] != "//"} {
        return 0
    }

    set i 2 ; # skip first chars

    while {$i < [string length $str]} {
        set c [char_at $str $i]

        if {$c == "\n"} {
            return $i
        }

        set i [expr $i + 1]
    }

    return 0
}

proc print_token {lineno kind val} {
    puts "\[$lineno, \"$kind\", \"$val\"]"
}

set lineno 1
set pos 0

set src [read_stdin_all]
set src_size [string length $src]

while {$pos < $src_size} {
    set rest [substring $src $pos $src_size]

    if {0 < [sym_size $rest]} {
        set size [sym_size $rest]
        set val [substring $rest 0 $size]
        print_token $lineno "sym" $val
        set pos [expr $pos + $size]

    } elseif {0 < [str_size $rest]} {
        set size [str_size $rest]
        set val [substring $rest 1 [expr $size + 1]]
        print_token $lineno "str" $val
        set pos [expr $pos + $size + 2]

    } elseif {0 < [comment_size $rest]} {
        set size [comment_size $rest]
        set pos [expr $pos + $size]

    } elseif {0 < [digit_size $rest]} {
        set size [digit_size $rest]
        set val [substring $rest 0 $size]
        print_token $lineno "int" $val
        set pos [expr $pos + $size]

    } elseif {0 < [ident_size $rest]} {
        set size [ident_size $rest]
        set val [substring $rest 0 $size]
        if {[is_kw $val]} {
            set kind "kw"
        } else {
            set kind "ident"
        }
        print_token $lineno $kind $val
        set pos [expr $pos + $size]

    } elseif {[substring $rest 0 1] == " "} {
        incr pos
    } elseif {[substring $rest 0 1] == "\n"} {
        incr pos

    } else {
        puts_kv_e "rest" $rest
        error "PANIC 130"
    }
}

