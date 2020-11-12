# Kiss

*A type-safe, compiled Lisp for Haxe programs*

## What is Kiss?

Kiss is a work in progress. (See: [Who should use Kiss?](#Who-should-use-Kiss?))

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

## Who should use Kiss?

As of November 2020:

* No one. So far there is only the most basic proof-of-concept in a branch of the Hiss repository.

At the next milestone:

* Hobbyists writing disposable code without deadlines.