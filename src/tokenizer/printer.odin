package tokenizer

import "core:fmt"
import "kobold:tokenizer"

print :: proc(tokens: []tokenizer.Token) {
    fmt.printfln("%-16s\t%-16s\tline:column (offset)", "Token Type", "Literal")
    fmt.println( "----------------------------------------------------------------------------")
    for token in tokens {
        lit: string
        if token.type == .DOC_COMMENT {
            lit = token.text[:17]
        } else {
            lit = token.text
        }
        fmt.printfln("%-16v\t%-16s\t%d:%d (%d)", token.type, lit, token.pos.line, token.pos.col, token.pos.offset)
    }

    fmt.println()
}
