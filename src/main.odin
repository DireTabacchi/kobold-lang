package main

import "base:intrinsics"
import "core:fmt"
import "core:os"
import "kobold:tokenizer"
import "kobold:parser"
import "kobold:ast"

KOBOLD_VERSION :: "0.0.22" // Since commit c34c5f

main :: proc() {
    args := os.args

    if len(args) < 2 {
        fmt.eprintln("Not enough arguments.")
        os.exit(1)
    }

    tok : tokenizer.Tokenizer
    tokenizer.tokenizer_init(&tok, os.args[1])
    defer tokenizer.tokenizer_destroy(&tok)

    tokens := tokenizer.scan(&tok)
    defer delete(tokens)
    
    fmt.printfln("[Tokens] %-16s\t%-16s\tline:column (offset)", "Token Type", "Literal")
    fmt.println( "----------------------------------------------------------------------------")
    for token in tokens {
        lit: string
        if token.type == .Doc_Comment {
            lit = token.text[:17]
        } else {
            lit = token.text
        }
        fmt.printfln("[Tokens] %-16v\t%-16s\t%d:%d (%d)", token.type, lit, token.pos.line, token.pos.col, token.pos.offset)
    }

    fmt.println()

    p : parser.Parser
    parser.parser_init(&p, tokens[:])
    parser.parse(&p)

    if p.error_count > 0 {
        return
    }

    printer: ast.AST_Printer
    ast.printer_init(&printer)
    ast.print_ast(&printer, p.prog)
}
