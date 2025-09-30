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
    kb_tok.init(&tokenizer, os.args[1])

    tokens := kb_tok.scan(&tokenizer)
    defer delete(tokens)
    
    for tok in tokens {
        fmt.printfln("[Compiler] %v", tok)
    }
}
