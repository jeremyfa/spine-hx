# spine-hx

Spine runtime for Haxe automatically converted from the official Java/libgdx runtime.

## Licensing

This Spine Runtime may only be used for personal or internal use, typically to evaluate Spine before purchasing. If you would like to incorporate a Spine Runtime into your applications, distribute software containing a Spine Runtime, or modify a Spine Runtime, then you will need a valid [Spine license](https://esotericsoftware.com/spine-purchase). Please see the [Spine Runtimes Software License](https://github.com/EsotericSoftware/spine-runtimes/blob/master/LICENSE) for detailed information.

The Spine Runtimes are developed with the intent to be used with data exported from Spine. By purchasing Spine, `Section 2` of the [Spine Software License](https://esotericsoftware.com/files/license.txt) grants the right to create and distribute derivative works of the Spine Runtimes.

## Spine version

spine-hx works with data exported from Spine 3.7.xx.

spine-hx supports all Spine features until 3.7.xx.

spine-hx does support loading the binary format.

## Renderer

The runtime is currently provided as is, with no default renderer.
However it should not be too difficult to create a renderer for any Haxe game engine/framework based on this runtime, as long as the engine can draw quads and 2d meshes.

## Code generation

This repository will be updated on a regular basis when new versions of Spine get available, but you can do the conversion yourself as well.

Ensure you have [Node.js](https://nodejs.org), [Haxe](https://haxe.org/) and [Git](https://git-scm.com/) installed on your machine, then run in a terminal, inside _spine-hx_ directory:

```
haxe convert.hxml
```

Every file of the runtime is converted automatically, except the files located inside ``support/`` directory and ``SkeletonBinary.hx``.

## Thanks to

[@Beeblerox](https://github.com/Beeblerox) who provided a manually converted SkeletonBinary.hx file (from C# code base)

