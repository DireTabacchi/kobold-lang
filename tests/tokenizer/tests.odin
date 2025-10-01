package tests_tokenizer

import "core:testing"
import "core:os"
import "core:log"
import "core:fmt"
import "core:strings"
import tk "../../tokenizer"

Test_Src_Selector :: enum {
    Arithmetic_Ops,
    Collections,
    Comments,
    Conditionals,
    For_Loops,
    Logic_Operators,
    Numbers,
    Procs,
    Simple_Decl,
    Simple_Lit,
    User_Types,
}

test_srcs :: [Test_Src_Selector]string {
    .Arithmetic_Ops =   "tests/tokenizer/srcs/arithmetic_operators.kb",
    .Collections =      "tests/tokenizer/srcs/collections.kb",
    .Comments =         "tests/tokenizer/srcs/comments.kb",
    .Conditionals =     "tests/tokenizer/srcs/conditionals.kb",
    .For_Loops =        "tests/tokenizer/srcs/for_loops.kb",
    .Logic_Operators =  "tests/tokenizer/srcs/logic_operators.kb",
    .Numbers =          "tests/tokenizer/srcs/numbers.kb",
    .Procs =            "tests/tokenizer/srcs/procs.kb",
    .Simple_Decl =      "tests/tokenizer/srcs/simple_declaration.kb",
    .Simple_Lit =       "tests/tokenizer/srcs/simple_literals.kb",
    .User_Types =       "tests/tokenizer/srcs/user_types.kb",
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

    error_msg_builder := strings.builder_make()

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
