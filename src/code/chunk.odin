package code

import "kobold:object"

Chunk :: struct {
    code: [dynamic]Byte_Code,
    constants: [dynamic]object.Object,
}

chunk_destroy :: proc(ch: ^Chunk) {
    for c in ch.constants {
        if c.type == object.Value_Kind.Array {
            arr, _ := c.value.(object.Array)
            delete(arr.data)
        }
    }
    delete(ch.constants)
    delete(ch.code)
}
