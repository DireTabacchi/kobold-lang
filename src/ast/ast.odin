package ast

import "base:intrinsics"
import "core:mem"
import "kobold:tokenizer"

Node :: struct {
    start: tokenizer.Pos,
    end: tokenizer.Pos,
    derived: ^Node,
}

Program :: struct {
    using node: Node,

    stmts: [dynamic]^Statement,
}

Statement :: struct {
    using base: Node,
    derived_statement: Any_Statement,
}

Expression :: struct {
    using base: Node,
    derived_expression: Any_Expression,
}

Declaration :: struct {
    using node: Statement,
}

Declarator :: struct {
    using node: Statement,
    name: string,
    type: tokenizer.Token_Kind,
    value: ^Expression,

    is_mutable: bool,
}

Expression_Statement :: struct {
    using node: Statement,
    expr: ^Expression,
}

Binary_Expression :: struct {
    using node: Expression,
    left: ^Expression,
    op: tokenizer.Token,
    right: ^Expression,
}

Unary_Expression :: struct {
    using node: Expression,
    op: tokenizer.Token,
    expr: ^Expression,
}

Proc_Call :: struct {
    using node: Expression,
    name: string,
    args: []^Expression,
}

Literal :: struct {
    using node: Expression,
    type: tokenizer.Token_Kind,
    value: string,
}

Identifier :: struct {
    using node: Expression,
    name: string,
}

Selector :: struct {
    using node: Expression,
    ident: string,
    field: ^Expression,
}

Any_Statement :: union {
    ^Declaration,
    ^Expression_Statement,
}

Any_Expression :: union {
    ^Binary_Expression,
    ^Unary_Expression,
    ^Proc_Call,
    ^Literal,
    ^Identifier,
    ^Selector,
}

new :: proc($T: typeid, start, end: tokenizer.Pos) -> ^T {
    node, _ := mem.new(T)
    node.start = start
    node.end = end
    node.derived = node
    when intrinsics.type_has_field(T, "derived_statement") {
        node.derived_statement = node
    }
    when intrinsics.type_has_field(T, "derived_expression") {
        node.derived_expression = node
    }

    return node
}

destroy :: proc(tree: ^Program) {
    for stmt in tree.stmts {
        statement_destroy(stmt.derived_statement)
        delete(tree.stmts)
    }
}

statement_destroy :: proc(stmt: Any_Statement) {
    #partial switch s in stmt {
    case ^Expression_Statement:
        expression_destroy(s.expr.derived_expression)
        free(s)
    }
}

expression_destroy :: proc(expr: Any_Expression) {
    #partial switch e in expr {
    case ^Binary_Expression:
        expression_destroy(e.left.derived_expression)
        expression_destroy(e.right.derived_expression)
        free(e)
    case ^Literal:
        free(e)
    }
}
