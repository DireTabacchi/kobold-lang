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

Invalid_Expression :: struct {
    using node: Expression,
}

Type_Specifier :: struct {
    using base: Node,
    derived_type: Any_Type,
}

Invalid_Statement :: struct {
    using node: Statement,
}

Declarator :: struct {
    using node: Statement,
    name: string,
    type: ^Type_Specifier,
    value: ^Expression,

    mutable: bool,
}

Procedure_Declarator :: struct {
    using node: Statement,
    name: string,
    params: []^Statement,
    return_type: ^Type_Specifier,
    body: []^Statement,
}

Parameter_Declarator :: struct {
    using node: Statement,
    name: string,
    type: ^Type_Specifier,
}

Return_Statement :: struct {
    using node: Statement,
    expr: ^Expression,
}

Assignment_Statement :: struct {
    using node: Statement,
    name: string,
    value: ^Expression,
}

Assignment_Operation_Statement :: struct {
    using node: Statement,
    name: string,
    op: tokenizer.Token_Kind,
    value: ^Expression,
}

Expression_Statement :: struct {
    using node: Statement,
    expr: ^Expression,
}

If_Statement :: struct {
    using node: Statement,
    cond: ^Expression,
    consequent: []^Statement,
    alternative: ^Statement,
}

Else_If_Statement :: struct {
    using node: Statement,
    cond: ^Expression,
    consequent: []^Statement,
    alternative: ^Statement,
}

Else_Statement :: struct {
    using node: Statement,
    consequent: []^Statement,
}

For_Statement :: struct {
    using node: Statement,
    decl: ^Statement,
    cond_expr: ^Expression,
    cont_stmt: ^Statement,
    body: []^Statement,
}

Break_Statement :: struct {
    using node: Statement,
    //curr_scope: int,
    breaking_scope: int,
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

Builtin_Type :: struct {
    using node: Type_Specifier,
    type: tokenizer.Token_Kind,
}

Invalid_Type :: struct {
    using node: Type_Specifier,
    tok: tokenizer.Token,
}

Any_Statement :: union {
    ^Invalid_Statement,
    ^Declarator,
    ^Procedure_Declarator,
    ^Parameter_Declarator,
    ^Expression_Statement,
    ^Assignment_Statement,
    ^Assignment_Operation_Statement,
    ^If_Statement,
    ^Else_If_Statement,
    ^Else_Statement,
    ^For_Statement,
    ^Break_Statement,
    ^Return_Statement,
}

Any_Expression :: union {
    ^Invalid_Expression,
    ^Binary_Expression,
    ^Unary_Expression,
    ^Proc_Call,
    ^Literal,
    ^Identifier,
    ^Selector,
}

Any_Type :: union {
    ^Invalid_Type,
    ^Builtin_Type,
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
    when intrinsics.type_has_field(T, "derived_type") {
        node.derived_type = node
    }

    return node
}

destroy :: proc(tree: ^Program) {
    for stmt in tree.stmts {
        statement_destroy(stmt.derived_statement)
    }
    delete(tree.stmts)
}

statement_destroy :: proc(stmt: Any_Statement) {
    #partial switch s in stmt {
    case ^Declarator:
        if s.type != nil {
            type_specifier_destroy(s.type.derived_type)
        }
        if s.value != nil {
            expression_destroy(s.value.derived_expression)
        }
        free(s)
    case ^Procedure_Declarator:
        for param in s.params {
            statement_destroy(param.derived_statement)
        }
        if s.params != nil {
            delete(s.params)
        }
        if s.return_type != nil {
            type_specifier_destroy(s.return_type.derived_type)
        }
        for body_stmt in s.body {
            statement_destroy(body_stmt.derived_statement)
        }
        if s.body != nil {
            delete(s.body)
        }
        free(s)
    case ^Parameter_Declarator:
        type_specifier_destroy(s.type.derived_type)
        free(s)
    case ^Assignment_Statement:
        expression_destroy(s.value.derived_expression)
        free(s)
    case ^Assignment_Operation_Statement:
        expression_destroy(s.value.derived_expression)
        free(s)
    case ^Expression_Statement:
        expression_destroy(s.expr.derived_expression)
        free(s)
    case ^If_Statement:
        expression_destroy(s.cond.derived_expression)
        for cons in s.consequent {
            statement_destroy(cons.derived_statement)
        }
        if s.consequent != nil {
            delete(s.consequent)
        }
        if s.alternative != nil {
            statement_destroy(s.alternative.derived_statement)
        }
        free(s)
    case ^Else_If_Statement:
        expression_destroy(s.cond.derived_expression)
        for cons in s.consequent {
            statement_destroy(cons.derived_statement)
        }
        if s.consequent != nil {
            delete(s.consequent)
        }
        if s.alternative != nil {
            statement_destroy(s.alternative.derived_statement)
        }
        free(s)
    case ^Else_Statement:
        for cons in s.consequent {
            statement_destroy(cons.derived_statement)
        }
        if s.consequent != nil {
            delete(s.consequent)
        }
        free(s)
    case ^For_Statement:
        if s.decl != nil {
            statement_destroy(s.decl.derived_statement)
        }
        if s.cond_expr != nil {
            expression_destroy(s.cond_expr.derived_expression)
        }
        if s.cont_stmt != nil {
            statement_destroy(s.cont_stmt.derived_statement)
        }
        for body_stmt in s.body {
            statement_destroy(body_stmt.derived_statement)
        }
        if s.body != nil {
            delete(s.body)
        }
        free(s)
    case ^Break_Statement:
        free(s)
    case ^Return_Statement:
        if s.expr != nil {
            expression_destroy(s.expr.derived_expression)
        }
        free(s)
    }
}

expression_destroy :: proc(expr: Any_Expression) {
    #partial switch e in expr {
    case ^Invalid_Expression:
        free(e)
    case ^Binary_Expression:
        expression_destroy(e.left.derived_expression)
        expression_destroy(e.right.derived_expression)
        free(e)
    case ^Unary_Expression:
        expression_destroy(e.expr.derived_expression)
        free(e)
    case ^Literal:
        free(e)
    case ^Identifier:
        free(e)
    case ^Proc_Call:
        for arg in e.args {
            expression_destroy(arg.derived_expression)
        }
        if e.args != nil {
            delete(e.args)
        }
        free(e)
    }
}

type_specifier_destroy :: proc(type_spec: Any_Type) {
    switch ts in type_spec {
    case ^Invalid_Type:
        free(ts)
    case ^Builtin_Type:
        free(ts)
    }
}
