# The Kobold Scripting Language

Kobold is a scripting language. It is a strongly-typed, procedural language that is currently in the very early stages
of development.

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

Kobold is a strongly-typed language. The following types can be used in variable declarations.

```
int     // 64-bit signed integer
uint    // 64-bit unsigned integer
float   // 64-bit floating point number
bool    // Boolean
rune    // A rune (utf-8 encoded character)
string  // A string (of utf-8 encoded characters)
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

for var i := 1; i < n; i = i + 1 {
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
