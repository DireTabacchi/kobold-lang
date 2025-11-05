#+feature dynamic-literals
package procedure

import "core:fmt"
import "core:time"

import "kobold:code"
import "kobold:object"

Proc_Type :: enum {
    Script,
    Proc,
}

Procedure :: struct {
    name: string,       // For debug/error info
    arity: byte,
    type: Proc_Type,
    return_type: object.Value_Kind,
    chunk: code.Chunk,
}

Builtin_Proc :: struct {
    name: string,
    arity: byte,
    varargs: bool,
    return_type: object.Value_Kind,
    exec: proc (args: ..object.Value) -> object.Value,
}

new_proc_main :: proc(type: Proc_Type) -> ^Procedure {
    procedure := new(Procedure)
    procedure.name = "Script"
    procedure.arity = 0
    procedure.type = type
    return procedure
}

new_proc_name :: proc(name: string, arity: byte, type: Proc_Type) -> ^Procedure {
    procedure := new(Procedure)
    procedure.name = name
    procedure.arity = arity
    procedure.type = type
    return procedure
}

new_proc :: proc{
    new_proc_main,
    new_proc_name,
}

builtin_procs := map[string]Builtin_Proc{
    "println" = Builtin_Proc{
        "println", 1, true, object.Value_Kind.Nil, builtin_println,
    },
    "print" = Builtin_Proc{
        "print", 1, true, object.Value_Kind.Nil, builtin_print,
    },
    "len" = Builtin_Proc{
        "len", 1, false, object.Value_Kind.Integer, builtin_array_len,
    },
    "clock" = Builtin_Proc{
        "clock", 0, false, object.Value_Kind.Integer, builtin_clock,
    },
}

builtin_procs_destroy :: proc() {
    delete(builtin_procs)
}

builtin_print :: proc(args: ..object.Value) -> object.Value {
    for arg in args {
        // TODO: Find better way to handle escapes
        #partial switch arg.type {
        case .String:
            if arg.value.(string) == `\n` {
                fmt.print("\n")
            } else {
                fmt.print(arg.value)
            }
        case:
            fmt.print(arg.value)
        }
    }
    return object.Value{ object.Value_Kind.Nil, i64(0), false }
}

builtin_println :: proc(args: ..object.Value) -> object.Value {
    for arg in args {
        // TODO: See builtin_print
        #partial switch arg.type {
        case .String:
            if arg.value.(string) == `\n` {
                fmt.print("\n")
            } else {
                fmt.print(arg.value)
            }
        case:
            fmt.print(arg.value)
        }
    }
    fmt.print("\n")

    return object.Value{ object.Value_Kind.Nil, i64(0), false }
}

builtin_array_len :: proc(args: ..object.Value) -> object.Value {
    arg := args[0]
    arr := arg.value.(object.Array)
    ret_val := object.Value{ object.Value_Kind.Integer, i64(arr.len), false }
    return ret_val
}

builtin_clock :: proc(args: ..object.Value) -> object.Value {
    now := time.now()
    ret_val := object.Value{ object.Value_Kind.Integer, i64(time.time_to_unix_nano(now)), false }
    return ret_val
}
