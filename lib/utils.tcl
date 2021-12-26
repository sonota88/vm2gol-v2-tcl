proc read_stdin_all {} {
    read stdin
}

proc print {arg} {
    puts -nonewline $arg
}

proc print_e {arg} {
    puts -nonewline stderr $arg
}

proc puts_e {arg} {
    puts stderr $arg
}

proc puts_kv_e {k v} {
    print_e $k
    print_e " ("
    print_e $v
    print_e ")\n"
}

proc char_at {s i} {
    return [string range $s $i $i]
}

proc substring {s from to} {
    return [string range $s $from [expr $to - 1]]
}

proc digit_size {str} {
    set i 0

    while {$i < [string length $str]} {
        set c [char_at $str $i]
        set n [scan $c %c]

        if {48 <= $n && $n <= 57} {
        } elseif {$c == "-"} {
        } else {
            break
        }

        set i [expr $i + 1]
    }

    return $i
}

proc ident_size {str} {
    set i 0

    while {$i < [string length $str]} {
        set c [char_at $str $i]
        set n [scan $c %c]
        # puts_kv_e "n" $n

        if {97 <= $n && $n <= 122} {
            # a..z
        } elseif {48 <= $n && $n <= 57} {
            # 0..9
        } elseif {$c == "_"} {
        } else {
            break
        }

        set i [expr $i + 1]
    }

    return $i
}

proc str_size {str} {
    if {[char_at $str 0] != "\""} {
        return -1
    }

    set i 1 ; # skip first char

    while {$i < [string length $str]} {
        set c [char_at $str $i]

        if {$c == "\""} {
            return [expr $i - 1]
        }

        set i [expr $i + 1]
    }

    return -1
}
