package compiler

import "core:strconv"

import "kobold:ast"
import "kobold:code"
import "kobold:object"

Compiler :: struct {
    chunk: code.Chunk,
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
    idx : u16 = cast(u16)len(chunk.constants)
    append(&chunk.constants, val)
    emit_byte(chunk, cast(byte)code.Op_Code.Constant_Int)
    emit_bytes(chunk, idx)
}

emit_bytes :: proc(chunk: ^code.Chunk, bytes: u16) {
    lower : u8 = cast(u8)(bytes & 0x00FF)
    upper : u8 = cast(u8)(bytes >> 8)
    emit_byte(chunk, upper)
    emit_byte(chunk, lower)
}

emit_byte :: proc (chunk: ^code.Chunk, b: byte) {
    append(&chunk.code, b)
}
