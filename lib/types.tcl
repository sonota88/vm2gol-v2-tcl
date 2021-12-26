proc Node_new {type val} {
    set node {}
    lappend node $type
    lappend node $val
    return $node
}

proc Node_new_int {val} {
    Node_new "int" $val
}

proc Node_new_str {val} {
    Node_new "str" $val
}

proc Node_new_list {val} {
    Node_new "list" $val
}

proc Node_get_type {node} {
    return [lindex $node 0]
}

proc Node_get_val {node} {
    return [lindex $node 1]
}

# --------------------------------

proc List_rest {xs i} {
    set _i 0
    set newxs {}

    foreach x $xs {
        if {$i <= $_i} {
            lappend newxs $x
        }
        set _i [expr $_i + 1]
    }

    return $newxs
}
