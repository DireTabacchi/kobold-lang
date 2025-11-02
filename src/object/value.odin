package object

import "kobold:tokenizer"

Value :: struct {
    type: Value_Kind,
    value: Value_Type,
    mutable: bool,
}

Local :: struct {
    using val: Value,
    scope: int,
}

Global :: struct {
    using val: Value,
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
    data: []Value,
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

value_from_token_kind :: proc(val_type: tokenizer.Token_Kind, mutable: bool) -> Value {
    val: Value
    val.mutable = mutable
    #partial switch val_type {
    case .Type_Integer:
        val.type = .Integer
        val.value = i64(0)
    case .Type_Unsigned_Integer:
        val.type = .Unsigned_Integer
        val.value = u64(0)
    case .Type_Float:
        val.type = .Float
        val.value = 0.0
    case .Type_Boolean:
        val.type = .Boolean
        val.value = false
    case .Type_String:
        val.type = .String
        val.value = ""
    case .Type_Rune:
        val.type = .Rune
        val.value = rune(0)
    }

    return val
}
