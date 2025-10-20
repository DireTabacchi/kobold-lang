package ast

import "base:intrinsics"
import "core:fmt"
import "core:strings"

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
        strings.write_rune(&ap.builder, '\u251C')
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
            strings.write_string(&ap.builder, "\u2514nil\n")
        }
    case ^Assignment_Statement:
        write_tabs(ap)
        strings.write_string(&ap.builder, "\u2514Assignment Statement:\n")
        ap.indent_lvl += 1
        defer ap.indent_lvl -= 1
        write_tabs(ap)
        fmt.sbprintfln(&ap.builder, "\u251Cname: %s", st.name)
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
        for stmt in st.consequent {
            print_stmt(ap, stmt.derived_statement)
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
        for stmt in st.consequent {
            print_stmt(ap, stmt.derived_statement)
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
        for stmt in st.consequent {
            print_stmt(ap, stmt.derived_statement)
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
        print_expr(ap, st.cond_expr.derived_expression)
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
        for s in st.body {
            print_stmt(ap, s.derived_statement)
        }
    }

}

print_type_specifier :: proc(ap: ^AST_Printer, type: Any_Type) {
    switch t in type {
    case ^Builtin_Type:
        fmt.sbprintfln(&ap.builder, "type: %s", t.type)
    case ^Invalid_Type:
        strings.write_string(&ap.builder, "type: INVALID\n")
    }
}

print_expr :: proc(ap: ^AST_Printer, expr: Any_Expression) {
    ap.indent_lvl += 1
    defer ap.indent_lvl -= 1

    #partial switch ex in expr {
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
        for arg in ex.args {
            print_expr(ap, arg.derived_expression)
        }
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
    }
}

write_tabs :: proc(ap: ^AST_Printer) {
    for i := 0; i < ap.indent_lvl; i += 1 {
        strings.write_rune(&ap.builder, '\t')
    }
}
