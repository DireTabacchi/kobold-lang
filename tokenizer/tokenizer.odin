package tokenizer

import "core:unicode/utf8"
import "core:os"
import "core:fmt"

Tokenizer :: struct {
    src: string,
    ch: rune,           // src[offset]
    offset: int,        // current read char offset, src[read_offset-1]
    read_offset: int,   // next char, offset+1
    line: int,
    line_offset: int,
}

init :: proc(t: ^Tokenizer, path: string) {
    src, err := os.read_entire_file_or_err(path)

    if err != nil {
        fmt.eprintfln("Failed to read file %s: %v", path, err)
    }

    t.src = string(src)
    t.ch = ' '
    t.offset = 0
    t.read_offset = 0
    t.line = len(t.src) > 0 ? 1 : 0
    t.line_offset = 0

    advance(t)
}


scan :: proc(t: ^Tokenizer) -> [dynamic]Token {
    tokens: [dynamic]Token
    scanloop: for t.offset < len(t.src) {
        skip_whitespace(t)
        offset := t.offset
        kind: Token_Kind
        lit: string
        pos: Pos
        switch ch := t.ch; true {
        case is_digit(ch):
            kind, lit = scan_number(t)
        case is_alpha(ch):
            kind, lit = scan_keyword_or_identifier(t, offset)
        case:
            if t.ch == utf8.RUNE_EOF {
                token := Token{.EOF, token_list[.EOF], Pos{offset, t.line, offset - t.line_offset + 1}}
                append(&tokens, token)
                break scanloop
            } else {
                advance(t)
                switch ch {
                case ':':
                    kind = .Colon
                case '=':
                    if t.ch == '=' {
                        advance(t)
                        kind = .Eq
                    } else {
                        kind = .Assign
                    }
                case ';':
                    kind = .Semicolon
                case',':
                    kind = .Comma
                case '{':
                    kind = .L_Brace
                case '}':
                    kind = .R_Brace
                case '(':
                    kind = .L_Paren
                case ')':
                    kind = .R_Paren
                case '[':
                    kind = .L_Bracket
                case ']':
                    kind = .R_Bracket
                case '!':
                    if t.ch == '=' {
                        advance(t)
                        kind = .Neq
                    } else {
                        kind = .Not
                    }
                case '&':
                    if t.ch == '&' {
                        advance(t)
                        kind = .Logical_And
                    }
                case '|':
                    if t.ch == '|' {
                        advance(t)
                        kind = .Logical_Or
                    }
                case '<':
                    if t.ch == '=' {
                        advance(t)
                        kind = .Leq
                    } else {
                        kind = .Lt
                    }
                case '>':
                    if t.ch == '=' {
                        advance(t)
                        kind = .Geq
                    } else {
                        kind = .Gt
                    }
                case '+':
                    kind = .Plus
                case '-':
                    if t.ch == '>' {
                        advance(t)
                        kind = .Arrow
                    } else {
                        kind = .Minus
                    }
                case '*':
                    kind = .Mult
                case '/':
                    if t.ch == '/' {
                        skip_comment(t)
                        continue
                    } else if t.ch == '!' {
                        advance(t)
                        kind = .Doc_Comment
                        break
                    } else if t.ch == '*' {
                        advance(t)
                        skip_block_comment(t)
                        continue
                    } else {
                        kind = .Div
                    }
                case '%':
                    kind = .Mod
                    if t.ch == '%' {
                        advance(t)
                        kind = .Mod_Floor
                    }
                case '\'':
                    kind = .Rune
                    lit = utf8.runes_to_string({t.ch})
                    for t.ch != '\'' {
                        advance(t)
                    }
                    advance(t)
                case '"':
                    kind = .String
                    for t.ch != '"' {
                        advance(t)
                    }
                    lit = t.src[offset+1:t.offset]
                    advance(t)
                case:
                    kind = .Invalid
                    lit = utf8.runes_to_string({ch})
                }
            }
        }

        if lit == "" {
            lit = token_list[kind]
        }

        pos = Pos{offset, t.line, offset - t.line_offset + 1}

        if kind == .Doc_Comment {
            lit = doc_comment(t, t.offset)
        }

        token := Token{kind, lit, pos}
        append(&tokens, token)
    }
    fmt.println("finished scanning")
    return tokens
}

scan_number :: proc(t: ^Tokenizer) -> (Token_Kind, string) {
    offset := t.offset
    kind := Token_Kind.Integer
    for is_digit(t.ch) {
        advance(t)
    }

    scan_fraction(t, &kind)

    return kind, t.src[offset:t.offset]
}

scan_keyword_or_identifier :: proc(t: ^Tokenizer, start: int) -> (Token_Kind, string) {
    offset := t.offset
    for is_alpha(peek(t)) || is_digit(peek(t)) {
        advance(t)
    }

    advance(t)
    switch ch := t.src[start]; ch {
    case 'a':
        return check_keyword(t, 1, 4, offset, "rray", .Array)
    case 'b':
        return check_keyword(t, 1, 3, offset, "ool", .Type_Boolean)
    case 'c':
        return check_keyword(t, 1, 4, offset, "onst", .Const)
    case 'e':
        return check_keyword(t, 1, 3, offset, "num", .Enum)
    case 'f':
        switch t.src[start+1] {
        case 'a':
            return check_keyword(t, 2, 3, offset, "lse", .False)
        case 'l':
            return check_keyword(t, 2, 3, offset, "oat", .Type_Float)
        }
    case 'i':
        switch t.src[start+1] {
        case 'f':
            return .If, token_list[.If]
        case 'n':
            return check_keyword(t, 1, 2, offset, "nt", .Type_Integer)
        }
    case 'p':
        return check_keyword(t, 1, 3, offset, "roc", .Proc)
    case 'r':
        switch t.src[start+1] {
        case 'e':
            switch t.src[start+2] {
            case 'c':
                return check_keyword(t, 3, 3, offset, "ord", .Record)
            case 't':
                return check_keyword(t, 3, 3, offset, "urn", .Return)
            }
        case 'u':
            return check_keyword(t, 2, 2, offset, "ne", .Type_Rune)
        }
    case 's':
        return check_keyword(t, 1, 5, offset, "tring", .Type_String)
    case 't':
        switch t.src[start+1] {
        case 'r':
            return check_keyword(t, 2, 2, offset, "ue", .True)
        case 'y':
            return check_keyword(t, 2, 2, offset, "pe", .Type)
        }
    case 'u':
        return check_keyword(t, 1, 3, offset, "int", .Type_Unsigned_Integer)
    case 'v':
        return check_keyword(t, 1, 2, offset, "ar", .Var)
    }

    lit := t.src[offset:t.offset]

    return .Identifier, lit
}

scan_fraction :: proc(t: ^Tokenizer, kind: ^Token_Kind) {
    if t.ch == '.' {
        kind^ = .Float
        advance(t)
        for is_digit(t.ch) {
            advance(t)
        }
    }
}

advance :: proc(t: ^Tokenizer) {
    if t.read_offset < len(t.src) {
        t.offset = t.read_offset
        if t.ch == '\n' {
            t.line += 1
            t.line_offset = t.offset
        }
        t.ch = rune(t.src[t.read_offset])
        t.read_offset += 1
    } else {
        t.offset = len(t.src)
        t.ch = -1
    }
}

peek :: proc(t: ^Tokenizer) -> rune {
    return rune(t.src[t.read_offset])
}

skip_whitespace :: proc(t: ^Tokenizer) {
    for {
        switch t.ch {
        case '\n', '\r', '\t', ' ':
            advance(t)
        case:
            return
        }
    }
}

skip_comment :: proc(t: ^Tokenizer) {
    for t.ch != '\n' {
        advance(t)
    }
}

skip_block_comment :: proc(t: ^Tokenizer) {
    for t.ch != '*' {
        advance(t)
    }
    advance(t)
    advance(t)
}

doc_comment :: proc(t: ^Tokenizer, offset: int) -> string {

    for t.ch != '!' {
        advance(t)
    }

    dc := t.src[offset:t.offset]

    advance(t)
    advance(t)

    return dc
}

is_digit :: proc(r: rune) -> bool {
    return '0' <= r && r <= '9'
}

is_alpha :: proc(r: rune) -> bool {
    return 'a' <= r && r <= 'z' || 'A' <= r && r <= 'Z' || r == '_'
}

check_keyword :: proc(t: ^Tokenizer, start, rest_length, offset: int, rest: string, kind: Token_Kind) -> (Token_Kind, string) {
    expected_length := start + rest_length
    actual_length := t.offset - offset

    if expected_length == actual_length && rest == t.src[offset+start:][:rest_length] {
        return kind, t.src[offset:t.offset]
    }

    return .Identifier, t.src[offset:t.offset]
}
