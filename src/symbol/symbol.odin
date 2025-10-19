package symbol

import "core:mem"

import "kobold:tokenizer"

Symbol :: struct {
    name: string,               // Name of the symbol (const [x]...)
    type: tokenizer.Token_Kind, // Type of the symbol (const x: [int]...)
    mutable: bool,              // Mutability of the symbol ([const] x...)
    scope: int,                 // Which scope this identifier belongs
    id: int,                    // ID of this symbol, converts to index
}

Symbol_Table :: struct {
    outer: ^Symbol_Table,
    scope: int,

    symbols: [dynamic]Symbol,
}

new_with_none :: proc() -> ^Symbol_Table {
    st, _ := mem.new(Symbol_Table)
    return st
}

new_with_outer :: proc(outer: ^Symbol_Table) -> ^Symbol_Table {
    st, _ := mem.new(Symbol_Table)
    st.outer = outer
    st.scope = outer.scope + 1
    return st
}

new :: proc{
    new_with_none,
    new_with_outer,
}

destroy :: proc(st: ^Symbol_Table) {
    delete(st.symbols)
    free(st)
}

symbol_exists :: proc(name: string, sym_table: Symbol_Table) -> (Symbol, bool) {
    for sym in sym_table.symbols {
        if name == sym.name {
            return sym, true
        }
    }

    if sym_table.outer != nil {
        return symbol_exists(name, sym_table.outer^)
    }

    return Symbol{}, false
}
