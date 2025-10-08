package parser

import "core:fmt"

import "kobold:ast"
import "kobold:tokenizer"

Parser :: struct {
    toks: []tokenizer.Token,

    prev_tok: tokenizer.Token,
    curr_tok: tokenizer.Token,
    curr_idx: int,

    prog: ^ast.Program,
}

parser_init :: proc(p: ^Parser, tokens: []tokenizer.Token) {
    p.toks = tokens
    p.curr_idx = 0

    p.prev_tok = {}
    p.curr_tok = p.toks[p.curr_idx]

    p.prog = new(ast.Program)
}

parse :: proc(p: ^Parser) {
    for p.curr_tok.type != .EOF {
        stmt := parse_statement(p)
        if stmt != nil {
            append(&p.prog.stmts, stmt)
        } else {
            fmt.println("error parsing statement")
        }
    }
}

parse_statement :: proc(p: ^Parser) -> ^ast.Statement {
    #partial switch p.curr_tok.type {
    case:
        expr_stmt := parse_expr_statement(p)
        if expr_stmt == nil {
            fmt.eprintln("error parsing expression statement")
        }
        return expr_stmt
    }
}

parse_expr_statement :: proc(p: ^Parser) -> ^ast.Statement {
    start_pos := p.curr_tok.pos
    expr := parse_expression(p)

    if expr == nil {
        fmt.eprintln("error parsing expression")
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
        fmt.eprintln("error parsing binary expression")
    }

    return bin_expr
}

parse_binary_expr :: proc(p: ^Parser, curr_prec: int) -> ^ast.Expression {
    start_pos := p.curr_tok.pos
    expr := parse_unary_expr(p)

    if expr == nil {
        fmt.eprintln("error parsing unary expression")
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
    case .Identifier, .Integer, .True, .False:
        lit := parse_literal(p)
        return lit
    }

    return nil
}

parse_literal :: proc(p: ^Parser) -> ^ast.Expression {
    start_pos := p.curr_tok.pos

    #partial switch p.curr_tok.type {
    case .Integer, .True, .False:
        tok := advance_token(p)
        lit := ast.new(ast.Literal, start_pos, end_pos(p.prev_tok))
        lit.type = tok.type
        lit.value = tok.text
        return lit
    case .Identifier:
        // TODO: Should create a symbol table and make a procedure to parse an identifier and add it to that table
        tok := advance_token(p)
        ident := ast.new(ast.Identifier, start_pos, end_pos(p.prev_tok))
        ident.name = tok.text
        return ident
    case:
        return nil
    }
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
        fmt.eprintfln("expected '%v', got '%s'", type, p.curr_tok.text)
    }
    advance_token(p)
    return prev
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
