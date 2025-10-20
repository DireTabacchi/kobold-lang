package tokenizer

import "core:fmt"
import "core:os"
import "core:unicode"
import "core:unicode/utf8"

Tokenizer :: struct {
    src: string,
    ch: rune,           // src[offset]
    offset: int,        // current read char offset, src[read_offset-1]
    read_offset: int,   // next char, offset+1
    line: int,
    line_offset: int,

    error_count: int,
}

tokenizer_init :: proc(t: ^Tokenizer, path: string) {
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

    fmt.printfln("Source:\n%s", path)
    fmt.println(t.src)

    advance(t)
}

tokenizer_destroy :: proc(t: ^Tokenizer) {
    delete(t.src)
}

scan :: proc(t: ^Tokenizer) -> [dynamic]Token {
    tokens: [dynamic]Token
    scanloop: for {
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
            if t.ch == utf8.RUNE_EOF || t.ch == -1 {
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
                    } else if t.ch == '>' {
                        advance(t)
                        kind = .Fat_Arrow
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
                case '.':
                    if t.ch == '.' {
                        peeked := peek(t)
                        if peeked == '<' {
                            advance(t)
                            advance(t)
                            kind = .Range_Ex
                        } else if peeked == '=' {
                            advance(t)
                            advance(t)
                            kind = .Range_Inc
                        }
                    } else {
                        kind = .Dot
                    }
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
                    if t.ch == '=' {
                        advance(t)
                        kind = .Assign_Add
                    } else {
                        kind = .Plus
                    }
                case '-':
                    if t.ch == '>' {
                        advance(t)
                        kind = .Arrow
                    } else if t.ch == '=' {
                        advance(t)
                        kind = .Assign_Minus
                    } else {
                        kind = .Minus
                    }
                case '*':
                    if t.ch == '=' {
                        advance(t)
                        kind = .Assign_Mult
                    } else {
                        kind = .Mult
                    }
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
                    } else if t.ch == '=' {
                        advance(t)
                        kind = .Assign_Div
                    } else {
                        kind = .Div
                    }
                case '%':
                    if t.ch == '%' {
                        advance(t)
                        if t.ch == '=' {
                            advance(t)
                            kind = .Assign_Mod_Floor
                        } else {
                            kind = .Mod_Floor
                        }
                    } else if t.ch == '=' {
                        advance(t)
                        kind = .Assign_Mod
                    } else {
                        kind = .Mod
                    }
                case '\'':
                    kind = .Rune
                    lit = scan_rune(t)
                case '"':
                    kind = .String
                    lit = scan_string(t)
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
    return tokens
}

scan_number :: proc(t: ^Tokenizer) -> (Token_Kind, string) {
    offset := t.offset
    kind := Token_Kind.Integer
    for is_digit(t.ch) {
        advance(t)
    }

    if is_alpha(t.ch) && t.ch == 'u' {
        advance(t)
        kind = Token_Kind.Unsigned_Integer
    }

    scan_fraction(t, &kind)

    return kind, t.src[offset:t.offset]
}

// TODO: Should be invalid to have Float that does not have digits after the period
scan_fraction :: proc(t: ^Tokenizer, kind: ^Token_Kind) {
    if t.ch == '.' {
        if peek(t) == '.' {
            return
        }
        kind^ = .Float
        advance(t)
        for is_digit(t.ch) {
            advance(t)
        }
    }
}

scan_string :: proc(t: ^Tokenizer) -> string {
    offset := t.offset-1

    for {
        ch := t.ch
        if t.ch == '\n' || t.ch < 0 {
            error(t, offset, "unterminated string literal")
        }
        advance(t)
        if ch == '\"' {
            break
        }
    }

    return t.src[offset:t.offset]
}

scan_rune :: proc(t: ^Tokenizer) -> string {
    offset := t.offset-1

    n := 0
    for {
        ch := t.ch
        if t.ch == '\n' || t.ch < 0 {
            error(t, offset, "unterminated rune literal")
        }
        advance(t)
        if ch == '\'' {
            break
        }
        n += 1
    }

    if n != 1 {
        error(t, offset, "illegal rune literal")
    }

    return t.src[offset:t.offset]
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
        if t.offset - start > 1 {
            switch t.src[start+1] {
            case 'o':
                return check_keyword(t, 2, 2, offset, "ol", .Type_Boolean)
            case 'r':
                return check_keyword(t, 2, 3, offset, "eak", .Break)
            }
        }
    case 'c':
        if t.offset - start > 1 {
            switch t.src[start+1] {
            case 'a':
                return check_keyword(t, 2, 2, offset, "se", .Case)
            case 'o':
                return check_keyword(t, 2, 3, offset, "nst", .Const)
            }
        }
    case 'e':
        if t.offset - start > 1 {
            switch t.src[start+1] {
            case 'n':
                return check_keyword(t, 2, 2, offset, "um", .Enum)
            case 'l':
                return check_keyword(t, 2, 2, offset, "se", .Else)
            }
        }
    case 'f':
        if t.offset - start > 1 {
            switch t.src[start+1] {
            case 'a':
                return check_keyword(t, 2, 3, offset, "lse", .False)
            case 'l':
                return check_keyword(t, 2, 3, offset, "oat", .Type_Float)
            case 'o':
                return check_keyword(t, 2, 1, offset, "r", .For)
            }
        }
    case 'i':
        if t.offset - start > 1 {
            switch t.src[start+1] {
            case 'f':
                return check_keyword(t, 1, 1, offset, "f", .If)
            case 'n':
                if t.offset - start > 2 {
                    switch t.src[start+2] {
                    case 't':
                        return check_keyword(t, 2, 1, offset, "t", .Type_Integer)
                    }
                } else {
                    return check_keyword(t, 1, 1, offset, "n", .In)
                }
            }
        }
    case 'm':
        return check_keyword(t, 1, 2, offset, "ap", .Map)
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
        switch t.src[start+1] {
        case 'e':
            return check_keyword(t, 2, 1, offset, "t", .Set)
        case 't':
            return check_keyword(t, 2, 4, offset, "ring", .Type_String)
        case 'w':
            return check_keyword(t, 2, 4, offset, "itch", .Switch)
        }
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

check_keyword :: proc(t: ^Tokenizer, start, rest_length, offset: int, rest: string, kind: Token_Kind) -> (Token_Kind, string) {
    expected_length := start + rest_length
    actual_length := t.offset - offset

    if expected_length == actual_length && rest == t.src[offset+start:][:rest_length] {
        return kind, t.src[offset:t.offset]
    }

    return .Identifier, t.src[offset:t.offset]
}

advance :: proc(t: ^Tokenizer) {
    if t.read_offset < len(t.src) {
        t.offset = t.read_offset
        if t.ch == '\n' {
            t.line += 1
            t.line_offset = t.offset
        }
        r, w := rune(t.src[t.offset]), 1
        switch {
        case r == 0:
            error(t, t.offset, "illegal NUL character.")
        case r >= utf8.RUNE_SELF:
            r, w = utf8.decode_rune_in_string(t.src[t.offset:])
            if r == utf8.RUNE_ERROR {
                error(t, t.offset, "illegal UTF-8 encoding")
            } else if r == utf8.RUNE_BOM {
                error(t, t.offset, "illegal byte order mark")
            }
        }
        t.read_offset += w
        t.ch = r
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
    if r < utf8.RUNE_SELF {
        return 'a' <= r && r <= 'z' || 'A' <= r && r <= 'Z' || r == '_'
    }
    return unicode.is_letter(r)
}

error :: proc(t: ^Tokenizer, offset: int, msg: string) {
    pos := Pos{offset, t.line, offset - t.line_offset + 1}
    fmt.eprintfln("[%d:%d] %s", pos.line, pos.col, msg)

    t.error_count += 1
}
