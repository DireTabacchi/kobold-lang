package tests_tokenizer

import "core:testing"
import "core:os"
import "core:log"
import "core:fmt"
import "core:strings"
import tk "../../tokenizer"

Test_Src_Selector :: enum {
    Assign_Ops,
    Const_Decls,
    Numbers,
    Record,
}

test_srcs :: [Test_Src_Selector]string {
    .Assign_Ops =       "tests/tokenizer/srcs/assign_ops.kb",
    .Const_Decls =      "tests/tokenizer/srcs/const_decls.kb",
    .Numbers =          "tests/tokenizer/srcs/numbers.kb",
    .Record =           "tests/tokenizer/srcs/record.kb",
}

@(test)
tokenize_numbers_test :: proc(t: ^testing.T) {
    expected: []tk.Token = {
        tk.Token{.Integer, "12", tk.Pos{0, 1, 1}},
        tk.Token{.Integer, "13", tk.Pos{3, 1, 4}},
        tk.Token{.Integer, "1", tk.Pos{6, 1, 7}},
        tk.Token{.Integer, "0", tk.Pos{8, 1, 9}},
        tk.Token{.Integer, "32", tk.Pos{10, 1, 11}},
        tk.Token{.Float, "23.2", tk.Pos{13, 1, 14}},
        tk.Token{.Float, "33.1", tk.Pos{18, 1, 19}},
        tk.Token{.Integer, "42", tk.Pos{23, 2, 1}},
        tk.Token{.Float, "123.45", tk.Pos{26, 2, 4}},
        tk.Token{.EOF, "EOF", tk.Pos{33, 2, 11}}
    }

    tok: tk.Tokenizer
    tk.tokenizer_init(&tok, test_srcs[.Numbers])

    scanned_tokens := tk.scan(&tok)
    defer delete(scanned_tokens)

    testing.expect(t, len(expected) == len(scanned_tokens), "Incorrect number of tokens.")

    for expected_token, i in expected {
        scanned_token := scanned_tokens[i]
        testing.expect_value(t, scanned_token, expected_token)
    }

    tk.tokenizer_destroy(&tok)
}

@(test)
tokenize_assign_ops_test :: proc(t: ^testing.T) {
    expected: []tk.Token = {
        tk.Token{.Identifier, "assign", tk.Pos{0, 1, 1}},
        tk.Token{.Assign, "=", tk.Pos{7, 1, 8}},
        tk.Token{.String, "\"test\"", tk.Pos{9, 1, 10}},
        tk.Token{.Semicolon, ";", tk.Pos{15, 1, 16}},
        tk.Token{.Identifier, "assign_add", tk.Pos{17, 2, 1}},
        tk.Token{.Assign_Add, "+=", tk.Pos{28, 2, 12}},
        tk.Token{.Integer, "2", tk.Pos{31, 2, 15}},
        tk.Token{.Semicolon, ";", tk.Pos{32, 2, 16}},
        tk.Token{.Identifier, "assign_minus", tk.Pos{34, 3, 1}},
        tk.Token{.Assign_Minus, "-=", tk.Pos{47, 3, 14}},
        tk.Token{.Integer, "3", tk.Pos{50, 3, 17}},
        tk.Token{.Semicolon, ";", tk.Pos{51, 3, 18}},
        tk.Token{.Identifier, "assign_mult", tk.Pos{53, 4, 1}},
        tk.Token{.Assign_Mult, "*=", tk.Pos{65, 4, 13}},
        tk.Token{.Integer, "4", tk.Pos{68, 4, 16}},
        tk.Token{.Semicolon, ";", tk.Pos{69, 4, 17}},
        tk.Token{.Identifier, "assign_div", tk.Pos{71, 5, 1}},
        tk.Token{.Assign_Div, "/=", tk.Pos{82, 5, 12}},
        tk.Token{.Integer, "5", tk.Pos{85, 5, 15}},
        tk.Token{.Semicolon, ";", tk.Pos{86, 5, 16}},
        tk.Token{.Identifier, "assign_mod", tk.Pos{88, 6, 1}},
        tk.Token{.Assign_Mod, "%=", tk.Pos{99, 6, 12}},
        tk.Token{.Integer, "6", tk.Pos{102, 6, 15}},
        tk.Token{.Semicolon, ";", tk.Pos{103, 6, 16}},
        tk.Token{.Identifier, "assign_mod_floor", tk.Pos{105, 7, 1}},
        tk.Token{.Assign_Mod_Floor, "%%=", tk.Pos{122, 7, 18}},
        tk.Token{.Integer, "7", tk.Pos{126, 7, 22}},
        tk.Token{.Semicolon, ";", tk.Pos{127, 7, 23}},
        tk.Token{.EOF, "EOF", tk.Pos{129, 7, 25}},
    }

    tok: tk.Tokenizer
    tk.tokenizer_init(&tok, test_srcs[.Assign_Ops])

    scanned_tokens := tk.scan(&tok)
    defer delete(scanned_tokens)

    testing.expect(t, len(expected) == len(scanned_tokens), "Incorrect number of tokens.")

    for expected_token, i in expected {
        scanned_token := scanned_tokens[i]
        testing.expect_value(t, scanned_token, expected_token)
    }

    tk.tokenizer_destroy(&tok)
}

@(test)
tokenize_record_test :: proc(t: ^testing.T) {
    expected: []tk.Token = {
        tk.Token{.Type, "type", tk.Pos{0, 1, 1}},
        tk.Token{.Identifier, "Person", tk.Pos{5, 1, 6}},
        tk.Token{.Colon, ":", tk.Pos{11, 1, 12}},
        tk.Token{.Record, "record", tk.Pos{13, 1, 14}},
        tk.Token{.L_Brace, "{", tk.Pos{20, 1, 21}},
        tk.Token{.Identifier, "name", tk.Pos{26, 2, 5}},
        tk.Token{.Colon, ":", tk.Pos{30, 2, 9}},
        tk.Token{.Type_String, "string", tk.Pos{32, 2, 11}},
        tk.Token{.Semicolon, ";", tk.Pos{38, 2, 17}},
        tk.Token{.Identifier, "age", tk.Pos{44, 3, 5}},
        tk.Token{.Colon, ":", tk.Pos{47, 3, 8}},
        tk.Token{.Type_Integer, "int", tk.Pos{49, 3, 10}},
        tk.Token{.Semicolon, ";", tk.Pos{52, 3, 13}},
        tk.Token{.R_Brace, "}", tk.Pos{54, 4, 1}},
        tk.Token{.Semicolon, ";", tk.Pos{55, 4, 2}},
        tk.Token{.Var, "var", tk.Pos{58, 6, 1}},
        tk.Token{.Identifier, "niklaus", tk.Pos{62, 6, 5}},
        tk.Token{.Colon, ":", tk.Pos{70, 6, 13}},
        tk.Token{.Assign, "=", tk.Pos{71, 6, 14}},
        tk.Token{.Identifier, "Person", tk.Pos{73, 6, 16}},
        tk.Token{.L_Brace, "{", tk.Pos{79, 6, 22}},
        tk.Token{.String, "\"Niklaus Wirth\"", tk.Pos{85, 7, 5}},
        tk.Token{.Comma, ",", tk.Pos{100, 7, 20}},
        tk.Token{.Integer, "89", tk.Pos{102, 7, 22}},
        tk.Token{.Comma, ",", tk.Pos{104, 7, 24}},
        tk.Token{.R_Brace, "}", tk.Pos{106, 8, 1}},
        tk.Token{.Semicolon, ";", tk.Pos{107, 8, 2}},
        tk.Token{.Identifier, "niklaus", tk.Pos{110, 10, 1}},
        tk.Token{.Dot, ".", tk.Pos{117, 10, 8}},
        tk.Token{.Identifier, "name", tk.Pos{118, 10, 9}},
        tk.Token{.Semicolon, ";", tk.Pos{122, 10, 13}},
        tk.Token{.EOF, "EOF", tk.Pos{124, 10, 15}},
    }

    tok: tk.Tokenizer
    tk.tokenizer_init(&tok, test_srcs[.Record])

    scanned_tokens := tk.scan(&tok)
    defer delete(scanned_tokens)

    testing.expect(t, len(expected) == len(scanned_tokens), "Incorrect number of tokens.")

    for expected_token, i in expected {
        scanned_token := scanned_tokens[i]
        testing.expect_value(t, scanned_token, expected_token)
    }

    tk.tokenizer_destroy(&tok)
}

@(test)
tokenize_const_decls :: proc(t: ^testing.T) {
    expected: []tk.Token = {
        tk.Token{.Const, "const", tk.Pos{0, 1, 1}},
        tk.Token{.Identifier, "WIDTH", tk.Pos{6, 1, 7}},
        tk.Token{.Colon, ":", tk.Pos{11, 1, 12}},
        tk.Token{.Type_Unsigned_Integer, "uint", tk.Pos{13, 1, 14}},
        tk.Token{.Assign, "=", tk.Pos{18, 1, 19}},
        tk.Token{.Integer, "1920", tk.Pos{20, 1, 21}},
        tk.Token{.Semicolon, ";", tk.Pos{24, 1, 25}},
        tk.Token{.Const, "const", tk.Pos{26, 2, 1}},
        tk.Token{.Identifier, "HEIGHT", tk.Pos{32, 2, 7}},
        tk.Token{.Colon, ":", tk.Pos{38, 2, 13}},
        tk.Token{.Type_Unsigned_Integer, "uint", tk.Pos{40, 2, 15}},
        tk.Token{.Assign, "=", tk.Pos{45, 2, 20}},
        tk.Token{.Integer, "1080", tk.Pos{47, 2, 22}},
        tk.Token{.Semicolon, ";", tk.Pos{51, 2, 26}},
        tk.Token{.Const, "const", tk.Pos{53, 3, 1}},
        tk.Token{.Identifier, "INITIAL", tk.Pos{59, 3, 7}},
        tk.Token{.Colon, ":", tk.Pos{66, 3, 14}},
        tk.Token{.Type_Rune, "rune", tk.Pos{68, 3, 16}},
        tk.Token{.Assign, "=", tk.Pos{73, 3, 21}},
        tk.Token{.Rune, "'K'", tk.Pos{75, 3, 23}},
        tk.Token{.Semicolon, ";", tk.Pos{78, 3, 26}},
        tk.Token{.Const, "const", tk.Pos{80, 4, 1}},
        tk.Token{.Identifier, "REFRESH_RATE", tk.Pos{86, 4, 7}},
        tk.Token{.Colon, ":", tk.Pos{98, 4, 19}},
        tk.Token{.Type_Float, "float", tk.Pos{100, 4, 21}},
        tk.Token{.Assign, "=", tk.Pos{106, 4, 27}},
        tk.Token{.Float, "59.997", tk.Pos{108, 4, 29}},
        tk.Token{.Semicolon, ";", tk.Pos{114, 4, 35}},
        tk.Token{.EOF, "EOF", tk.Pos{116, 4, 37}},
    }
    tok: tk.Tokenizer
    tk.tokenizer_init(&tok, test_srcs[.Const_Decls])

    scanned_tokens := tk.scan(&tok)
    defer delete(scanned_tokens)

    testing.expect(t, len(expected) == len(scanned_tokens), "Incorrect number of tokens.")

    for expected_token, i in expected {
        scanned_token := scanned_tokens[i]
        testing.expect_value(t, scanned_token, expected_token)
    }

    tk.tokenizer_destroy(&tok)
}
