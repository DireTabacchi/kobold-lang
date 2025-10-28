package main

import "base:intrinsics"
import "core:fmt"
import "core:os"
import "core:mem"
_ :: mem

import "kobold:tokenizer"
import "kobold:parser"
import "kobold:ast"
import "kobold:compiler"
import "kobold:vm"

KOBOLD_VERSION :: "0.0.41"

main :: proc() {
    when ODIN_DEBUG {   // From Odin Overview
        track: mem.Tracking_Allocator
        mem.tracking_allocator_init(&track, context.allocator)
        context.allocator = mem.tracking_allocator(&track)

        defer {
            if len(track.allocation_map) > 0 {
                bytes_leaked := 0
                fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
                for _, entry in track.allocation_map {
                    fmt.eprintfln("- %v bytes @ %v\n", entry.size, entry.location)
                    bytes_leaked += entry.size
                }
                fmt.eprintfln("Leaked a total of %v bytes.", bytes_leaked)
            }

            if len(track.bad_free_array) > 0 {
                for entry in track.bad_free_array {
                    fmt.eprintfln("%v bad free at %v\n", entry.location, entry.memory)
                }
            }

            mem.tracking_allocator_destroy(&track)
        }
    }

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

    tokenizer.print(tokens[:])
    
    p : parser.Parser
    parser.parser_init(&p, tokens[:])
    defer parser.parser_destroy(&p)
    parser.parse(&p)
    defer ast.destroy(p.prog)

    if p.error_count > 0 {
        return
    }

    fmt.println("Symbol Table:")
    for sym in p.sym_table.symbols {
        fmt.println(sym)
    }

    printer: ast.AST_Printer
    ast.printer_init(&printer)
    ast.print_ast(&printer, p.prog)

    ast.printer_destroy(&printer)

    comp: compiler.Compiler
    compiler.compiler_init(&comp)

    compiler.compile(&comp, p.prog)
    defer compiler.compiler_destroy(&comp)

    compiler.print(comp)

    //fmt.println("Constants:")
    //fmt.println(comp.chunk.constants)

    fmt.println("Globals:")
    fmt.println(comp.globals)

    virtual_machine: vm.Virtual_Machine
    vm.vm_init(&virtual_machine, comp.main_proc, comp.procs[:])

    vm.run(&virtual_machine)
    fmt.println("=== VM Finished ===")
    fmt.printfln("Stack top: %v", virtual_machine.stack[virtual_machine.frames[virtual_machine.frame_count-1].sp-1].value)
    fmt.printfln("Globals:\n%v", virtual_machine.globals)
    fmt.printfln("stack:\n%v", virtual_machine.stack[:virtual_machine.frames[virtual_machine.frame_count-1].sp])
    vm.vm_destroy(&virtual_machine)
}
