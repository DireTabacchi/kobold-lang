package symbol

import "kobold:tokenizer"

Symbol :: struct {
    name: string,               // Name of the symbol (const [x]...)
    type: tokenizer.Token_Kind, // Type of the symbol (const x: [int]...)
    mutable: bool,              // Mutability of the symbol ([const] x...)
    id: int,                    // ID of this symbol, converts to index
}
