# EEL

## Introduction

This language's name is `eel`, and E, E, L, does not stand for anything in particular. Briefly, the goal
was to develop a language in the C-family style, and with some extras that will be detailed in the next sections.

For a quick view of the language, explore the folder `examples`. There several examples of scripts can be found.
In particular:

1. `binsearch.eel` -- example using binary search
2. `derivative.eel` -- example of derivative calculation with lambdas and closures
3. `euclid.eel` -- example of the Euclid algorithms for the calculation of the greatest-common divisor
4. `factorial.eel` -- example of implementation of factorial
5. `fibonacci.eel` -- example of Fibonacci numbers (recursive)
6. `fibonaccidp.eel` -- example of Fibonacci numbers (using arrays)
7. `modular.eel` -- example of closure for modular congruence
8. `quicksort.eel` -- example with quicksort
9. `sosqrs.eel` -- example where the sum of odd squares
10. `squares.eel` -- example of a simple sum using arrays
11. `sum.eel` -- example of a simple for loop
12. `z.eel` -- example of Mandelbrot numbers

To run an example, do:

```shell
$ lua eel.lua examples/<example>.eel
```

## Syntax and features

#### Syntax

Syntax is similar to that of C, and other C-family members. So expressions like `++x` or `y += x` are expected. 
The operators also behave like those of C, including the bitwise operators.

Control structures are also similar, for example:

```Javascript

if (A)
    print("A is true");
else if (B)
    print("B is true");
else 
   print("Else");


for (k = 0; k < N; ++k) {
    // stuff here
}


for (; ; ) {
    // infinite loop
}

while (!foo(a, b)) {
    // stuff here
}


while (true) {
    // infinite loop
}
```

Like C, `eel` also supports `break` and `continue`.

There are however differences. The most noticible is the power operator `**`. For example, `x**2` will square `x`. 
The switch control structure is also slightly different. For example:

```Javascript

switch (x) {
case 1:
    print("x == 1");
case 2:
    print("x == 2");
case 3:
    print("x == 3");
default:
    print("x is neither 1, 2, nor 3");
}

```
The switch-case control structures does not require break. The moment a case is matched, the body of the case is executed,
and once it gets to the end of the case, it will terminate the switch-case. If neither cases match, the default will be run. 

#### Comments

Comments in `eel` are similar to C99. That is:

```Javascript

// I'm a single line comment

/*
    I'm a multi-line
        comment
            comment
                comment
*/

```

#### Declaration statments

All variables have to be declared; the expression with an undeclared variable will yield a compilation error.

Declaration is done using the keywords `let` or `const`. By the declaring a variable as `const` we are imposing a read-only
constraint. The use of a `const` variable as left-hand side in an assignment statement yields a compilation error. 

Declarations can be simple, where only the qualifier (`let` or `const`) and the name of the variable is used; or compose, 
where the qualifier, the name and an expression for assignment is used. Examples;

```Javascript
let s;
let m = 123;
const PI = 3.14;
const zero;      // always zero
```

A variable simply declared (i.e. without assignment) will have default value value zero. **Note** if a constant is
simply declared, that variable will be always zero (last declaration in the example)

#### Numbers, strings and operators

#### Control structures and blocks

#### Lists and arrays


### Features

#### Boolean values

#### Prefix and postfix operators

#### `let` and `const`

#### `break` and `continue`

#### Function calls and recursion

#### Function values (`funval`)


## Future work

Due to time availability I was not able to implement the following features that I wished:

1. Hashmaps / dictionaries
2. Function overload
3. String manipulation
4. Better error messages

## Self assessment

TODO
