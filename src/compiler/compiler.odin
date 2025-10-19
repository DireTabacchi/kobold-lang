package compiler

// TODO: compile Else-If and Else statements

import "core:fmt"
import "core:strconv"
import "core:strings"
import "core:unicode/utf8"

import "kobold:ast"
import "kobold:code"
import "kobold:object"
import "kobold:symbol"
import "kobold:tokenizer"

Op_Code :: code.Op_Code

Compiler :: struct {
    chunk: code.Chunk,
    globals: [dynamic]object.Global,
    locals: [dynamic]object.Local,

    curr_scope: int,

    sym_table: ^symbol.Symbol_Table,
}

compiler_init :: proc(comp: ^Compiler) {
    comp.sym_table = symbol.new()
}

compiler_destroy :: proc(comp: ^Compiler) {
    code.chunk_destroy(&comp.chunk)
    delete(comp.globals)
    delete(comp.locals)
    symbol.destroy(comp.sym_table)
}

compile :: proc(comp: ^Compiler, prog: ^ast.Program) {
    for statement in prog.stmts {
        compile_statement(comp, statement.derived_statement)
    }
    emit_byte(&comp.chunk, byte(Op_Code.RET))
    fmt.println("=== Finished Compilation ===")
}

compile_statement :: proc(comp: ^Compiler, stmt: ast.Any_Statement) {
    #partial switch st in stmt {
        case ^ast.Declarator:
            if comp.curr_scope == 0 {
                idx : u16 = u16(len(comp.globals))
                make_global(comp, st.name, st.type.derived_type.(^ast.Builtin_Type).type, st.mutable)
                if st.value != nil {
                    compile_expression(comp, st.value.derived_expression)
                    emit_byte(&comp.chunk, byte(Op_Code.SETG))
                    emit_bytes(&comp.chunk, idx)
                }
            } else {
                idx : u16 = u16(len(comp.locals))
                make_local(comp, st.name, st.type.derived_type.(^ast.Builtin_Type).type, st.mutable)
                if st.value != nil {
                    compile_expression(comp, st.value.derived_expression)
                } else {
                    decl_type := st.type.derived_type.(^ast.Builtin_Type).type
                    emit_constant(&comp.chunk, decl_type)
                }
                emit_byte(&comp.chunk, byte(Op_Code.SETL))
                emit_bytes(&comp.chunk, idx)
            }
        case ^ast.Assignment_Statement:
            _, scope, idx := resolve_variable(comp, st.name)
            compile_expression(comp, st.value.derived_expression)
            if scope == 0 {
                emit_byte(&comp.chunk, byte(Op_Code.SETG))
            } else {
                emit_byte(&comp.chunk, byte(Op_Code.SETL))
            }
            emit_bytes(&comp.chunk, u16(idx))
        case ^ast.Expression_Statement:
            compile_expression(comp, st.expr.derived_expression)
        case ^ast.If_Statement:
            compile_expression(comp, st.cond.derived_expression)
            else_jump := emit_jump(&comp.chunk, byte(Op_Code.JF))
            begin_scope(comp)
            for s in st.consequent {
                compile_statement(comp, s.derived_statement)
            }
            end_scope(comp)
            if st.alternative != nil {
                end_jump := emit_jump(&comp.chunk, byte(Op_Code.JMP))
                patch_jump(&comp.chunk, else_jump)
                compile_statement(comp, st.alternative.derived_statement)
                patch_jump(&comp.chunk, end_jump)
            } else {
                patch_jump(&comp.chunk, else_jump)
            }
        case ^ast.Else_If_Statement:
            compile_expression(comp, st.cond.derived_expression)
            else_jump := emit_jump(&comp.chunk, byte(Op_Code.JF))
            begin_scope(comp)
            for s in st.consequent {
                compile_statement(comp, s.derived_statement)
            }
            end_scope(comp)
            if st.alternative != nil {
                end_jump := emit_jump(&comp.chunk, byte(Op_Code.JMP))
                patch_jump(&comp.chunk, else_jump)
                compile_statement(comp,st.alternative.derived_statement)
                patch_jump(&comp.chunk, end_jump)
            } else {
                patch_jump(&comp.chunk, else_jump)
            }
        case ^ast.Else_Statement:
            begin_scope(comp)
            for s in st.consequent {
                compile_statement(comp, s.derived_statement)
            }
    }
}

make_global :: proc(comp: ^Compiler, name: string, type: tokenizer.Token_Kind, mutable: bool) {
    sym := symbol.Symbol{ name, type, mutable, comp.curr_scope, len(comp.globals) }
    append(&comp.sym_table.symbols, sym)

    val: object.Global
    #partial switch sym.type {
    case .Type_Integer:
        val.type = .Integer
        val.value = i64(0)
    case .Type_Unsigned_Integer:
        val.type = .Unsigned_Integer
        val.value = u64(0)
    case .Type_Float:
        val.type = .Float
        val.value = 0.0
    case .Type_Boolean:
        val.type = .Boolean
        val.value = false
    case .Type_String:
        val.type = .String
        val.value = ""
    case .Type_Rune:
        val.type = .Rune
        val.value = rune(0)
    }
    val.mutable = sym.mutable
    append(&comp.globals, val)
}

make_local :: proc(comp: ^Compiler, name: string, type: tokenizer.Token_Kind, mutable: bool) {
    sym := symbol.Symbol{ name, type, mutable, comp.curr_scope, len(comp.locals) }
    append(&comp.sym_table.symbols, sym)

    val: object.Local
    #partial switch sym.type {
    case .Type_Integer:
        val.type = .Integer
        val.value = i64(0)
    case .Type_Unsigned_Integer:
        val.type = .Unsigned_Integer
        val.value = u64(0)
    case .Type_Float:
        val.type = .Float
        val.value = 0.0
    case .Type_Boolean:
        val.type = .Boolean
        val.value = false
    case .Type_String:
        val.type = .String
        val.value = ""
    case .Type_Rune:
        val.type = .Rune
        val.value = rune(0)
    }
    val.mutable = sym.mutable
    val.scope = comp.curr_scope
    append(&comp.locals, val)
}

resolve_variable :: proc(c: ^Compiler, name: string) -> (val: object.Value, scope: int, idx: int) {
    sym, _ := resolve_symbol(c, name)
    if sym.scope == 0 {
        global := c.globals[sym.id]
        val.type = global.type
        val.value = global.value
        val.mutable = global.mutable
        scope = 0
        idx = sym.id
    } else {
        local := c.locals[sym.id]
        val.type = local.type
        val.value = local.value
        val.mutable = local.mutable
        scope = sym.scope
        idx = sym.id
    }
    return
}

//resolve_global :: proc(c: ^Compiler, global_name: string) -> (val:object.Value, idx: int) {
//    val, idx = resolve_symbol(c, global_name)
//    val.value = c.globals[idx].value
//    return
//}

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
        case .Eq:
            emit_byte(&comp.chunk, byte(Op_Code.EQ))
        case .Neq:
            emit_byte(&comp.chunk, byte(Op_Code.NEQ))
        case .Lt:
            emit_byte(&comp.chunk, byte(Op_Code.LSSR))
        case .Gt:
            emit_byte(&comp.chunk, byte(Op_Code.GRTR))
        case .Leq:
            emit_byte(&comp.chunk, byte(Op_Code.LEQ))
        case .Geq:
            emit_byte(&comp.chunk, byte(Op_Code.GEQ))
        case .Logical_And:
            emit_byte(&comp.chunk, byte(Op_Code.LAND))
        case .Logical_Or:
            emit_byte(&comp.chunk, byte(Op_Code.LOR))
        }
    case ^ast.Unary_Expression:
        compile_expression(comp, e.expr.derived_expression)
        #partial switch e.op.type {
        case .Minus:
            emit_byte(&comp.chunk, byte(Op_Code.NEG))
        case .Not:
            emit_byte(&comp.chunk, byte(Op_Code.NOT))
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
        _, scope, idx := resolve_variable(comp, e.name)
        if scope == 0 {
            emit_byte(&comp.chunk, byte(Op_Code.GETG))
        } else {
            emit_byte(&comp.chunk, byte(Op_Code.GETL))
        }
        emit_bytes(&comp.chunk, u16(idx))
    }
}

emit_constant_val :: proc(chunk: ^code.Chunk, val: object.Value) {
    idx : u16 = u16(len(chunk.constants))
    append(&chunk.constants, val)
    emit_byte(chunk, byte(Op_Code.PUSH))
    emit_bytes(chunk, idx)
}

emit_constant_zero :: proc(chunk: ^code.Chunk, type: tokenizer.Token_Kind) {
    val: object.Value
    val.mutable = true
    #partial switch type {
    case .Type_Integer:
        val.type = .Integer
        val.value = i64(0)
    case .Type_Unsigned_Integer:
        val.type = .Unsigned_Integer
        val.value = u64(0)
    case .Type_Float:
        val.type = .Float
        val.value = f64(0)
    case .Type_Boolean:
        val.type = .Boolean
        val.value = false
    case .Type_String:
        val.type = .String
        val.value = ""
    case .Type_Rune:
        val.type = .Rune
        val.value = rune(0)
    }

    emit_constant_val(chunk, val)
}

emit_constant :: proc{
    emit_constant_val,
    emit_constant_zero,
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

emit_jump :: proc(chunk: ^code.Chunk, b: byte) -> u16 {
    append(&chunk.code, b)
    loc := u16(len(chunk.code))
    emit_bytes(chunk, 0xFFFF)
    return loc
}

patch_jump :: proc(chunk: ^code.Chunk, loc: u16) {
    lo : u8 = cast(u8)((len(chunk.code)-1) & 0x00FF)
    hi : u8 = cast(u8)((len(chunk.code)-1) >> 8)
    chunk.code[loc] = hi
    chunk.code[loc+1] = lo
}

resolve_symbol :: proc(c: ^Compiler, sym_name: string) -> (sym: symbol.Symbol, resolved: bool) {
    sym, resolved = symbol.symbol_exists(sym_name, c.sym_table^)
    return
}

begin_scope :: proc(comp: ^Compiler) {
    comp.curr_scope += 1
    comp.sym_table = symbol.new(comp.sym_table)
}

end_scope :: proc(comp: ^Compiler) {
    for i := len(comp.locals) - 1; i >= 0; i -= 1 {
        if comp.locals[i].scope == comp.curr_scope {
            pop(&comp.locals)
            emit_byte(&comp.chunk, byte(Op_Code.POP))
        }
    }
    comp.curr_scope -= 1
    end_table := comp.sym_table
    comp.sym_table = comp.sym_table.outer
    symbol.destroy(end_table)
}
