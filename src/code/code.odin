package code

//import "kobold:object"

Op_Code :: enum byte {
    PUSHC,  // Push a constant onto the stack. Op1: 2-byte index into constants table.
    ADD,    // Add the two values on the top of the stack. [SP-1] + [SP]
    SUB,    // Subtract two values on the top of the stack. [SP-1] - [SP]
    MULT,   // Multiply the two values on the top of the stack. [SP-1] * [SP]
    DIV,    // Divide the two values on the top of the stack. [SP-1] / [SP]
    MOD,    // Perform modulo with truncated division of the two values on the top of the stack. [SP-1] % [SP]
    MODF,   // Perform modulo with floored division of the two values on the top of the stack. [SP-1] %% [SP]
    NEG,    // Negate the value at the top of the stack
    SETG,   // Set a global variable to a value. Op1: 2-byte index into globals table.
    RET,    // (Planned) Return (a possible value) from function call. (Current) Exit program execution.
}

Byte_Code :: byte
