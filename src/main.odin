package main

import kb_tok "tokenizer"
import "core:fmt"
import "core:os"

main :: proc() {
    args := os.args

    if len(args) < 2 {
        fmt.eprintln("Not enough arguments.")
        os.exit(1)
    }

    tokenizer : kb_tok.Tokenizer
    kb_tok.tokenizer_init(&tokenizer, os.args[1])
    defer kb_tok.tokenizer_destroy(&tokenizer)

    tokens := kb_tok.scan(&tokenizer)
    defer delete(tokens)
    
    fmt.printfln("[Tokens] %-16s\t%-16s\tline:column (offset)", "Token Type", "Literal")
    fmt.println( "----------------------------------------------------------------------------")
    for tok in tokens {
        lit: string
        if tok.type == .Doc_Comment {
            lit = tok.text[:17]
        } else {
            lit = tok.text
        }
        fmt.printfln("[Tokens] %-16v\t%-16s\t%d:%d (%d)", tok.type, lit, tok.pos.line, tok.pos.col, tok.pos.offset)
    }
}
