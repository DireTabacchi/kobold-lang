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

print_ast :: proc(ap: ^AST_Printer, prog: ^Program) {
    for stmt in prog.stmts {
        strings.write_string(&ap.builder, "Statement:\n")
        print_stmt(ap, stmt.derived_statement)
    }

    ast_string := strings.to_string(ap.builder)
    res := strings.expand_tabs(ast_string, ap.tab_size)
    fmt.println(res)
}

print_stmt :: proc(ap: ^AST_Printer, stmt: Any_Statement) {
    ap.indent_lvl += 1
    defer ap.indent_lvl -= 1

    #partial switch st in stmt {
    case ^Expression_Statement:
        write_tabs(ap)
        strings.write_string(&ap.builder, "\u2514Expression Statement:\n")
        print_expr(ap, st.expr.derived_expression)
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
    }
}

write_tabs :: proc(ap: ^AST_Printer) {
    for i := 0; i < ap.indent_lvl; i += 1 {
        strings.write_rune(&ap.builder, '\t')
    }
}
