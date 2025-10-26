package code

//import "kobold:object"

Op_Code :: enum byte {
    PUSH,   // Push a constant onto the stack.
            // Op1: 2-byte index into constants table.
    POP,    // Pop a value off of the stack. Removes the top value and decrements SP.
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
    JMP,    // Unconditional JUMP instruction. Jump to bytecode instruction specified as operand.
            // Op1: 2-byte instruction location to set IP to.
    JF,     // Jump if False. Jump to bytecode instruction specified as operand if the top of stack value is false.
    CALL,   
    SETG,   // Set a global variable in the globals table to a value.
            // Op1: 2-byte index into globals table.
    GETG,   // Get a global variable from the globals table, and push its value on the stack.
            // Op1: 2-byte index into globals table.
    SETL,   // Set a local variable to a value.
            // Op1: 2-byte location on the stack.
    GETL,   // Get a the value of a local variable from the stack, and push its value on the stack.
            // Op1: 2-byte location on the stack.
    RET,    // Return (a possible value) from a function call. Can also be used to stop program execution.
            // Will clean up local variables from the stack that may have been created during function execution.
            // (Planned) Return (a possible value) from function call. (Current) Exit program execution.
}

Byte_Code :: byte
