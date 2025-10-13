package object

Value :: struct {
    type: Value_Kind,
    value: Value_Type,
    mutable: bool,
}

Value_Kind :: enum {
    Integer,
}

Value_Type :: union {
    i64,
}
