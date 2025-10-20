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
var beta: uint = 219u;     // explicitly typed `float`
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
