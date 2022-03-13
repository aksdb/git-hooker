# git-hooker

A simple git-hook wrapper that delegates hooks to (potentially multiple) global hooks and
local hooks. The idea is to not setup hooks on each individual repo and also to use custom
hooks even when there are repo-specific hooks in place.

It does that by generating delegate hooks and configuring git to globally use that directory
as `hookpath`.

It looks for hooks in:

* Subdirectories within `$HOME/.git-hooker/hooks/` (also symlinks)
* `$REPO/.git/hooks`
* `$REPO/.githooks`

They are executed in this order.

## Build

The tool is written in [Nim](https://nim-lang.org).

Why? Because I was bored and wanted to try Nim. Go produced too big binaries (and this usecase really doesn't need a scheduler and garbage collector; tinygo wasn't able to handle `os/exec` yet). Rust has too much mental overhead and the binaries are also still quite large. Freepascal was nice, since it is also batteries-included, but was still bigger than Nim (250kb vs 90kb).

Simply install `Nim` and run `make` (or look at the Makefile on how to compile manually).

## Usage

`./git-hooker install`

This will create all necessary directories and configure git to use them.

It uses the reference to the binary you call this from, so you should not move the binary somewhere else
afterwards. You can, however, simply call `install` again.
