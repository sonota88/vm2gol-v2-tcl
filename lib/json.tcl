proc _json_parse {json} {
    set i 1 ; # skip first [
    set xs {}

    while {$i < [string length $json]} {
        set rest [string range $json $i [string length $json]]

        if {[string first "\[" $rest 0] == 0} {
            set rv [_json_parse $rest]
            set child [lindex $rv 0]
            set size  [lindex $rv 1]

            lappend xs [Node_new_list $child]

            set i [expr $i + $size]

        } elseif {[string first "\]" $rest 0] == 0} {
            incr i
            break

        } elseif {[string first " " $rest 0] == 0} {
            incr i

        } elseif {[string first "," $rest 0] == 0} {
            incr i

        } elseif {[string first "\n" $rest 0] == 0} {
            incr i

        } elseif {0 < [digit_size $rest]} {
            set size [digit_size $rest]
            set val [substring $rest 0 $size]
            lappend xs [Node_new_int $val]

            set i [expr $i + $size]

        } elseif {0 <= [str_size $rest]} {
            set size [str_size $rest]
            set s [substring $rest 1 [expr $size + 1]]

            lappend xs [Node_new_str $s]

            set i [expr $i + $size + 2]

        } else {
            puts_kv_e "rest" $rest
            error "PANIC"
        }
    }

    set rv {}
    lappend rv $xs
    lappend rv $i
    return $rv
}

proc json_parse {json} {
    set rv [_json_parse $json]
    return [lindex $rv 0]
}

proc print_indent {lv} {
    set i 0
    while {$i < $lv} {
        print "  "
        set i [expr $i + 1]
    }
}

proc _json_print_node {node lv} {
    set type [Node_get_type $node]
    set val [Node_get_val $node]

    print_indent $lv
    if {$type == "int"} {
        print $val
    } elseif {$type == "str"} {
        print "\""
        print $val
        print "\""
    } elseif {$type == "list"} {
        _json_print_list $val $lv
    } else {
        puts_kv_e "node" $node
        error [format "_json_print_list: unsupported type (%s)" $type]
    }
}

proc _json_print_list {xs lv} {
    print "\["

    set i 0
    foreach node $xs {
        if {$i >= 1} {
            print ","
        }
        print "\n"
        _json_print_node $node [expr $lv + 1]
        incr i
    }
    print "\n"

    print_indent $lv
    print "]"
}

proc json_print {data} {
    _json_print_list $data 0
}
