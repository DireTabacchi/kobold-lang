package tokenizer

Token :: struct {
    type: Token_Kind,
    text: string,
    pos: Pos,
}

Pos :: struct {
    offset: int,
    line: int,
    col: int,
}

Token_Kind :: enum {
    INVALID,                // Unknown token/Error token
    EOF,
    // Single-character tokens
    SEMICOLON,              // ;
    L_BRACE,                // {
    R_BRACE,                // }
    L_BRACKET,              // [
    R_BRACKET,              // ]
    L_PAREN,                // (
    R_PAREN,                // )
    COMMA,                  // ,
    DOT,                    // .

    // Operators
    COLON,                  // :
    IN,                     // in
    ARROW,                  // ->
    FAT_ARROW,              // =>
    // -- Assignment
    ASSIGN,                 // =
    ASSIGN_ADD,             // +=
    ASSIGN_MINUS,           // -=
    ASSIGN_MULT,            // *=
    ASSIGN_DIV,             // /=
    ASSIGN_MOD,             // %=
    ASSIGN_MOD_FLOOR,       // %%=
    // -- Arithmetic
    MINUS,                  // -
    PLUS,                   // +
    MULT,                   // *
    DIV,                    // /
    MOD,                    // %
    MOD_FLOOR,              // %%
    // -- Logical
    NOT,                    // !
    LOGICAL_AND,            // &&
    LOGICAL_OR,             // ||
    EQ,                     // ==
    NEQ,                    // !=
    LT,                     // <
    GT,                     // >
    LEQ,                    // <=
    GEQ,                    // >=
    // -- Range
    RANGE_EX,               // ..<
    RANGE_INC,              // ..=

    // Literals
    IDENTIFIER,             // var_name
    INTEGER,                // 1234
    UNSIGNED_INTEGER,       // 1234u
    FLOAT,                  // 12.34
    RUNE,                   // 'K'
    STRING,                 // "Kobold"
    TRUE,                   // true
    FALSE,                  // false
    DOC_COMMENT,            // /! the doc comment !/

    // Keywords
    // -- Declarations
    VAR,                    // var
    CONST,                  // const
    TYPE,                   // type
    ENUM,                   // enum
    RECORD,                 // record
    PROC,                   // proc
    ARRAY,                  // array
    MAP,                    // map
    SET,                    // set
    // -- Control flow
    RETURN,                 // return
    FOR,                    // for
    IF,                     // if
    ELSE,                   // else
    SWITCH,                 // switch
    CASE,                   // case
    BREAK,                  // break
    // -- Types
    TYPE_INTEGER,           // int
    TYPE_UNSIGNED_INTEGER,  // uint
    TYPE_FLOAT,             // float
    TYPE_BOOLEAN,           // bool
    TYPE_RUNE,              // rune
    TYPE_STRING,            // string
}

token_list := [Token_Kind]string {
    .INVALID = "invalid",
    .EOF = "EOF",
    .SEMICOLON = ";",
    .L_BRACE = "{",
    .R_BRACE = "}",
    .L_BRACKET = "[",
    .R_BRACKET = "]",
    .L_PAREN = "(",
    .R_PAREN = ")",
    .COMMA = ",",
    .DOT = ".",

    .COLON = ":",
    .IN = "in",
    .ARROW = "->",
    .FAT_ARROW = "=>",

    .ASSIGN = "=",
    .ASSIGN_ADD = "+=",
    .ASSIGN_MINUS = "-=",
    .ASSIGN_MULT = "*=",
    .ASSIGN_DIV = "/=",
    .ASSIGN_MOD = "%=",
    .ASSIGN_MOD_FLOOR = "%%=",

    .MINUS = "-",
    .PLUS = "+",
    .MULT = "*",
    .DIV = "/",
    .MOD = "%",
    .MOD_FLOOR = "%%",

    .NOT = "!",
    .LOGICAL_AND = "&&",
    .LOGICAL_OR = "||",
    .EQ = "==",
    .NEQ = "!=",
    .LT = "<",
    .GT = ">",
    .LEQ = "<=",
    .GEQ = ">=",

    .RANGE_EX = "..<",
    .RANGE_INC = "..=",

    .IDENTIFIER = "identifier",
    .INTEGER = "integer",
    .UNSIGNED_INTEGER = "unsigned integer",
    .FLOAT = "float",
    .RUNE = "rune",
    .STRING = "string",
    .TRUE = "true",
    .FALSE = "false",
    .DOC_COMMENT = "doc comment",

    .VAR = "var",
    .CONST = "const",
    .TYPE = "type",
    .ENUM = "enum",
    .RECORD = "record",
    .PROC = "proc",
    .ARRAY = "array",
    .MAP = "map",
    .SET = "set",

    .RETURN = "return",
    .FOR = "for",
    .IF = "if",
    .ELSE = "else",
    .SWITCH = "switch",
    .CASE = "case",
    .BREAK = "break",

    .TYPE_INTEGER = "int",
    .TYPE_UNSIGNED_INTEGER = "uint",
    .TYPE_FLOAT = "float",
    .TYPE_BOOLEAN = "bool",
    .TYPE_RUNE = "rune",
    .TYPE_STRING = "string",
}
