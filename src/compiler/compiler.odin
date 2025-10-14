package compiler

import "core:fmt"
import "core:strconv"
import "core:strings"
import "core:unicode/utf8"

import "kobold:ast"
import "kobold:code"
import "kobold:object"
import "kobold:symbol"
//import "kobold:tokenizer"

Op_Code :: code.Op_Code

Compiler :: struct {
    chunk: code.Chunk,
    globals: [dynamic]object.Value,

    sym_table: []symbol.Symbol,
}

compiler_init :: proc(comp: ^Compiler, syms: []symbol.Symbol) {
    comp.sym_table = syms
}

compiler_destroy :: proc(comp: ^Compiler) {
    code.chunk_destroy(&comp.chunk)
    delete(comp.globals)
}

compile :: proc(comp: ^Compiler, prog: ^ast.Program) {
    for statement in prog.stmts {
        #partial switch stmt in statement.derived_statement {
        case ^ast.Declarator:
            idx : u16 = u16(len(comp.globals))
            make_global(comp, stmt.name)
            if stmt.value != nil {
                compile_expression(comp, stmt.value.derived_expression)
                emit_byte(&comp.chunk, u8(Op_Code.SETG))
                emit_bytes(&comp.chunk, idx)
            }
        case ^ast.Expression_Statement:
            compile_expression(comp, stmt.expr.derived_expression)
        }
    }
    emit_byte(&comp.chunk, byte(Op_Code.RET))
    fmt.println("=== Finished Compilation ===")
}

make_global :: proc(comp: ^Compiler, name: string) {
    val, _ := resolve_symbol(comp, name)
    switch val.type {
    case .Integer:
        val.value = i64(0)
    case .Unsigned_Integer:
        val.value = u64(0)
    case .Float:
        val.value = 0.0
    case .Boolean:
        val.value = false
    case .String:
        val.value = ""
    case .Rune:
        val.value = rune(0)
    }
    append(&comp.globals, val)
}

resolve_symbol :: proc(c: ^Compiler, sym_name: string) -> (val: object.Value, idx: int) {
    for sym in c.sym_table {
        if sym_name == sym.name {
            #partial switch sym.type {
            case .Type_Integer:
                val.type = .Integer
            case .Type_Unsigned_Integer:
                val.type = .Unsigned_Integer
            case .Type_Float:
                val.type = .Float
            case .Type_Boolean:
                val.type = .Boolean
            case .Type_String:
                val.type = .String
            case .Type_Rune:
                val.type = .Rune
            }
            val.mutable = sym.mutable
            idx = sym.id
            break
        }
    }

    return
}

compile_expression :: proc(comp: ^Compiler, expr: ast.Any_Expression) {
    #partial switch e in expr {
    case ^ast.Binary_Expression:
        compile_expression(comp, e.left.derived_expression)
        compile_expression(comp, e.right.derived_expression)
        #partial switch e.op.type {
        case .Plus:
            emit_byte(&comp.chunk, byte(Op_Code.ADD))
        case .Minus:
            emit_byte(&comp.chunk, byte(Op_Code.SUB))
        case .Mult:
            emit_byte(&comp.chunk, byte(Op_Code.MULT))
        case .Div:
            emit_byte(&comp.chunk, byte(Op_Code.DIV))
        case .Mod:
            emit_byte(&comp.chunk, byte(Op_Code.MOD))
        case .Mod_Floor:
            emit_byte(&comp.chunk, byte(Op_Code.MODF))
        }
    case ^ast.Unary_Expression:
        compile_expression(comp, e.expr.derived_expression)
        #partial switch e.op.type {
        case .Minus:
            emit_byte(&comp.chunk, byte(Op_Code.NEG))
        }
    case ^ast.Literal:
        #partial switch e.type {
        case .Integer:
            lit_val, _ := strconv.parse_i64(e.value)
            val := object.Value{ .Integer, lit_val, false }
            emit_constant(&comp.chunk, val)
        case .Unsigned_Integer:
            lit_val, _ := strconv.parse_u64(strings.trim_suffix(e.value, "u"))
            val := object.Value{ .Unsigned_Integer, lit_val, false }
            emit_constant(&comp.chunk, val)
        case .Float:
            lit_val, _ := strconv.parse_f64(e.value)
            val := object.Value{ .Float, lit_val, false }
            emit_constant(&comp.chunk, val)
        case .True, .False:
            lit_val, _ := strconv.parse_bool(e.value)
            val := object.Value{ .Boolean, lit_val, false }
            emit_constant(&comp.chunk, val)
        case .String:
            lit_val := strings.trim(e.value, "\"")
            val := object.Value{ .String, lit_val, false }
            emit_constant(&comp.chunk, val)
        case .Rune:
            lit_val, _ := utf8.decode_rune(strings.trim(e.value, "'"))
            val := object.Value{ .Rune, lit_val, false }
            emit_constant(&comp.chunk, val)
        }
    case ^ast.Identifier:
        _, idx := resolve_symbol(comp, e.name)
        emit_byte(&comp.chunk, byte(Op_Code.GETG))
        emit_bytes(&comp.chunk, u16(idx))
    }
}

emit_constant :: proc (chunk: ^code.Chunk, val: object.Value) {
    idx : u16 = u16(len(chunk.constants))
    append(&chunk.constants, val)
    emit_byte(chunk, byte(Op_Code.PUSHC))
    emit_bytes(chunk, idx)
}

emit_bytes :: proc(chunk: ^code.Chunk, bytes: u16) {
    lo : u8 = cast(u8)(bytes & 0x00FF)
    hi : u8 = cast(u8)(bytes >> 8)
    emit_byte(chunk, hi)
    emit_byte(chunk, lo)
}

emit_byte :: proc (chunk: ^code.Chunk, b: byte) {
    append(&chunk.code, b)
}
