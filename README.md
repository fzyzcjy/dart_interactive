# [dart_interactive](https://github.com/fzyzcjy/dart_interactive)

[![Flutter Package](https://img.shields.io/pub/v/interactive.svg)](https://pub.dev/packages/interactive)
[![CI](https://github.com/fzyzcjy/dart_interactive/actions/workflows/ci.yaml/badge.svg)](https://github.com/fzyzcjy/dart_interactive/actions/workflows/ci.yaml)

![](https://raw.githubusercontent.com/fzyzcjy/dart_interactive/master/doc/logo.svg)

A lot of sibling languages have a REPL, and is quite helpful in everyday usage, while Dart did not have it (even though it was the [7th](https://github.com/dart-lang/sdk/issues?q=is%3Aissue+is%3Aopen+sort%3Areactions-%2B1-desc) highest-voted request). So here it comes!

## 🚀 Features

A full-featured REPL (interactive shell), with:

* Use any third-party package freely
* Auto hot-reload code anywhere, with state preserved
* Supports full grammar in REPL
* Play with existing code side-by-side

## 📚 Demo

### Demo 1: Demonstrate features

1. Use 3rd party package

```dart
>>> !dart pub add path // normal shell command
>>> import 'package:path/path.dart'; // normal import
>>> join('directory', 'file.txt') // use it (`join` is a function in 3rd party package `path`)
directory/file.txt
```

2. Auto hot-reload

```dart
>>> import 'a.dart';
>>> myFunc()
hello, tom
// ... change content of `a.dart` ...
>>> myFunc()
hello, alex
```

3. Support full grammar

```dart
>>> a = 10;
// support rich grammar
>>> int g() => a++; class A {} class B {}
... class C extends A implements B {
...   int b = 20;
...   int f() { int c = 30; a++; b++; c++; return a+b+c+g(); }
... }
>>> c = C()
>>> c.f()
74
// support redefine class/method/...
>>> class C extends A implements B { int b = 20; int f() => b; }
>>> c.f()
21
```

### Demo 2: Sample workflow

Surely, you do not *have to* use it like this. It is just a workflow that I personally feel comfortable when working with IPython/Juypter.

Suppose we have `my_app.dart` with some code, probably edited inside an IDE:

```dart
class Counter {
  int count = 0;
  String greet() => 'Hi Tom, you have count $count!';
}
```

Play with it a bit:

```dart
$ interactive --directory path/to/my/package
>>> import 'my_app.dart';
>>> counter = Counter();
>>> counter.count = 10;
>>> counter.greet()
Hi Tom, you have count 10!
>>> counter.count = 20;
>>> counter.greet()
Hi Tom, you have count 20!
```

Then we realize something wrong and want to change it:

```dart
(change "Tom" to "Alex" inside `my_app.dart`)
```

Continue playing with it (auto hot reloaded, and state preserved):

```dart
>>> counter.greet()
Hi Alex, you have count 20!
```

We can also use all dependencies in the package as well, since the REPL code is just like a normal code file in this package.

```dart
>>> import 'package:whatever_package';
>>> functionInWhateverPackage();
```

## 🎼 Getting started

Install (just standard procedure of installing global dart packages):

```shell
dart pub global activate interactive
```

Use (just a normal binary):

```shell
interactive
```

And play with it :)

## Detailed functionality list

### Expressions

```dart
>>> a = 'Hello'; b = ' world!'; 
>>> '$a, $b'                   
Hello,  world!
```

### Statements

```dart
>>> print(a)
Hello
```

<small>(All methods, not only `print`)</small>

### Functions

#### Define and redefine

```dart
>>> String f() => 'old';
>>> f()
old
>>> String f() => 'new';
>>> f()
new
```

#### Use local and global variables

```dart
>>> a = 10;
>>> int f() { int b = 20; a++; b++; return a+b; }
>>> f() 
32
>>> f()
33
```

### Classes

#### Define and redefine, preserving states

```dart
>>> class C { int a = 10; int f() => a * 2; }
>>> c = C(); print(c.f());
20
>>> class C { int a = 1000; int f() => a * 3; }
>>> c.f()
30
```

<small>Remark: This follows the Dart hot reload semantics.</small>

#### Extends and implements

```dart
>>> class A { int f() => 10; } class B extends A { int f() => 20; }
>>> A().f() + B().f()
30
>>> class B implements A { int f() => 30; }
>>> A().f() + B().f()
40
```

#### Use local variables, fields, and global variables

```dart
>>> a = 10;
>>> class C { int b = 20; int f() { int c = 30; a++; b++; c++; return a+b+c; } }
>>> c = C(); print(c.f()); print(c.f());
63
65
```

### Add libraries as dependency

Use `!dart pub add package_name`, just like what is done in Python (Jupyter/IPython).

```dart
>>> join('directory', 'file.txt')
(...error, since have not added that dependency...)
>>> !dart pub add path
Resolving dependencies...

+ path 1.8.2

Changed 1 dependency!

>>> join('directory', 'file.txt')
(...error, since have imported it...)
>>> import 'package:path/path.dart';
>>> join('directory', 'file.txt')   
directory/file.txt
```

### Imports

#### Built-in package

```dart
>>> Random().nextInt(100)
(some error outputs here, because it is not imported)
>>> import "dart:math";
>>> Random().nextInt(100)
9
```

#### Third party package

Note: If it has not been added to dependency, please follow instructions above and use `!dart pub add path` to add it.

```dart
>>> join('directory', 'file.txt')
(...error, since have imported it...)
>>> import 'package:path/path.dart';
>>> join('directory', 'file.txt')   
directory/file.txt
```

### Multiple in one go

```dart
>>> int g() => 42; class C { int a = 10; int f() => a * 2; }
>>> C().f() + g()
62
```

### Multi line if not ended

(The `...`, instead of `>>>`, appears in the two lines, because the package detects it is not finished.)

```dart
>>> class C {
...   int a = 10;
... }
>>> 
```

### Run commands

Use prefix `!`.

```dart
>>> !whoami
tom
>>> !date
2022-10-22 ...outputs...
```

### Execute within environment of existing package

```dart
interactive --directory path/to/your/package
```

## Implementation

General:

* Create a blank package and an isolate as execution workspace
* Extract imports/classes/functions/etc using analyzer, with replacing when it has the same name, and synthesize a dart file - thus supports rich Dart feature
* Trigger Dart's hot-reload after the dart file is updated
* Use analyzer to distinguish expressions/statements/compilation-units and do corresponding transformation
* The only thing to let Dart VM service to evaluate is `generatedMethod()`, and do not evaluate anything more
* Adding dependencies is as simple as running standard shell command

As for "global" variables:

* Indeed implemented by a field variable
* Statements: Make it inside `extension on dynamic { Object? generatedMethod() { ...the statements... } }` to access it seamlessly
* Functions: Convert functions to extension methods on dynamic to access it seamlessly
* Classes: Synthesize getters/setters in classes, and delegate to the field variables, whenever there is a potential access to global variable to access it seamlessly

TODO more implementation discussions if people are interested (above is so brief)

## Known Issues

#### Windows non-WSL terminal

Because of Dart's bug (https://github.com/dart-lang/sdk/issues/48329), the upstream `cli_repl` package does not work well on Windows. The issues vary from terminal to terminal, but generally speaking, backspace doesn't work, we cannot move on the command line with arrows nor Ctrl+B/F, and no command history with arrows or ^P/^N either.

Since `dart_interactive` depends on it, it is suggested to use [WSL](https://learn.microsoft.com/en-us/windows/wsl/install) or *nix.

#### Command history

Command history is not yet saved between sessions. However, this is implementable, and feel free to create an issue or PR.

#### Some errors will lead to `Hot reload failed`

Currently, some user mistakes will produce `Hot reload failed` error instead of the actual error. It will break the next command or the whole REPL. If you can't evaluate something simple as "1" after two tries, you can restart quickly with Ctrl/Cmd+D, Up Arrow and Enter in most terminals.

<details>
<summary>Example</summary>

```
>>> 1
1
>>> print() // <----- oops, argument is not optional
[WARNING 2024-03-13 01:50:18.419137] Error: Hot reload failed, maybe because code has syntax error?
>>> 1
[WARNING 2024-03-13 01:50:20.464239] Error: Hot reload failed, maybe because code has syntax error?
>>> 1
[WARNING 2024-03-13 01:50:20.464239] Error: Hot reload failed, maybe because code has syntax error?
```

</details>

## ✨ Contributors

<!-- ALL-CONTRIBUTORS-BADGE:START - Do not remove or modify this section -->
[![All Contributors](https://img.shields.io/badge/all_contributors-9-orange.svg?style=flat-square)](#contributors-)
<!-- ALL-CONTRIBUTORS-BADGE:END -->

Thanks goes to these wonderful people ([emoji key](https://allcontributors.org/docs/en/emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tbody>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/fzyzcjy"><img src="https://avatars.githubusercontent.com/u/5236035?v=4?s=100" width="100px;" alt="fzyzcjy"/><br /><sub><b>fzyzcjy</b></sub></a><br /><a href="https://github.com/fzyzcjy/dart_interactive/commits?author=fzyzcjy" title="Code">💻</a> <a href="https://github.com/fzyzcjy/dart_interactive/commits?author=fzyzcjy" title="Documentation">📖</a> <a href="#ideas-fzyzcjy" title="Ideas, Planning, & Feedback">🤔</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://mrale.ph"><img src="https://avatars.githubusercontent.com/u/131846?v=4?s=100" width="100px;" alt="Vyacheslav Egorov"/><br /><sub><b>Vyacheslav Egorov</b></sub></a><br /><a href="#ideas-mraleph" title="Ideas, Planning, & Feedback">🤔</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://blackhc.net"><img src="https://avatars.githubusercontent.com/u/729312?v=4?s=100" width="100px;" alt="Andreas Kirsch"/><br /><sub><b>Andreas Kirsch</b></sub></a><br /><a href="#ideas-BlackHC" title="Ideas, Planning, & Feedback">🤔</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://manichord.com/blog"><img src="https://avatars.githubusercontent.com/u/71999?v=4?s=100" width="100px;" alt="Maksim Lin"/><br /><sub><b>Maksim Lin</b></sub></a><br /><a href="#ideas-maks" title="Ideas, Planning, & Feedback">🤔</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/Keithcat1"><img src="https://avatars.githubusercontent.com/u/47483928?v=4?s=100" width="100px;" alt="Keithcat1"/><br /><sub><b>Keithcat1</b></sub></a><br /><a href="https://github.com/fzyzcjy/dart_interactive/commits?author=Keithcat1" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://vegardit.com"><img src="https://avatars.githubusercontent.com/u/426959?v=4?s=100" width="100px;" alt="Sebastian Thomschke"/><br /><sub><b>Sebastian Thomschke</b></sub></a><br /><a href="https://github.com/fzyzcjy/dart_interactive/commits?author=sebthom" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/arcanemachine"><img src="https://avatars.githubusercontent.com/u/3351767?v=4?s=100" width="100px;" alt="arcanemachine"/><br /><sub><b>arcanemachine</b></sub></a><br /><a href="https://github.com/fzyzcjy/dart_interactive/commits?author=arcanemachine" title="Code">💻</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/davidmartos96"><img src="https://avatars.githubusercontent.com/u/22084723?v=4?s=100" width="100px;" alt="David Martos"/><br /><sub><b>David Martos</b></sub></a><br /><a href="https://github.com/fzyzcjy/dart_interactive/commits?author=davidmartos96" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/Chematronix"><img src="https://avatars.githubusercontent.com/u/6773039?v=4?s=100" width="100px;" alt="Chematronix"/><br /><sub><b>Chematronix</b></sub></a><br /><a href="https://github.com/fzyzcjy/dart_interactive/commits?author=Chematronix" title="Code">💻</a></td>
    </tr>
  </tbody>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

More specifically, thanks for all these contributions:

* [@mraleph](https://github.com/mraleph) (Dart team): [Pointing](https://github.com/dart-lang/sdk/issues/39965#issuecomment-854854283) out Dart exposes hot reload and expression evaluation.
* [@BlackHC](https://github.com/BlackHC): Prior [proof of concept](https://github.com/BlackHC/dart_repl) and [article](https://medium.com/dartlang/evolving-dart-repl-poc-233440a35e1f) on the problem of creating a REPL.
* [@maks](https://github.com/maks): Prior [prototype](https://github.com/maks/dart_repl) as [an update-to-Dart-2](https://github.com/dart-lang/sdk/issues/39965#issuecomment-1287953021) of @BlackHC's prototype.
* [@davidmartos96](https://github.com/davidmartos96): Fix package import bug. Fix windows hot reload bug. Update analyze.
* [@Keithcat1](https://github.com/Keithcat1): Partially fix printing object.
* [@sebthom](https://github.com/sebthom): Use unused TCP port.
* [@arcanemachine](https://github.com/arcanemachine): Pin dependency.
