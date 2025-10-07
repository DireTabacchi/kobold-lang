package ast

import "kobold:tokenizer"

Node :: struct {
    start: tokenizer.Pos,
    end: tokenizer.Pos,
    derived: ^Node,
}

Statement :: struct {
    using node: Node,
    derived_statement: Any_Statement,
}

Expression :: struct {
    using node: Node,
    derived_expression: Any_Expression,
}

Declaration :: struct {
    using node: Statement,
}

Declarator :: struct {
    using node: Declaration,
    name: string,
    type: tokenizer.Token_Kind,
    value: ^Expr,

    is_mutable: bool,
}

Binary_Expression :: struct {
    using node: Expression,
    left: ^Expr,
    op: tokenizer.Token,
    right: ^Expr,
}

Unary_Expression :: struct {
    using node: Expression,
    op: tokenizer.Token,
    expr: ^Expression,
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

Any_Statement :: union {
    ^Declaration,
}

Any_Expression :: union {
    ^Binary_Expression,
    ^Unary_Expression,
    ^Literal,
    ^Identifier,
}
