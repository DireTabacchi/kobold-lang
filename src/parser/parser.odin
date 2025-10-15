package parser

// TODO: More robust error handling

import "core:fmt"

import "kobold:ast"
import "kobold:tokenizer"
import "kobold:symbol"

Parser :: struct {
    toks: []tokenizer.Token,

    prev_tok: tokenizer.Token,
    curr_tok: tokenizer.Token,
    curr_idx: int,

    sym_table: [dynamic]symbol.Symbol,

    error_count: int,

    prog: ^ast.Program,
}

parser_init :: proc(p: ^Parser, tokens: []tokenizer.Token) {
    p.toks = tokens
    p.curr_idx = 0

    p.prev_tok = {}
    p.curr_tok = p.toks[p.curr_idx]

    p.error_count = 0

    p.prog = new(ast.Program)
}

parser_destroy :: proc(p: ^Parser) {
    free(p.prog)
    delete(p.sym_table)
}

parse :: proc(p: ^Parser) {
    for p.curr_tok.type != .EOF {
        stmt := parse_statement(p)
        if stmt != nil {
            append(&p.prog.stmts, stmt)
        } else {
            error(p, p.curr_tok.pos, "error parsing statement")
            return
        }
    }
    fmt.println("=== Finished parsing ===")
}

parse_statement :: proc(p: ^Parser) -> ^ast.Statement {
    #partial switch p.curr_tok.type {
    case .Var, .Const:
        decl_stmt := parse_decl_statement(p)
        if decl_stmt == nil {
            error(p, p.curr_tok.pos, "error parsing declaration statement")
            return nil
        }
        return decl_stmt
    case:
        expr_stmt := parse_expr_statement(p)
        if expr_stmt == nil {
            error(p, p.curr_tok.pos, "error parsing expression statement")
            return nil
        }
        return expr_stmt
    }
    return nil
}

parse_decl_statement :: proc(p: ^Parser) -> ^ast.Statement {
    decl_type := p.curr_tok.type
    #partial switch decl_type {
    case .Const:
        return parse_const_decl(p)
    case .Var:
        return parse_var_decl(p)
    }
    return nil
}

parse_const_decl :: proc(p: ^Parser) -> ^ast.Statement {
    start_pos := p.curr_tok.pos
    advance_token(p)
    ident := expect_token(p, .Identifier)
    expect_token(p, .Colon)
    type := parse_type_specifier(p)
    assign_tok := expect_token(p, .Assign)
    val := parse_expression(p)
    semi_tok := expect_token(p, .Semicolon)
    cd := ast.new(ast.Declarator, start_pos, end_pos(p.prev_tok))
    cd.name = ident.text
    cd.mutable = false

    if type == nil {
        error(p, assign_tok.pos, "expected a type name")
        type = ast.new(ast.Invalid_Type, assign_tok.pos, assign_tok.pos)
        cd.type = type
    } else {
        cd.type = type
    }
    if val == nil {
        error(p, assign_tok.pos, "expected an expression")
        val = ast.new(ast.Invalid_Expression, semi_tok.pos, semi_tok.pos)
        cd.value = val
    } else {
        cd.value = val
    }

    if _, t_invalid := cd.type.derived_type.(^ast.Invalid_Type); t_invalid {
        return cd
    }

    if _, exists := symbol.symbol_exists(cd.name, p.sym_table[:]); exists {
        errorf_msg(p, cd.start, "name `%s` already used", cd.name)
        return cd
    }

    expr_type := expression_type(p^, val)
    type_type, _ := type.derived_type.(^ast.Builtin_Type)
    if val_type := expr_type.derived_type.(^ast.Builtin_Type); val_type.type != type_type.type {
        errorf_msg(p, start_pos, "cannot assign value of type `%s` to variable of type `%s`", val_type.type, type_type.type)
    }
    free(expr_type)

    const_type: tokenizer.Token_Kind
    #partial switch t in type.derived_type {
    case ^ast.Builtin_Type:
        const_type = t.type
    }

    const_symbol := symbol.Symbol{ cd.name, const_type, false, len(p.sym_table) }
    append(&p.sym_table, const_symbol)

    return cd
}

parse_var_decl :: proc(p: ^Parser) -> ^ast.Statement {
    start_pos := p.curr_tok.pos
    advance_token(p)
    ident := expect_token(p, .Identifier)
    expect_token(p, .Colon)
    type := parse_type_specifier(p)
    if _, is_assign := check_token(p, .Assign); is_assign {
        advance_token(p)
    }

    val := parse_expression(p)
    expect_token(p, .Semicolon)
    vd := ast.new(ast.Declarator, start_pos, end_pos(p.prev_tok))
    vd.name = ident.text
    vd.mutable = true

    _, invalid_val := val.derived_expression.(^ast.Invalid_Expression)

    if type == nil && !invalid_val {
        type = expression_type(p^, val)
        if _, invalid := type.derived_type.(^ast.Invalid_Type); invalid {
            errorf_msg(p, start_pos, "cannot deduce type of var `%s`", vd.name)
        }
        vd.type = type
    } else if type == nil && invalid_val {
        errorf_msg(p, start_pos, "cannot deduce type of var `%s`", vd.name)
    }

    if type != nil && invalid_val {
        vd.type = type
        vd.value = nil
        free(val)
    } else {
        expr_type := expression_type(p^, val)
        type_type, _ := type.derived_type.(^ast.Builtin_Type)
        if val_type := expr_type.derived_type.(^ast.Builtin_Type); val_type.type != type_type.type {
            errorf_msg(p, start_pos, "cannot assign value of type `%s` to variable of type `%s`", val_type.type, type_type.type)
        }
        free(expr_type)
        vd.type = type
        vd.value = val
    }

    if _, exists := symbol.symbol_exists(vd.name, p.sym_table[:]); exists {
        errorf_msg(p, vd.start, "name `%s` already used", vd.name)
        return vd
    }

    var_type: tokenizer.Token_Kind
    #partial switch t in type.derived_type {
    case ^ast.Builtin_Type:
        var_type = t.type
    }

    var_symbol := symbol.Symbol{ vd.name, var_type, true, len(p.sym_table) }
    append(&p.sym_table, var_symbol)

    return vd
}

expression_type :: proc(p: Parser, expr: ^ast.Expression) -> ^ast.Type_Specifier {
    #partial switch e in expr.derived_expression {
    case ^ast.Binary_Expression:
        #partial switch e.op.type {
        case .Logical_And..=.Geq:
            ts := ast.new(ast.Builtin_Type, e.start, e.end)
            ts.type = .Type_Boolean
            return ts
        case:
            return expression_type(p, e.left)
        }
    case ^ast.Unary_Expression:
        #partial switch e.op.type {
        case .Not:
            ts := ast.new(ast.Builtin_Type, e.start, e.end)
            ts.type = .Type_Boolean
            return ts
        }
        return expression_type(p, e.expr)
    case ^ast.Literal:
        type: tokenizer.Token_Kind
        #partial switch e.type {
        case .Integer:
            type = .Type_Integer
        case .Unsigned_Integer:
            type = .Type_Unsigned_Integer
        case .True, .False:
            type = .Type_Boolean
        case .Float:
            type = .Type_Float
        case .Rune:
            type = .Type_Rune
        case .String:
            type = .Type_String
        case:
            it := ast.new(ast.Invalid_Type, e.start, e.end)
            return it
        }

        ts := ast.new(ast.Builtin_Type, expr.start, expr.end)
        ts.type = type
        return ts
    case ^ast.Identifier:
        name := e.name
        type: tokenizer.Token_Kind
        for sym in p.sym_table {
            if name == sym.name {
                type = sym.type
            }
        }
        ts := ast.new(ast.Builtin_Type, expr.start, expr.end)
        ts.type = type
        return ts
    case:
        it := ast.new(ast.Invalid_Type, expr.start, expr.end)
        return it
    }
}

parse_type_specifier :: proc(p: ^Parser) -> ^ast.Type_Specifier {
    if p.curr_tok.type == .Assign {
        return nil
    }

    start_pos := p.curr_tok.pos
    t := advance_token(p)
    ts := ast.new(ast.Builtin_Type, start_pos, end_pos(p.prev_tok))
    ts.type = t.type
    return ts
}

parse_expr_statement :: proc(p: ^Parser) -> ^ast.Statement {
    start_pos := p.curr_tok.pos
    expr := parse_expression(p)

    if expr == nil {
        error(p, p.curr_tok.pos, "error parsing expression")
        return nil
    }

    expect_token(p, .Semicolon)

    es := ast.new(ast.Expression_Statement, start_pos, end_pos(p.prev_tok))
    es.expr = expr
    return es
}

parse_expression :: proc(p: ^Parser) -> ^ast.Expression {
    //start_pos := p.curr_tok.pos
    bin_expr := parse_binary_expr(p, 0)

    if bin_expr == nil {
        error(p, p.curr_tok.pos, "error parsing binary expression")
        return nil
    }

    return bin_expr
}

parse_binary_expr :: proc(p: ^Parser, curr_prec: int) -> ^ast.Expression {
    start_pos := p.curr_tok.pos
    expr := parse_unary_expr(p)

    if expr == nil {
        error(p, p.curr_tok.pos, "error parsing unary expression")
        return nil
    }

    #partial switch e in expr.derived_expression {
    case ^ast.Invalid_Expression:
        return expr
    }

    for op_prec := precedence(p.curr_tok); op_prec > curr_prec; op_prec -= 1 {
        for {
            op := p.curr_tok
            if op_prec != precedence(op) {
                break
            }
            #partial switch p.curr_tok.type {
            case .Minus..=.Geq:
                advance_token(p)
                rhs_expr := parse_binary_expr(p, op_prec)
                be := ast.new(ast.Binary_Expression, start_pos, end_pos(p.prev_tok))
                be.left = expr
                be.op = op
                be.right = rhs_expr
                expr = be
            }
        }
    }
    return expr
}

parse_unary_expr :: proc(p: ^Parser) -> ^ast.Expression {
    start_pos := p.curr_tok.pos

    #partial switch p.curr_tok.type {
    case .Minus, .Not:
        op := p.curr_tok
        advance_token(p)
        expr := parse_unary_expr(p)
        ue := ast.new(ast.Unary_Expression, start_pos, end_pos(p.prev_tok))
        ue.op = op
        ue.expr = expr
        return ue
    case:
        expr := parse_primary(p)
        return expr
    }

}

parse_primary :: proc(p: ^Parser) -> ^ast.Expression {
    //start_pos := p.curr_tok.pos

    #partial switch p.curr_tok.type {
    case .L_Paren:
        advance_token(p)
        expr := parse_expression(p)
        expect_token(p, .R_Paren) // Note: consume R_Paren
        return expr
    case .Integer, .Unsigned_Integer, .Float, .True, .False, .String, .Rune:
        lit := parse_literal(p)
        return lit
    case .Identifier:
        #partial switch tok := peek_token(p); tok.type {
        case .L_Paren:
            return parse_proc_call(p)
        case .Dot:
            return parse_ident_selector(p)
        case:
            return parse_identifier(p)
        }
    }

    ie := ast.new(ast.Invalid_Expression, p.prev_tok.pos, p.curr_tok.pos)
    return ie
    //return nil
}

parse_ident_selector :: proc(p: ^Parser) -> ^ast.Expression {
    start_pos := p.curr_tok.pos

    ident := advance_token(p)
    expect_token(p, .Dot)
    field: ^ast.Expression
    #partial switch tok := peek_token(p); tok.type {
    case .Dot:
        field = parse_ident_selector(p)

    case:
        field = parse_identifier(p)
    }
    is := ast.new(ast.Selector, start_pos, end_pos(p.prev_tok))
    is.ident = ident.text
    is.field = field
    return is
}

parse_proc_call :: proc(p: ^Parser) -> ^ast.Expression {
    start_pos := p.curr_tok.pos

    name := advance_token(p)
    expect_token(p, .L_Paren)
    arg_list := parse_expr_list(p)
    expect_token(p, .R_Paren)

    pc := ast.new(ast.Proc_Call, start_pos, end_pos(p.prev_tok))
    pc.name = name.text
    pc.args = arg_list
    return pc
}

parse_expr_list :: proc(p: ^Parser) -> []^ast.Expression {
    expr_list: [dynamic]^ast.Expression
    for p.curr_tok.type != .R_Paren {
        pos := p.curr_tok.pos
        expr := parse_expression(p)
        if expr == nil {
            error(p, pos, "expected expression")
        }
        append(&expr_list, expr)

        if p.curr_tok.type == .Comma { // Optional trailing comma
            advance_token(p)
        }
    }

    return expr_list[:]
}

parse_literal :: proc(p: ^Parser) -> ^ast.Expression {
    start_pos := p.curr_tok.pos

    #partial switch p.curr_tok.type {
    case .Integer, .Unsigned_Integer, .Float, .True, .False, .String, .Rune:
        tok := advance_token(p)
        lit := ast.new(ast.Literal, start_pos, end_pos(p.prev_tok))
        lit.type = tok.type
        lit.value = tok.text
        return lit
    case:
        return nil
    }
}

parse_identifier :: proc(p: ^Parser) -> ^ast.Expression {
    start_pos := p.curr_tok.pos
    // TODO: Should create a symbol table and make a procedure to parse an identifier and add it to that table
    if tok := expect_token(p, .Identifier); tok.type == .Identifier {
        ident := ast.new(ast.Identifier, start_pos, end_pos(p.prev_tok))
        ident.name = tok.text
        return ident
    }
    fmt.eprintln("could not find valid expression")
    ie := ast.new(ast.Invalid_Expression, start_pos, end_pos(p.prev_tok))
    return ie
}

advance_token :: proc(p: ^Parser) -> tokenizer.Token {
    p.prev_tok = p.curr_tok
    if p.curr_tok.type != .EOF {
        p.curr_idx += 1
        p.curr_tok = p.toks[p.curr_idx]
    }

    return p.prev_tok
}


expect_token :: proc(p: ^Parser, type: tokenizer.Token_Kind) -> tokenizer.Token {
    prev := p.curr_tok
    if p.curr_tok.type != type {
        pos := p.curr_tok.pos
        errorf_msg(p, pos, "expected '%s', got '%s'", tokenizer.token_list[type], p.curr_tok.text)
        //fmt.eprintfln("[%d:%d] expected '%s', got '%s'", pos.line, pos.col, tokenizer.token_list[type], p.curr_tok.text)
    }
    advance_token(p)
    return prev
}

peek_token :: proc(p: ^Parser) -> tokenizer.Token {
    if p.curr_tok.type == .EOF {
        return p.curr_tok
    }
    return p.toks[p.curr_idx+1]
}

check_token :: proc(p: ^Parser, type: tokenizer.Token_Kind) -> (tokenizer.Token, bool) {
    return p.curr_tok, p.curr_tok.type == type
}

end_pos :: proc(tok: tokenizer.Token) -> tokenizer.Pos {
    pos := tok.pos
    pos.offset += len(tok.text)
    pos.col += len(tok.text)
    return pos
}

/*
Op_Precs :: enum {
    None,
    Term,       // +, -
    Factor,     // *, /, %, %%
    Unary,      // - <num>
}
*/

precedence :: proc(token: tokenizer.Token) -> int {
    #partial switch token.type {
    case .Logical_And:
        return 1
    case .Logical_Or:
        return 2
    case .Eq..=.Geq:
        return 3
    case .Minus, .Plus:
        return 4
    case .Mult, .Div, .Mod, .Mod_Floor:
        return 5
    case:
        return 0
    }
}

error_msg :: proc(p: ^Parser, pos: tokenizer.Pos, msg: string) {
    p.error_count += 1
    fmt.eprintfln("[%d:%d] %s", pos.line, pos.col, msg)
}

errorf_msg :: proc(p: ^Parser, pos: tokenizer.Pos, fmt_msg: string, args: ..any) {
    p.error_count += 1
    fmt.eprintf("[%d:%d] ", pos.line, pos.col)
    fmt.eprintfln(fmt_msg, ..args)
}

error :: proc {
    error_msg,
}
