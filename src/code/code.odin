package code

//import "kobold:object"

Op_Code :: enum byte {
    PUSHC,  // Push a constant onto the stack. Op1: 2-byte index into constants table.
    ADD,    // Add the two values on the top of the stack. [SP-1] + [SP]
    SUB,    // Subtract two values on the top of the stack. [SP-1] - [SP]
    MULT,   // Multiply the two values on the top of the stack. [SP-1] * [SP]
    DIV,    // Divide the two values on the top of the stack. [SP-1] / [SP]
    MOD,    // Perform modulo with truncated division of the two values on the top of the stack. [SP-1] % [SP]
    EQ,     // Compare the two values on the top of the stack. [SP-1] == [SP]
    NEQ,    // Compare the two values on the top of the stack. [SP-1] != [SP]
    LSSR,   // Compare the two values on the top of the stack. [SP-1] < [SP]
    GRTR,   // Compare the two values on the top of the stack. [SP-1] > [SP]
    LEQ,    // Compare the two values on the top of the stack. [SP-1] <= [SP]
    GEQ,    // Compare the two values on the top of the stack. [SP-1] >= [SP]
    LAND,   // Compare the two values on the top of the stack for true. [SP-1]==TRUE && [SP]==TRUE
    LOR,    // Compare the two values on the top of the stack for true. [SP-1]==TRUE || [SP]==TRUE
    MODF,   // Perform modulo with floored division of the two values on the top of the stack. [SP-1] %% [SP]
    NEG,    // Negate the value at the top of the stack.
    NOT,    // Invert the Boolean value at the top of the stack.
    SETG,   // Set a global variable in the globals table to a value.
            // Op1: 2-byte index into globals table.
    GETG,   // Get a global variable from the globals table, and push its value on the stack.
            // Op1: 2-byte index into globals table.
    RET,    // (Planned) Return (a possible value) from function call. (Current) Exit program execution.
}

Byte_Code :: byte
