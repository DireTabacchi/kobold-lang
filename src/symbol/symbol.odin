package symbol

import "core:mem"
import "core:fmt"

import "kobold:ast"
import "kobold:tokenizer"

Symbol :: struct {
    name: string,               // Name of the symbol (const [x]...)
    type: Symbol_Type,          // Type of the symbol (const x: [int]...)
    mutable: bool,              // Mutability of the symbol ([const] x...)
    scope: int,                 // Which scope this identifier belongs
    id: int,                    // ID of this symbol, converts to index
}

Symbol_Table :: struct {
    outer: ^Symbol_Table,
    scope: int,

    symbols: [dynamic]Symbol,
}

Symbol_Type :: union {
    ^Builtin_Symbol_Type,
    ^Identifier_Symbol_Type,
    ^Array_Symbol_Type,
    ^Alias_Symbol_Type,
}

Builtin_Symbol_Type :: struct {
    type: tokenizer.Token_Kind,
}

Alias_Symbol_Type :: struct {
    subtype: Symbol_Type,
}

Identifier_Symbol_Type :: struct {
    typename: string,
}

Array_Symbol_Type :: struct {
    type: Symbol_Type,  // The type that the array holds
    length: int,
}

make_symbol_type_pos :: proc(pos: tokenizer.Pos, type_spec: ^ast.Type_Specifier) -> Symbol_Type {
    type: Symbol_Type
    #partial switch t in type_spec.derived_type {
    case ^ast.Builtin_Type:
        type, _ = mem.new(Builtin_Symbol_Type)
        type.(^Builtin_Symbol_Type).type = t.type
    case ^ast.Array_Type:
        type, _ = mem.new(Array_Symbol_Type)
        #partial switch arr_type in t.type.derived_type {
        case ^ast.Builtin_Type:
            type.(^Array_Symbol_Type).type, _ = mem.new(Builtin_Symbol_Type)
            type.(^Array_Symbol_Type).type.(^Builtin_Symbol_Type).type = arr_type.type
        case ^ast.Array_Type:
            error_msg(pos, "multi-dimensional arrays are not yet supported")
            type.(^Array_Symbol_Type).type, _ = mem.new(Builtin_Symbol_Type)
            type.(^Array_Symbol_Type).type.(^Builtin_Symbol_Type).type = tokenizer.Token_Kind.ARRAY
        }
    case ^ast.Identifier_Type:
        type, _ = mem.new(Identifier_Symbol_Type)
        type.(^Identifier_Symbol_Type).typename = t.identifier
    case ^ast.Alias_Type:
        type, _ = mem.new(Alias_Symbol_Type)
        type.(^Alias_Symbol_Type).subtype = make_symbol_type_pos(pos, t.subtype)
    }
    return type
}

make_symbol_type_no_pos :: proc(type_spec: ^ast.Type_Specifier) -> Symbol_Type {
    type: Symbol_Type
    #partial switch t in type_spec.derived_type {
    case ^ast.Builtin_Type:
        type, _ = mem.new(Builtin_Symbol_Type)
        type.(^Builtin_Symbol_Type).type = t.type
    case ^ast.Array_Type:
        type, _ = mem.new(Array_Symbol_Type)
        #partial switch arr_type in t.type.derived_type {
        case ^ast.Builtin_Type:
            type.(^Array_Symbol_Type).type, _ = mem.new(Builtin_Symbol_Type)
            type.(^Array_Symbol_Type).type.(^Builtin_Symbol_Type).type = arr_type.type
        case ^ast.Array_Type:
            type.(^Array_Symbol_Type).type, _ = mem.new(Builtin_Symbol_Type)
            type.(^Array_Symbol_Type).type.(^Builtin_Symbol_Type).type = tokenizer.Token_Kind.ARRAY
        }
    case ^ast.Identifier_Type:
        type, _ = mem.new(Identifier_Symbol_Type)
        type.(^Identifier_Symbol_Type).typename = t.identifier
    case ^ast.Alias_Type:
        type, _ = mem.new(Alias_Symbol_Type)
        type.(^Alias_Symbol_Type).subtype = make_symbol_type_no_pos(t.subtype)
    }
    return type
}

make_symbol_type :: proc{
    make_symbol_type_pos,
    make_symbol_type_no_pos,
}

symbol_destroy :: proc(sym: ^Symbol) {
    symbol_type_destroy(&sym.type)
}

symbol_type_destroy :: proc(sym_type: ^Symbol_Type) {
    switch t in sym_type {
    case ^Builtin_Symbol_Type:
        free(t)
    case ^Array_Symbol_Type:
        symbol_type_destroy(&t.type)
        free(t)
    case ^Identifier_Symbol_Type:
        free(t)
    case ^Alias_Symbol_Type:
        symbol_type_destroy(&t.subtype)
        free(t)
    }
}

type_specifier_from_symbol_type :: proc(st: Symbol_Type) -> ^ast.Type_Specifier {
    ZERO_POS :: tokenizer.Pos { 0, 0, 0 }
    switch sym_type in st {
    case ^Builtin_Symbol_Type:
        bt := ast.new(ast.Builtin_Type, ZERO_POS, ZERO_POS)
        bt.type = sym_type.type
        return bt
    case ^Array_Symbol_Type:
        at := ast.new(ast.Array_Type, ZERO_POS, ZERO_POS)
        at.length = sym_type.length
        at.type = type_specifier_from_symbol_type(sym_type.type)
        return at
    case ^Identifier_Symbol_Type:
        it := ast.new(ast.Identifier_Type, ZERO_POS, ZERO_POS)
        it.identifier = sym_type.typename
        return it
    case ^Alias_Symbol_Type:
        at := ast.new(ast.Alias_Type, ZERO_POS, ZERO_POS)
        at.subtype = type_specifier_from_symbol_type(sym_type.subtype)
        return at
    }
    it := ast.new(ast.Builtin_Type, ZERO_POS, ZERO_POS)
    return it
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

table_destroy :: proc(st: ^Symbol_Table) {
    for &sym in st.symbols {
        symbol_destroy(&sym)
    }
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

error_msg :: proc(pos: tokenizer.Pos, msg: string) {
    fmt.eprintfln("[%d:%d] %s", pos.line, pos.col, msg)
}
