# The Kobold Scripting Language

Kobold is a scripting language. It is a strongly-typed, procedural language that is currently in the very early stages
of development.

Version: **0.0.44**

## Building

### Prerequisites

- Latest stable release of [Odin](https://github.com/odin-lang/Odin)

### Steps

1. Ensure that the Odin compiler is installed.
2. Clone this repository.
```
$ git clone https://github.com/DireTabacchi/kobold-lang.git
```
3. Run the build script.
```
$ ./build.sh
```

Currently, all test scripts in the `tests/compiler/srcs` directory are guarenteed to run. To run a script, use
```
$ ./kobo tests/compiler/srcs/<name of test script>
```

## `kobo`

`kobo` is the main tool that will help you interact with the Kobold language. Other than script names, it will currently
accept the following commands:

- `version`: print the current version of Kobold and the version of Odin it was built with.
- `help`: print a help text.

# Overview

## Literals

The constants in Kobold are as follows

```
123         // 64-bit signed integer literal
123u        // 64-bit unsigned integer literal
12.3        // 64-bit floating point literal

true        // Boolean value true
false       // Boolean value false

'K'         // A rune (utf-8 encoded character)
"Kobold"    // A string (of utf-8 encoded characters)
```

## Types

Kobold is a strongly-typed language.

### Base Types

The following types can be used in variable declarations.

```
int     // 64-bit signed integer
uint    // 64-bit unsigned integer
float   // 64-bit floating point number
bool    // Boolean
rune    // A rune (utf-8 encoded character)
string  // A string (of utf-8 encoded characters)
```

### Container Types

Kobold currently has one container type.

#### Array

The `array` in Kobold is a compile-time known homogeneous (same type) list of values. An `array` declaration must be
annotated for the type. Array declarations may be optionally initialized, otherwise they will be initialized with the
number of values in the `array` to zero values. An `array` type is annotated with the ``array`` keyword, followed by the size
in brackets (`[]`), followed by the type it will hold. An `array` can be initialized by surrounding the values it
contains in braces (`{}`);

```
var vals: array[3]int;        // An array of three floats, all initialized to `0`: `{ 0, 0, 0 }`
var constants: array[3]float = { 3.14159265, 1.61803398, 6.02214076 };
```

When passed to a procedure as an argument, `array`s will be copied.

The builtin procedure `len` will return the number of elements in the `array`, or, in other words, the number of
elements the `array` can hold.

```
var arr_len := len(vals); // arr_len == 3
```

### Zero Values of Types

The zero values of these types are:

```
0       // int (Signed Integer)
0u      // uint (Unsigned Integer)
0.0     // float (Floating point number)
false   // bool (Boolean)
'NUL'   // rune (0x0000, utf-8 value 0, ASCII value 0)
""      // string (Empty string)
```

The zero value of the `array` is the number of elements the `array` holds set to the zero value of their type.

## Operators

The operators are, in order of high-to-low precedence, line-by-line:

```
()          // grouping, parenthesized expression
! -         // unary NOT, negative
* / % %%    // multiply, divide, truncated modulus, floored modulus
+ -         // add, subtract
== !=       // Equality and Inequality
&&          // Logical AND
||          // Logical OR
```

## Variable Declarations

A variable can be either mutable or immutable. How they are declared decides their mutability.

### Mutable Variables

A mutable variable is declared with the `var` keyword and can be implicitly typed.

```
var alfa := 2.19;   // implicitly derives `float`
```

They can also be explicitly typed.

```
var beta: uint = 219u;     // explicitly typed `uint` (unsigned integer)
```

As seen above, if you explicitly type a variable, you must give it the correct type literal.

`var` variables can also be declared without an initializing value. They must be declared with a type.

```
var charlie: int;
```

`var` variables declared in this way will recieve their zero values.

### Immutable (const) Variables

An immutable (`const`) variable must have its type and value declared and initialized at once.

```
const PI: float = 3.1415926;
const initial: rune = 'K';
const name: string = "Kobold";
```

### Assignment

`var` variables can be reassigned using the assignment operators.

#### Simple Assignment

A basic assignment uses the `=` operator.

```
var foo := 3;
var bar := 7;
foo = bar + 20;     // Assign the variable `foo` to the value `bar + 20`
```

#### Assignment Operations

Assignment-like operators exist for each of the arithmetic operators.

```
foo += 1;   // add 1 to foo; equivalent to `foo = foo + 1`
foo -= 1;   // subtract 1 from foo; equivalent to `foo = foo - 1`
foo *= 3;   // multiply foo by 3; equivalent to `foo = foo * 3`
foo /= 3;   // divide foo by 3; equivalent to `foo = foo / 3`
foo %= 2;   // apply modulus to foo by 2; equivalent to `foo = foo % 2`
foo %%= 2;  // apply floored modulus to foo by 2; equivalent to `foo = foo %% 2`
```

Any expression can be used with assignment-like operators. The expression will first be evaluated, then the operation
defined by the operator will be performed.

```
foo += bar + 70 / baz;  // equivalent to `foo = foo + (bar + 70 / baz)`
```

## If Statements

The `if` statement does not require the condition to be surrounded by parentheses (`()`), and requires a block (`{}`).

```
var alfa := 3;
if alfa == 3 {
    alfa = alfa * 7;
}
```

The general form is `if <condition> { block }`, where `<condition>` is an expression that must evaluate to a Boolean
value.

There are also the `else if` and `else` statements.

```
var foo := 7;
if foo > 7 {
    var bar := foo + 8;
} else if foo < 7 {
    var baz := foo - 2;
} else {
    var boz := foo / 2;
}
```

There can be as many `else if`s following an `if` statement as needed, and a final `else` statement is optional.

## Loop Statements

There is only one keyword to signal a loop: `for`. Using this keyword with different forms allows for the creation of
the various loop constructs.

### Traditional For Loop

The first loop construct is the traditional "for-loop". It has three parts:

- a **Declaration Statement**,
- a **Conditional Expression**,
- and a **Continue Statement**.

In this form, the *Declaration Statement* and *Conditional Expression* are always required, but the continue expression
is optional. The *Conditional Expression* must evaluate to a Boolean value.

The following example (from `tests/compiler/srcs/iterative_fib.kb`) shows this form with a *Continue Statement*.

```
var a := 0;
var b := 1;
var n := 10;

for var i := 1; i < n; i += 1 {
    var c := a + b;
    a = b;
    b = c;
}
```

Similarly, the above program, but without the *Continue Statement* (from `tests/compiler/srcs/iterative_fib2.kb`).

```
var a := 0;
var b := 1;
var n := 10;

for var i := 1; i < n; {
    var c := a + b;
    a = b;
    b = c;
    i = i + 1;
}
```

### While Loop

While the term `while` doesn't exist as a keyword in Kobold, its functionality can be similarly achieved with the
keyword `for` followed by an *Conditional Expression*. As with the traditional for-loop, the *Conditional Expression*
must evaluate to a Boolean value.

```
var foo := 0;
for foo < 10 {
    foo = foo + 1;
}
```

### "Infinite" Loop

By leaving the three expressions blank, you can achieve an "infinite" loop. The `break` statement allows for exiting the
innermost loop.

```
var foo := 0;
for {
    foo = foo + 1;
    if foo > 10 {
        break;
    }
}
```

The `break` statement can be used in any loop to exit early.

## Procedures

**Procedures** in Kobold act like functions in other languages. A procedure declaration starts with the keyword
`proc`, followed by the name of the procedure, followed by a parameter list enclosed in parentheses, followed by an
arrow operator (`->`) and a return type, and finished with a code block.

```
proc add(a: int, b: int) -> int {
    var res := a + b;
    return res;
}

// alternatively
proc add(a: int, b: int) -> int {
    return a + b;
}

proc double(a: int) -> int {
    return add(a, a);
}

var foo := double(3);   // foo == 6
```

The `return` keyword will return the value or expression that follows. `return` can also be used to exit early in a
procedure that doesn't return a value.

```
proc foo(a: float) {
    // Do some calculations...

    if a > 10.0 {
        return;
    }

    // Rest of procedure...
}
```

Procedure arguments are *pass-by-value*. In the following code snippet, `bar` will still hold the value `42` after it
has been passed to the procedure `foo`.

```
proc foo(a: int) {
    a = a + 1;
}

var bar := 42;
foo(bar);
```

### Builtin Procedures

Kobold currently has **four** builtin procedures.

#### `print(..args)`

`print` takes a variable number of arguments and outputs them to `stdout`. No spaces are inserted between arguments.
Currently `\n` (newline) is the only accepted escape sequence in strings.

```
print("Hello world!");              // outputs `Hello world!` to `stdout`. No newline.
print("Hello world ", 2, "!\n");    // outputs `Hello world 2!` to `stdout`. Newline is printed (escape sequence)
```

#### `println(..args)`

`println` takes a variable number of arguments and outputs them to `stdout` with an added newline. No spaces are
inserted between arguments. Currently `\n` (newline) is the only accepted escape sequence in strings.

```
println("Hello world!");    // outputs `Hello world!` to `stdout`. Newline added at end.
println("results: { ", results[0], ", ", results[1], ", ", results[2], " }");
```

#### `len(arr: array) -> int`

`len` returns the length of the array passed in. The returned value is of type `int`.

```
const my_arr: array[3]float = { 3.14159265, 1.61803398, 6.02214076 };
var my_arr_len := len(my_arr);  // my_arr_len == 3
```

#### `clock() -> int`

`clock` returns the current time in nanoseconds. The returned value is of type `int`.

```
var start: int;
var end: int;
start = clock();
// Do some calculations...
end = clock();
var delta := end - start;
println("Calculations took ", delta, " nanoseconds");
```

# Roadmap

The following is a list of items that are planned for the language before hitting version `0.1.0`.

- [X] Constant Declarations
- [X] Variable Declarations
- [X] Assignment Statements
    - [X] Basic Assignment (`a = expr;`)
    - [X] Assignment Operation Operators (`+=`, `*=`, `-=`,etc.)
- [ ] Operators
    - [X] Arithmetic Operators
    - [X] Logical Operators
    - [ ] Range Operators
- [X] If Statements
    - [X] Branching (`else if`, `else`)
- [ ] Switch Statements
- [ ] Loops
    - [X] Traditional For Loop
    - [X] Traditional While Loop
    - [X] "Infinite" Loop
    - [ ] Iterative Loops (`for ... in ...`)
    - [ ] Control Flow Statements
        - [X] `break`
        - [ ] `continue`
- [ ] Procedures
    - [X] Procedure Declarations
    - [X] Procedure Calls
    - [ ] Pass-by-reference
    - [ ] Multiple Returns
    - [ ] Recursion Support
- [ ] Collections
    - [X] `array`
    - [ ] `map`
    - [ ] `set`
    - [ ] `vector`
    - [ ] `matrix`
    - [ ] Collection Accessing
- [ ] User-defined Types
    - [ ] `enum`
    - [ ] `record`
    - [ ] `range`
