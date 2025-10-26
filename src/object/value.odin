package object

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
}

Value_Type :: union {
    i64,
    u64,
    f64,
    bool,
    string,
    rune,
}
