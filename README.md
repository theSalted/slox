# slox

[![Swift](https://github.com/theSalted/slox/actions/workflows/swift.yml/badge.svg)](https://github.com/theSalted/slox/actions/workflows/swift.yml)

Yet another Swift Implementation of a Lox Interpreter.

This project follows the book [Crafting Interpreters](http://www.craftinginterpreters.com/) written by [Bob Nystrom](https://twitter.com/munificentbob).

> [!NOTE]  
> This project sometimes deviate from offical implementation in the book. For better conformance with Swift feature and standard paractice. I also made an effort to make this project more extensible, since I intend to use this as foundation for future project. 

## Progress
- [x] Scanner
  - [x] `\**\` style comments
  - [x] Comprehensive Tests
- [x] Abstract Syntax Tree
  - [x] Code generator 
  - [x] Cli tool 
  - [x] Generation from JSON
  - [x] AST Printer
  - [x] Essential types 
  - [x] Basic Tests
  - [ ] Comprehensive Tests
- [ ] Parser
  - [x] Basic expression
  - [ ] Statement
  - [ ] Error recovery
  - [x] Basic Tests
  - [ ] Comprehensive Tests


## Reference
- [Original Implementation](https://github.com/munificent/craftinginterpreters)
- The [slox](https://github.com/alexito4/slox) implementation I referenced.
