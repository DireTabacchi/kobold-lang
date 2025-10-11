package code

import "kobold:object"

Chunk :: struct {
    code: [dynamic]Byte_Code,
    constants: [dynamic]object.Value,
}

chunk_destroy :: proc(ch: ^Chunk) {
    delete(ch.constants)
    delete(ch.code)
}
