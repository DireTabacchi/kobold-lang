package code

//import "kobold:object"

Op_Code :: enum byte {
    PushC,      // Push a constant onto the stack. Op1: 2-byte index into constants table.
    Add,        // Add the two values on the top of the stack. [SP-1] + [SP]
    Subtract,   // Subtract two values on the top of the stack. [SP-1] = [SP]
    Multiply,   // Multiply the two values on the top of the stack. [SP-1] * [SP]
    Divide,     // Divide the two values on the top of the stack. [SP-1] / [SP]
}

Byte_Code :: byte
