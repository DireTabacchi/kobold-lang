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
                    kind = .Assign
                case ';':
                    kind = .Semicolon
                case '+':
                    kind = .Plus
                case '-':
                    kind = .Minus
                case '*':
                    kind = .Mult
                case '/':
                    kind = .Div
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

        token := Token{kind, lit, Pos{offset, t.line, offset - t.line_offset + 1}}
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
    case 'b':
        return check_keyword(t, 1, 3, offset, "ool", .Type_Boolean)
    case 'c':
        return check_keyword(t, 1, 4, offset, "onst", .Const)
    case 'f':
        switch t.src[start+1] {
        case 'a':
            return check_keyword(t, 2, 3, offset, "lse", .False)
        case 'l':
            return check_keyword(t, 2, 3, offset, "oat", .Type_Float)
        }
    case 'i':
        return check_keyword(t, 1, 2, offset, "nt", .Type_Integer)
    case 'r':
        return check_keyword(t, 1, 3, offset, "une", .Type_Rune)
    case 's':
        return check_keyword(t, 1, 5, offset, "tring", .Type_String)
    case 't':
        return check_keyword(t, 1, 3, offset, "rue", .True)
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
