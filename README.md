# slox

[![Swift](https://github.com/theSalted/slox/actions/workflows/swift.yml/badge.svg)](https://github.com/theSalted/slox/actions/workflows/swift.yml)

Swift Implementation of a Lox Interpreter.

Lox is a dynamically typed and turin complete programmimng language. 

> [!NOTE]
> This implementation have achieved 100% of Lox's main specification. And couple challenge specification. I have plan to work on a Swift based DSL that builds on top of this project; and a compiled version of Lox with a lower level lanaguge. I consider Slox as done. 

This project follows the book [Crafting Interpreters](http://www.craftinginterpreters.com/) written by [Bob Nystrom](https://twitter.com/munificentbob).

> [!NOTE]  
> This project sometimes deviate from offical implementation in the book (the interpreter not the language). For better conformance with Swift feature and standard paractice. I also made an effort to make this project more extensible, since I intend to use this as foundation for future project. 

<img width="1134" alt="Screenshot 2024-06-20 at 5 10 14 AM" src="https://github.com/theSalted/slox/assets/30554090/dc473ba3-6825-4769-93c5-9c974ae84920">

## Progress
- [x] Scanner
  - [x] `\**\` style comments
  - [x] Comprehensive Tests
- [x] Abstract Syntax Tree
  - [x] Code generator 
  - [x] Cli tool 
  - [x] Generation from JSON
  - [x] AST Printer
  - [ ] Pretty Printer
  - [x] Essential types 
  - [x] Basic Tests
  - [ ] Comprehensive Tests
- [x] Parser
  - [x] Basic expression
  - [ ] Extended expressions (comma operator, ternary operator `?:`)
  - [ ] Error productions to handle each binary operator appearing without a left-hand operand
  - [x] Statement
  - [ ] Error recovery
  - [x] Basic Tests
  - [ ] Comprehensive Tests
- [x] Interpreter
  - [x] Basic expression
  - [x] Statements
  - [x] States
  - [x] Scoping
  - [x] Control Flows
  - [ ] Break and Continue
  - [x] Functions
  - [x] Foreign/Native Function
  - [x] Classes
  - [x] Runtime Entities (Callable, LoxClass, LoxFunction, & LoxInstance)
  - [x] Inheritance 
  - [ ] Expression support for REPL mode
  - [ ] Integration Tests / Lox Scripts
- [x] Resolver
  - [x] Static Analysis
  - [x] Top-level return
  - [x] Undefined Variable
  - [x] Local Scope variable declaration

## Reference
- [Original Implementation](https://github.com/munificent/craftinginterpreters)
- The [slox](https://github.com/alexito4/slox) implementation I referenced.
