package compiler

import "core:strconv"

import "kobold:ast"
import "kobold:code"
import "kobold:object"
//import "kobold:tokenizer"

Compiler :: struct {
    chunk: code.Chunk,
}

compiler_destroy :: proc(comp: ^Compiler) {
    code.chunk_destroy(&comp.chunk)
}

compile :: proc(comp: ^Compiler, prog: ^ast.Program) {
    for statement in prog.stmts {
        #partial switch stmt in statement.derived_statement {
        case ^ast.Expression_Statement:
            compile_expression(comp, stmt.expr.derived_expression)
        }
    }
}

compile_expression :: proc(comp: ^Compiler, expr: ast.Any_Expression) {
    #partial switch e in expr {
    case ^ast.Binary_Expression:
        compile_expression(comp, e.left.derived_expression)
        compile_expression(comp, e.right.derived_expression)
        #partial switch e.op.type {
        case .Plus:
            emit_byte(&comp.chunk, byte(code.Op_Code.Add))
        case .Minus:
            emit_byte(&comp.chunk, byte(code.Op_Code.Subtract))
        case .Mult:
            emit_byte(&comp.chunk, byte(code.Op_Code.Multiply))
        case .Div:
            emit_byte(&comp.chunk, byte(code.Op_Code.Divide))
        }
    case ^ast.Literal:
        #partial switch e.type {
        case .Integer:
            lit_val, _ := strconv.parse_i64(e.value)
            val := object.Value{ .Integer, lit_val }
            emit_constant(&comp.chunk, val)
        }
    }
}

emit_constant :: proc (chunk: ^code.Chunk, val: object.Value) {
    idx : u16 = u16(len(chunk.constants))
    append(&chunk.constants, val)
    emit_byte(chunk, cast(byte)code.Op_Code.PushC)
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
