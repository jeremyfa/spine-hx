# spine-hx

Spine runtime for Haxe automatically converted from the official Java/libgdx runtime.

## Licensing

You can integrate the Spine Runtimes into your software free of charge, but users of your software must have their own [Spine license](https://esotericsoftware.com/spine-purchase). Please make your users aware of this requirement! This option is often chosen by those making development tools, such as an SDK, game toolkit, or software library.

In order to distribute your software containing the Spine Runtimes to others that don't have a Spine license, you need a [Spine license](https://esotericsoftware.com/spine-purchase) at the time of integration. Then you can distribute your software containing the Spine Runtimes however you like, provided others don't modify it or use it to create new software. If others want to do that, they'll need their own Spine license.

For the official legal terms governing the Spine Runtimes, please read the [Spine Runtimes License Agreement](http://esotericsoftware.com/spine-runtimes-license) and Section 2 of the [Spine Editor License Agreement](http://esotericsoftware.com/spine-editor-license#s2).

## Spine version

spine-hx works with data exported from Spine 4.0.xx.

spine-hx supports all Spine features until 4.0.xx.

spine-hx does support loading the binary format.

## Renderer

The runtime is currently provided as is, with no default renderer.
However it should not be too difficult to create a renderer for any Haxe game engine/framework based on this runtime, as long as the engine can draw quads and 2d meshes.

## Code generation

This repository will be updated on a regular basis when new versions of Spine get available, but you can do the conversion yourself as well.

Ensure you have [Node.js](https://nodejs.org), [Haxe](https://haxe.org/) and [Git](https://git-scm.com/) installed on your machine, then run in a terminal, inside _spine-hx_ directory:

```
npm install
haxe convert.hxml
```

Every file of the runtime is converted automatically, except the files located inside ``support/`` directory and ``SkeletonBinary.hx``.

Warning: haxe 3.4.7 should be used for conversion (this is only a requirement for conversion: generated runtime is compatible with all recent haxe version including 4.0 and above).

## Thanks to

[@Beeblerox](https://github.com/Beeblerox) who provided a manually converted SkeletonBinary.hx file (from C# code base)

⚠️ SkeletonBinary is not available on runtime 4.0 yet

