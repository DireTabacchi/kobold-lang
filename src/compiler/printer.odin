package compiler

import "core:fmt"
import "core:strings"

import "kobold:object"
import procs "kobold:object/procedure"

print :: proc(comp: Compiler) {
    print_procedure(comp.main_proc^)
    for p in comp.procs {
        print_procedure(p^)
    }
}

print_procedure :: proc(procedure: procs.Procedure) {
    if procedure.type == .Script {
        fmt.printfln("Script: (%d bytes)", len(procedure.chunk.code))
    } else if procedure.type == .Proc {
        fmt.printfln("Proc %s: (%d bytes)", procedure.name, len(procedure.chunk.code))
    }
    for i := 0; i < len(procedure.chunk.code); i += 1 {
        switch procedure.chunk.code[i] {
        case u8(Op_Code.PUSH):
            hi := procedure.chunk.code[i+1]
            lo := procedure.chunk.code[i+2]
            idx: u16 = (u16(hi) << 8) | u16(lo)
            val := procedure.chunk.constants[idx]
            val_builder, _ := strings.builder_make_none()
            defer strings.builder_destroy(&val_builder)
            write_value(&val_builder, val)
            fmt.printfln("%8X    %-8s %#8X    %- 16v", i, "PUSH", idx, strings.to_string(val_builder))
            i += 2
        case u8(Op_Code.POP):
            fmt.printfln("%8X    %-8s", i, "POP")
        case u8(Op_Code.ADD):
            fmt.printfln("%8X    %-8s", i, "ADD")
        case u8(Op_Code.SUB):
            fmt.printfln("%8X    %-8s", i, "SUB")
        case u8(Op_Code.MULT):
            fmt.printfln("%8X    %-8s", i, "MULT")
        case u8(Op_Code.DIV):
            fmt.printfln("%8X    %-8s", i, "DIV")
        case u8(Op_Code.MOD):
            fmt.printfln("%8X    %-8s", i, "MOD")
        case u8(Op_Code.MODF):
            fmt.printfln("%8X    %-8s", i, "MODF")
        case u8(Op_Code.EQ):
            fmt.printfln("%8X    %-8s", i, "EQ")
        case u8(Op_Code.NEQ):
            fmt.printfln("%8X    %-8s", i, "NEQ")
        case u8(Op_Code.LSSR):
            fmt.printfln("%8X    %-8s", i, "LSSR")
        case u8(Op_Code.GRTR):
            fmt.printfln("%8X    %-8s", i, "GRTR")
        case u8(Op_Code.LEQ):
            fmt.printfln("%8X    %-8s", i, "LEQ")
        case u8(Op_Code.GEQ):
            fmt.printfln("%8X    %-8s", i, "GEQ")
        case u8(Op_Code.LAND):
            fmt.printfln("%8X    %-8s", i, "LAND")
        case u8(Op_Code.LOR):
            fmt.printfln("%8X    %-8s", i, "LOR")
        case u8(Op_Code.NEG):
            fmt.printfln("%8X    %-8s", i, "NEG")
        case u8(Op_Code.NOT):
            fmt.printfln("%8X    %-8s", i, "NOT")
        case u8(Op_Code.CALL):
            hi := procedure.chunk.code[i+1]
            lo := procedure.chunk.code[i+2]
            loc : u16 = (u16(hi) << 8) | u16(lo)
            fmt.printfln("%8X    %-8s %#8X", i, "CALL", loc)
            i += 2
        case u8(Op_Code.CALLBI):
            hi := procedure.chunk.code[i+1]
            lo := procedure.chunk.code[i+2]
            loc : u16 = (u16(hi) << 8) | u16(lo)
            arg_count := procedure.chunk.code[i+3]
            fmt.printfln("%8X    %-8s %#8X    % -6d", i, "CALLBI", loc, arg_count)
            i += 3
        case u8(Op_Code.JMP):
            hi := procedure.chunk.code[i+1]
            lo := procedure.chunk.code[i+2]
            loc : u16 = (u16(hi) << 8) | u16(lo)
            fmt.printfln("%8X    %-8s %#8X", i, "JMP", loc)
            i += 2
        case u8(Op_Code.JF):
            hi := procedure.chunk.code[i+1]
            lo := procedure.chunk.code[i+2]
            loc : u16 = (u16(hi) << 8) | u16(lo)
            fmt.printfln("%8X    %-8s %#8X", i, "JF", loc)
            i += 2
        case u8(Op_Code.SETG):
            hi := procedure.chunk.code[i+1]
            lo := procedure.chunk.code[i+2]
            idx : u16 = (u16(hi) << 8) | u16(lo)
            fmt.printfln("%8X    %-8s %#8X", i, "SETG", idx)
            i += 2
        case u8(Op_Code.GETG):
            hi := procedure.chunk.code[i+1]
            lo := procedure.chunk.code[i+2]
            idx : u16 = (u16(hi) << 8) | u16(lo)
            fmt.printfln("%8X    %-8s %#8X", i, "GETG", idx)
            i += 2
        case u8(Op_Code.SETL):
            hi := procedure.chunk.code[i+1]
            lo := procedure.chunk.code[i+2]
            idx : u16 = (u16(hi) << 8) | u16(lo)
            fmt.printfln("%8X    %-8s %#8X", i, "SETL", idx)
            i += 2
        case u8(Op_Code.GETL):
            hi := procedure.chunk.code[i+1]
            lo := procedure.chunk.code[i+2]
            idx : u16 = (u16(hi) << 8) | u16(lo)
            fmt.printfln("%8X    %-8s %#8X", i, "GETL", idx)
            i += 2
        case u8(Op_Code.BLDARR):
            hi := procedure.chunk.code[i+1]
            lo := procedure.chunk.code[i+2]
            quant : u16 = (u16(hi) << 8) | u16(lo)
            fmt.printfln("%8X    %-8s %- 8d", i, "BLDARR", quant)
            i += 2
        case u8(Op_Code.GETARR):
            fmt.printfln("%8X    %-8s", i, "GETARR")
        case u8(Op_Code.SETARR):
            fmt.printfln("%8X    %-8s", i, "SETARR")
        case u8(Op_Code.RET):
            fmt.printfln("%8X    %-8s", i, "RET")
        }
    }
}

write_value :: proc(builder: ^strings.Builder, value: object.Object) {
    #partial switch value.type {
    case object.Value_Kind.Integer:
        strings.write_i64(builder, value.value.(i64))
    case object.Value_Kind.Unsigned_Integer:
        strings.write_u64(builder, value.value.(u64))
    case object.Value_Kind.Float:
        strings.write_f64(builder, value.value.(f64), 'f')
    case object.Value_Kind.Boolean:
        if value.value.(bool) {
            strings.write_string(builder, "true")
        } else {
            strings.write_string(builder, "false")
        }
    case object.Value_Kind.String:
        strings.write_quoted_string(builder, value.value.(string))
    case object.Value_Kind.Rune:
        strings.write_rune(builder, value.value.(rune))
    case object.Value_Kind.Array:
        arr := value.value.(object.Array)
        strings.write_string(builder, "{ ")
        for v, i in arr.data {
            write_value(builder, v)
            if i == 9 && i < arr.len - 1 {
                strings.write_string(builder, ", ...")
                break
            }
            if i < arr.len - 1 {
                strings.write_string(builder, ", ")
            }
        }
        strings.write_string(builder, " }")
    }
}
