package compiler

import "core:strconv"

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
            compile_expression(comp, stmt.value.derived_expression)
            idx : u16 = u16(len(comp.globals))
            val := resolve_symbol(comp, stmt.name)
            append(&comp.globals, val)
            emit_byte(&comp.chunk, u8(Op_Code.SETG))
            emit_bytes(&comp.chunk, idx)
        case ^ast.Expression_Statement:
            compile_expression(comp, stmt.expr.derived_expression)
        }
    }
    emit_byte(&comp.chunk, byte(Op_Code.RET))
}

resolve_symbol :: proc(c: ^Compiler, sym_name: string) -> object.Value {
    val: object.Value
    for sym in c.sym_table {
        if sym_name == sym.name {
            #partial switch sym.type {
            case .Type_Integer:
                val.type = .Integer
            }
            val.mutable = sym.mutable
            break
        }
    }

    return val
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
        }
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
