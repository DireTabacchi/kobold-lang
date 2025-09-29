package tokenizer

Token :: struct {
    type: Token_Kind,
    text: string,
    pos: Pos,
}

Pos :: struct {
    file: string,
    offset: int,
    line: int,
    col: int,
}

Token_Kind :: enum {
    // Single-character tokens
    Semicolon,              // ;
    L_Brace,                // {
    R_Brace,                // }
    L_Bracket,              // [
    R_Bracket,              // ]
    L_Paren,                // (
    R_Paren,                // )

    // Operators
    Colon,                  // :
    In,                     // in
    Fat_Arrow,              // =>
    L_Doc_Comment,          // /!
    R_Doc_Comment,          // !/
    // -- Assignment
    Assign,                 // =
    Assign_Add,             // +=
    Assign_Minus,           // -=
    Assign_Mult,            // *=
    Assign_Div,             // /=
    Assign_Mod,             // %=
    Assign_Mod_Floor,       // %%=
    // -- Arithmetic
    Minus,                  // -
    Plus,                   // +
    Mult,                   // *
    Div,                    // /
    Mod,                    // %
    Mod_Floor,              // %%
    // -- Logical
    Not,                    // !
    Logical_And,            // &&
    Logical_Or,             // ||
    Eq,                     // ==
    Neq,                    // !=
    Lt,                     // <
    Gt,                     // >
    Leq,                    // <=
    Geq,                    // >=
    // -- Range
    Range_Ex,               // ..<
    Range_Inc,              // ..=

    // Literals
    Identifier,             // var_name
    Integer,                // 1234
    Float,                  // 12.34
    Rune,                   // 'K'
    String,                 // "Kobold"
    True,                   // true
    False,                  // false

    // Keywords
    // -- Declarations
    Var,                    // var
    Const,                  // const
    Type,                   // type
    Enum,                   // enum
    Record,                 // record
    Proc,                   // proc
    Array,                  // array
    Map,                    // map
    Set,                    // set
    // -- Control flow
    For,                    // for
    If,                     // if
    Else,                   // else
    Switch,                 // switch
    Case,                   // case
    // -- Types
    Type_Integer,           // int
    Type_Unsigned_Integer,  // uint
    Type_Float,             // float
    Type_Boolean,           // bool
    Type_Rune,              // rune
    Type_String,            // string
}

token_list := [Token_Kind]string {
    .Semicolon = ";",
    .L_Brace = "{",
    .R_Brace = "}",
    .L_Bracket = "[",
    .R_Bracket = "]",
    .L_Paren = "(",
    .R_Paren = ")",

    .Colon = ":",
    .In = "in",
    .Fat_Arrow = "=>",
    .L_Doc_Comment = "/!",
    .R_Doc_Comment = "!/",

    .Assign = "=",
    .Assign_Add = "+=",
    .Assign_Minus = "-=",
    .Assign_Mult = "*=",
    .Assign_Div = "/=",
    .Assign_Mod = "%=",
    .Assign_Mod_Floor = "%%=",

    .Minus = "-",
    .Plus = "+",
    .Mult = "*",
    .Div = "/",
    .Mod = "%",
    .Mod_Floor = "%%",

    .Not = "!",
    .Logical_And = "&&",
    .Logical_Or = "||",
    .Eq = "==",
    .Neq = "!=",
    .Lt = "<",
    .Gt = ">",
    .Leq = "<=",
    .Geq = ">=",

    .Range_Ex = "..<",
    .Range_Inc = "..=",

    .Identifier = "identifier",
    .Integer = "integer",
    .Float = "float",
    .Rune = "rune",
    .String = "string",
    .True = "true",
    .False = "false",

    .Var = "var",
    .Const = "const",
    .Type = "type",
    .Enum = "enum",
    .Record = "record",
    .Proc = "proc",
    .Array = "array",
    .Map = "map",
    .Set = "set",

    .For = "for",
    .If = "if",
    .Else = "else",
    .Switch = "switch",
    .Case = "case",

    .Type_Integer = "int",
    .Type_Unsigned_Integer = "uint",
    .Type_Float = "float",
    .Type_Boolean = "bool",
    .Type_Rune = "rune",
    .Type_String = "string",
}
