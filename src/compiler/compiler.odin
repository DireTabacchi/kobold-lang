package compiler

import "core:fmt"
import "core:mem"
import "core:strconv"
import "core:strings"
import "core:unicode/utf8"

import "kobold:ast"
import "kobold:code"
import "kobold:object"
import proc_lib "kobold:object/procedure"
import "kobold:symbol"
import "kobold:tokenizer"

Op_Code :: code.Op_Code

Compiler :: struct {
    main_proc: ^proc_lib.Procedure,

    globals: [dynamic]object.Global,
    locals: [dynamic]object.Local,
    procs: [dynamic]^proc_lib.Procedure,
    builtin_procs: [dynamic]^proc_lib.Builtin_Proc,

    curr_scope: int,
    loop_scopes: [dynamic]int,
    proc_scopes: [dynamic]int,
    break_stats: [dynamic]Break_Stat,
    flag_break: bool,

    sym_table: ^symbol.Symbol_Table,
}

Break_Stat :: struct {
    loc: u16,
    scope: int,
    local_count: int,
}

compiler_init :: proc(comp: ^Compiler) {
    comp.sym_table = symbol.new()
    comp.main_proc = proc_lib.new_proc(.SCRIPT)

    append(&comp.builtin_procs, &proc_lib.builtin_procs["println"])
    append(&comp.builtin_procs, &proc_lib.builtin_procs["print"])
    append(&comp.builtin_procs, &proc_lib.builtin_procs["len"])
    append(&comp.builtin_procs, &proc_lib.builtin_procs["clock"])
}

compiler_destroy :: proc(comp: ^Compiler) {
    for p in comp.procs {
        code.chunk_destroy(&p.chunk)
        free(p)
    }
    code.chunk_destroy(&comp.main_proc.chunk)
    free(comp.main_proc)
    delete(comp.procs)
    for len(comp.builtin_procs) > 0 {
        pop(&comp.builtin_procs)
    }
    delete(comp.builtin_procs)
    for g in comp.globals {
        if g.type == object.Value_Kind.ARRAY {
            arr, _ := g.value.(object.Array)
            delete(arr.data)
        }
    }
    delete(comp.globals)
    delete(comp.locals)
    delete(comp.loop_scopes)
    delete(comp.proc_scopes)
    delete(comp.break_stats)
    symbol.table_destroy(comp.sym_table)
}

compile :: proc(comp: ^Compiler, prog: ^ast.Program) {
    for statement in prog.stmts {
        compile_statement(comp, comp.main_proc, statement.derived_statement)
    }
    emit_byte(&comp.main_proc.chunk, byte(Op_Code.RET))
    when ODIN_DEBUG {
        fmt.println("=== Finished Compilation ===")
    }
}

compile_statement :: proc(comp: ^Compiler, curr_proc: ^proc_lib.Procedure, stmt: ast.Any_Statement) {
    #partial switch st in stmt {
    case ^ast.Declarator:
        set_op: Op_Code
        idx: u16
        if comp.curr_scope == 0 {
            set_op = Op_Code.SETG
            idx = u16(len(comp.globals))
            make_global(comp, st.name, st.type, st.mutable)
        } else {
            set_op = Op_Code.SETL
            idx = u16(len(comp.locals))
            make_local(comp, st.name, st.type, st.mutable)
        }

        if st.value != nil {
            compile_expression(comp, curr_proc, st.value.derived_expression)
            if arr_type, is_arr := st.type.derived_type.(^ast.Array_Type); is_arr {
                emit_byte(&curr_proc.chunk, byte(Op_Code.BLDARR))
                emit_bytes(&curr_proc.chunk, u16(arr_type.length))
            }
        } else {
            emit_constant(&curr_proc.chunk, st.type^)
        }
        emit_byte(&curr_proc.chunk, byte(set_op))
        emit_bytes(&curr_proc.chunk, idx)

    case ^ast.Type_Declarator:
        symbol_type := symbol.make_symbol_type(st.type)
        type_symbol := symbol.Symbol{ st.name, symbol_type, false, comp.curr_scope, len(comp.sym_table.symbols) }
        append(&comp.sym_table.symbols, type_symbol)

    case ^ast.Assignment_Statement:
        scope, idx: int
        #partial switch ident in st.ident.derived_expression {
        case ^ast.Identifier:
            _, scope, idx = resolve_variable(comp, ident.name)

        case ^ast.Array_Accessor:
            _, scope, idx = resolve_variable(comp, ident.ident)
        }
        compile_expression(comp, curr_proc, st.value.derived_expression)
        set_op, get_op: Op_Code
        if scope == 0 {
            set_op = .SETG
            get_op = .GETG
        } else {
            set_op = .SETL
            get_op = .GETL
        }
        #partial switch ident in st.ident.derived_expression {
        case ^ast.Array_Accessor:
            compile_expression(comp, curr_proc, ident.index.derived_expression)
            emit_byte(&curr_proc.chunk, byte(get_op))
            emit_bytes(&curr_proc.chunk, u16(idx))
            emit_byte(&curr_proc.chunk, byte(Op_Code.SETARR))
        }
        emit_byte(&curr_proc.chunk, byte(set_op))
        emit_bytes(&curr_proc.chunk, u16(idx))

    case ^ast.Assignment_Operation_Statement:
        scope, idx: int
        #partial switch ident in st.ident.derived_expression {
        case ^ast.Identifier:
            _, scope, idx = resolve_variable(comp, ident.name)
        case ^ast.Array_Accessor:
            _, scope, idx = resolve_variable(comp, ident.ident)
        }
        set_op, get_op: Op_Code
        if scope == 0 {
            set_op = .SETG
            get_op = .GETG
        } else {
            set_op = .SETL
            get_op = .GETL
        }
        emit_byte(&curr_proc.chunk, byte(get_op))
        emit_bytes(&curr_proc.chunk, u16(idx))
        compile_expression(comp, curr_proc, st.value.derived_expression)
        #partial switch st.op {
        case .ASSIGN_ADD:
            emit_byte(&curr_proc.chunk, byte(Op_Code.ADD))
        case .ASSIGN_MINUS:
            emit_byte(&curr_proc.chunk, byte(Op_Code.SUB))
        case .ASSIGN_MULT:
            emit_byte(&curr_proc.chunk, byte(Op_Code.MULT))
        case .ASSIGN_DIV:
            emit_byte(&curr_proc.chunk, byte(Op_Code.DIV))
        case .ASSIGN_MOD:
            emit_byte(&curr_proc.chunk, byte(Op_Code.MOD))
        case .ASSIGN_MOD_FLOOR:
            emit_byte(&curr_proc.chunk, byte(Op_Code.MODF))
        }
        emit_byte(&curr_proc.chunk, byte(set_op))
        emit_bytes(&curr_proc.chunk, u16(idx))

    case ^ast.Expression_Statement:
        compile_expression(comp, curr_proc, st.expr.derived_expression)

    case ^ast.If_Statement:
        compile_expression(comp, curr_proc, st.cond.derived_expression)
        else_jump := emit_jump(&curr_proc.chunk, byte(Op_Code.JF))
        begin_scope(comp)
        for s in st.consequent {
            compile_statement(comp, curr_proc, s.derived_statement)
        }
        end_scope(comp, curr_proc, false)
        if st.alternative != nil {
            end_jump := emit_jump(&curr_proc.chunk, byte(Op_Code.JMP))
            patch_jump(&curr_proc.chunk, else_jump)
            compile_statement(comp, curr_proc, st.alternative.derived_statement)
            patch_jump(&curr_proc.chunk, end_jump)
        } else {
            patch_jump(&curr_proc.chunk, else_jump)
        }

    case ^ast.Else_If_Statement:
        compile_expression(comp, curr_proc, st.cond.derived_expression)
        else_jump := emit_jump(&curr_proc.chunk, byte(Op_Code.JF))
        begin_scope(comp)
        for s in st.consequent {
            compile_statement(comp, curr_proc, s.derived_statement)
        }
        end_scope(comp, curr_proc, false)
        if st.alternative != nil {
            end_jump := emit_jump(&curr_proc.chunk, byte(Op_Code.JMP))
            patch_jump(&curr_proc.chunk, else_jump)
            compile_statement(comp, curr_proc, st.alternative.derived_statement)
            patch_jump(&curr_proc.chunk, end_jump)
        } else {
            patch_jump(&curr_proc.chunk, else_jump)
        }

    case ^ast.Else_Statement:
        begin_scope(comp)
        for s in st.consequent {
            compile_statement(comp, curr_proc, s.derived_statement)
        }
        end_scope(comp, curr_proc, false)

    case ^ast.For_Statement:
        begin_scope(comp)

        append(&comp.loop_scopes, comp.curr_scope)

        if st.decl != nil {
            compile_statement(comp, curr_proc, st.decl.derived_statement)
        }

        cond_loc := u16(len(curr_proc.chunk.code)) - 1
        conditional_defined := st.cond_expr != nil
        exit_jump: u16
        if conditional_defined {
            compile_expression(comp, curr_proc, st.cond_expr.derived_expression)
            exit_jump = emit_jump(&curr_proc.chunk, byte(Op_Code.JF))
        }

        begin_scope(comp)
        for s in st.body {
            compile_statement(comp, curr_proc, s.derived_statement)
        }
        end_scope(comp, curr_proc, false)

        if st.cont_stmt != nil {
            compile_statement(comp, curr_proc, st.cont_stmt.derived_statement)
        }

        repeat_jump := emit_jump(&curr_proc.chunk, byte(Op_Code.JMP))
        patch_jump(&curr_proc.chunk, repeat_jump, cond_loc)

        if comp.flag_break {
            break_locals: int
            for br_idx := len(comp.break_stats) - 1; br_idx >= 0 && comp.break_stats[br_idx].scope == comp.curr_scope; br_idx -= 1 {
                break_locals = comp.break_stats[br_idx].local_count > break_locals ? comp.break_stats[br_idx].local_count : break_locals
            }
            for break_locals > 0 {
                emit_byte(&curr_proc.chunk, byte(Op_Code.POP))
                break_locals -= 1
            }
            for br_idx := len(comp.break_stats) - 1; br_idx >= 0 && comp.break_stats[br_idx].scope == comp.curr_scope; br_idx -= 1 {
                jmp_loc := u16(len(curr_proc.chunk.code) - comp.break_stats[br_idx].local_count) - 1
                patch_jump(&curr_proc.chunk, comp.break_stats[br_idx].loc, jmp_loc)
                pop(&comp.break_stats)
            }
            comp.flag_break = len(comp.break_stats) > 0
        }

        if conditional_defined {
            patch_jump(&curr_proc.chunk, exit_jump)
        }
        pop(&comp.loop_scopes)
        end_scope(comp, curr_proc, false)

    case ^ast.Break_Statement:
        comp.flag_break = true
        break_stat: Break_Stat
        breaking_scope_idx := len(comp.loop_scopes) - 1
        break_stat.scope = comp.loop_scopes[breaking_scope_idx]
        for i := len(comp.locals) - 1; i >= 0 && comp.locals[i].scope > break_stat.scope; i -= 1 {
            break_stat.local_count += 1
        }
        break_stat.loc = emit_jump(&curr_proc.chunk, byte(Op_Code.JMP))
        append(&comp.break_stats, break_stat)

    case ^ast.Procedure_Declarator:
        new_proc := proc_lib.new_proc(st.name, byte(len(st.params)), proc_lib.Proc_Type.PROC)
        if st.return_type == nil {
            new_proc.return_type = object.Value_Kind.NIL
        } else {
            //return_type, ok := st.return_type.derived_type.(^ast.Builtin_Type)
            #partial switch return_type in st.return_type.derived_type {
            case ^ast.Builtin_Type:
                #partial switch return_type.type {
                case .TYPE_INTEGER:
                    new_proc.return_type = object.Value_Kind.INTEGER
                case .TYPE_UNSIGNED_INTEGER:
                    new_proc.return_type = object.Value_Kind.UNSIGNED_INTEGER
                case .TYPE_FLOAT:
                    new_proc.return_type = object.Value_Kind.FLOAT
                case .TYPE_BOOLEAN:
                    new_proc.return_type = object.Value_Kind.BOOLEAN
                case .TYPE_RUNE:
                    new_proc.return_type = object.Value_Kind.RUNE
                case .TYPE_STRING:
                    new_proc.return_type = object.Value_Kind.STRING
                }
            case ^ast.Array_Type:
                new_proc.return_type = object.Value_Kind.ARRAY
            case:
                fmt.eprintfln("[%d:%d] unknown return type", st.start.line, st.start.col)
                return
            }
        }
        begin_scope(comp)
        append(&comp.proc_scopes, comp.curr_scope)
        for param in st.params {
            if param_stmt, ok := param.derived_statement.(^ast.Parameter_Declarator); ok {
                make_local(comp, param_stmt.name, param_stmt.type, false)
            }
        }
        for s in st.body {
            compile_statement(comp, new_proc, s.derived_statement)
        }
        pop(&comp.proc_scopes)
        end_scope(comp, new_proc, true)

        last_st := st.body[len(st.body)-1]
        if _, is_return := last_st.derived_statement.(^ast.Return_Statement); !is_return {
            emit_byte(&new_proc.chunk, byte(Op_Code.RET))
        }

        proc_sym_type, _ := mem.new(symbol.Builtin_Symbol_Type)
        proc_sym_type.type = tokenizer.Token_Kind.PROC
        sym := symbol.Symbol{ new_proc.name, proc_sym_type, false, comp.curr_scope, len(comp.procs) }

        append(&comp.sym_table.symbols, sym)
        append(&comp.procs, new_proc)

    case ^ast.Return_Statement:
        if st.expr != nil {
            compile_expression(comp, curr_proc, st.expr.derived_expression)
        }
        emit_byte(&curr_proc.chunk, byte(Op_Code.RET))
    }
}

make_array :: proc (arr_type_info: ast.Array_Type, mutable: bool) -> object.Array {
    arr: object.Array
    arr.len = arr_type_info.length
    switch subtype in arr_type_info.type.derived_type {
    case ^ast.Builtin_Type:
        arr.data = make([]object.Object, arr_type_info.length)
        for i := 0; i < arr_type_info.length; i += 1 {
            arr.data[i] = object.value_from_token_kind(subtype.type, mutable)
        }
        arr.type = object.value_kind(subtype.type)
    case ^ast.Array_Type:
        // TODO: multi-dimensional arrays
    case ^ast.Identifier_Type:
    case ^ast.Alias_Type:
    case ^ast.Invalid_Type:
    }

    return arr
}

make_global :: proc(comp: ^Compiler, name: string, type: ^ast.Type_Specifier, mutable: bool) {
    //type_tok: tokenizer.Token_Kind
    //switch t in type.derived_type {
    //case ^ast.Builtin_Type:
    //    type_tok = t.type
    //case ^ast.Array_Type:
    //    type_tok = tokenizer.Token_Kind.ARRAY
    //case ^ast.Identifier_Type:
    //    type_tok
    //case ^ast.Invalid_Type:
    //    type_tok = tokenizer.Token_Kind.INVALID
    //}
    sym_type := symbol.make_symbol_type(type.start, type)
    val: object.Global
    switch st in sym_type {
    case ^symbol.Builtin_Symbol_Type:
        #partial switch st.type {
        case .TYPE_INTEGER:
            val.type = .INTEGER
            val.value = i64(0)
        case .TYPE_UNSIGNED_INTEGER:
            val.type = .UNSIGNED_INTEGER
            val.value = u64(0)
        case .TYPE_FLOAT:
            val.type = .FLOAT
            val.value = 0.0
        case .TYPE_BOOLEAN:
            val.type = .BOOLEAN
            val.value = false
        case .TYPE_STRING:
            val.type = .STRING
            val.value = ""
        case .TYPE_RUNE:
            val.type = .RUNE
            val.value = rune(0)
        }
    case ^symbol.Array_Symbol_Type:
        arr_type := type.derived_type.(^ast.Array_Type)
        val.type = .ARRAY
        arr := make_array(arr_type^, mutable)
        val.value = arr
    case ^symbol.Identifier_Symbol_Type:
        sym, resolved := resolve_symbol(comp, st.typename)
        if resolved {
            ts := symbol.type_specifier_from_symbol_type(sym.type)
            make_global(comp, name, ts, mutable)
            ast.type_specifier_destroy(ts.derived_type)
            symbol.symbol_type_destroy(&sym_type)
            return
        } else {
            return
        }
    case ^symbol.Alias_Symbol_Type:
        ts := symbol.type_specifier_from_symbol_type(st.subtype)
        make_global(comp, name, ts, mutable)
        ast.type_specifier_destroy(ts.derived_type)
        symbol.symbol_type_destroy(&sym_type)
        return
    }

    sym := symbol.Symbol{ name, sym_type, mutable, comp.curr_scope, len(comp.globals) }
    append(&comp.sym_table.symbols, sym)

    val.mutable = sym.mutable
    append(&comp.globals, val)
}

make_local :: proc(comp: ^Compiler, name: string, type: ^ast.Type_Specifier, mutable: bool) {
    sym_type := symbol.make_symbol_type(type.start, type)
    sym := symbol.Symbol{ name, sym_type, mutable, comp.curr_scope, len(comp.locals) }
    append(&comp.sym_table.symbols, sym)

    val: object.Local
    switch st in sym.type {
    case ^symbol.Builtin_Symbol_Type:
        #partial switch st.type {
        case .TYPE_INTEGER:
            val.type = .INTEGER
            val.value = i64(0)
        case .TYPE_UNSIGNED_INTEGER:
            val.type = .UNSIGNED_INTEGER
            val.value = u64(0)
        case .TYPE_FLOAT:
            val.type = .FLOAT
            val.value = 0.0
        case .TYPE_BOOLEAN:
            val.type = .BOOLEAN
            val.value = false
        case .TYPE_STRING:
            val.type = .STRING
            val.value = ""
        case .TYPE_RUNE:
            val.type = .RUNE
            val.value = rune(0)
        }
    case ^symbol.Array_Symbol_Type:
        arr_type := type.derived_type.(^ast.Array_Type)
        val.type = .ARRAY
        arr := make_array(arr_type^, sym.mutable)
        val.value = arr
    case ^symbol.Identifier_Symbol_Type:
    case ^symbol.Alias_Symbol_Type:
    }
    val.mutable = sym.mutable
    val.scope = comp.curr_scope
    append(&comp.locals, val)
}

resolve_variable :: proc(c: ^Compiler, name: string) -> (val: object.Object, scope: int, idx: int) {
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

compile_expression :: proc(comp: ^Compiler, curr_proc: ^proc_lib.Procedure, expr: ast.Any_Expression) {
    #partial switch e in expr {
    case ^ast.Binary_Expression:
        compile_expression(comp, curr_proc, e.left.derived_expression)
        compile_expression(comp, curr_proc, e.right.derived_expression)
        #partial switch e.op.type {
        case .PLUS:
            emit_byte(&curr_proc.chunk, byte(Op_Code.ADD))
        case .MINUS:
            emit_byte(&curr_proc.chunk, byte(Op_Code.SUB))
        case .MULT:
            emit_byte(&curr_proc.chunk, byte(Op_Code.MULT))
        case .DIV:
            emit_byte(&curr_proc.chunk, byte(Op_Code.DIV))
        case .MOD:
            emit_byte(&curr_proc.chunk, byte(Op_Code.MOD))
        case .MOD_FLOOR:
            emit_byte(&curr_proc.chunk, byte(Op_Code.MODF))
        case .EQ:
            emit_byte(&curr_proc.chunk, byte(Op_Code.EQ))
        case .NEQ:
            emit_byte(&curr_proc.chunk, byte(Op_Code.NEQ))
        case .LT:
            emit_byte(&curr_proc.chunk, byte(Op_Code.LSSR))
        case .GT:
            emit_byte(&curr_proc.chunk, byte(Op_Code.GRTR))
        case .LEQ:
            emit_byte(&curr_proc.chunk, byte(Op_Code.LEQ))
        case .GEQ:
            emit_byte(&curr_proc.chunk, byte(Op_Code.GEQ))
        case .LOGICAL_AND:
            emit_byte(&curr_proc.chunk, byte(Op_Code.LAND))
        case .LOGICAL_OR:
            emit_byte(&curr_proc.chunk, byte(Op_Code.LOR))
        }
    case ^ast.Unary_Expression:
        compile_expression(comp, curr_proc, e.expr.derived_expression)
        #partial switch e.op.type {
        case .MINUS:
            emit_byte(&curr_proc.chunk, byte(Op_Code.NEG))
        case .NOT:
            emit_byte(&curr_proc.chunk, byte(Op_Code.NOT))
        }
    case ^ast.Expression_List:
        #reverse for el in e.list {
            compile_expression(comp, curr_proc, el.derived_expression)
        }
    case ^ast.Literal:
        #partial switch e.type {
        case .INTEGER:
            lit_val, _ := strconv.parse_i64(e.value)
            val := object.Object{ .INTEGER, lit_val, false, 0 }
            emit_constant(&curr_proc.chunk, val)
        case .UNSIGNED_INTEGER:
            lit_val, _ := strconv.parse_u64(strings.trim_suffix(e.value, "u"))
            val := object.Object{ .UNSIGNED_INTEGER, lit_val, false, 0 }
            emit_constant(&curr_proc.chunk, val)
        case .FLOAT:
            lit_val, _ := strconv.parse_f64(e.value)
            val := object.Object{ .FLOAT, lit_val, false, 0 }
            emit_constant(&curr_proc.chunk, val)
        case .TRUE, .FALSE:
            lit_val, _ := strconv.parse_bool(e.value)
            val := object.Object{ .BOOLEAN, lit_val, false, 0 }
            emit_constant(&curr_proc.chunk, val)
        case .STRING:
            lit_val := strings.trim(e.value, "\"")
            val := object.Object{ .STRING, lit_val, false, 0 }
            emit_constant(&curr_proc.chunk, val)
        case .RUNE:
            lit_val, _ := utf8.decode_rune(strings.trim(e.value, "'"))
            val := object.Object{ .RUNE, lit_val, false, 0 }
            emit_constant(&curr_proc.chunk, val)
        }
    case ^ast.Identifier:
        _, scope, idx := resolve_variable(comp, e.name)
        if scope == 0 {
            emit_byte(&curr_proc.chunk, byte(Op_Code.GETG))
        } else {
            emit_byte(&curr_proc.chunk, byte(Op_Code.GETL))
        }
        emit_bytes(&curr_proc.chunk, u16(idx))
    case ^ast.Proc_Call:
        sym, exists := resolve_symbol(comp, e.name)
        if !exists {
            if e.name in proc_lib.builtin_procs {
                if el, ok := e.args.derived_expression.(^ast.Expression_List); ok {
                    #reverse for arg in el.list {
                        compile_expression(comp, curr_proc, arg.derived_expression)
                    }
                    id: int
                    for builtin, idx in comp.builtin_procs {
                        if builtin.name == e.name {
                            id = idx
                        }
                    }
                    emit_byte(&curr_proc.chunk, byte(Op_Code.CALLBI))
                    emit_bytes(&curr_proc.chunk, u16(id))
                    emit_byte(&curr_proc.chunk, byte(len(el.list)))
                }
                return
            } else {
                // TODO: should error, do not run code
                fmt.eprintfln("could not resolve symbol `%s`", e.name)
                return
            }
        }

        if el, ok := e.args.derived_expression.(^ast.Expression_List); ok {
            for arg in el.list {
                compile_expression(comp, curr_proc, arg.derived_expression)
            }
            emit_byte(&curr_proc.chunk, byte(Op_Code.CALL))
            emit_bytes(&curr_proc.chunk, u16(sym.id))
        }

    case ^ast.Array_Accessor:
        scope, idx: int
        _, scope, idx = resolve_variable(comp, e.ident)
        get_op: Op_Code
        if scope == 0 {
            get_op = .GETG
        } else {
            get_op = .GETL
        }
        compile_expression(comp, curr_proc, e.index.derived_expression)
        emit_byte(&curr_proc.chunk, byte(get_op))
        emit_bytes(&curr_proc.chunk, u16(idx))
        emit_byte(&curr_proc.chunk, byte(Op_Code.GETARR))
    }
}

emit_constant_val :: proc(chunk: ^code.Chunk, val: object.Object) {
    idx : u16 = u16(len(chunk.constants))
    append(&chunk.constants, val)
    emit_byte(chunk, byte(Op_Code.PUSH))
    emit_bytes(chunk, idx)
}

emit_constant_zero :: proc(chunk: ^code.Chunk, type: ast.Type_Specifier) {
    val: object.Object
    val.mutable = true
    #partial switch t in type.derived_type {
    case ^ast.Builtin_Type:
        #partial switch t.type {
        case .TYPE_INTEGER:
            val.type = .INTEGER
            val.value = i64(0)
        case .TYPE_UNSIGNED_INTEGER:
            val.type = .UNSIGNED_INTEGER
            val.value = u64(0)
        case .TYPE_FLOAT:
            val.type = .FLOAT
            val.value = f64(0)
        case .TYPE_BOOLEAN:
            val.type = .BOOLEAN
            val.value = false
        case .TYPE_STRING:
            val.type = .STRING
            val.value = ""
        case .TYPE_RUNE:
            val.type = .RUNE
            val.value = rune(0)
        }
    case ^ast.Array_Type:
        arr := make_array(t^, true)
        val.type = object.Value_Kind.ARRAY
        val.value = arr
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

patch_jump_current_loc :: proc(chunk: ^code.Chunk, loc: u16) {
    lo : u8 = cast(u8)((len(chunk.code)-1) & 0x00FF)
    hi : u8 = cast(u8)((len(chunk.code)-1) >> 8)
    chunk.code[loc] = hi
    chunk.code[loc+1] = lo
}

patch_jump_to_loc :: proc(chunk: ^code.Chunk, jmp, to_loc: u16) {
    lo : u8 = cast(u8)(to_loc & 0x00FF)
    hi : u8 = cast(u8)(to_loc >> 8)
    chunk.code[jmp] = hi
    chunk.code[jmp+1] = lo
}

patch_jump :: proc{
    patch_jump_current_loc,
    patch_jump_to_loc,
}

resolve_symbol :: proc(c: ^Compiler, sym_name: string) -> (sym: symbol.Symbol, resolved: bool) {
    sym, resolved = symbol.symbol_exists(sym_name, c.sym_table^)
    return
}

begin_scope :: proc(comp: ^Compiler) {
    comp.curr_scope += 1
    comp.sym_table = symbol.new(comp.sym_table)
}

end_scope :: proc(comp: ^Compiler, curr_proc: ^proc_lib.Procedure, is_proc_scope: bool) {
    for i := len(comp.locals) - 1; i >= 0; i -= 1 {
        if len(comp.locals) > 0 && comp.locals[i].scope >= comp.curr_scope {
            val := pop(&comp.locals)
            if val.type == object.Value_Kind.ARRAY {
                arr := val.value.(object.Array)
                delete(arr.data)
            }
            if !is_proc_scope {
                emit_byte(&curr_proc.chunk, byte(Op_Code.POP))
            }
        }
    }
    comp.curr_scope -= 1
    end_table := comp.sym_table
    comp.sym_table = comp.sym_table.outer
    symbol.table_destroy(end_table)
}
