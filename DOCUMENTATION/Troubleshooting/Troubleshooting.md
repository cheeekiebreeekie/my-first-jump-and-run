[Main Page](../My_First_Jump_And_Run.md)
#Troubleshooting

This page lists common problems when building or running the project, and how to fix them. For build steps, see [Building](../Building/Building.md).

## Build

### `godot-cpp is not available within this folder`

The godot-cpp submodule was not initialized. Run:

```console
$ git submodule update --init --recursive
```

### `<format>` not found or `std::vformat` errors

`player.h` uses `<format>`, which needs GCC 13 or newer. Ubuntu 22.04 ships GCC 11. Install GCC 13 and make sure `gcc-13` and `g++-13` are on your `PATH`.

### SCons cannot find `gcc-13` or `g++-13`

The SConstruct hard-codes these compiler names. On Windows with MinGW, they may not exist. Either install them under those names or edit the `CC` and `CXX` values in the SConstruct.

## Launcher

### `Target binaries missing`

The launcher expects `bin/My_First_Jump_And_Run.x86_64` (or `.exe` on Windows) and the matching library in a `bin/` folder next to it. Keep the folder structure intact, as described in the README.

### Linux: no terminal window opens

The launcher starts a terminal with `-e`. Install a supported terminal (`allacritty`, `kitty`, `konsole`, or `xterm`),or set the `TERMINAL` variable to one that accepts `-e`.

### Linux: `Permission denied` when launching

The launcher needs execute permission. Open a terminal in the launcher's directory:

```console
$ chmod +x launcher
```

## Runtime

### `Unknown material` error

`set_character_material` only accepts `oak`, `concrete`, or `aerogel`. Any other name prints this error and leaves the material unchanged.

### Save file not found or not loading

Saves are read from `res://save/save1.json`. The file is only created by saving in-game and a missing file is silently ignored on load, so check the path first.

## Naming

### Library name

The library is named `EXTENSION-NAME`, and the entry symbol is `example_library_init`. Both come from the Godot GDExtension template and were kept on purpose, so renaming them is not needed for the project to run. If you rename the library, update the SConstruct, `addons/cpp/example.gdextension`, and `jumpandrunlauncher.cpp` together.