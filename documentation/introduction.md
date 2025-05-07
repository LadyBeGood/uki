## Table of contents
- [Introduction](#introduction)
- [Language Features](#language-features)
- [Hello World](#hello-world)
- [Comments](#comments)



## Introduction
Utkrisht (uki) is a programming language for building frontend of web applications.

Utkrisht code is compiled into plain HTML, CSS, and JavaScript that runs directly in the browser.

## Language Features

- **Minimalistic syntax**: No boilerplate code while maintaining a readable structure.
- **Procedural**: Code runs top to bottom, with clear flow and structure.
- **Dynamically (but strongly) typed**: Values have types that are checked, but you don’t need to declare them explicitly.
- **Component-based UI**: Functions can return DOM elements, enabling modular UI building.
- **Readable compiled code**: Output is annotated with comments, so it’s understandable and debuggable.
- **Small bundle size**: No extra code is included—only what you write and what’s needed for the browser.

## Installation 
TODO

## Hello World
```
write "Hello World"
```
`write` is a build-in function. Arguments of a function are 
not required to be enclosed inside round brackets

## Comments
### Simple comments
Comments are ignored by the compiler. uki only supports single line comments
```
# This is a comment
```
### Documentation comments
A comment just before a `container declaration` is considered a `documentation comment`. 
Documentation comments are tokenised by the compiler.
```
# Checking for primality using an optimised trial division primality 
# test algorithm (1)
is-prime num:
    when num !> 1
        exit wrong
    then num = 2
        exit right
    then (remainder num, 2) = 0
        exit wrong

    loop 3_(power num, 0.5)_2 with i
        when (remainder num, i) = 0
            exit wrong
    
    exit right

# Number given by the user
number: to-number prompt "What is your number?"

# Print the message (2)
write "|number| is a |when !is-prime number: "not "|prime number"
```
(1) If two comments are only seperated by a newline, the compiler treats them as 
one

(2) This comment is not considered a documentation comment


