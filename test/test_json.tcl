source lib/utils.tcl
source lib/types.tcl
source lib/json.tcl

proc test_1 {} {
    set data {}
    json_print $data
}

proc test_2 {} {
    set data {
        {"int" 1}
    }
    json_print $data
}

proc test_3 {} {
    set data {
        {"str" "fdsa"}
    }
    json_print $data
}

proc test_4 {} {
    set data {
        {"int" -123}
    }
    json_print $data
}

proc test_5 {} {
    set data {
        {"int" 123}
        {"str" "fdsa"}
    }
    json_print $data
}

proc test_6 {} {
    set data {
        {"list" {}}
    }
    json_print $data
}

proc test_7 {} {
    set data {
        {"int" 1}
        {"str" "a"}
        {"list" {
            {"int" 2}
            {"str" "b"}
        }}
        {"int" 3}
        {"str" "c"}
    }
    json_print $data
}

proc test_8 {} {
    set data {
        {"str" "漢字"}
    }
    json_print $data
}

# test_1
# test_2
# test_3
# test_4
# test_5
# test_6
# test_7
# test_8

set json [read_stdin_all]
set data [json_parse $json]
json_print $data
