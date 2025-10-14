package object

Value :: struct {
    type: Value_Kind,
    value: Value_Type,
    mutable: bool,
}

Value_Kind :: enum {
    Integer,
    Float,
    Boolean,
    String,
    Rune,
}

Value_Type :: union {
    i64,
    f64,
    bool,
    string,
    rune,
}
