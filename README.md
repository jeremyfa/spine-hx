# spine-hx

Spine runtime for Haxe ported from official AS3 runtime.

This repository was created because the other most recent spine runtime for haxe ([spinehaxe](https://github.com/bendmorris/spinehaxe)) doesn't seem to be updated anymore and is missing various new Spine features.

In order to be up to date and make it easy to add new updates, the code is staying as close as possible to the official ActionScript 3 runtime.

Current code is converted from: https://github.com/EsotericSoftware/spine-runtimes/tree/16489aaf58aac43b1b3ebd9bf76fb47c6a2cd1b0
(Spine runtime v3.4, commit July 18 2016)

Updates will be possible by following the [changes on the as3 runtime](https://github.com/EsotericSoftware/spine-runtimes/commits/master/spine-as3) and simply applying them on the haxe code.

## Licensing

This Spine Runtime may only be used for personal or internal use, typically to evaluate Spine before purchasing. If you would like to incorporate a Spine Runtime into your applications, distribute software containing a Spine Runtime, or modify a Spine Runtime, then you will need a valid [Spine license](https://esotericsoftware.com/spine-purchase). Please see the [Spine Runtimes Software License](https://github.com/EsotericSoftware/spine-runtimes/blob/master/LICENSE) for detailed information.

The Spine Runtimes are developed with the intent to be used with data exported from Spine. By purchasing Spine, `Section 2` of the [Spine Software License](https://esotericsoftware.com/files/license.txt) grants the right to create and distribute derivative works of the Spine Runtimes.

## Spine version

spine-hx works with data exported from Spine 3.4.02.

spine-hx supports all Spine features until 3.4.02, including meshes. If using the `spine.flash` classes for rendering, meshes are not supported.

spine-hx does not yet support loading the binary format.

## Compatibility layer

In order to stay close to the ActionScript 3 implementation, a `spine.compat` package is included in the library. The library should work fine with OpenFl or plain js/flash target (if not, please file an issue).

The compatibility layer was made possible by including some (edited) files from [OpenFl](https://github.com/openfl/openfl) and [as3hx](https://github.com/HaxeFoundation/as3hx) projects. Thanks for their work!
