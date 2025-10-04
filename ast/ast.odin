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

Any_Statement :: union {
    ^Declaration,
}

Any_Expression :: union {

}
