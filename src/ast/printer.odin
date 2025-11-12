package ast

import "base:intrinsics"
import "core:fmt"
import "core:strings"

import "kobold:tokenizer"

AstPrinter :: struct {
    builder: strings.Builder,
    indents: [dynamic]IndentPattern,
}

IndentPattern :: enum {
    NONE,   // "    "
    MID,    // "   │"
    BRANCH, // "   ├"
    LAST,   // "   └"
}

indent_patterns := [IndentPattern]string {
    .NONE =     "    ",
    .MID =      "   \u2502",
    .BRANCH =   "   \u251C",
    .LAST =     "   \u2514",
}

printer_init :: proc(ap: ^AstPrinter, tab_size: int = 4) {
    ap.builder = strings.builder_make()
}

printer_destroy :: proc(ap: ^AstPrinter) {
    strings.builder_destroy(&ap.builder)
    delete(ap.indents)
}

print_ast :: proc(ap: ^AstPrinter, prog: ^Program) {
    prog_len := len(prog.stmts)
    strings.write_string(&ap.builder, "Program:\n")
    append(&ap.indents, IndentPattern.LAST)
    for stmt, i in prog.stmts {
        if prog_len - 1 == i {
            swap_last_indent(ap, IndentPattern.LAST)
        } else {
            swap_last_indent(ap, IndentPattern.BRANCH)
        }
        write_indents(ap)
        strings.write_string(&ap.builder, "Statement:\n")
        if prog_len - 1 == i {
            swap_last_indent(ap, IndentPattern.NONE)
        } else {
            swap_last_indent(ap, IndentPattern.MID)
        }
        print_stmt(ap, stmt.derived_statement, true)
    }
    pop(&ap.indents)

    ast_string := strings.to_string(ap.builder)
    fmt.println(ast_string)
}

print_stmt :: proc(ap: ^AstPrinter, stmt: Any_Statement, last: bool) {
    switch st in stmt {
    case ^Declarator:
        append_last_or_branch(ap, last)
        write_indents(ap)
        strings.write_string(&ap.builder, "Declarator:\n")
        swap_mid_or_none(ap, last)
        append(&ap.indents, IndentPattern.BRANCH)
        write_indents(ap)
        fmt.sbprintfln(&ap.builder, "mutability: %s", st.mutable ? "var" : "const")
        write_indents(ap)
        fmt.sbprintfln(&ap.builder, "name: %s", st.name)
        write_indents(ap)
        strings.write_string(&ap.builder, "type:\n")
        swap_last_indent(ap, IndentPattern.MID)
        print_type_specifier(ap, st.type.derived_type)
        swap_last_indent(ap, IndentPattern.LAST)
        write_indents(ap)
        strings.write_string(&ap.builder, "value:\n")
        swap_last_indent(ap, IndentPattern.NONE)
        if st.value != nil {
            print_expr(ap, st.value.derived_expression, true)
        } else {
            append(&ap.indents, IndentPattern.LAST)
            write_indents(ap)
            strings.write_string(&ap.builder, "<nil>\n")
            pop(&ap.indents)
        }
        pop(&ap.indents)
        pop(&ap.indents)

    case ^Procedure_Declarator:
        append_last_or_branch(ap, last)
        write_indents(ap)
        strings.write_string(&ap.builder, "Procedure Declarator:\n")
        swap_mid_or_none(ap, last)
        append(&ap.indents, IndentPattern.BRANCH)
        write_indents(ap)
        fmt.sbprintfln(&ap.builder, "name: %s", st.name)
        write_indents(ap)
        strings.write_string(&ap.builder, "params:\n")
        swap_last_indent(ap, IndentPattern.MID)
        params_len := len(st.params)
        if params_len == 0 {
            append(&ap.indents, IndentPattern.LAST)
            write_indents(ap)
            strings.write_string(&ap.builder, "<empty>\n")
            pop(&ap.indents)
        } else {
            for param, i in st.params {
                if params_len - 1 == i {
                    print_stmt(ap, param.derived_statement, true)
                } else {
                    print_stmt(ap, param.derived_statement, false)
                }
            }
        }
        swap_last_indent(ap, IndentPattern.BRANCH)
        write_indents(ap)
        strings.write_string(&ap.builder, "return_type:\n")
        swap_last_indent(ap, IndentPattern.MID)
        if st.return_type == nil {
            append(&ap.indents, IndentPattern.LAST)
            write_indents(ap)
            strings.write_string(&ap.builder, "<nil>\n")
            pop(&ap.indents)
        } else {
            print_type_specifier(ap, st.return_type.derived_type)
        }
        swap_last_indent(ap, IndentPattern.LAST)
        write_indents(ap)
        strings.write_string(&ap.builder, "body:\n")
        body_len := len(st.body)
        if body_len == 0 {
            append(&ap.indents, IndentPattern.LAST)
            write_indents(ap)
            strings.write_string(&ap.builder, "<empty>\n")
            pop(&ap.indents)
        } else {
            swap_last_indent(ap, IndentPattern.NONE)
            for body_stmt, i in st.body {
                if body_len - 1 == i {
                    print_stmt(ap, body_stmt.derived_statement, true)
                } else {
                    print_stmt(ap, body_stmt.derived_statement, false)
                }
            }
        }
        pop(&ap.indents)
        pop(&ap.indents)

    case ^Type_Declarator:
        append_last_or_branch(ap, last)
        write_indents(ap)
        strings.write_string(&ap.builder, "Type Declarator:\n")
        swap_mid_or_none(ap, last)
        append(&ap.indents, IndentPattern.BRANCH)
        write_indents(ap)
        fmt.sbprintfln(&ap.builder, "name: %s", st.name)
        swap_last_indent(ap, IndentPattern.LAST)
        write_indents(ap)
        strings.write_string(&ap.builder, "type:\n")
        swap_last_indent(ap, IndentPattern.NONE)
        print_type_specifier(ap, st.type.derived_type)
        pop(&ap.indents)
        pop(&ap.indents)

    case ^Parameter_Declarator:
        append_last_or_branch(ap, last)
        write_indents(ap)
        strings.write_string(&ap.builder, "Parameter Declarator:\n")
        swap_mid_or_none(ap, last)
        append(&ap.indents, IndentPattern.BRANCH)
        write_indents(ap)
        fmt.sbprintfln(&ap.builder, "name: %s", st.name)
        swap_last_indent(ap, IndentPattern.LAST)
        write_indents(ap)
        fmt.sbprintfln(&ap.builder, "type:")
        swap_last_indent(ap, IndentPattern.NONE)
        print_type_specifier(ap, st.type.derived_type)
        pop(&ap.indents)
        pop(&ap.indents)

    case ^Assignment_Statement:
        append_last_or_branch(ap, last)
        write_indents(ap)
        strings.write_string(&ap.builder, "Assignment Statement:\n")
        swap_mid_or_none(ap, last)
        append(&ap.indents, IndentPattern.BRANCH)
        write_indents(ap)
        strings.write_string(&ap.builder, "ident:\n")
        swap_last_indent(ap, IndentPattern.MID)
        print_expr(ap, st.ident.derived_expression, true)
        swap_last_indent(ap, IndentPattern.LAST)
        write_indents(ap)
        strings.write_string(&ap.builder, "value:\n")
        swap_last_indent(ap, IndentPattern.NONE)
        print_expr(ap, st.value.derived_expression, true)
        pop(&ap.indents)
        pop(&ap.indents)

    case ^Assignment_Operation_Statement:
        append_last_or_branch(ap, last)
        write_indents(ap)
        strings.write_string(&ap.builder, "Assignment Operation Statement:\n")
        swap_mid_or_none(ap, last)
        append(&ap.indents, IndentPattern.BRANCH)
        write_indents(ap)
        strings.write_string(&ap.builder, "ident:\n")
        swap_last_indent(ap, IndentPattern.MID)
        print_expr(ap, st.ident.derived_expression, true)
        swap_last_indent(ap, IndentPattern.BRANCH)
        write_indents(ap)
        fmt.sbprintfln(&ap.builder, "op: %s", tokenizer.token_list[st.op])
        swap_last_indent(ap, IndentPattern.LAST)
        write_indents(ap)
        strings.write_string(&ap.builder, "value:\n")
        swap_last_indent(ap, IndentPattern.NONE)
        print_expr(ap, st.value.derived_expression, true)
        pop(&ap.indents)
        pop(&ap.indents)

    case ^Expression_Statement:
        append_last_or_branch(ap, last)
        write_indents(ap)
        strings.write_string(&ap.builder, "Expression Statement:\n")
        swap_mid_or_none(ap, last)
        print_expr(ap, st.expr.derived_expression, true)
        pop(&ap.indents)

    case ^If_Statement:
        append_last_or_branch(ap, last)
        write_indents(ap)
        strings.write_string(&ap.builder, "If Statement:\n")
        swap_mid_or_none(ap, last)
        append(&ap.indents, IndentPattern.BRANCH)
        write_indents(ap)
        strings.write_string(&ap.builder, "cond:\n")
        swap_last_indent(ap, IndentPattern.MID)
        print_expr(ap, st.cond.derived_expression, false)
        swap_last_indent(ap, IndentPattern.BRANCH)
        write_indents(ap)
        strings.write_string(&ap.builder, "consequent:\n")
        swap_last_indent(ap, IndentPattern.MID)
        cons_len := len(st.consequent)
        for cons, i in st.consequent {
            if cons_len - 1 == i {
                print_stmt(ap, cons.derived_statement, true)
            } else {
                print_stmt(ap, cons.derived_statement, false)
            }
        }
        swap_last_indent(ap, IndentPattern.LAST)
        write_indents(ap)
        strings.write_string(&ap.builder, "alternative:\n")
        swap_last_indent(ap, IndentPattern.NONE)
        if st.alternative != nil {
            print_stmt(ap, st.alternative.derived_statement, true)
        } else {
            append(&ap.indents, IndentPattern.LAST)
            write_indents(ap)
            strings.write_string(&ap.builder, "<nil>\n")
            pop(&ap.indents)
        }
        pop(&ap.indents)
        pop(&ap.indents)

    case ^Else_If_Statement:
        append_last_or_branch(ap, last)
        write_indents(ap)
        strings.write_string(&ap.builder, "Else If Statement:\n")
        swap_mid_or_none(ap, last)
        append(&ap.indents, IndentPattern.BRANCH)
        write_indents(ap)
        strings.write_string(&ap.builder, "cond:\n")
        swap_last_indent(ap, IndentPattern.MID)
        print_expr(ap, st.cond.derived_expression, false)
        swap_last_indent(ap, IndentPattern.BRANCH)
        write_indents(ap)
        strings.write_string(&ap.builder, "consequent:\n")
        swap_last_indent(ap, IndentPattern.MID)
        cons_len := len(st.consequent)
        for cons, i in st.consequent {
            if cons_len - 1 == i {
                print_stmt(ap, cons.derived_statement, true)
            } else {
                print_stmt(ap, cons.derived_statement, false)
            }
        }
        swap_last_indent(ap, IndentPattern.LAST)
        write_indents(ap)
        strings.write_string(&ap.builder, "alternative:\n")
        swap_last_indent(ap, IndentPattern.NONE)
        if st.alternative == nil {
            append(&ap.indents, IndentPattern.LAST)
            write_indents(ap)
            strings.write_string(&ap.builder, "<nil>\n")
            pop(&ap.indents)
        } else {
            print_stmt(ap, st.alternative.derived_statement, true)
        }
        pop(&ap.indents)
        pop(&ap.indents)

    case ^Else_Statement:
        append_last_or_branch(ap, last)
        write_indents(ap)
        strings.write_string(&ap.builder, "Else Statement:\n")
        swap_mid_or_none(ap, last)
        append(&ap.indents, IndentPattern.LAST)
        write_indents(ap)
        strings.write_string(&ap.builder, "consequent:\n")
        swap_last_indent(ap, IndentPattern.NONE)
        cons_len := len(st.consequent)
        for cons, i in st.consequent {
            if cons_len - 1 == i {
                print_stmt(ap, cons.derived_statement, true)
            } else {
                print_stmt(ap, cons.derived_statement, false)
            }
        }
        pop(&ap.indents)
        pop(&ap.indents)

    case ^For_Statement:
        append_last_or_branch(ap, last)
        write_indents(ap)
        strings.write_string(&ap.builder, "For Statement:\n")
        swap_mid_or_none(ap, last)
        append(&ap.indents, IndentPattern.BRANCH)
        write_indents(ap)
        strings.write_string(&ap.builder, "decl:\n")
        swap_last_indent(ap, IndentPattern.MID)
        if st.decl == nil {
            append(&ap.indents, IndentPattern.LAST)
            write_indents(ap)
            strings.write_string(&ap.builder, "<nil>\n")
            pop(&ap.indents)
        } else {
            print_stmt(ap, st.decl.derived_statement, true)
        }
        swap_last_indent(ap, IndentPattern.BRANCH)
        write_indents(ap)
        strings.write_string(&ap.builder, "cond_expr:\n")
        swap_last_indent(ap, IndentPattern.MID)
        if st.cond_expr == nil {
            append(&ap.indents, IndentPattern.LAST)
            write_indents(ap)
            strings.write_string(&ap.builder, "<nil>\n")
            pop(&ap.indents)
        } else {
            print_expr(ap, st.cond_expr.derived_expression, false)
        }
        swap_last_indent(ap, IndentPattern.BRANCH)
        write_indents(ap)
        strings.write_string(&ap.builder, "cont_stmt:\n")
        swap_last_indent(ap, IndentPattern.MID)
        if st.cont_stmt ==  nil {
            append(&ap.indents, IndentPattern.LAST)
            write_indents(ap)
            strings.write_string(&ap.builder, "<nil>\n")
            pop(&ap.indents)
        } else {
            print_stmt(ap, st.cont_stmt.derived_statement, true)
        }
        swap_last_indent(ap, IndentPattern.LAST)
        write_indents(ap)
        strings.write_string(&ap.builder, "body:\n")
        swap_last_indent(ap, IndentPattern.NONE)
        body_len := len(st.body)
        for body_stmt, i in st.body {
            if body_len - 1 == i {
                print_stmt(ap, body_stmt.derived_statement, true)
            } else {
                print_stmt(ap, body_stmt.derived_statement, false)
            }
        }
        pop(&ap.indents)
        pop(&ap.indents)

    case ^Break_Statement:
        append_last_or_branch(ap, last)
        write_indents(ap)
        strings.write_string(&ap.builder, "Break Statement\n")
        swap_mid_or_none(ap, last)
        append(&ap.indents, IndentPattern.LAST)
        write_indents(ap)
        fmt.sbprintfln(&ap.builder, "breaking_scope: %d", st.breaking_scope)
        pop(&ap.indents)
        pop(&ap.indents)

    case ^Return_Statement:
        append_last_or_branch(ap, last)
        write_indents(ap)
        strings.write_string(&ap.builder, "Return Statement:\n")
        swap_mid_or_none(ap, last)
        append(&ap.indents, IndentPattern.LAST)
        write_indents(ap)
        strings.write_string(&ap.builder, "expr:\n")
        swap_last_indent(ap, IndentPattern.NONE)
        if st.expr == nil {
            append(&ap.indents, IndentPattern.LAST)
            write_indents(ap)
            strings.write_string(&ap.builder, "<nil>\n")
            pop(&ap.indents)
        } else {
            print_expr(ap, st.expr.derived_expression, true)
        }
        pop(&ap.indents)
        pop(&ap.indents)

    case ^Invalid_Statement:
        append_last_or_branch(ap, last)
        write_indents(ap)
        strings.write_string(&ap.builder, "Invalid Statement\n")
        pop(&ap.indents)
    }
}

print_type_specifier :: proc(ap: ^AstPrinter, type: Any_Type) {
    switch t in type {
    case ^Builtin_Type:
        append(&ap.indents, IndentPattern.LAST)
        write_indents(ap)
        fmt.sbprintfln(&ap.builder, "%s", t.type)
        pop(&ap.indents)

    case ^Identifier_Type:
        append(&ap.indents, IndentPattern.LAST)
        write_indents(ap)
        strings.write_string(&ap.builder, "Identifier Type:\n")
        swap_last_indent(ap, IndentPattern.NONE)
        append(&ap.indents, IndentPattern.LAST)
        write_indents(ap)
        fmt.sbprintfln(&ap.builder, "identifier: %s", t.identifier)
        pop(&ap.indents)
        pop(&ap.indents)

    case ^Alias_Type:
        append(&ap.indents, IndentPattern.LAST)
        write_indents(ap)
        strings.write_string(&ap.builder, "Type Alias:\n")
        swap_last_indent(ap, IndentPattern.NONE)
        append(&ap.indents, IndentPattern.BRANCH)
        write_indents(ap)
        fmt.sbprintfln(&ap.builder, "alias: %s", t.alias)
        swap_last_indent(ap, IndentPattern.LAST)
        write_indents(ap)
        strings.write_string(&ap.builder, "type:\n")
        swap_last_indent(ap, IndentPattern.NONE)
        print_type_specifier(ap, t.type.derived_type)
        pop(&ap.indents)
        pop(&ap.indents)

    case ^Array_Type:
        append(&ap.indents, IndentPattern.LAST)
        write_indents(ap)
        strings.write_string(&ap.builder, "Array:\n")
        swap_last_indent(ap, IndentPattern.NONE)
        append(&ap.indents, IndentPattern.BRANCH)
        write_indents(ap)
        fmt.sbprintfln(&ap.builder, "length: %d", t.length)
        swap_last_indent(ap, IndentPattern.LAST)
        write_indents(ap)
        strings.write_string(&ap.builder, "type:\n")
        swap_last_indent(ap, IndentPattern.NONE)
        print_type_specifier(ap, t.type.derived_type)
        pop(&ap.indents)
        pop(&ap.indents)

    case ^Invalid_Type:
        append(&ap.indents, IndentPattern.LAST)
        write_indents(ap)
        strings.write_string(&ap.builder, "type: INVALID\n")
        pop(&ap.indents)
    }
}

print_expr :: proc(ap: ^AstPrinter, expr: Any_Expression, last: bool) {
    #partial switch ex in expr {
    case ^Expression_List:
        append_last_or_branch(ap, last)
        write_indents(ap)
        strings.write_string(&ap.builder, "Expression List:\n")
        swap_mid_or_none(ap, last)
        //swap_last_indent(ap, IndentPattern.NONE)
        if len(ex.list) == 0 {
            append(&ap.indents, IndentPattern.LAST)
            write_indents(ap)
            strings.write_string(&ap.builder, "<empty>\n")
            pop(&ap.indents)
        } else {
            expr_list_len := len(ex.list)
            for item, i in ex.list {
                if expr_list_len - 1 == i {
                    print_expr(ap, item.derived_expression, true)
                } else {
                    print_expr(ap, item.derived_expression, false)
                }
            }
        }
        pop(&ap.indents)

    case ^Binary_Expression:
        append_last_or_branch(ap, last)
        //append(&ap.indents, IndentPattern.LAST)
        write_indents(ap)
        strings.write_string(&ap.builder, "Binary Expression:\n")
        swap_mid_or_none(ap, last)
        //swap_last_indent(ap, IndentPattern.NONE)
        append(&ap.indents, IndentPattern.BRANCH)
        write_indents(ap)
        fmt.sbprintfln(&ap.builder, "op: %s", ex.op.text)
        write_indents(ap)
        strings.write_string(&ap.builder, "left:\n")
        swap_last_indent(ap, IndentPattern.MID)
        print_expr(ap, ex.left.derived_expression, true)
        swap_last_indent(ap, IndentPattern.LAST)
        write_indents(ap)
        strings.write_string(&ap.builder, "right:\n")
        swap_last_indent(ap, IndentPattern.NONE)
        print_expr(ap, ex.right.derived_expression, true)
        pop(&ap.indents)
        pop(&ap.indents)

    case ^Unary_Expression:
        append_last_or_branch(ap, last)
        write_indents(ap)
        strings.write_string(&ap.builder, "Unary Expression:\n")
        swap_mid_or_none(ap, last)
        append(&ap.indents, IndentPattern.BRANCH)
        write_indents(ap)
        fmt.sbprintfln(&ap.builder, "op: %s", ex.op.text)
        swap_last_indent(ap, IndentPattern.LAST)
        write_indents(ap)
        strings.write_string(&ap.builder, "expr:\n")
        swap_last_indent(ap, IndentPattern.NONE)
        print_expr(ap, ex.expr.derived_expression, true)
        pop(&ap.indents)
        pop(&ap.indents)

    case ^Literal:
        append_last_or_branch(ap, last)
        write_indents(ap)
        strings.write_string(&ap.builder, "Literal:\n")
        swap_mid_or_none(ap, last)
        append(&ap.indents, IndentPattern.BRANCH)
        write_indents(ap)
        fmt.sbprintfln(&ap.builder, "type: %v", ex.type)
        swap_last_indent(ap, IndentPattern.LAST)
        write_indents(ap)
        fmt.sbprintfln(&ap.builder, "value: %s", ex.value)
        pop(&ap.indents)
        pop(&ap.indents)

    case ^Identifier:
        append_last_or_branch(ap, last)
        write_indents(ap)
        strings.write_string(&ap.builder, "Identifier:\n")
        swap_mid_or_none(ap, last)
        append(&ap.indents, IndentPattern.LAST)
        write_indents(ap)
        fmt.sbprintfln(&ap.builder, "name: %s", ex.name)
        pop(&ap.indents)
        pop(&ap.indents)

    case ^Proc_Call:
        append_last_or_branch(ap, last)
        write_indents(ap)
        strings.write_string(&ap.builder, "Procedure Call:\n")
        swap_mid_or_none(ap, last)
        swap_last_indent(ap, IndentPattern.NONE)
        append(&ap.indents, IndentPattern.BRANCH)
        write_indents(ap)
        fmt.sbprintfln(&ap.builder, "name: %s", ex.name)
        swap_last_indent(ap, IndentPattern.LAST)
        write_indents(ap)
        strings.write_string(&ap.builder, "args:\n")
        swap_last_indent(ap, IndentPattern.NONE)
        print_expr(ap, ex.args.derived_expression, true)
        pop(&ap.indents)
        pop(&ap.indents)

    case ^Selector:
        // TODO: When enums/records are implemented
        //write_tabs(ap)
        strings.write_string(&ap.builder, "\u2514Identifier Selector:\n")
        //ap.indent_lvl += 1
        //defer ap.indent_lvl -= 1
        //write_tabs(ap)
        fmt.sbprintfln(&ap.builder, "\u251Cident: %s", ex.ident)
        //write_tabs(ap)
        strings.write_string(&ap.builder, "\u2514field:\n")
        print_expr(ap, ex.field.derived_expression, true)

    case ^Array_Accessor:
        append_last_or_branch(ap, last)
        write_indents(ap)
        strings.write_string(&ap.builder, "Array Accessor:\n")
        swap_mid_or_none(ap, last)
        append(&ap.indents, IndentPattern.BRANCH)
        write_indents(ap)
        fmt.sbprintfln(&ap.builder, "ident: %s", ex.ident)
        swap_last_indent(ap, IndentPattern.LAST)
        write_indents(ap)
        strings.write_string(&ap.builder, "index:\n")
        swap_last_indent(ap, IndentPattern.NONE)
        print_expr(ap, ex.index.derived_expression, true)
        pop(&ap.indents)
        pop(&ap.indents)
    }
}

write_indents :: proc(ap: ^AstPrinter) {
    for indent in ap.indents {
        strings.write_string(&ap.builder, indent_patterns[indent])
    }
}

append_last_or_branch :: proc(ap: ^AstPrinter, last: bool) {
    if last {
        append(&ap.indents, IndentPattern.LAST)
    } else {
        append(&ap.indents, IndentPattern.BRANCH)
    }
}

swap_mid_or_none :: proc(ap: ^AstPrinter, last: bool) {
    if last {
        swap_last_indent(ap, IndentPattern.NONE)
    } else {
        swap_last_indent(ap, IndentPattern.MID)
    }
}

swap_last_indent :: proc(ap: ^AstPrinter, new_pattern: IndentPattern) {
    ap.indents[len(ap.indents)-1] = new_pattern
}
