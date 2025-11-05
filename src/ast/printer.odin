package ast

import "base:intrinsics"
import "core:fmt"
import "core:strings"

import "kobold:tokenizer"

AST_Printer :: struct {
    builder: strings.Builder,
    indent_lvl: int,
    tab_size: int,
}

printer_init :: proc(ap: ^AST_Printer, tab_size: int = 4) {
    ap.builder = strings.builder_make()
    ap.indent_lvl = 0
    ap.tab_size = 4
}

printer_destroy :: proc(ap: ^AST_Printer) {
    strings.builder_destroy(&ap.builder)
}

print_ast :: proc(ap: ^AST_Printer, prog: ^Program) {
    for stmt in prog.stmts {
        strings.write_string(&ap.builder, "Statement:\n")
        print_stmt(ap, stmt.derived_statement)
    }

    ast_string := strings.to_string(ap.builder)
    res := strings.expand_tabs(ast_string, ap.tab_size)
    fmt.println(res)
    delete(res)
}

print_stmt :: proc(ap: ^AST_Printer, stmt: Any_Statement) {
    ap.indent_lvl += 1
    defer ap.indent_lvl -= 1

    #partial switch st in stmt {
    case ^Declarator:
        write_tabs(ap)
        strings.write_string(&ap.builder, "\u2514Declarator:\n")
        ap.indent_lvl += 1
        defer ap.indent_lvl -= 1
        write_tabs(ap)
        fmt.sbprintfln(&ap.builder, "\u251Cmutability: %s", st.mutable ? "var" : "const")
        write_tabs(ap)
        fmt.sbprintfln(&ap.builder, "\u251Cname: %s", st.name)
        write_tabs(ap)
        strings.write_string(&ap.builder, "\u251Ctype:\n")
        //fmt.println(st.type)
        print_type_specifier(ap, st.type.derived_type)
        write_tabs(ap)
        strings.write_string(&ap.builder, "\u2514value:\n")
        if st.value != nil {
            print_expr(ap, st.value.derived_expression)
        } else {
            ap.indent_lvl += 1
            defer ap.indent_lvl -= 1
            write_tabs(ap)
            strings.write_string(&ap.builder, "<nil>\n")
        }
    case ^Procedure_Declarator:
        write_tabs(ap)
        strings.write_string(&ap.builder, "\u2514Procedure Declarator:\n")
        ap.indent_lvl += 1
        defer ap.indent_lvl -= 1
        write_tabs(ap)
        fmt.sbprintfln(&ap.builder, "\u251Cname: %s", st.name)
        write_tabs(ap)
        strings.write_string(&ap.builder, "\u251Cparams:")
        if len(st.params) == 0 {
            strings.write_string(&ap.builder, " <empty>\n")
        } else {
            strings.write_string(&ap.builder, "\n")
            for param in st.params {
                print_stmt(ap, param.derived_statement)
            }
        }
        if st.return_type != nil {
            write_tabs(ap)
            strings.write_string(&ap.builder, "\u251Creturn_type:\n")
            //ap.indent_lvl += 1
            //write_tabs(ap)
            print_type_specifier(ap, st.return_type.derived_type)
            //ap.indent_lvl -= 1

        }
        write_tabs(ap)
        strings.write_string(&ap.builder, "\u2514body:\n")
        if len(st.body) == 0 {
            ap.indent_lvl += 1
            write_tabs(ap)
            strings.write_string(&ap.builder, "<empty>\n")
            ap.indent_lvl -= 1
        } else {
            for body_stmt in st.body {
                print_stmt(ap, body_stmt.derived_statement)
            }
        }
    case ^Parameter_Declarator:
        write_tabs(ap)
        strings.write_string(&ap.builder, "\u2514Parameter Declarator:\n")
        ap.indent_lvl += 1
        defer ap.indent_lvl -= 1
        write_tabs(ap)
        fmt.sbprintfln(&ap.builder, "\u251Cname: %s", st.name)
        //write_tabs(ap)
        print_type_specifier(ap, st.type.derived_type)
    case ^Assignment_Statement:
        write_tabs(ap)
        strings.write_string(&ap.builder, "\u2514Assignment Statement:\n")
        ap.indent_lvl += 1
        defer ap.indent_lvl -= 1
        write_tabs(ap)
        strings.write_string(&ap.builder, "\u251Cident:\n")
        print_expr(ap, st.ident.derived_expression)
        //fmt.sbprintfln(&ap.builder, "\u251Cname: %s", st.name)
        write_tabs(ap)
        strings.write_string(&ap.builder, "\u2514value:\n")
        print_expr(ap, st.value.derived_expression)
    case ^Assignment_Operation_Statement:
        write_tabs(ap)
        strings.write_string(&ap.builder, "\u2514Assignment Operation Statement:\n")
        ap.indent_lvl += 1
        defer ap.indent_lvl -= 1
        write_tabs(ap)
        //fmt.sbprintfln(&ap.builder, "\u251Cident: %s", st.name)
        strings.write_string(&ap.builder, "\u251Cident:\n")
        print_expr(ap, st.ident.derived_expression)
        write_tabs(ap)
        fmt.sbprintfln(&ap.builder, "\u251Cop: %s", tokenizer.token_list[st.op])
        write_tabs(ap)
        strings.write_string(&ap.builder, "\u2514value:\n")
        print_expr(ap, st.value.derived_expression)
    case ^Expression_Statement:
        write_tabs(ap)
        strings.write_string(&ap.builder, "\u2514Expression Statement:\n")
        print_expr(ap, st.expr.derived_expression)
    case ^If_Statement:
        write_tabs(ap)
        strings.write_string(&ap.builder, "\u2514If Statement:\n")
        ap.indent_lvl += 1
        defer ap.indent_lvl -= 1
        write_tabs(ap)
        strings.write_string(&ap.builder, "cond:\n")
        print_expr(ap, st.cond.derived_expression)
        write_tabs(ap)
        strings.write_string(&ap.builder, "consequent:\n")
        for cons in st.consequent {
            print_stmt(ap, cons.derived_statement)
        }
        write_tabs(ap)
        strings.write_string(&ap.builder, "alternative:\n")
        if st.alternative != nil {
            print_stmt(ap, st.alternative.derived_statement)
        } else {
            ap.indent_lvl += 1
            write_tabs(ap)
            strings.write_string(&ap.builder, "<nil>\n")
            ap.indent_lvl -= 1
        }
    case ^Else_If_Statement:
        write_tabs(ap)
        strings.write_string(&ap.builder, "\u2514Else If Statement:\n")
        ap.indent_lvl += 1
        defer ap.indent_lvl -= 1
        write_tabs(ap)
        strings.write_string(&ap.builder, "cond:\n")
        print_expr(ap, st.cond.derived_expression)
        write_tabs(ap)
        strings.write_string(&ap.builder, "consequent:\n")
        for cons in st.consequent {
            print_stmt(ap, cons.derived_statement)
        }
        write_tabs(ap)
        strings.write_string(&ap.builder, "alternative:\n")
        if st.alternative != nil {
            print_stmt(ap, st.alternative.derived_statement)
        } else {
            ap.indent_lvl += 1
            write_tabs(ap)
            strings.write_string(&ap.builder, "\u2514nil\n")
            ap.indent_lvl -= 1
        }
    case ^Else_Statement:
        write_tabs(ap)
        strings.write_string(&ap.builder, "\u2514Else Statement:\n")
        ap.indent_lvl += 1
        defer ap.indent_lvl -= 1
        write_tabs(ap)
        strings.write_string(&ap.builder, "\u2514consequent:\n")
        for cons in st.consequent {
            print_stmt(ap, cons.derived_statement)
        }
    case ^For_Statement:
        write_tabs(ap)
        strings.write_string(&ap.builder, "\u2514For Statement:\n")
        ap.indent_lvl += 1
        defer ap.indent_lvl -= 1
        write_tabs(ap)
        strings.write_string(&ap.builder, "decl:\n")
        if st.decl == nil {
            ap.indent_lvl += 1
            write_tabs(ap)
            strings.write_string(&ap.builder, "\u2514nil\n")
            ap.indent_lvl -= 1
        } else {
            print_stmt(ap, st.decl.derived_statement)
        }
        write_tabs(ap)
        strings.write_string(&ap.builder, "cond_expr:\n")
        if st.cond_expr == nil {
            ap.indent_lvl += 1
            write_tabs(ap)
            strings.write_string(&ap.builder, "\u2514nil\n")
            ap.indent_lvl -= 1
        } else {
            print_expr(ap, st.cond_expr.derived_expression)
        }
        write_tabs(ap)
        strings.write_string(&ap.builder, "cont_stmt:\n")
        if st.cont_stmt ==  nil {
            ap.indent_lvl += 1
            write_tabs(ap)
            strings.write_string(&ap.builder, "\u2514nil\n")
            ap.indent_lvl -= 1
        } else {
            print_stmt(ap, st.cont_stmt.derived_statement)
        }
        write_tabs(ap)
        strings.write_string(&ap.builder, "body:\n")
        for body_stmt in st.body {
            print_stmt(ap, body_stmt.derived_statement)
        }
    case ^Break_Statement:
        write_tabs(ap)
        strings.write_string(&ap.builder, "\u2514Break Statement\n")
        ap.indent_lvl += 1
        write_tabs(ap)
        fmt.sbprintfln(&ap.builder, "\u2514breaking_scope: %d", st.breaking_scope)
        ap.indent_lvl -= 1
    case ^Return_Statement:
        write_tabs(ap)
        strings.write_string(&ap.builder, "\u2514Return Statement:\n")
        ap.indent_lvl += 1
        defer ap.indent_lvl -= 1
        write_tabs(ap)
        strings.write_string(&ap.builder, "\u2514expr:\n")
        if st.expr == nil {
            ap.indent_lvl += 1
            write_tabs(ap)
            strings.write_string(&ap.builder, "<nil>\n")
            ap.indent_lvl -= 1
        } else {
            print_expr(ap, st.expr.derived_expression)
        }
    }

}

print_type_specifier :: proc(ap: ^AST_Printer, type: Any_Type) {
    ap.indent_lvl += 1
    defer ap.indent_lvl -= 1

    switch t in type {
    case ^Builtin_Type:
        write_tabs(ap)
        fmt.sbprintfln(&ap.builder, "\u2514%s", t.type)
    case ^Array_Type:
        write_tabs(ap)
        strings.write_string(&ap.builder, "\u2514Array:\n")
        ap.indent_lvl += 1
        defer ap.indent_lvl -= 1
        write_tabs(ap)
        fmt.sbprintfln(&ap.builder, "\u251Clength: %d", t.length)
        write_tabs(ap)
        strings.write_string(&ap.builder, "\u2514type:\n")
        print_type_specifier(ap, t.type.derived_type)
    case ^Invalid_Type:
        strings.write_string(&ap.builder, "\u2514type: INVALID\n")
    }
}

print_expr :: proc(ap: ^AST_Printer, expr: Any_Expression) {
    ap.indent_lvl += 1
    defer ap.indent_lvl -= 1

    #partial switch ex in expr {
    case ^Expression_List:
        write_tabs(ap)
        strings.write_string(&ap.builder, "\u2514Expression List:\n")
        if len(ex.list) == 0 {
            ap.indent_lvl += 1
            write_tabs(ap)
            strings.write_string(&ap.builder, "<empty>\n")
            ap.indent_lvl -= 1
        } else {
            for item in ex.list {
                print_expr(ap, item.derived_expression)
            }
        }

    case ^Binary_Expression:
        write_tabs(ap)
        strings.write_string(&ap.builder, "\u2514Binary Expression:\n")
        ap.indent_lvl += 1
        defer ap.indent_lvl -= 1
        write_tabs(ap)
        fmt.sbprintfln(&ap.builder, "op: %s", ex.op.text)
        write_tabs(ap)
        strings.write_string(&ap.builder, "left:\n")
        print_expr(ap, ex.left.derived_expression)
        write_tabs(ap)
        strings.write_string(&ap.builder, "right:\n")
        print_expr(ap, ex.right.derived_expression)

    case ^Unary_Expression:
        write_tabs(ap)
        strings.write_string(&ap.builder, "\u2514Unary Expression:\n")
        ap.indent_lvl += 1
        defer ap.indent_lvl -= 1
        write_tabs(ap)
        fmt.sbprintfln(&ap.builder, "op: %s", ex.op.text)
        write_tabs(ap)
        strings.write_string(&ap.builder, "expr:\n")
        print_expr(ap, ex.expr.derived_expression)

    case ^Literal:
        write_tabs(ap)
        strings.write_string(&ap.builder, "\u2514Literal:\n")
        ap.indent_lvl += 1
        defer ap.indent_lvl -= 1
        write_tabs(ap)
        fmt.sbprintfln(&ap.builder, "\u251Ctype: %v", ex.type)
        write_tabs(ap)
        fmt.sbprintfln(&ap.builder, "\u2514value: %s", ex.value)

    case ^Identifier:
        write_tabs(ap)
        strings.write_string(&ap.builder, "\u2514Identifier:\n")
        ap.indent_lvl += 1
        defer ap.indent_lvl -= 1
        write_tabs(ap)
        fmt.sbprintfln(&ap.builder, "\u2514name: %s", ex.name)

    case ^Proc_Call:
        write_tabs(ap)
        strings.write_string(&ap.builder, "\u2514Procedure Call:\n")
        ap.indent_lvl += 1
        defer ap.indent_lvl -= 1
        write_tabs(ap)
        fmt.sbprintfln(&ap.builder, "\u251Cname: %s", ex.name)
        write_tabs(ap)
        strings.write_string(&ap.builder, "\u2514args:\n")
        print_expr(ap, ex.args.derived_expression)
    case ^Selector:
        write_tabs(ap)
        strings.write_string(&ap.builder, "\u2514Identifier Selector:\n")
        ap.indent_lvl += 1
        defer ap.indent_lvl -= 1
        write_tabs(ap)
        fmt.sbprintfln(&ap.builder, "\u251Cident: %s", ex.ident)
        write_tabs(ap)
        strings.write_string(&ap.builder, "\u2514field:\n")
        print_expr(ap, ex.field.derived_expression)
    case ^Array_Accessor:
        write_tabs(ap)
        strings.write_string(&ap.builder, "\u2514Array Accessor:\n")
        ap.indent_lvl += 1
        defer ap.indent_lvl -= 1
        write_tabs(ap)
        fmt.sbprintfln(&ap.builder, "\u251Cident: %s", ex.ident)
        write_tabs(ap)
        strings.write_string(&ap.builder, "\u2514index:\n")
        print_expr(ap, ex.index.derived_expression)
    }
}

write_tabs :: proc(ap: ^AST_Printer) {
    for i := 0; i < ap.indent_lvl; i += 1 {
        strings.write_rune(&ap.builder, '\t')
    }
}
