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
    Nil,
    Integer,
    Unsigned_Integer,
    Float,
    Boolean,
    String,
    Rune,
    Array,
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
    case .Type_Integer:
        return Value_Kind.Integer
    case .Type_Unsigned_Integer:
        return Value_Kind.Unsigned_Integer
    case .Type_Float:
        return Value_Kind.Float
    case .Type_Boolean:
        return Value_Kind.Boolean
    case .Type_String:
        return Value_Kind.String
    case .Type_Rune:
        return Value_Kind.Rune
    }
    return Value_Kind.Nil
}

value_from_token_kind :: proc(val_type: tokenizer.Token_Kind, mutable: bool) -> Object {
    obj: Object
    obj.mutable = mutable
    #partial switch val_type {
    case .Type_Integer:
        obj.type = .Integer
        obj.value = i64(0)
    case .Type_Unsigned_Integer:
        obj.type = .Unsigned_Integer
        obj.value = u64(0)
    case .Type_Float:
        obj.type = .Float
        obj.value = 0.0
    case .Type_Boolean:
        obj.type = .Boolean
        obj.value = false
    case .Type_String:
        obj.type = .String
        obj.value = ""
    case .Type_Rune:
        obj.type = .Rune
        obj.value = rune(0)
    }

    return obj
}
