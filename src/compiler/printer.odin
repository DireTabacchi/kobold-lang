package compiler

import "core:fmt"
import "kobold:code"

Op_Code :: code.Op_Code

print :: proc(chunk: code.Chunk) {
    fmt.println("======= <Script> =======")
    fmt.println(chunk.code)
    for i := 0; i < len(chunk.code); i += 1 {
        switch chunk.code[i] {
        case u8(Op_Code.PushC):
            hi := chunk.code[i+1]
            lo := chunk.code[i+2]
            idx : u16 = (u16(hi) << 8) | u16(lo)
            fmt.printfln("%8X    %-16s %#8X % 16d", i, "PUSHC", idx, chunk.constants[idx].value)
            i += 2
        case u8(Op_Code.Add):
            fmt.printfln("%8X    %-16s", i, "ADD")
        case u8(Op_Code.Subtract):
            fmt.printfln("%8X    %-16s", i, "SUB")
        case u8(Op_Code.Multiply):
            fmt.printfln("%8X    %-16s", i, "MULT")
        case u8(Op_Code.Divide):
            fmt.printfln("%8X    %-16s", i, "DIV")
        }
    }
}
