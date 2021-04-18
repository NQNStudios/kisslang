# kiss-vscode README
Experimental Kiss support for VSCode

## Features

* Syntax highlighting for .kiss files
* Statically typed scripting for Visual Studio Code at runtime

## Requirements

* Haxe 4 installed and available in your system PATH.
* haxelibs:
    * hxnodejs
    * vscode
    * kiss
    * hscript
    * uuid
    * tink_macro

## Config

Kiss-Vscode checks the paths in your `UserProfile`, `HOME`, and `MSYSHOME` environment variables in order to find a `.kiss` folder. Your `.kiss` folder should contain files like the example in `kisslang/projects/kiss-vscode/config/default`. When you launch VSCode, these files will be compiled and can add new features to VSCode at runtime. To re-compile and reload these files, run "Reload Kiss config" from the command palette. To run a command from your config, run "Run a Kiss command" from the command palette. To use keyboard shortcuts, run "Run a Kiss keyboard shortcut command" or use the default shortcut, `Ctrl+;`.

## Extension Settings

## Known Issues

## Release Notes