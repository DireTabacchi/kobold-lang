package compiler

import "core:fmt"
//import "kobold:code"

print :: proc(comp: Compiler) {
    fmt.println("======= <Script> =======")
    fmt.println("Bytecode:", comp.chunk.code)
    fmt.printfln("Bytecode Size: %d bytes", len(comp.chunk.code))
    for i := 0; i < len(comp.chunk.code); i += 1 {
        switch comp.chunk.code[i] {
        case u8(Op_Code.PUSH):
            hi := comp.chunk.code[i+1]
            lo := comp.chunk.code[i+2]
            idx : u16 = (u16(hi) << 8) | u16(lo)
            fmt.printfln("%8X    %-8s %#8X    %- 16v", i, "PUSH", idx, comp.chunk.constants[idx].value)
            i += 2
        case u8(Op_Code.POP):
            fmt.printfln("%8X    %-8s", i, "POP")
        case u8(Op_Code.ADD):
            fmt.printfln("%8X    %-8s", i, "ADD")
        case u8(Op_Code.SUB):
            fmt.printfln("%8X    %-8s", i, "SUB")
        case u8(Op_Code.MULT):
            fmt.printfln("%8X    %-8s", i, "MULT")
        case u8(Op_Code.DIV):
            fmt.printfln("%8X    %-8s", i, "DIV")
        case u8(Op_Code.MOD):
            fmt.printfln("%8X    %-8s", i, "MOD")
        case u8(Op_Code.MODF):
            fmt.printfln("%8X    %-8s", i, "MODF")
        case u8(Op_Code.EQ):
            fmt.printfln("%8X    %-8s", i, "EQ")
        case u8(Op_Code.NEQ):
            fmt.printfln("%8X    %-8s", i, "NEQ")
        case u8(Op_Code.LSSR):
            fmt.printfln("%8X    %-8s", i, "LSSR")
        case u8(Op_Code.GRTR):
            fmt.printfln("%8X    %-8s", i, "GRTR")
        case u8(Op_Code.LEQ):
            fmt.printfln("%8X    %-8s", i, "LEQ")
        case u8(Op_Code.GEQ):
            fmt.printfln("%8X    %-8s", i, "GEQ")
        case u8(Op_Code.LAND):
            fmt.printfln("%8X    %-8s", i, "LAND")
        case u8(Op_Code.LOR):
            fmt.printfln("%8X    %-8s", i, "LOR")
        case u8(Op_Code.NEG):
            fmt.printfln("%8X    %-8s", i, "NEG")
        case u8(Op_Code.NOT):
            fmt.printfln("%8X    %-8s", i, "NOT")
        case u8(Op_Code.JMP):
            hi := comp.chunk.code[i+1]
            lo := comp.chunk.code[i+2]
            loc : u16 = (u16(hi) << 8) | u16(lo)
            fmt.printfln("%8X    %-8s %#8X", i, "JMP", loc)
            i += 2
        case u8(Op_Code.JF):
            hi := comp.chunk.code[i+1]
            lo := comp.chunk.code[i+2]
            loc : u16 = (u16(hi) << 8) | u16(lo)
            fmt.printfln("%8X    %-8s %#8X", i, "JF", loc)
            i += 2
        case u8(Op_Code.SETG):
            hi := comp.chunk.code[i+1]
            lo := comp.chunk.code[i+2]
            idx : u16 = (u16(hi) << 8) | u16(lo)
            fmt.printfln("%8X    %-8s %#8X", i, "SETG", idx)
            i += 2
        case u8(Op_Code.GETG):
            hi := comp.chunk.code[i+1]
            lo := comp.chunk.code[i+2]
            idx : u16 = (u16(hi) << 8) | u16(lo)
            fmt.printfln("%8X    %-8s %#8X", i, "GETG", idx)
            i += 2
        case u8(Op_Code.SETL):
            hi := comp.chunk.code[i+1]
            lo := comp.chunk.code[i+2]
            idx : u16 = (u16(hi) << 8) | u16(lo)
            fmt.printfln("%8X    %-8s %#8X", i, "SETL", idx)
            i += 2
        case u8(Op_Code.GETL):
            hi := comp.chunk.code[i+1]
            lo := comp.chunk.code[i+2]
            idx : u16 = (u16(hi) << 8) | u16(lo)
            fmt.printfln("%8X    %-8s %#8X", i, "GETL", idx)
            i += 2
        case u8(Op_Code.RET):
            fmt.printfln("%8X    %-8s", i, "RET")
        }
    }
}
