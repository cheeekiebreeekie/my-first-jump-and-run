[Main Page](../My_First_Jump_And_Run.md)
# Building

The extension is compiled with SCons against godot-cpp. This page covers the build itself. See [Architecture](../Architecture/Architecture.md) for what it does.

## Requirements

- gcc-13 / g++-13
- SCons
- The godot-cpp git submodule

## Build

###Linux (WSL Ubuntu 22.04.1 LTS)
``` console
$ git submodule update --init --recursive
$ scons platform=linux target=template_debug
$ scons platform=linux target=template_release
$ g++ -std=c++20 -o jumpandrun.linux/launcher jumpandrunlauncher.cpp
$ chmod +x jumpandrun.linux/launcher
```
The shared library is written to `bin/linux/`

###Windows 11 (MinGW)
```console
$ git submodule update --init --recursive
$ scons platform=windows target=template_debug
$ scons platform=windows target=template_release
$ g++ -std=c++20 -o jumpandrun.windows/launcher.exe jumpandrunlauncher.cpp
```

The shared library is written to `bin/windows/`

> [!NOTE]
> The library is named `EXTENSION-NAME`. This comes from the template and is kept on purpose.
> See [Troubleshooting](../Troubleshooting/Troubleshooting.md#library-name).

## Troubleshooting

### `godot-cpp is not available within this folder`

The submodule was not initialized. Run the first command in [Build](#build).
