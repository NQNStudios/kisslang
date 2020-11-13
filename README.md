# Kiss

*A type-safe, compiled Lisp for Haxe programs*

[![Build Status](https://travis-ci.org/hissvn/kisslang.svg?branch=main)](https://travis-ci.org/hissvn/kisslang)

## What is Kiss?

Kiss is a work in progress. (See: [Who should use Kiss?](#who-should-use-kiss))

**Kiss aims to be:**

- [ ] A statically typed Lisp
- [ ] that runs correctly almost anywhere,
- [ ] is usable at any stage of its development,
- [ ] doesn't break downstream code when it updates,
- [ ] and doesn't require full-time maintenance

**Main features:**

- [ ] Traditional Lisp macros
- [ ] [Reader macros](https://gist.github.com/chaitanyagupta/9324402)
- [ ] Plug-and-play with every pure-Haxe library on Haxelib
- [ ] Smooth FFI with any non-Haxe library you can find or write Haxe bindings for

**Extra goodies:**

- [ ] string interpolation
- [ ] raw string literals

## How does it work?

Kiss

* reads Kiss code from .kiss files
* converts the Kiss expressions into [Haxe macro expressions](https://api.haxe.org/haxe/macro/Expr.html)
* provides a [builder macro](https://haxe.org/manual/macro-type-building.html) which adds your Kiss functions to your Haxe classes before compiling

By compiling into Haxe expressions, Kiss leverages all of the cross-target, cross-platform, type-safety, and null-safety features of the Haxe language.

## Why?

I've been working on a Haxe-based interpreted Lisp called [Hiss](https://github.com/hissvn/hiss) since December 2019. I had to rewrite Hiss from scratch at least once. I've learned so much from writing Hiss, but it has majorly slowed down the productivity of Hiss-based projects because it is so complex, fast-changing, and prone to runtime errors. Kiss is like a Kompiled hISS, and a reminder to Keep It Simple, Stupid.

## How will this repo work?

The full implementation of the Kiss language will live here.

This will also be a [monorepo](https://danluu.com/monorepo/) including the VSCode extension, REPL, library ports, libraries, and other experiments that use Kiss. The biggest reason for lumping it all together is that for now, all downstream Kiss code can share the same testing and CI tools, to help achieve the language goal of not breaking downstream code.

## What does the license mean?

Licenses are confusing and GPL licenses can be intimidating. I've chosen the LGPL because I never want any big corporation to profit from my work. If you are an independent developer/studio with good intentions, I'm willing to negotiate usage of Kiss under a different license on a case-by-case basis.

## Who should use Kiss?

As of November 2020:

* No one. So far it is only a VERY basic proof-of-concept.

At the next milestone:

* Language design enthusiasts
* Hobbyists writing disposable code without deadlines

Hopefully someday:

* Professional game developers who want to learn the ways of Lisp