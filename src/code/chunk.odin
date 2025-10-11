package code

import "kobold:object"

Chunk :: struct {
    code: [dynamic]Byte_Code,
    constants: [dynamic]object.Value,
}
