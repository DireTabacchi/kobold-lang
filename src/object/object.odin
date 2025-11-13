package object

import "kobold:tokenizer"

Object :: struct {
    type: Value_Kind,
    value: Value_Type,
    mutable: bool,

    ref_count: int,
}

Local :: struct {
    using val: Object,
    scope: int,
}

Global :: struct {
    using val: Object,
}

Value_Kind :: enum {
    NIL,
    INTEGER,
    UNSIGNED_INTEGER,
    FLOAT,
    BOOLEAN,
    STRING,
    RUNE,
    ARRAY,
}

Value_Type :: union {
    i64,
    u64,
    f64,
    bool,
    string,
    rune,
    Array,
}

Array :: struct {
    data: []Object,
    type: Value_Kind,
    len: int,
}

value_kind :: proc(tok_type: tokenizer.Token_Kind) -> Value_Kind {
    #partial switch tok_type {
    case .TYPE_INTEGER:
        return Value_Kind.INTEGER
    case .TYPE_UNSIGNED_INTEGER:
        return Value_Kind.UNSIGNED_INTEGER
    case .TYPE_FLOAT:
        return Value_Kind.FLOAT
    case .TYPE_BOOLEAN:
        return Value_Kind.BOOLEAN
    case .TYPE_STRING:
        return Value_Kind.STRING
    case .TYPE_RUNE:
        return Value_Kind.RUNE
    }
    return Value_Kind.NIL
}

value_from_token_kind :: proc(val_type: tokenizer.Token_Kind, mutable: bool) -> Object {
    obj: Object
    obj.mutable = mutable
    #partial switch val_type {
    case .TYPE_INTEGER:
        obj.type = .INTEGER
        obj.value = i64(0)
    case .TYPE_UNSIGNED_INTEGER:
        obj.type = .UNSIGNED_INTEGER
        obj.value = u64(0)
    case .TYPE_FLOAT:
        obj.type = .FLOAT
        obj.value = 0.0
    case .TYPE_BOOLEAN:
        obj.type = .BOOLEAN
        obj.value = false
    case .TYPE_STRING:
        obj.type = .STRING
        obj.value = ""
    case .TYPE_RUNE:
        obj.type = .RUNE
        obj.value = rune(0)
    }

    return obj
}
