package compiler

import "core:fmt"
import "kobold:code"

print :: proc(chunk: code.Chunk) {
    fmt.println("======= <Script> =======")
    fmt.println("Bytecode:", chunk.code)
    for i := 0; i < len(chunk.code); i += 1 {
        switch chunk.code[i] {
        case u8(Op_Code.PUSHC):
            hi := chunk.code[i+1]
            lo := chunk.code[i+2]
            idx : u16 = (u16(hi) << 8) | u16(lo)
            fmt.printfln("%8X    %-16s %#8X % 16d", i, "PUSHC", idx, chunk.constants[idx].value)
            i += 2
        case u8(Op_Code.ADD):
            fmt.printfln("%8X    %-16s", i, "ADD")
        case u8(Op_Code.SUB):
            fmt.printfln("%8X    %-16s", i, "SUB")
        case u8(Op_Code.MULT):
            fmt.printfln("%8X    %-16s", i, "MULT")
        case u8(Op_Code.DIV):
            fmt.printfln("%8X    %-16s", i, "DIV")
        case u8(Op_Code.MOD):
            fmt.printfln("%8X    %-16s", i, "MOD")
        case u8(Op_Code.MODF):
            fmt.printfln("%8X    %-16s", i, "MODF")
        case u8(Op_Code.NEG):
            fmt.printfln("%8X    %-16s", i, "NEG")
        case u8(Op_Code.RET):
            fmt.printfln("%8X    %-16s", i, "RET")
        }
    }
}
