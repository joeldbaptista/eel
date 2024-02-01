# EEL

## Introduction

This language's name is `eel`, and E, E, L, does not stand for anything in particular. Briefly, the goal
was to develop a language in the C-family style, and with some extras that will be detailed in the next sections.
Also, by design, `eel` is stricter than what is expected from a scripting language, due to strict declaration rules 
and scope (see section [Scopes](## Scopes)).

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

### General view and syntax

A script in `eel.` is a list of functions, where one has to be named `main`, containing no argumments.

Syntax is similar to that of C, and other C-family members. So expressions like `++x` or `y += x` are expected. 
The operators also behave like those of C, including the bitwise operators that have the same precedence rules as in C. 

So expressions as those that follow are supported:

```Javascript

2 ** 10 // power operator

1 >> 2  // right shift
1 << 2  // left shift
2 | 7   // bitwise or
2 & 7   // bitwise and
~2      // bitwise not

x == 1 && y > 10    // boolean and
x != 1 || y >= 10   // boolean or
!(x == 1)           // boolean not
```

A word about prefix/postfix notation. The operator `++` and `--` work as in C, that is: `foo(++x)` will increment `x` and apply `foo`
over the incremented `x`; but `foo(x++)` will apply `foo` over `x`, and only then increment `x`.

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

// code ommitted

for (k = 0; k < 10; ++k) {
    if (k > 5) break;
    s += k**2;
}

```

And the next example will just add even numbers:

```Javascript

// code ommitted

for (k = 0; k < 10; ++k) {
    if (k & 1) continue;
    s += k;
}

```

There are however differences. The most noticibly is the power operator `**`. For example, `x**2` will square `x`. 
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
If no default exists, the switch terminates. 

Like C, Strings are defined using double quotes only, but single quotes are not recognized in the current version of the language, 
for example:

```Javascript
if (n & 1) {
    print("Hello there %s! You're odd!", n);
}

print('This is an error; there are not single-quotes in eel');
```

Finally, boolean values (`true` and `false`) are recognized, and they behave as `1` and `0` respectively. 

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

### Declaration statments

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
simply declared, that variable will be always zero (last declaration in the example)

### Arrays and lists

Arrays can be single dimension or multi-dimensional; the next snippet exemplifies their declaration and use:

```Javascript

let r[10]       // this is a vector length 10; i.e. size 10
let s[10,10];   // this is a 10x10 matrix; i.e. size 100
let t = [];     // this is a list; it can grown "indefinitely"
```

Bounding checks are applied to size defined arrays; that is, requesting data outside the predefined dimensions
will yield an run-time error.

Indices in list and arrays are start at zero. For example:

```Javascript
main()
{
    let r[10, 10];
    for (let i=0; i < 10; ++i) {
        for (let j=i; j < 10; ++j) {
            if (i == j) {
                r[i, j] = i;
            } else {
                r[i, j] = i + j;
                r[j, i] = i + j;
            }
        }
    }
    @r;
}
```

The lenght of a list can be infered with the operator `#` as in lua; that is:

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

```
let r = [];
for (let k=0; k < 100; ++k)
    r[k] = k**2;
@r; // prints a list or array as requested
```

### Function calls and recursion

Functions are defined and utilised as in C and C-like languages. The example, `euclid.eel` shows how a function 
is defined and called:

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

The current implementation allows recursion, without forward declaration; the examples `factorial.eel` and `fibonacci.eel` 
show how recursion is used in `eel`.

```javascript
fibo(n) {
    if (n < 2) return n;
    return fibo(n-1) + fibo(n-2);
}

main() {
    print("the 20-th fibonacci term: %s", fibo(20));
}
```

TODO -- explain implementation.

### Function values (`funval`)

Function values (or `funval`) are functions that can be assigned to variables, and thus can be used for lambdas
functions or for closures. The example `derivatives.eel` exemplify the use of closures and lambdas:

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

TODO -- explain how this was implemented


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

This rule however is not applied to lambdas where shadowing is applied; for example:

```javascript
main()
{
    let x = 10;
    const f = (x) { 
        let x = 100;
        return x**2; 
    };
    let a = 11;
    print("f(%s) = %s", a, f(a));  // prints "f(11) = 10000.0"
}
```

## Future work

Due to time availability I was not able to implement the following features that I wished:

1. Hashmaps / dictionaries
2. Function overload
3. String manipulation
4. Better error messages

## Self assessment

TODO
