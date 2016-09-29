/******************************************************************************
 * Spine Runtimes Software License
 * Version 2.3
 *
 * Copyright (c) 2013-2015, Esoteric Software
 * All rights reserved.
 *
 * You are granted a perpetual, non-exclusive, non-sublicensable and
 * non-transferable license to use, install, execute and perform the Spine
 * Runtimes Software (the "Software") and derivative works solely for personal
 * or internal use. Without the written permission of Esoteric Software (see
 * Section 2 of the Spine Software License Agreement), you may not (a) modify,
 * translate, adapt or otherwise create derivative works, improvements of the
 * Software or develop new applications using the Software or (b) remove,
 * delete, alter or obscure any trademarks or any copyright, trademark, patent
 * or other intellectual property or proprietary rights notices on or in the
 * Software, including any copy thereof. Redistributions in binary or source
 * form must include this license and terms.
 *
 * THIS SOFTWARE IS PROVIDED BY ESOTERIC SOFTWARE "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL ESOTERIC SOFTWARE BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *****************************************************************************/
package spine;

import flash.errors.ArgumentError;
import flash.errors.Error;
import spine.animation.PathConstraintMixTimeline;
import spine.animation.PathConstraintSpacingTimeline;
import spine.animation.PathConstraintPositionTimeline;
import spine.animation.TransformConstraintTimeline;
import spine.animation.ShearTimeline;
import spine.attachments.PathAttachment;
import spine.attachments.VertexAttachment;
import flash.utils.ByteArray;
import spine.animation.Animation;
import spine.animation.AttachmentTimeline;
import spine.animation.ColorTimeline;
import spine.animation.CurveTimeline;
import spine.animation.DrawOrderTimeline;
import spine.animation.EventTimeline;
import spine.animation.DeformTimeline;
import spine.animation.IkConstraintTimeline;
import spine.animation.RotateTimeline;
import spine.animation.ScaleTimeline;
import spine.animation.Timeline;
import spine.animation.TranslateTimeline;
import spine.attachments.Attachment;
import spine.attachments.AttachmentLoader;
import spine.attachments.AttachmentType;
import spine.attachments.BoundingBoxAttachment;
import spine.attachments.MeshAttachment;
import spine.attachments.RegionAttachment;


class SkeletonJson
{
    public var attachmentLoader : AttachmentLoader;
    public var scale : Float = 1;
    private var linkedMeshes : Array<LinkedMesh> = new Array<LinkedMesh>();

    public function new(attachmentLoader : AttachmentLoader = null)
    {
        this.attachmentLoader = attachmentLoader;
    }

    /** @param object A String or ByteArray. */
    public function readSkeletonData(object : Dynamic, name : String = null) : SkeletonData
    {
        if (object == null)
        {
            throw new ArgumentError("object cannot be null.");
        }

        var root : Dynamic;
        if (Std.is(object, String))
        {
            root = haxe.Json.parse(Std.string(object));
        }
        else
        {
            if (Std.is(object, ByteArray))
            {
                root = haxe.Json.parse(cast((object), ByteArray).readUTFBytes(cast((object), ByteArray).length));
            }
            else
            {
                if (Std.is(object, Dynamic))
                {
                    root = object;
                }
                else
                {
                    throw new ArgumentError("object must be a String, ByteArray or Object.");
                }
            }
        }

        var skeletonData : SkeletonData = new SkeletonData();
        skeletonData.name = name;

        // Skeleton.
        var skeletonMap : Dynamic = Reflect.field(root, "skeleton");
        if (skeletonMap != null)
        {
            skeletonData.hash = Reflect.field(skeletonMap, "hash");
            skeletonData.version = Reflect.field(skeletonMap, "spine");
            skeletonData.width = Reflect.field(skeletonMap, "width") != null ? Reflect.field(skeletonMap, "width") : 0;
            skeletonData.height = Reflect.field(skeletonMap, "height") != null ? Reflect.field(skeletonMap, "height") : 0;
        }

        // Bones.
        var boneData:BoneData;
        var bonesField:Array<Dynamic> = Reflect.field(root, "bones");
        for (boneMap in bonesField)
        {
            var parent : BoneData = null;
            var parentName : String = Reflect.field(boneMap, "parent");
            if (parentName != null)
            {
                parent = skeletonData.findBone(parentName);
                if (parent == null)
                {
                    throw new Error("Parent bone not found: " + parentName);
                }
            }
            boneData = new BoneData(skeletonData.bones.length, Reflect.field(boneMap, "name"), parent);
            boneData.length = spine.as3hx.Compat.parseFloat(Reflect.field(boneMap, "length") != null ? Reflect.field(boneMap, "length") : 0) * scale;
            boneData.x = spine.as3hx.Compat.parseFloat(Reflect.field(boneMap, "x") != null ? Reflect.field(boneMap, "x") : 0) * scale;
            boneData.y = spine.as3hx.Compat.parseFloat(Reflect.field(boneMap, "y") != null ? Reflect.field(boneMap, "y") : 0) * scale;
            boneData.rotation = (Reflect.field(boneMap, "rotation") != null ? Reflect.field(boneMap, "rotation") : 0);
            boneData.scaleX = (Reflect.field(boneMap, "scaleX") != null) ? Reflect.field(boneMap, "scaleX") : 1;
            boneData.scaleX = (Reflect.field(boneMap, "scaleY") != null) ? Reflect.field(boneMap, "scaleY") : 1;
            boneData.shearX = spine.as3hx.Compat.parseFloat(Reflect.field(boneMap, "shearX") != null ? Reflect.field(boneMap, "shearX") : 0);
            boneData.shearY = spine.as3hx.Compat.parseFloat(Reflect.field(boneMap, "shearY") != null ? Reflect.field(boneMap, "shearY") : 0);
            boneData.inheritRotation = Reflect.field(boneMap, "inheritRotation") != null ? Reflect.field(boneMap, "inheritRotation") : true;
            boneData.inheritScale = Reflect.field(boneMap, "inheritScale") != null ? Reflect.field(boneMap, "inheritScale") : true;
            skeletonData.bones.push(boneData);
        }

        // Slots.
        var slotsField:Array<Dynamic> = Reflect.field(root, "slots");
        for (slotMap in slotsField)
        {
            var slotName : String = Reflect.field(slotMap, "name");
            var boneName : String = Reflect.field(slotMap, "bone");
            boneData = skeletonData.findBone(boneName);
            if (boneData == null)
            {
                throw new Error("Slot bone not found: " + boneName);
            }
            var slotData : SlotData = new SlotData(skeletonData.slots.length, slotName, boneData);

            var color : String = Reflect.field(slotMap, "color");
            if (color != null)
            {
                slotData.r = toColor(color, 0);
                slotData.g = toColor(color, 1);
                slotData.b = toColor(color, 2);
                slotData.a = toColor(color, 3);
            }

            slotData.attachmentName = Reflect.field(slotMap, "attachment");
            slotData.blendMode = Reflect.field(slotMap, "blend") != null ? Reflect.field(slotMap, "blend") : BlendMode.Normal;
            skeletonData.slots.push(slotData);
        }

        // IK constraints.
        var ikField:Array<Dynamic> = Reflect.field(root, "ik");
        if (ikField != null) {
            for (constraintMap in ikField)
            {
                var ikConstraintData : IkConstraintData = new IkConstraintData(Reflect.field(constraintMap, "name"));

                var bonesField:Array<String> = Reflect.field(constraintMap, "bones");
                for (boneName in bonesField)
                {
                    var bone : BoneData = skeletonData.findBone(boneName);
                    if (bone == null)
                    {
                        throw new Error("IK constraint bone not found: " + boneName);
                    }
                    ikConstraintData.bones.push(bone);
                }

                ikConstraintData.target = skeletonData.findBone(Reflect.field(constraintMap, "target"));
                if (ikConstraintData.target == null)
                {
                    throw new Error("Target bone not found: " + Reflect.field(constraintMap, "target"));
                }

                ikConstraintData.bendDirection = Reflect.field(constraintMap, "bendPositive") != null && Reflect.field(constraintMap, "bendPositive") == true ? 1 : -1;
                ikConstraintData.mix = Reflect.field(constraintMap, "mix") != null ? Reflect.field(constraintMap, "mix") : 1;

                skeletonData.ikConstraints.push(ikConstraintData);
            }
        }

        // Transform constraints.
        var transformField:Array<Dynamic> = Reflect.field(root, "transform");
        for (constraintMap in transformField)
        {
            var transformConstraintData : TransformConstraintData = new TransformConstraintData(Reflect.field(constraintMap, "name"));

            var bonesField:Array<String> = Reflect.field(constraintMap, "bones");
            for (boneName in bonesField)
            {
                var bone = skeletonData.findBone(boneName);
                if (bone == null)
                {
                    throw new Error("Transform constraint bone not found: " + boneName);
                }
                transformConstraintData.bones.push(bone);
            }

            transformConstraintData.target = skeletonData.findBone(Reflect.field(constraintMap, "target"));
            if (transformConstraintData.target == null)
            {
                throw new Error("Target bone not found: " + Reflect.field(constraintMap, "target"));
            }

            transformConstraintData.offsetRotation = spine.as3hx.Compat.parseFloat(Reflect.field(constraintMap, "rotation") != null ? Reflect.field(constraintMap, "rotation") : 0);
            transformConstraintData.offsetX = spine.as3hx.Compat.parseFloat(Reflect.field(constraintMap, "x") != null ? Reflect.field(constraintMap, "x") : 0) * scale;
            transformConstraintData.offsetY = spine.as3hx.Compat.parseFloat(Reflect.field(constraintMap, "y") != null ? Reflect.field(constraintMap, "y") : 0) * scale;
            transformConstraintData.offsetScaleX = spine.as3hx.Compat.parseFloat(Reflect.field(constraintMap, "scaleX") != null ? Reflect.field(constraintMap, "scaleX") : 0);
            transformConstraintData.offsetScaleY = spine.as3hx.Compat.parseFloat(Reflect.field(constraintMap, "scaleY") != null ? Reflect.field(constraintMap, "scaleY") : 0);
            transformConstraintData.offsetShearY = spine.as3hx.Compat.parseFloat(Reflect.field(constraintMap, "shearY") != null ? Reflect.field(constraintMap, "shearY") : 0);

            transformConstraintData.rotateMix = Reflect.field(constraintMap, "rotateMix") != null ? Reflect.field(constraintMap, "rotateMix") : 1;
            transformConstraintData.translateMix = Reflect.field(constraintMap, "translateMix") != null ? Reflect.field(constraintMap, "translateMix") : 1;
            transformConstraintData.scaleMix = Reflect.field(constraintMap, "scaleMix") != null ? Reflect.field(constraintMap, "scaleMix") : 1;
            transformConstraintData.shearMix = Reflect.field(constraintMap, "shearMix") != null ? Reflect.field(constraintMap, "shearMix") : 1;

            skeletonData.transformConstraints.push(transformConstraintData);
        }

        // Path constraints.
        var pathMap:Array<Dynamic> = Reflect.field(root, "path");
        for (constraintMap in pathMap)
        {
            var pathConstraintData : PathConstraintData = new PathConstraintData(Reflect.field(constraintMap, "name"));

            var bonesField:Array<String> = Reflect.field(constraintMap, "bones");
            for (boneName in bonesField)
            {
                var bone = skeletonData.findBone(boneName);
                if (bone == null)
                {
                    throw new Error("Path constraint bone not found: " + boneName);
                }
                pathConstraintData.bones.push(bone);
            }

            pathConstraintData.target = skeletonData.findSlot(Reflect.field(constraintMap, "target"));
            if (pathConstraintData.target == null)
            {
                throw new Error("Path target slot not found: " + Reflect.field(constraintMap, "target"));
            }

            pathConstraintData.positionMode = Reflect.field(constraintMap, "positionMode") != null ? Reflect.field(constraintMap, "positionMode") : PositionMode.Percent;
            pathConstraintData.spacingMode = Reflect.field(constraintMap, "spacingMode") != null ? Reflect.field(constraintMap, "spacingMode") : SpacingMode.Length;
            pathConstraintData.rotateMode = Reflect.field(constraintMap, "rotateMode") != null ? Reflect.field(constraintMap, "rotateMode") : RotateMode.Tangent;
            pathConstraintData.offsetRotation = spine.as3hx.Compat.parseFloat(Reflect.field(constraintMap, "rotation") != null ? Reflect.field(constraintMap, "rotation") : 0);
            pathConstraintData.position = spine.as3hx.Compat.parseFloat(Reflect.field(constraintMap, "position") != null ? Reflect.field(constraintMap, "position") : 0);
            if (pathConstraintData.positionMode == PositionMode.Fixed)
            {
                pathConstraintData.position *= scale;
            }
            pathConstraintData.spacing = spine.as3hx.Compat.parseFloat(Reflect.field(constraintMap, "spacing") != null ? Reflect.field(constraintMap, "spacing") : 0);
            if (pathConstraintData.spacingMode == SpacingMode.Length || pathConstraintData.spacingMode == SpacingMode.Fixed)
            {
                pathConstraintData.spacing *= scale;
            }
            pathConstraintData.rotateMix = Reflect.field(constraintMap, "rotateMix") != null ? Reflect.field(constraintMap, "rotateMix") : 1;
            pathConstraintData.translateMix = Reflect.field(constraintMap, "translateMix") != null ? Reflect.field(constraintMap, "translateMix") : 1;

            skeletonData.pathConstraints.push(pathConstraintData);
        }

        // Skins.
        var skins : Dynamic = Reflect.field(root, "skins");
        for (skinName in Reflect.fields(skins))
        {
            var skinMap : Dynamic = Reflect.field(skins, skinName);
            var skin : Skin = new Skin(skinName);
            for (slotName in Reflect.fields(skinMap))
            {
                var slotIndex : Int = skeletonData.findSlotIndex(slotName);
                var slotEntry : Dynamic = Reflect.field(skinMap, slotName);
                for (attachmentName in Reflect.fields(slotEntry))
                {
                    var attachment : Attachment = readAttachment(Reflect.field(slotEntry, attachmentName), skin, slotIndex, attachmentName);
                    if (attachment != null)
                    {
                        skin.addAttachment(slotIndex, attachmentName, attachment);
                    }
                }
            }
            skeletonData.skins[skeletonData.skins.length] = skin;
            if (skin.name == "default")
            {
                skeletonData.defaultSkin = skin;
            }
        }

        // Linked meshes.
        var linkedMeshes : Array<LinkedMesh> = this.linkedMeshes;
        for (linkedMesh in linkedMeshes)
        {
            var parentSkin : Skin = linkedMesh.skin == null ? skeletonData.defaultSkin : skeletonData.findSkin(linkedMesh.skin);
            if (parentSkin == null)
            {
                throw new Error("Skin not found: " + linkedMesh.skin);
            }
            var parentMesh : Attachment = parentSkin.getAttachment(linkedMesh.slotIndex, linkedMesh.parent);
            if (parentMesh == null)
            {
                throw new Error("Parent mesh not found: " + linkedMesh.parent);
            }
            linkedMesh.mesh.parentMesh = cast((parentMesh), MeshAttachment);
            linkedMesh.mesh.updateUVs();
        }
        spine.as3hx.Compat.setArrayLength(linkedMeshes, 0);

        // Events.
        var events : Dynamic = Reflect.field(root, "events");
        if (events != null)
        {
            for (eventName in Reflect.fields(events))
            {
                var eventMap : Dynamic = Reflect.field(events, eventName);
                var eventData : EventData = new EventData(eventName);
                eventData.intValue = Reflect.field(eventMap, "int") != null ? Reflect.field(eventMap, "int") : 0;
                eventData.floatValue = Reflect.field(eventMap, "float") != null ? Reflect.field(eventMap, "float") : 0;
                eventData.stringValue = Reflect.field(eventMap, "string") != null ? Reflect.field(eventMap, "string") : null;
                skeletonData.events.push(eventData);
            }
        }

        // Animations.
        var animations : Dynamic = Reflect.field(root, "animations");
        for (animationName in Reflect.fields(animations))
        {
            readAnimation(Reflect.field(animations, animationName), animationName, skeletonData);
        }

        return skeletonData;
    }

    private function readAttachment(map : Dynamic, skin : Skin, slotIndex : Int, name : String) : Attachment
    {
        name = Reflect.field(map, "name") != null ? Reflect.field(map, "name") : name;

        var typeName : String = Reflect.field(map, "type") != null ? Reflect.field(map, "type") : "region";
        var type : AttachmentType = typeName;

        var scale : Float = this.scale;
        var color : String;
        switch (type)
        {
            case AttachmentType.Region:
                var region : RegionAttachment = attachmentLoader.newRegionAttachment(skin, name, Reflect.field(map, "path") != null ? Reflect.field(map, "path") : name);
                if (region == null)
                {
                    return null;
                }
                region.path = Reflect.field(map, "path") != null ? Reflect.field(map, "path") : name;
                region.x = spine.as3hx.Compat.parseFloat(Reflect.field(map, "x") != null ? Reflect.field(map, "x") : 0) * scale;
                region.y = spine.as3hx.Compat.parseFloat(Reflect.field(map, "y") != null ? Reflect.field(map, "y") : 0) * scale;
                region.scaleX = Reflect.field(map, "scaleX") != null ? Reflect.field(map, "scaleX") : 1;
                region.scaleY = Reflect.field(map, "scaleY") != null ? Reflect.field(map, "scaleY") : 1;
                region.rotation = Reflect.field(map, "rotation") != null ? Reflect.field(map, "rotation") : 0;
                region.width = spine.as3hx.Compat.parseFloat(Reflect.field(map, "width") != null ? Reflect.field(map, "width") : 0) * scale;
                region.height = spine.as3hx.Compat.parseFloat(Reflect.field(map, "height") != null ? Reflect.field(map, "height") : 0) * scale;
                color = Reflect.field(map, "color");
                if (color != null)
                {
                    region.r = toColor(color, 0);
                    region.g = toColor(color, 1);
                    region.b = toColor(color, 2);
                    region.a = toColor(color, 3);
                }
                region.updateOffset();
                return region;
            case AttachmentType.Mesh, AttachmentType.LinkedMesh:
                var mesh : MeshAttachment = attachmentLoader.newMeshAttachment(skin, name, Reflect.field(map, "path") != null ? Reflect.field(map, "path") : name);
                if (mesh == null)
                {
                    return null;
                }
                mesh.path = Reflect.field(map, "path") != null ? Reflect.field(map, "path") : name;

                color = Reflect.field(map, "color");
                if (color != null)
                {
                    mesh.r = toColor(color, 0);
                    mesh.g = toColor(color, 1);
                    mesh.b = toColor(color, 2);
                    mesh.a = toColor(color, 3);
                }

                mesh.width = spine.as3hx.Compat.parseFloat(Reflect.field(map, "width") != null ? Reflect.field(map, "width") : 0) * scale;
                mesh.height = spine.as3hx.Compat.parseFloat(Reflect.field(map, "height") != null ? Reflect.field(map, "height") : 0) * scale;

                if (Reflect.field(map, "parent") != null)
                {
                    mesh.inheritDeform = (Reflect.field(map, "deform") != null) ? cast(Reflect.field(map, "deform"), Bool) : true;
                    linkedMeshes.push(new LinkedMesh(mesh, Reflect.field(map, "skin"), slotIndex, Reflect.field(map, "parent")));
                    return mesh;
                }

                var uvs : Array<Float> = getFloatArray(map, "uvs", 1);
                readVertices(map, mesh, uvs.length);
                mesh.triangles = getUintArray(map, "triangles");
                mesh.regionUVs = uvs;
                mesh.updateUVs();

                mesh.hullLength = spine.as3hx.Compat.parseInt(Reflect.field(map, "hull") ? Reflect.field(map, "hull") : 0) * 2;
                if (Reflect.field(map, "edges") != null)
                {
                    mesh.edges = getIntArray(map, "edges");
                }
                return mesh;
            case AttachmentType.BoundingBox:
                var box : BoundingBoxAttachment = attachmentLoader.newBoundingBoxAttachment(skin, name);
                if (box == null)
                {
                    return null;
                }
                readVertices(map, box, spine.as3hx.Compat.parseInt(Reflect.field(map, "vertexCount")) << 1);
                return box;
            case AttachmentType.Path:
                var path : PathAttachment = attachmentLoader.newPathAttachment(skin, name);
                if (path == null)
                {
                    return null;
                }
                path.closed = (Reflect.field(map, "closed") != null) ? cast(Reflect.field(map, "closed"), Bool) : false;
                path.constantSpeed = (Reflect.field(map, "constantSpeed") != null) ? cast(Reflect.field(map, "constantSpeed"), Bool) : true;

                var vertexCount : Int = spine.as3hx.Compat.parseInt(Reflect.field(map, "vertexCount"));
                readVertices(map, path, vertexCount << 1);

                var lengths : Array<Float> = new Array<Float>();
                var lengthsField:Array<Dynamic> = Reflect.field(map, "lengths");
                for (curves in lengthsField)
                {
                    lengths.push(spine.as3hx.Compat.parseFloat(curves) * scale);
                }
                path.lengths = lengths;
                return path;
            case AttachmentType.RegionSequence:
        }

        return null;
    }

    private function readVertices(map : Dynamic, attachment : VertexAttachment, verticesLength : Int) : Void
    {
        attachment.worldVerticesLength = verticesLength;
        var vertices : Array<Float> = getFloatArray(map, "vertices", 1);
        if (verticesLength == vertices.length)
        {
            if (scale != 1)
            {
                var i : Int = 0;
                var n : Int = vertices.length;
                while (i < n)
                {
                    vertices[i] *= scale;
                    i++;
                }
            }
            attachment.vertices = vertices;
            return;
        }

        var weights : Array<Float> = new Array<Float>();
        spine.as3hx.Compat.setArrayLength(weights, 0);
        var bones : Array<Int> = new Array<Int>();
        spine.as3hx.Compat.setArrayLength(bones, 0);
        var i = 0;
        var n = vertices.length;
        while (i < n)
        {
            var boneCount : Int = spine.as3hx.Compat.parseInt(vertices[i++]);
            bones.push(boneCount);
            var nn : Int = spine.as3hx.Compat.parseInt(i + boneCount * 4);
            while (i < nn)
            {
                bones.push(spine.as3hx.Compat.parseInt(vertices[i]));
                weights.push(vertices[i + 1] * scale);
                weights.push(vertices[i + 2] * scale);
                weights.push(vertices[i + 3]);
                i += 4;
            }
        }
        attachment.bones = bones;
        attachment.vertices = weights;
    }

    private function readAnimation(map : Dynamic, name : String, skeletonData : SkeletonData) : Void
    {
        var scale : Float = this.scale;
        var timelines : Array<Timeline> = new Array<Timeline>();
        var duration : Float = 0;

        var slotMap : Dynamic;
        var slotIndex : Int;
        var slotName : String;
        var values : Array<Dynamic>;
        var valueMap : Dynamic;
        var frameIndex : Int;
        var i : Int;
        var timelineName : String;

        var slots : Dynamic = Reflect.field(map, "slots");
        for (slotName in Reflect.fields(slots))
        {
            slotMap = Reflect.field(slots, slotName);
            slotIndex = skeletonData.findSlotIndex(slotName);

            for (timelineName in Reflect.fields(slotMap))
            {
                values = Reflect.field(slotMap, timelineName);
                if (timelineName == "color")
                {
                    var colorTimeline : ColorTimeline = new ColorTimeline(values.length);
                    colorTimeline.slotIndex = slotIndex;

                    frameIndex = 0;
                    for (valueMap in values)
                    {
                        var color : String = Reflect.field(valueMap, "color");
                        var r : Float = toColor(color, 0);
                        var g : Float = toColor(color, 1);
                        var b : Float = toColor(color, 2);
                        var a : Float = toColor(color, 3);
                        colorTimeline.setFrame(frameIndex, Reflect.field(valueMap, "time"), r, g, b, a);
                        readCurve(valueMap, colorTimeline, frameIndex);
                        frameIndex++;
                    }
                    timelines[timelines.length] = colorTimeline;
                    duration = Math.max(duration, colorTimeline.frames[(colorTimeline.frameCount - 1) * ColorTimeline.ENTRIES]);
                }
                else
                {
                    if (timelineName == "attachment")
                    {
                        var attachmentTimeline : AttachmentTimeline = new AttachmentTimeline(values.length);
                        attachmentTimeline.slotIndex = slotIndex;

                        frameIndex = 0;
                        for (valueMap in values)
                        {
                            attachmentTimeline.setFrame(frameIndex++, Reflect.field(valueMap, "time"), Reflect.field(valueMap, "name"));
                        }
                        timelines[timelines.length] = attachmentTimeline;
                        duration = Math.max(duration, attachmentTimeline.frames[attachmentTimeline.frameCount - 1]);
                    }
                    else
                    {
                        throw new Error("Invalid timeline type for a slot: " + timelineName + " (" + slotName + ")");
                    }
                }
            }
        }

        var bones : Dynamic = Reflect.field(map, "bones");
        for (boneName in Reflect.fields(bones))
        {
            var boneIndex : Int = skeletonData.findBoneIndex(boneName);
            if (boneIndex == -1)
            {
                throw new Error("Bone not found: " + boneName);
            }
            var boneMap : Dynamic = Reflect.field(bones, boneName);

            for (timelineName in Reflect.fields(boneMap))
            {
                values = Reflect.field(boneMap, timelineName);
                if (timelineName == "rotate")
                {
                    var rotateTimeline : RotateTimeline = new RotateTimeline(values.length);
                    rotateTimeline.boneIndex = boneIndex;

                    frameIndex = 0;
                    for (valueMap in values)
                    {
                        rotateTimeline.setFrame(frameIndex, Reflect.field(valueMap, "time"), Reflect.field(valueMap, "angle"));
                        readCurve(valueMap, rotateTimeline, frameIndex);
                        frameIndex++;
                    }
                    timelines[timelines.length] = rotateTimeline;
                    duration = Math.max(duration, rotateTimeline.frames[(rotateTimeline.frameCount - 1) * RotateTimeline.ENTRIES]);
                }
                else
                {
                    if (timelineName == "translate" || timelineName == "scale" || timelineName == "shear")
                    {
                        var translateTimeline : TranslateTimeline;
                        var timelineScale : Float = 1;
                        if (timelineName == "scale")
                        {
                            translateTimeline = new ScaleTimeline(values.length);
                        }
                        else
                        {
                            if (timelineName == "shear")
                            {
                                translateTimeline = new ShearTimeline(values.length);
                            }
                            else
                            {
                                translateTimeline = new TranslateTimeline(values.length);
                                timelineScale = scale;
                            }
                        }
                        translateTimeline.boneIndex = boneIndex;

                        frameIndex = 0;
                        for (valueMap in values)
                        {
                            var x : Float = spine.as3hx.Compat.parseFloat(Reflect.field(valueMap, "x") || 0) * timelineScale;
                            var y : Float = spine.as3hx.Compat.parseFloat(Reflect.field(valueMap, "y") || 0) * timelineScale;
                            translateTimeline.setFrame(frameIndex, Reflect.field(valueMap, "time"), x, y);
                            readCurve(valueMap, translateTimeline, frameIndex);
                            frameIndex++;
                        }
                        timelines[timelines.length] = translateTimeline;
                        duration = Math.max(duration, translateTimeline.frames[(translateTimeline.frameCount - 1) * TranslateTimeline.ENTRIES]);
                    }
                    else
                    {
                        throw new Error("Invalid timeline type for a bone: " + timelineName + " (" + boneName + ")");
                    }
                }
            }
        }

        var ikMap : Dynamic = Reflect.field(map, "ik");
        for (ikConstraintName in Reflect.fields(ikMap))
        {
            var ikConstraint : IkConstraintData = skeletonData.findIkConstraint(ikConstraintName);
            values = Reflect.field(ikMap, ikConstraintName);
            var ikTimeline : IkConstraintTimeline = new IkConstraintTimeline(values.length);
            ikTimeline.ikConstraintIndex = skeletonData.ikConstraints.indexOf(ikConstraint);
            frameIndex = 0;
            for (valueMap in values)
            {
                var mix : Float = (Reflect.field(valueMap, "mix") != null) ? Reflect.field(valueMap, "mix") : 1;
                var bendDirection : Int = (Reflect.field(valueMap, "bendPositive") != null && Reflect.field(valueMap, "bendPositive") == true) ? 1 : -1;
                ikTimeline.setFrame(frameIndex, Reflect.field(valueMap, "time"), mix, bendDirection);
                readCurve(valueMap, ikTimeline, frameIndex);
                frameIndex++;
            }
            timelines[timelines.length] = ikTimeline;
            duration = Math.max(duration, ikTimeline.frames[(ikTimeline.frameCount - 1) * IkConstraintTimeline.ENTRIES]);
        }

        var transformMap : Dynamic = Reflect.field(map, "transform");
        for (transformName in Reflect.fields(transformMap))
        {
            var transformConstraint : TransformConstraintData = skeletonData.findTransformConstraint(transformName);
            values = Reflect.field(transformMap, transformName);
            var transformTimeline : TransformConstraintTimeline = new TransformConstraintTimeline(values.length);
            transformTimeline.transformConstraintIndex = skeletonData.transformConstraints.indexOf(transformConstraint);
            frameIndex = 0;
            for (valueMap in values)
            {
                var rotateMix : Float = Reflect.field(valueMap, "rotateMix") != null ? Reflect.field(valueMap, "rotateMix") : 1;
                var translateMix : Float = Reflect.field(valueMap, "translateMix") != null ? Reflect.field(valueMap, "translateMix") : 1;
                var scaleMix : Float = Reflect.field(valueMap, "scaleMix") != null ? Reflect.field(valueMap, "scaleMix") : 1;
                var shearMix : Float = Reflect.field(valueMap, "shearMix") != null ? Reflect.field(valueMap, "shearMix") : 1;
                transformTimeline.setFrame(frameIndex, Reflect.field(valueMap, "time"), rotateMix, translateMix, scaleMix, shearMix);
                readCurve(valueMap, transformTimeline, frameIndex);
                frameIndex++;
            }
            timelines.push(transformTimeline);
            duration = Math.max(duration, transformTimeline.frames[(transformTimeline.frameCount - 1) * TransformConstraintTimeline.ENTRIES]);
        }

        // Path constraint timelines.
        var paths : Dynamic = Reflect.field(map, "paths");
        for (pathName in Reflect.fields(paths))
        {
            var index : Int = skeletonData.findPathConstraintIndex(pathName);
            if (index == -1)
            {
                throw new Error("Path constraint not found: " + pathName);
            }
            var data : PathConstraintData = skeletonData.pathConstraints[index];

            var pathMap : Dynamic = Reflect.field(paths, pathName);
            for (timelineName in Reflect.fields(pathMap))
            {
                values = Reflect.field(pathMap, timelineName);

                if (timelineName == "position" || timelineName == "spacing")
                {
                    var pathTimeline : PathConstraintPositionTimeline;
                    var timelineScale:Float = 1;
                    if (timelineName == "spacing")
                    {
                        pathTimeline = new PathConstraintSpacingTimeline(values.length);
                        if (data.spacingMode == SpacingMode.Length || data.spacingMode == SpacingMode.Fixed)
                        {
                            timelineScale = scale;
                        }
                    }
                    else
                    {
                        pathTimeline = new PathConstraintPositionTimeline(values.length);
                        if (data.positionMode == PositionMode.Fixed)
                        {
                            timelineScale = scale;
                        }
                    }
                    pathTimeline.pathConstraintIndex = index;
                    frameIndex = 0;
                    for (valueMap in values)
                    {
                        var value : Float = Reflect.field(valueMap, timelineName) != null ? Reflect.field(valueMap, timelineName) : 0;
                        pathTimeline.setFrame(frameIndex, Reflect.field(valueMap, "time"), value * timelineScale);
                        readCurve(valueMap, pathTimeline, frameIndex);
                        frameIndex++;
                    }
                    timelines.push(pathTimeline);
                    duration = Math.max(duration,
                                    pathTimeline.frames[(pathTimeline.frameCount - 1) * PathConstraintPositionTimeline.ENTRIES]
                    );
                }
                else
                {
                    if (timelineName == "mix")
                    {
                        var pathMixTimeline : PathConstraintMixTimeline = new PathConstraintMixTimeline(values.length);
                        pathMixTimeline.pathConstraintIndex = index;
                        frameIndex = 0;
                        for (valueMap in values)
                        {
                            var rotateMix = Reflect.field(valueMap, "rotateMix") != null ? Reflect.field(valueMap, "rotateMix") : 1;
                            var translateMix = Reflect.field(valueMap, "translateMix") != null ? Reflect.field(valueMap, "translateMix") : 1;
                            pathMixTimeline.setFrame(frameIndex, Reflect.field(valueMap, "time"), rotateMix, translateMix);
                            readCurve(valueMap, pathMixTimeline, frameIndex);
                            frameIndex++;
                        }
                        timelines.push(pathMixTimeline);
                        duration = Math.max(duration,
                                        pathMixTimeline.frames[(pathMixTimeline.frameCount - 1) * PathConstraintMixTimeline.ENTRIES]
                    );
                    }
                }
            }
        }

        var deformMap : Dynamic = Reflect.field(map, "deform");
        for (skinName in Reflect.fields(deformMap))
        {
            var skin : Skin = skeletonData.findSkin(skinName);
            slotMap = Reflect.field(deformMap, skinName);
            for (slotName in Reflect.fields(slotMap))
            {
                slotIndex = skeletonData.findSlotIndex(slotName);
                var timelineMap : Dynamic = Reflect.field(slotMap, slotName);
                for (timelineName in Reflect.fields(timelineMap))
                {
                    values = Reflect.field(timelineMap, timelineName);

                    var attachment : VertexAttachment = try cast(skin.getAttachment(slotIndex, timelineName), VertexAttachment) catch(e:Dynamic) null;
                    if (attachment == null)
                    {
                        throw new Error("Deform attachment not found: " + timelineName);
                    }
                    var weighted : Bool = attachment.bones != null;
                    var vertices : Array<Float> = attachment.vertices;
                    var deformLength : Int = (weighted) ? vertices.length / 3 * 2 : vertices.length;

                    var deformTimeline : DeformTimeline = new DeformTimeline(values.length);
                    deformTimeline.slotIndex = slotIndex;
                    deformTimeline.attachment = attachment;

                    frameIndex = 0;
                    for (valueMap in values)
                    {
                        var deform : Array<Float>;
                        var verticesValue : Dynamic = Reflect.field(valueMap, "vertices");
                        if (verticesValue == null)
                        {
                            deform = (weighted) ? new Array<Float>() : vertices;
                        }
                        else
                        {
                            deform = new Array<Float>();
                            var start : Int = spine.as3hx.Compat.parseFloat(Reflect.field(valueMap, "offset") || 0);
                            var temp : Array<Float> = getFloatArray(valueMap, "vertices", 1);
                            for (i in 0...temp.length)
                            {
                                deform[start + i] = temp[i];
                            }
                            if (scale != 1)
                            {
                                var n : Int;
                                for (i in start...n)
                                {
                                    deform[i] *= scale;
                                }
                            }
                            if (!weighted)
                            {
                                for (i in 0...deformLength)
                                {
                                    deform[i] += vertices[i];
                                }
                            }
                        }

                        deformTimeline.setFrame(frameIndex, Reflect.field(valueMap, "time"), deform);
                        readCurve(valueMap, deformTimeline, frameIndex);
                        frameIndex++;
                    }
                    timelines[timelines.length] = deformTimeline;
                    duration = Math.max(duration, deformTimeline.frames[deformTimeline.frameCount - 1]);
                }
            }
        }

        var drawOrderValues : Array<Dynamic> = Reflect.field(map, "drawOrder");
        if (drawOrderValues == null)
        {
            drawOrderValues = Reflect.field(map, "draworder");
        }
        if (drawOrderValues != null)
        {
            var drawOrderTimeline : DrawOrderTimeline = new DrawOrderTimeline(drawOrderValues.length);
            var slotCount : Int = skeletonData.slots.length;
            frameIndex = 0;
            for (drawOrderMap in drawOrderValues)
            {
                var drawOrder : Array<Int> = null;
                if (Reflect.field(drawOrderMap, "offsets") != null)
                {
                    drawOrder = new Array<Int>();
                    i = spine.as3hx.Compat.parseInt(slotCount - 1);
                    while (i >= 0)
                    {
                        drawOrder[i] = -1;
                        i--;
                    }
                    var offsets : Array<Dynamic> = Reflect.field(drawOrderMap, "offsets");
                    var unchanged : Array<Int> = new Array<Int>();
                    var originalIndex : Int = 0;
                    var unchangedIndex : Int = 0;
                    for (offsetMap in offsets)
                    {
                        slotIndex = skeletonData.findSlotIndex(Reflect.field(offsetMap, "slot"));
                        if (slotIndex == -1)
                        {
                            throw new Error("Slot not found: " + Reflect.field(offsetMap, "slot"));
                        }
                        // Collect unchanged items.
                        while (originalIndex != slotIndex)
                        {
                            unchanged[unchangedIndex++] = originalIndex++;
                        }
                        // Set changed items.
                        drawOrder[originalIndex + Reflect.setField(offsetMap, "offset", Reflect.field(offsetMap, "offset"))];
                    }
                    // Collect remaining unchanged items.
                    while (originalIndex < slotCount)
                    {
                        unchanged[unchangedIndex++] = originalIndex++;
                    }
                    // Fill in unchanged items.
                    i = spine.as3hx.Compat.parseInt(slotCount - 1);
                    while (i >= 0)
                    {
                        if (drawOrder[i] == -1)
                        {
                            drawOrder[i] = unchanged[--unchangedIndex];
                        }
                        i--;
                    }
                }
                drawOrderTimeline.setFrame(frameIndex++, Reflect.field(drawOrderMap, "time"), drawOrder);
            }
            timelines[timelines.length] = drawOrderTimeline;
            duration = Math.max(duration, drawOrderTimeline.frames[drawOrderTimeline.frameCount - 1]);
        }

        var eventsMap : Array<Dynamic> = Reflect.field(map, "events");
        if (eventsMap != null)
        {
            var eventTimeline : EventTimeline = new EventTimeline(eventsMap.length);
            frameIndex = 0;
            for (eventMap in eventsMap)
            {
                var eventData : EventData = skeletonData.findEvent(Reflect.field(eventMap, "name"));
                if (eventData == null)
                {
                    throw new Error("Event not found: " + Reflect.field(eventMap, "name"));
                }
                var event : Event = new Event(Reflect.field(eventMap, "time"), eventData);
                event.intValue = Reflect.field(eventMap, "int") != null ? Reflect.field(eventMap, "int") : eventData.intValue;
                event.floatValue = Reflect.field(eventMap, "float") != null ? Reflect.field(eventMap, "float") : eventData.floatValue;
                event.stringValue = Reflect.field(eventMap, "string") != null ? Reflect.field(eventMap, "string") : eventData.stringValue;
                eventTimeline.setFrame(frameIndex++, event);
            }
            timelines[timelines.length] = eventTimeline;
            duration = Math.max(duration, eventTimeline.frames[eventTimeline.frameCount - 1]);
        }

        skeletonData.animations[skeletonData.animations.length] = new Animation(name, timelines, duration);
    }

    private static function readCurve(map : Dynamic, timeline : CurveTimeline, frameIndex : Int) : Void
    {
        var curve : Dynamic = Reflect.field(map, "curve");
        if (curve == null)
        {
            return;
        }
        if (curve == "stepped")
        {
            timeline.setStepped(frameIndex);
        }
        else
        {
            if (Std.is(curve, Array))
            {
                timeline.setCurve(frameIndex, Reflect.field(curve, Std.string(0)), Reflect.field(curve, Std.string(1)), Reflect.field(curve, Std.string(2)), Reflect.field(curve, Std.string(3)));
            }
        }
    }

    private static function toColor(hexString : String, colorIndex : Int) : Float
    {
        if (hexString.length != 8) throw "Color hexidecimal length must be 8, recieved: " + hexString;
        return Std.parseInt("0x" + hexString.substring(colorIndex * 2, colorIndex * 2 + 2)) / 255;
    }

    private static function getFloatArray(map : Dynamic, name : String, scale : Float) : Array<Float>
    {
        var list : Array<Dynamic> = Reflect.field(map, name);
        var values : Array<Float> = new Array<Float>();
        var i : Int = 0;
        var n : Int = list.length;
        if (scale == 1)
        {
            while (i < n)
            {
                values[i] = list[i];
                i++;
            }
        }
        else
        {
            while (i < n)
            {
                values[i] = list[i] * scale;
                i++;
            }
        }
        return values;
    }

    private static function getIntArray(map : Dynamic, name : String) : Array<Int>
    {
        var list : Array<Dynamic> = Reflect.field(map, name);
        var values : Array<Int> = new Array<Int>();
        var i : Int = 0;
        var n : Int = list.length;
        while (i < n)
        {
            values[i] = spine.as3hx.Compat.parseInt(list[i]);
            i++;
        }
        return values;
    }

    private static function getUintArray(map : Dynamic, name : String) : Array<Int>
    {
        var list : Array<Dynamic> = Reflect.field(map, name);
        var values : Array<Int> = new Array<Int>();
        var i : Int = 0;
        var n : Int = list.length;
        while (i < n)
        {
            values[i] = spine.as3hx.Compat.parseInt(list[i]);
            i++;
        }
        return values;
    }
}




class LinkedMesh
{
    @:allow(spine)
    private var parent : String;@:allow(spine)
    private var skin : String;
    @:allow(spine)
    private var slotIndex : Int;
    @:allow(spine)
    private var mesh : MeshAttachment;

    @:allow(spine)
    private function new(mesh : MeshAttachment, skin : String, slotIndex : Int, parent : String)
    {
        this.mesh = mesh;
        this.skin = skin;
        this.slotIndex = slotIndex;
        this.parent = parent;
    }
}
