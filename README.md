# EEL

## Introduction

This language's name is `eel`, and E, E, L, does not stand for anything in particular. Briefly, the goal
was to develop a language in the C-family style, and with some extras that will be detailed in the next sections.
Also, by design, `eel` is stricter than what is expected from a scripting language, due to strict declaration
and scope rules.

For a quick view of the language, explore the folder `examples`. There several examples of scripts can be found.
In particular:

0. `hello.eel` -- example with `print`
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
13. `bools.eel` -- example of short-circuit boolean operators
14. `break.eel` -- example of how `break` works
15. `const.eel` -- example of `const` works (will issue an error on purpose)
16. `continue.eel` -- example of how `continue` works
17. `lambda_scope.eel` -- example of how scopes behave with lambdas (will issue an error on purpose)
18. `pfix.eel` -- example how prefix/postfix operator works
19. `redeclaration.eel` -- example of redeclaration error (will issue an error on purpose)
20. `switch.eel` -- example of switch works in `eel` 
21. `undeclared.eel` -- example of undeclared variable error (will issue an error on purpose)

To run an example, do:

```shell
$ lua eel.lua examples/<example>.eel
```

## Syntax and features

### General view and syntax

A script in `eel` is a list of functions, where one has to be named `main`, containing no argumments.

Syntax is similar to that of C, and other C-family members. So expressions like `++x` or `y += x` are expected. 
The operators also behave like those of C, including the bitwise operators and modulo, and have the same precedence 
rules as in C. 

So expressions as those that follow are supported:

```Javascript

2 ** 10 // power operator
10 % 10 // modulo operator

1 >> 2  // right shift
1 << 2  // left shift
2 | 7   // bitwise or
2 & 7   // bitwise and
~2      // bitwise not

x == 1 && y > 10    // boolean and
x != 1 || y >= 10   // boolean or
!(x == 1)           // boolean not
```

The boolean operators operate in short-circuit. Check `examples/bools.eel` to demonstrate short-circuit effect.

A word about prefix/postfix notation. The operator `++` and `--` work as in C, that is: `foo(++x)` will increment `x` and apply `foo`
over the incremented `x`; but `foo(x++)` will apply `foo` over `x`, and only then increment `x`. Check `examples/pfix.eel` to
demonstrate that.

Similarly to C and Javascript, the ternary operator works as expected; next snippet exemplifies:

```Javascript
let x = -42;
print("x = %s", x > 0? 10: -10);
```

Control structures are also similar to those of C, for example:

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

Like C, `eel` also supports `break` and `continue`. Thus, the following example will just add up to `k == 5`:

```Javascript
main()
{
	let s = 0, k;

	for (k = 0; k < 10; ++k) {
		if (k > 5) break;
		s += k;
	}
	print("s = %s %s", s, k);
}
```

And the next example will just add even numbers:

```Javascript
main()
{
	let s = 0;

	for (let k = 0; k < 10; ++k) {
		if (k & 1) continue;
		print("k = %s", k);
		s += k;
	}
	print("s = %s", s);
}
```

There are however differences. The most noticibly is `unless` control structure, that does not exist in the C family. 
An example of use:

```javascript

let x == 0;

unless (x == 0) {
    print("x != 0");
} else {
    print("x == 0");   // it will print this one
}

```

The power operator, `**`, is another difference in comparison with C-like languages. For example, `x**2` will square `x`. 

The switch control structure is also slightly different. Example `examples/switch.eel` demonstrates that:

```Javascript
switch_me(x)
{
	let a = 0;

	switch (x) {
	case 1:
		a = 100;
	case 2:
		a = 200;
	default:
		a = 300;
	}
	return a;
}

main()
{
	print("x = 1, a = %s", switch_me(1));
	print("x = 2, a = %s", switch_me(2));
	print("x = 3, a = %s", switch_me(3));

	/*
        will print

        x = 1, a = 100
        x = 2, a = 200
        x = 3, a = 300
	*/
}
```

The switch-case control structures does not require break. The moment a case is matched, the body of the case is executed,
and once it gets to the end of the case, it will terminate the switch-case. If neither cases match, the default will be run. 
If no default exists, the switch terminates.

Like C, Strings are defined using double quotes only, but single quotes are not recognized in the current version of the language, 
for example:

```Javascript
if (n & 1) {
    print("Hello there %s! You're odd!", n);
}

print('This is an error; there are not single-quotes in eel');
```

### Comments

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

### Numbers, strings and booleans

Numbers in `eel` are floating point; they can be represented without decimal point (e.g. `123`), with decimal point (e.g. `123.456`),
using E-notation (e.g. `1.234e-10` or `1.234E-10`), or with the hexadecimal notation (e.g `0xA29F`).

Currently, strings have a diminute role, and are reduced to be used with `print`; for example (`examples/hello.eel`):

```javascript
main() {
    let name = "eel", favnum = 42;

    print("Hello world!");
    print("My name is %s", name);
    print("My favourite number is %s", favnum);
}
```

Finally, boolean values, `true` and `false`, are recognised, and they behave as `1` and `0` respectively. 

### Declaration statements

All variables have to be declared; the expression with an undeclared variable will yield a compilation error.

Declaration is done using the keywords `let` or `const`. By the declaring a variable as `const` we are imposing a read-only
constraint. The use of a `const` variable as left-hand side in an assignment statement yields a compilation error. 

Declarations can be simple, where only the qualifier (`let` or `const`) and the name of the variable is used; or composite, 
where the qualifier, the name and an expression for assignment is used. Examples;

```Javascript
let s;
let m = 123;
const PI = 3.14;
const zero;      // always zero
```

A variable simply declared (i.e. without assignment) will have default value value zero. **Note** if a constant is
simply declared, that variable will be always zero (last declaration in the example).

Similarly to C and other C-like languages, declarations can be done in sequence, that is, separated by `,`. 
For example:

```javascript
let a, b = 10, c; // declares threee variables a, b, c
const aa = 10, bb = 20, cc = 30; // declares three constants aa, bb, cc
```

**Note** Because all variable have to be declared, all code lives inside a function, all variables are
local to a particular function scope. Thus, all variables live in the stack.

### Arrays and lists

Arrays can be single dimension or multi-dimensional; the next snippet exemplifies their declaration and use:

```Javascript

let r[10]       // this is a vector length 10; i.e. size 10
let s[10,10];   // this is a 10x10 matrix; i.e. size 100
let t = [];     // this is a list; it can grown "indefinitely"
```

Bounding checks are applied to size defined arrays; that is, requesting data outside the predefined dimensions
will yield an run-time error.

Indices in list and arrays start at zero. For example:

```Javascript
main()
{
    let r[10,10];

    for (let i=0; i < 10; ++i) {
        for (let j=i; j < 10; ++j) {
            if (i == j) {
                r[i,j] = i;
            } else {
                r[i,j] = i + j;
                r[j,i] = i + j;
            }
        }
    }
    @r;
}
```

The length of a list can be infered with the operator `#` as in lua; that is:

```Javascript
main() 
{
    const r = [1, 2, 3, 4];
    print("r has %s elements", #r); // prints "r has 4 elements"
    print("r[%s] = %s", 0, r[0]);   // prints "r[0] = 1"
}
```

By the way, trying to add a new element to list `r` will yield a error, since `r` is declared constant; that is, 

```Javascript
r[1] = 1000;
print("the length of r is %s", #r);  // yield "Variable `r` is read-only"
```

If the size is not determined in a 1D array (a list), that structure can grow indefinitely. For example:

```javascript
let r = [];
for (let k=0; k < 100; ++k)
    r[k] = k**2;
@r; // prints a list or array as requested
```

### Function calls and recursion

Functions are defined and utilised as in C and C-like languages. A noticible difference is that in `eel` the last parameter
can be optional, thus the following snippet is possible:

```javascript
foo(a, b = 10) {
    return a + b;
}

main()
{
    print("foo(10) = %s", foo(10)); // prints foo(10) = 20
}

```

The example, `euclid.eel` shows a more complex use of functions in `eel`.

```javascript
gcd(a, b) {
    while (b != 0) {
        let t = b;
        b = a % b;
        a = t;
    }
    return a;
}

main() {
    let a = 1071, b = 462;
    let g = gcd(1071, 462);
    print("gcd(%s, %s) = %s", a, b, g);
}
```

The current implementation allows recursion, as exemplified in the examples `factorial.eel` and `fibonacci.eel`.
The next snippet is extracted from `fibonacci.eel`:

```javascript
fibo(n) {
    if (n < 2) return n;
    return fibo(n-1) + fibo(n-2);
}

main() {
    print("the 20-th fibonacci term: %s", fibo(20));
}
```

### Function values (`funval`)

Function values (or `funval`) are functions that can be assigned to variables, and thus can be used for lambdas
functions or for closures. Currently, `funval` does not accept default parameters. The example `derivatives.eel` 
exemplify the use of closures and lambdas:

```Javascript

derivative(f, dx) 
{
    return (x) { 
        return (f(x + dx) - f(x)) / dx; 
    };
}

main()
{ 
    /* calculation of derivatives using closure */
    let eps = 1e-10;
    let f = (x){ return x**2; };        // lambda, effecively an inline function
    let df = derivative(f, eps);

    print("df(2.0) = %s", df(2.0)); /* should be ~2.0*x */
    print("df(4.0) = %s", df(4.0));
}
```

Closures need to bring the context where they have been created. This was implemented using a extra instruction, `scntx` 
(store context) and `lcntx` (load context). These functions are responsible to save the context variables in a section
of a lua table (`cntx`). These variables are extracted by traversing the parent AST searching to utilised variables
in the body of the closure function. Next, instruction `fnld` loads the function to the stack in preparation for `fcall`
that runs the code of the function.

## Scopes

In `eel` all variables live inside a function. Thus, all variables are technically local. The scope influences the 
declaration statements. For example, a variable is a sub-scope cannot have the same name of a variable in top scope:

```javascript

main()
{
    let a = 1;
    {
        let a = 2;  // this is an error; redeclaration at scope level
    }
}

```

But:

```javascript

main()
{
    {
        let a = 1;
    }
    {
        let a = 2;  // this is OK; scopes are compatible
    }
}

```

This is implemented in the following way: 

After building the AST, the final stage of the parser consists in traversing the 
tree, labelling the blocks. The labels of the blocks are encode their nested relation. For example, a function block is level
1, and an immediate sub-block is 1.1. A list relating the scope and the variable is maintained by the compiler when is
compiling a function. This list is discarded after compilation. 

When a variable is declared, in the compilation of the declaration, the scope where the declaration happens is extracted, and
the compiler first checks if there's a variable with the same name at the same scope. If so, a compilation error is issued. 
If not, the compiler iterates over the list of scopes, effectively covering the chain of nested scopes. That is, if the variable
is declared in scope 1.2.3, the compiler first searches in scope 1, and then in scope 1.2. If at any point the a variable 
with the same name is found, an error is issued. If not, the variable is created. 

Scripts `examples/redeclaration.eel`, `examples/undeclared.eel` and `examples/lambda_scopes.eel` exemplify the errors 
that occured in both situations.

## Future work

Due to time unavailability I was not able to implement the following features that I wished:

1. Hashmaps / dictionaries
2. Function overload
3. String manipulation
4. Better error messages
5. Unit testing for each feature of the language

## Self assessment

| Language criteria             | Score      | Comment
|-------------------------------|------------|------------
| Language Completeness | 3 | More then one challenge implemented                                                                          |
| Code Quality & Report | 3 | Code is organized in components for modular development, although it requires a bit of refactoring.          |
| Originality & Scope   | 3 | The current implementation deviates considerably from Selene, and combines functional & procedural paradigms |
| Self assesment        | 2 | I feel the conceptual aspects of PEGs is not yet solidified in my mind                                       |
