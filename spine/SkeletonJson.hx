/******************************************************************************
 * Spine Runtimes Software License v2.5
 *
 * Copyright (c) 2013-2016, Esoteric Software
 * All rights reserved.
 *
 * You are granted a perpetual, non-exclusive, non-sublicensable, and
 * non-transferable license to use, install, execute, and perform the Spine
 * Runtimes software and derivative works solely for personal or internal
 * use. Without the written permission of Esoteric Software (see Section 2 of
 * the Spine Software License Agreement), you may not (a) modify, translate,
 * adapt, or develop new applications using the Spine Runtimes or otherwise
 * create derivative works or improvements of the Spine Runtimes or (b) remove,
 * delete, alter, or obscure any trademarks or any copyright, trademark, patent,
 * or other intellectual property or proprietary rights notices on or in the
 * Software, including any copy thereof. Redistributions in binary or source
 * form must include this license and terms.
 *
 * THIS SOFTWARE IS PROVIDED BY ESOTERIC SOFTWARE "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL ESOTERIC SOFTWARE BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES, BUSINESS INTERRUPTION, OR LOSS OF
 * USE, DATA, OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
 * IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *****************************************************************************/

package spine;

import spine.support.files.FileHandle;
import spine.support.graphics.Color;
import spine.support.graphics.TextureAtlas;
import spine.support.utils.Array;
import spine.support.utils.FloatArray;
import spine.support.utils.IntArray;
import spine.support.utils.JsonReader;
import spine.support.utils.JsonValue;
import spine.support.utils.SerializationException;
import spine.Animation.AttachmentTimeline;
import spine.Animation.ColorTimeline;
import spine.Animation.CurveTimeline;
import spine.Animation.DeformTimeline;
import spine.Animation.DrawOrderTimeline;
import spine.Animation.EventTimeline;
import spine.Animation.IkConstraintTimeline;
import spine.Animation.PathConstraintMixTimeline;
import spine.Animation.PathConstraintPositionTimeline;
import spine.Animation.PathConstraintSpacingTimeline;
import spine.Animation.RotateTimeline;
import spine.Animation.ScaleTimeline;
import spine.Animation.ShearTimeline;
import spine.Animation.Timeline;
import spine.Animation.TransformConstraintTimeline;
import spine.Animation.TranslateTimeline;
import spine.Animation.TwoColorTimeline;
import spine.BoneData.TransformMode;
import spine.BoneData.TransformMode_enum;
import spine.PathConstraintData.PositionMode;
import spine.PathConstraintData.PositionMode_enum;
import spine.PathConstraintData.RotateMode;
import spine.PathConstraintData.RotateMode_enum;
import spine.PathConstraintData.SpacingMode;
import spine.PathConstraintData.SpacingMode_enum;
import spine.attachments.AtlasAttachmentLoader;
import spine.attachments.Attachment;
import spine.attachments.AttachmentLoader;
import spine.attachments.AttachmentType;
import spine.attachments.BoundingBoxAttachment;
import spine.attachments.ClippingAttachment;
import spine.attachments.MeshAttachment;
import spine.attachments.PathAttachment;
import spine.attachments.PointAttachment;
import spine.attachments.RegionAttachment;
import spine.attachments.VertexAttachment;

/** Loads skeleton data in the Spine JSON format.
 * <p>
 * See <a href="http://esotericsoftware.com/spine-json-format">Spine JSON format</a> and
 * <a href="http://esotericsoftware.com/spine-loading-skeleton-data#JSON-and-binary-data">JSON and binary data</a> in the Spine
 * Runtimes Guide. */
class SkeletonJson {
    private var attachmentLoader:AttachmentLoader;
    private var scale:Float = 1;
    private var linkedMeshes:Array<LinkedMesh> = new Array();

    /*public function new(atlas:TextureAtlas) {
        attachmentLoader = new AtlasAttachmentLoader(atlas);
    }*/

    public function new(attachmentLoader:AttachmentLoader) {
        if (attachmentLoader == null) throw new IllegalArgumentException("attachmentLoader cannot be null.");
        this.attachmentLoader = attachmentLoader;
    }

    /** Scales bone positions, image sizes, and translations as they are loaded. This allows different size images to be used at
     * runtime than were used in Spine.
     * <p>
     * See <a href="http://esotericsoftware.com/spine-loading-skeleton-data#Scaling">Scaling</a> in the Spine Runtimes Guide. */
    #if !spine_no_inline inline #end public function getScale():Float {
        return scale;
    }

    #if !spine_no_inline inline #end public function setScale(scale:Float):Void {
        this.scale = scale;
    }

    #if !spine_no_inline inline #end public function parse(file:FileHandle):JsonValue {
        return new JsonReader().parse(file);
    }

    #if !spine_no_inline inline #end public function readSkeletonData(file:FileHandle):SkeletonData {
        if (file == null) throw new IllegalArgumentException("file cannot be null.");

        var scale:Float = this.scale;

        var skeletonData:SkeletonData = new SkeletonData();
        skeletonData.name = file.nameWithoutExtension();

        var root:JsonValue = parse(file);

        // Skeleton.
        var skeletonMap:JsonValue = root.get("skeleton");
        if (skeletonMap != null) {
            skeletonData.hash = skeletonMap.getString("hash", null);
            skeletonData.version = skeletonMap.getString("spine", null);
            skeletonData.width = skeletonMap.getFloat("width", 0);
            skeletonData.height = skeletonMap.getFloat("height", 0);
            skeletonData.fps = skeletonMap.getFloat("fps", 30);
            skeletonData.imagesPath = skeletonMap.getString("images", null);
            skeletonData.audioPath = skeletonMap.getString("audio", null);
        }

        // Bones.
        var boneMap:JsonValue = root.getChild("bones"); while (boneMap != null) {
            var parent:BoneData = null;
            var parentName:String = boneMap.getString("parent", null);
            if (parentName != null) {
                parent = skeletonData.findBone(parentName);
                if (parent == null) throw new SerializationException("Parent bone not found: " + parentName);
            }
            var data:BoneData = new BoneData(skeletonData.bones.size, boneMap.getString("name"), parent);
            data.length = boneMap.getFloat("length", 0) * scale;
            data.x = boneMap.getFloat("x", 0) * scale;
            data.y = boneMap.getFloat("y", 0) * scale;
            data.rotation = boneMap.getFloat("rotation", 0);
            data.scaleX = boneMap.getFloat("scaleX", 1);
            data.scaleY = boneMap.getFloat("scaleY", 1);
            data.shearX = boneMap.getFloat("shearX", 0);
            data.shearY = boneMap.getFloat("shearY", 0);
            data.transformMode = TransformMode_enum.valueOf(boneMap.getString("transform", TransformMode_enum.normal_name));

            var color:String = boneMap.getString("color", null);
            if (color != null) data.getColor().set(Color.valueOf(color));

            skeletonData.bones.add(data);
        boneMap = boneMap.next; }

        // Slots.
        var slotMap:JsonValue = root.getChild("slots"); while (slotMap != null) {
            var slotName:String = slotMap.getString("name");
            var boneName:String = slotMap.getString("bone");
            var boneData:BoneData = skeletonData.findBone(boneName);
            if (boneData == null) throw new SerializationException("Slot bone not found: " + boneName);
            var data:SlotData = new SlotData(skeletonData.slots.size, slotName, boneData);

            var color:String = slotMap.getString("color", null);
            if (color != null) data.getColor().set(Color.valueOf(color));

            var dark:String = slotMap.getString("dark", null);
            if (dark != null) data.setDarkColor(Color.valueOf(dark));

            data.attachmentName = slotMap.getString("attachment", null);
            data.blendMode = BlendMode_enum.valueOf(slotMap.getString("blend", BlendMode_enum.normal_name));
            skeletonData.slots.add(data);
        slotMap = slotMap.next; }

        // IK constraints.
        var constraintMap:JsonValue = root.getChild("ik"); while (constraintMap != null) {
            var data:IkConstraintData = new IkConstraintData(constraintMap.getString("name"));
            data.order = constraintMap.getInt("order", 0);

            var boneMap:JsonValue = constraintMap.getChild("bones"); while (boneMap != null) {
                var boneName:String = boneMap.asString();
                var bone:BoneData = skeletonData.findBone(boneName);
                if (bone == null) throw new SerializationException("IK bone not found: " + boneName);
                data.bones.add(bone);
            boneMap = boneMap.next; }

            var targetName:String = constraintMap.getString("target");
            data.target = skeletonData.findBone(targetName);
            if (data.target == null) throw new SerializationException("IK target bone not found: " + targetName);

            data.mix = constraintMap.getFloat("mix", 1);
            data.bendDirection = constraintMap.getBoolean("bendPositive", true) ? 1 : -1;
            data.compress = constraintMap.getBoolean("compress", false);
            data.stretch = constraintMap.getBoolean("stretch", false);
            data.uniform = constraintMap.getBoolean("uniform", false);

            skeletonData.ikConstraints.add(data);
        constraintMap = constraintMap.next; }

        // Transform constraints.
        var constraintMap:JsonValue = root.getChild("transform"); while (constraintMap != null) {
            var data:TransformConstraintData = new TransformConstraintData(constraintMap.getString("name"));
            data.order = constraintMap.getInt("order", 0);

            var boneMap:JsonValue = constraintMap.getChild("bones"); while (boneMap != null) {
                var boneName:String = boneMap.asString();
                var bone:BoneData = skeletonData.findBone(boneName);
                if (bone == null) throw new SerializationException("Transform constraint bone not found: " + boneName);
                data.bones.add(bone);
            boneMap = boneMap.next; }

            var targetName:String = constraintMap.getString("target");
            data.target = skeletonData.findBone(targetName);
            if (data.target == null) throw new SerializationException("Transform constraint target bone not found: " + targetName);

            data.local = constraintMap.getBoolean("local", false);
            data.relative = constraintMap.getBoolean("relative", false);

            data.offsetRotation = constraintMap.getFloat("rotation", 0);
            data.offsetX = constraintMap.getFloat("x", 0) * scale;
            data.offsetY = constraintMap.getFloat("y", 0) * scale;
            data.offsetScaleX = constraintMap.getFloat("scaleX", 0);
            data.offsetScaleY = constraintMap.getFloat("scaleY", 0);
            data.offsetShearY = constraintMap.getFloat("shearY", 0);

            data.rotateMix = constraintMap.getFloat("rotateMix", 1);
            data.translateMix = constraintMap.getFloat("translateMix", 1);
            data.scaleMix = constraintMap.getFloat("scaleMix", 1);
            data.shearMix = constraintMap.getFloat("shearMix", 1);

            skeletonData.transformConstraints.add(data);
        constraintMap = constraintMap.next; }

        // Path constraints.
        var constraintMap:JsonValue = root.getChild("path"); while (constraintMap != null) {
            var data:PathConstraintData = new PathConstraintData(constraintMap.getString("name"));
            data.order = constraintMap.getInt("order", 0);

            var boneMap:JsonValue = constraintMap.getChild("bones"); while (boneMap != null) {
                var boneName:String = boneMap.asString();
                var bone:BoneData = skeletonData.findBone(boneName);
                if (bone == null) throw new SerializationException("Path bone not found: " + boneName);
                data.bones.add(bone);
            boneMap = boneMap.next; }

            var targetName:String = constraintMap.getString("target");
            data.target = skeletonData.findSlot(targetName);
            if (data.target == null) throw new SerializationException("Path target slot not found: " + targetName);

            data.positionMode = PositionMode_enum.valueOf(constraintMap.getString("positionMode", "percent"));
            data.spacingMode = SpacingMode_enum.valueOf(constraintMap.getString("spacingMode", "length"));
            data.rotateMode = RotateMode_enum.valueOf(constraintMap.getString("rotateMode", "tangent"));
            data.offsetRotation = constraintMap.getFloat("rotation", 0);
            data.position = constraintMap.getFloat("position", 0);
            if (data.positionMode == PositionMode.fixed) data.position *= scale;
            data.spacing = constraintMap.getFloat("spacing", 0);
            if (data.spacingMode == SpacingMode.length || data.spacingMode == SpacingMode.fixed) data.spacing *= scale;
            data.rotateMix = constraintMap.getFloat("rotateMix", 1);
            data.translateMix = constraintMap.getFloat("translateMix", 1);

            skeletonData.pathConstraints.add(data);
        constraintMap = constraintMap.next; }

        // Skins.
        var skinMap:JsonValue = root.getChild("skins"); while (skinMap != null) {
            var skin:Skin = new Skin(skinMap.name);
            var slotEntry:JsonValue = skinMap.child; while (slotEntry != null) {
                var slot:SlotData = skeletonData.findSlot(slotEntry.name);
                if (slot == null) throw new SerializationException("Slot not found: " + slotEntry.name);
                var entry:JsonValue = slotEntry.child; while (entry != null) {
                    try {
                        var attachment:Attachment = readAttachment(entry, skin, slot.index, entry.name, skeletonData);
                        if (attachment != null) skin.addAttachment(slot.index, entry.name, attachment);
                    } catch (ex:Dynamic) {
                        throw new SerializationException("Error reading attachment: " + entry.name + ", skin: " + skin, ex);
                    }
                entry = entry.next; }
            slotEntry = slotEntry.next; }
            skeletonData.skins.add(skin);
            if (skin.name.equals("default")) skeletonData.defaultSkin = skin;
        skinMap = skinMap.next; }

        // Linked meshes.
        var i:Int = 0; var n:Int = linkedMeshes.size; while (i < n) {
            var linkedMesh:LinkedMesh = linkedMeshes.get(i);
            var skin:Skin = linkedMesh.skin == null ? skeletonData.getDefaultSkin() : skeletonData.findSkin(linkedMesh.skin);
            if (skin == null) throw new SerializationException("Skin not found: " + linkedMesh.skin);
            var parent:Attachment = skin.getAttachment(linkedMesh.slotIndex, linkedMesh.parent);
            if (parent == null) throw new SerializationException("Parent mesh not found: " + linkedMesh.parent);
            linkedMesh.mesh.setParentMesh(cast(parent, MeshAttachment));
            linkedMesh.mesh.updateUVs();
        i++; }
        linkedMeshes.clear();

        // Events.
        var eventMap:JsonValue = root.getChild("events"); while (eventMap != null) {
            var data:EventData = new EventData(eventMap.name);
            data.intValue = eventMap.getInt("int", 0);
            data.floatValue = eventMap.getFloat("float", 0);
            data.stringValue = eventMap.getString("string", "");
            data.audioPath = eventMap.getString("audio", null);
            if (data.audioPath != null) {
                data.volume = eventMap.getFloat("volume", 1);
                data.balance = eventMap.getFloat("balance", 0);
            }
            skeletonData.events.add(data);
        eventMap = eventMap.next; }

        // Animations.
        var animationMap:JsonValue = root.getChild("animations"); while (animationMap != null) {
            try {
                readAnimation(animationMap, animationMap.name, skeletonData);
            } catch (ex:Dynamic) {
                throw new SerializationException("Error reading animation: " + animationMap.name, ex);
            }
        animationMap = animationMap.next; }

        skeletonData.bones.shrink();
        skeletonData.slots.shrink();
        skeletonData.skins.shrink();
        skeletonData.events.shrink();
        skeletonData.animations.shrink();
        skeletonData.ikConstraints.shrink();
        return skeletonData;
    }

    private function readAttachment(map:JsonValue, skin:Skin, slotIndex:Int, name:String, skeletonData:SkeletonData):Attachment {
        var scale:Float = this.scale;
        name = map.getString("name", name);

        var type:String = map.getString("type", AttachmentType_enum.region_name);

        var _continueAfterSwitch0 = false; while(true) { var _switchCond0 = (AttachmentType_enum.valueOf(type)); {
        if (_switchCond0 == region) {
            var path:String = map.getString("path", name);
            var region:RegionAttachment = attachmentLoader.newRegionAttachment(skin, name, path);
            if (region == null) return null;
            region.setPath(path);
            region.setX(map.getFloat("x", 0) * scale);
            region.setY(map.getFloat("y", 0) * scale);
            region.setScaleX(map.getFloat("scaleX", 1));
            region.setScaleY(map.getFloat("scaleY", 1));
            region.setRotation(map.getFloat("rotation", 0));
            region.setWidth(map.getFloat("width") * scale);
            region.setHeight(map.getFloat("height") * scale);

            var color:String = map.getString("color", null);
            if (color != null) region.getColor().set(Color.valueOf(color));

            region.updateOffset();
            return region;
        }
        else if (_switchCond0 == boundingbox) {
            var box:BoundingBoxAttachment = attachmentLoader.newBoundingBoxAttachment(skin, name);
            if (box == null) return null;
            readVertices(map, box, map.getInt("vertexCount") << 1);

            var color:String = map.getString("color", null);
            if (color != null) box.getColor().set(Color.valueOf(color));
            return box;
        }
        else if (_switchCond0 == mesh) {
            {
            var path:String = map.getString("path", name);
            var mesh:MeshAttachment = attachmentLoader.newMeshAttachment(skin, name, path);
            if (mesh == null) return null;
            mesh.setPath(path);

            var color:String = map.getString("color", null);
            if (color != null) mesh.getColor().set(Color.valueOf(color));

            mesh.setWidth(map.getFloat("width", 0) * scale);
            mesh.setHeight(map.getFloat("height", 0) * scale);

            var parent:String = map.getString("parent", null);
            if (parent != null) {
                mesh.setInheritDeform(map.getBoolean("deform", true));
                linkedMeshes.add(new LinkedMesh(mesh, map.getString("skin", null), slotIndex, parent));
                return mesh;
            }

            var uvs:FloatArray = map.require("uvs").asFloatArray();
            readVertices(map, mesh, uvs.length);
            mesh.setTriangles(map.require("triangles").asShortArray());
            mesh.setRegionUVs(uvs);
            mesh.updateUVs();

            if (map.has("hull")) mesh.setHullLength(map.require("hull").asInt() * 2);
            if (map.has("edges")) mesh.setEdges(map.require("edges").asShortArray());
            return mesh;
        }
        } else if (_switchCond0 == linkedmesh) {
            var path:String = map.getString("path", name);
            var mesh:MeshAttachment = attachmentLoader.newMeshAttachment(skin, name, path);
            if (mesh == null) return null;
            mesh.setPath(path);

            var color:String = map.getString("color", null);
            if (color != null) mesh.getColor().set(Color.valueOf(color));

            mesh.setWidth(map.getFloat("width", 0) * scale);
            mesh.setHeight(map.getFloat("height", 0) * scale);

            var parent:String = map.getString("parent", null);
            if (parent != null) {
                mesh.setInheritDeform(map.getBoolean("deform", true));
                linkedMeshes.add(new LinkedMesh(mesh, map.getString("skin", null), slotIndex, parent));
                return mesh;
            }

            var uvs:FloatArray = map.require("uvs").asFloatArray();
            readVertices(map, mesh, uvs.length);
            mesh.setTriangles(map.require("triangles").asShortArray());
            mesh.setRegionUVs(uvs);
            mesh.updateUVs();

            if (map.has("hull")) mesh.setHullLength(map.require("hull").asInt() * 2);
            if (map.has("edges")) mesh.setEdges(map.require("edges").asShortArray());
            return mesh;
        }
        else if (_switchCond0 == path) {
            var path:PathAttachment = attachmentLoader.newPathAttachment(skin, name);
            if (path == null) return null;
            path.setClosed(map.getBoolean("closed", false));
            path.setConstantSpeed(map.getBoolean("constantSpeed", true));

            var vertexCount:Int = map.getInt("vertexCount");
            readVertices(map, path, vertexCount << 1);

            var lengths:FloatArray = FloatArray.create(vertexCount / 3);
            var i:Int = 0;
            var curves:JsonValue = map.require("lengths").child; while (curves != null) {
                lengths[i++] = curves.asFloat() * scale; curves = curves.next; }
            path.setLengths(lengths);

            var color:String = map.getString("color", null);
            if (color != null) path.getColor().set(Color.valueOf(color));
            return path;
        }
        else if (_switchCond0 == point) {
            var point:PointAttachment = attachmentLoader.newPointAttachment(skin, name);
            if (point == null) return null;
            point.setX(map.getFloat("x", 0) * scale);
            point.setY(map.getFloat("y", 0) * scale);
            point.setRotation(map.getFloat("rotation", 0));

            var color:String = map.getString("color", null);
            if (color != null) point.getColor().set(Color.valueOf(color));
            return point;
        }
        else if (_switchCond0 == clipping) {
            var clip:ClippingAttachment = attachmentLoader.newClippingAttachment(skin, name);
            if (clip == null) return null;

            var end:String = map.getString("end", null);
            if (end != null) {
                var slot:SlotData = skeletonData.findSlot(end);
                if (slot == null) throw new SerializationException("Clipping end slot not found: " + end);
                clip.setEndSlot(slot);
            }

            readVertices(map, clip, map.getInt("vertexCount") << 1);

            var color:String = map.getString("color", null);
            if (color != null) clip.getColor().set(Color.valueOf(color));
            return clip;
        }
        } break; }
        return null;
    }

    #if !spine_no_inline inline #end private function readVertices(map:JsonValue, attachment:VertexAttachment, verticesLength:Int):Void {
        attachment.setWorldVerticesLength(verticesLength);
        var vertices:FloatArray = map.require("vertices").asFloatArray();
        if (verticesLength == vertices.length) {
            if (scale != 1) {
                var i:Int = 0; var n:Int = vertices.length; while (i < n) {
                    vertices[i] *= scale; i++; }
            }
            attachment.setVertices(vertices);
            return;
        }
        var weights:FloatArray = new FloatArray(verticesLength * 3 * 3);
        var bones:IntArray = new IntArray(verticesLength * 3);
        var i:Int = 0; var n:Int = vertices.length; while (i < n) {
            var boneCount:Int = Std.int(vertices[i++]);
            bones.add(boneCount);
            var nn:Int = i + boneCount * 4; while (i < nn) {
                bones.add(Std.int(vertices[i]));
                weights.add(vertices[i + 1] * scale);
                weights.add(vertices[i + 2] * scale);
                weights.add(vertices[i + 3]);
            i += 4; }
        }
        attachment.setBones(bones.toArray());
        attachment.setVertices(weights.toArray());
    }

    #if !spine_no_inline inline #end private function readAnimation(map:JsonValue, name:String, skeletonData:SkeletonData):Void {
        var scale:Float = this.scale;
        var timelines:Array<Timeline> = new Array();
        var duration:Float = 0;

        // Slot timelines.
        var slotMap:JsonValue = map.getChild("slots"); while (slotMap != null) {
            var slot:SlotData = skeletonData.findSlot(slotMap.name);
            if (slot == null) throw new SerializationException("Slot not found: " + slotMap.name);
            var timelineMap:JsonValue = slotMap.child; while (timelineMap != null) {
                var timelineName:String = timelineMap.name;
                if (timelineName.equals("attachment")) {
                    var timeline:AttachmentTimeline = new AttachmentTimeline(timelineMap.size);
                    timeline.slotIndex = slot.index;

                    var frameIndex:Int = 0;
                    var valueMap:JsonValue = timelineMap.child; while (valueMap != null) {
                        timeline.setFrame(frameIndex++, valueMap.getFloat("time"), valueMap.getString("name")); valueMap = valueMap.next; }
                    timelines.add(timeline);
                    duration = MathUtils.max(duration, timeline.getFrames()[timeline.getFrameCount() - 1]);

                } else if (timelineName.equals("color")) {
                    var timeline:ColorTimeline = new ColorTimeline(timelineMap.size);
                    timeline.slotIndex = slot.index;

                    var frameIndex:Int = 0;
                    var valueMap:JsonValue = timelineMap.child; while (valueMap != null) {
                        var color:Color = Color.valueOf(valueMap.getString("color"));
                        timeline.setFrame(frameIndex, valueMap.getFloat("time"), color.r, color.g, color.b, color.a);
                        readCurve(valueMap, timeline, frameIndex);
                        frameIndex++;
                    valueMap = valueMap.next; }
                    timelines.add(timeline);
                    duration = MathUtils.max(duration, timeline.getFrames()[(timeline.getFrameCount() - 1) * ColorTimeline.ENTRIES]);

                } else if (timelineName.equals("twoColor")) {
                    var timeline:TwoColorTimeline = new TwoColorTimeline(timelineMap.size);
                    timeline.slotIndex = slot.index;

                    var frameIndex:Int = 0;
                    var valueMap:JsonValue = timelineMap.child; while (valueMap != null) {
                        var light:Color = Color.valueOf(valueMap.getString("light"));
                        var dark:Color = Color.valueOf(valueMap.getString("dark"));
                        timeline.setFrame(frameIndex, valueMap.getFloat("time"), light.r, light.g, light.b, light.a, dark.r, dark.g,
                            dark.b);
                        readCurve(valueMap, timeline, frameIndex);
                        frameIndex++;
                    valueMap = valueMap.next; }
                    timelines.add(timeline);
                    duration = MathUtils.max(duration, timeline.getFrames()[(timeline.getFrameCount() - 1) * TwoColorTimeline.ENTRIES]);

                } else
                    throw new RuntimeException("Invalid timeline type for a slot: " + timelineName + " (" + slotMap.name + ")");
            timelineMap = timelineMap.next; }
        slotMap = slotMap.next; }

        // Bone timelines.
        var boneMap:JsonValue = map.getChild("bones"); while (boneMap != null) {
            var bone:BoneData = skeletonData.findBone(boneMap.name);
            if (bone == null) throw new SerializationException("Bone not found: " + boneMap.name);
            var timelineMap:JsonValue = boneMap.child; while (timelineMap != null) {
                var timelineName:String = timelineMap.name;
                if (timelineName.equals("rotate")) {
                    var timeline:RotateTimeline = new RotateTimeline(timelineMap.size);
                    timeline.boneIndex = bone.index;

                    var frameIndex:Int = 0;
                    var valueMap:JsonValue = timelineMap.child; while (valueMap != null) {
                        timeline.setFrame(frameIndex, valueMap.getFloat("time"), valueMap.getFloat("angle"));
                        readCurve(valueMap, timeline, frameIndex);
                        frameIndex++;
                    valueMap = valueMap.next; }
                    timelines.add(timeline);
                    duration = MathUtils.max(duration, timeline.getFrames()[(timeline.getFrameCount() - 1) * RotateTimeline.ENTRIES]);

                } else if (timelineName.equals("translate") || timelineName.equals("scale") || timelineName.equals("shear")) {
                    var timeline:TranslateTimeline = null;
                    var timelineScale:Float = 1;
                    if (timelineName.equals("scale"))
                        timeline = new ScaleTimeline(timelineMap.size);
                    else if (timelineName.equals("shear"))
                        timeline = new ShearTimeline(timelineMap.size);
                    else {
                        timeline = new TranslateTimeline(timelineMap.size);
                        timelineScale = scale;
                    }
                    timeline.boneIndex = bone.index;

                    var frameIndex:Int = 0;
                    var valueMap:JsonValue = timelineMap.child; while (valueMap != null) {
                        var x:Float = valueMap.getFloat("x", 0); var y:Float = valueMap.getFloat("y", 0);
                        timeline.setFrame(frameIndex, valueMap.getFloat("time"), x * timelineScale, y * timelineScale);
                        readCurve(valueMap, timeline, frameIndex);
                        frameIndex++;
                    valueMap = valueMap.next; }
                    timelines.add(timeline);
                    duration = MathUtils.max(duration, timeline.getFrames()[(timeline.getFrameCount() - 1) * TranslateTimeline.ENTRIES]);

                } else
                    throw new RuntimeException("Invalid timeline type for a bone: " + timelineName + " (" + boneMap.name + ")");
            timelineMap = timelineMap.next; }
        boneMap = boneMap.next; }

        // IK constraint timelines.
        var constraintMap:JsonValue = map.getChild("ik"); while (constraintMap != null) {
            var constraint:IkConstraintData = skeletonData.findIkConstraint(constraintMap.name);
            var timeline:IkConstraintTimeline = new IkConstraintTimeline(constraintMap.size);
            timeline.ikConstraintIndex = skeletonData.getIkConstraints().indexOf(constraint, true);
            var frameIndex:Int = 0;
            var valueMap:JsonValue = constraintMap.child; while (valueMap != null) {
                timeline.setFrame(frameIndex, valueMap.getFloat("time"), valueMap.getFloat("mix", 1),
                    valueMap.getBoolean("bendPositive", true) ? 1 : -1, valueMap.getBoolean("compress", false),
                    valueMap.getBoolean("stretch", false));
                readCurve(valueMap, timeline, frameIndex);
                frameIndex++;
            valueMap = valueMap.next; }
            timelines.add(timeline);
            duration = MathUtils.max(duration, timeline.getFrames()[(timeline.getFrameCount() - 1) * IkConstraintTimeline.ENTRIES]);
        constraintMap = constraintMap.next; }

        // Transform constraint timelines.
        var constraintMap:JsonValue = map.getChild("transform"); while (constraintMap != null) {
            var constraint:TransformConstraintData = skeletonData.findTransformConstraint(constraintMap.name);
            var timeline:TransformConstraintTimeline = new TransformConstraintTimeline(constraintMap.size);
            timeline.transformConstraintIndex = skeletonData.getTransformConstraints().indexOf(constraint, true);
            var frameIndex:Int = 0;
            var valueMap:JsonValue = constraintMap.child; while (valueMap != null) {
                timeline.setFrame(frameIndex, valueMap.getFloat("time"), valueMap.getFloat("rotateMix", 1),
                    valueMap.getFloat("translateMix", 1), valueMap.getFloat("scaleMix", 1), valueMap.getFloat("shearMix", 1));
                readCurve(valueMap, timeline, frameIndex);
                frameIndex++;
            valueMap = valueMap.next; }
            timelines.add(timeline);
            duration = MathUtils.max(duration,
                timeline.getFrames()[(timeline.getFrameCount() - 1) * TransformConstraintTimeline.ENTRIES]);
        constraintMap = constraintMap.next; }

        // Path constraint timelines.
        var constraintMap:JsonValue = map.getChild("paths"); while (constraintMap != null) {
            var data:PathConstraintData = skeletonData.findPathConstraint(constraintMap.name);
            if (data == null) throw new SerializationException("Path constraint not found: " + constraintMap.name);
            var index:Int = skeletonData.pathConstraints.indexOf(data, true);
            var timelineMap:JsonValue = constraintMap.child; while (timelineMap != null) {
                var timelineName:String = timelineMap.name;
                if (timelineName.equals("position") || timelineName.equals("spacing")) {
                    var timeline:PathConstraintPositionTimeline = null;
                    var timelineScale:Float = 1;
                    if (timelineName.equals("spacing")) {
                        timeline = new PathConstraintSpacingTimeline(timelineMap.size);
                        if (data.spacingMode == SpacingMode.length || data.spacingMode == SpacingMode.fixed) timelineScale = scale;
                    } else {
                        timeline = new PathConstraintPositionTimeline(timelineMap.size);
                        if (data.positionMode == PositionMode.fixed) timelineScale = scale;
                    }
                    timeline.pathConstraintIndex = index;
                    var frameIndex:Int = 0;
                    var valueMap:JsonValue = timelineMap.child; while (valueMap != null) {
                        timeline.setFrame(frameIndex, valueMap.getFloat("time"), valueMap.getFloat(timelineName, 0) * timelineScale);
                        readCurve(valueMap, timeline, frameIndex);
                        frameIndex++;
                    valueMap = valueMap.next; }
                    timelines.add(timeline);
                    duration = MathUtils.max(duration,
                        timeline.getFrames()[(timeline.getFrameCount() - 1) * PathConstraintPositionTimeline.ENTRIES]);
                } else if (timelineName.equals("mix")) {
                    var timeline:PathConstraintMixTimeline = new PathConstraintMixTimeline(timelineMap.size);
                    timeline.pathConstraintIndex = index;
                    var frameIndex:Int = 0;
                    var valueMap:JsonValue = timelineMap.child; while (valueMap != null) {
                        timeline.setFrame(frameIndex, valueMap.getFloat("time"), valueMap.getFloat("rotateMix", 1),
                            valueMap.getFloat("translateMix", 1));
                        readCurve(valueMap, timeline, frameIndex);
                        frameIndex++;
                    valueMap = valueMap.next; }
                    timelines.add(timeline);
                    duration = MathUtils.max(duration,
                        timeline.getFrames()[(timeline.getFrameCount() - 1) * PathConstraintMixTimeline.ENTRIES]);
                }
            timelineMap = timelineMap.next; }
        constraintMap = constraintMap.next; }

        // Deform timelines.
        var deformMap:JsonValue = map.getChild("deform"); while (deformMap != null) {
            var skin:Skin = skeletonData.findSkin(deformMap.name);
            if (skin == null) throw new SerializationException("Skin not found: " + deformMap.name);
            var slotMap:JsonValue = deformMap.child; while (slotMap != null) {
                var slot:SlotData = skeletonData.findSlot(slotMap.name);
                if (slot == null) throw new SerializationException("Slot not found: " + slotMap.name);
                var timelineMap:JsonValue = slotMap.child; while (timelineMap != null) {
                    var attachment:VertexAttachment = cast(skin.getAttachment(slot.index, timelineMap.name), VertexAttachment);
                    if (attachment == null) throw new SerializationException("Deform attachment not found: " + timelineMap.name);
                    var weighted:Bool = attachment.getBones() != null;
                    var vertices:FloatArray = attachment.getVertices();
                    var deformLength:Int = weighted ? Std.int(vertices.length / 3 * 2) : vertices.length;

                    var timeline:DeformTimeline = new DeformTimeline(timelineMap.size);
                    timeline.slotIndex = slot.index;
                    timeline.attachment = attachment;

                    var frameIndex:Int = 0;
                    var valueMap:JsonValue = timelineMap.child; while (valueMap != null) {
                        var deform:FloatArray = null;
                        var verticesValue:JsonValue = valueMap.get("vertices");
                        if (verticesValue == null)
                            deform = weighted ?  FloatArray.create(deformLength): vertices;
                        else {
                            deform = FloatArray.create(deformLength);
                            var start:Int = valueMap.getInt("offset", 0);
                            Array.copy(verticesValue.asFloatArray(), 0, deform, start, verticesValue.size);
                            if (scale != 1) {
                                var i:Int = start; var n:Int = i + verticesValue.size; while (i < n) {
                                    deform[i] *= scale; i++; }
                            }
                            if (!weighted) {
                                var i:Int = 0; while (i < deformLength) {
                                    deform[i] += vertices[i]; i++; }
                            }
                        }

                        timeline.setFrame(frameIndex, valueMap.getFloat("time"), deform);
                        readCurve(valueMap, timeline, frameIndex);
                        frameIndex++;
                    valueMap = valueMap.next; }
                    timelines.add(timeline);
                    duration = MathUtils.max(duration, timeline.getFrames()[timeline.getFrameCount() - 1]);
                timelineMap = timelineMap.next; }
            slotMap = slotMap.next; }
        deformMap = deformMap.next; }

        // Draw order timeline.
        var drawOrdersMap:JsonValue = map.get("drawOrder");
        if (drawOrdersMap == null) drawOrdersMap = map.get("draworder");
        if (drawOrdersMap != null) {
            var timeline:DrawOrderTimeline = new DrawOrderTimeline(drawOrdersMap.size);
            var slotCount:Int = skeletonData.slots.size;
            var frameIndex:Int = 0;
            var drawOrderMap:JsonValue = drawOrdersMap.child; while (drawOrderMap != null) {
                var drawOrder:IntArray = null;
                var offsets:JsonValue = drawOrderMap.get("offsets");
                if (offsets != null) {
                    drawOrder = IntArray.create(slotCount);
                    var i:Int = slotCount - 1; while (i >= 0) {
                        drawOrder[i] = -1; i--; }
                    var unchanged:IntArray = IntArray.create(slotCount - offsets.size);
                    var originalIndex:Int = 0; var unchangedIndex:Int = 0;
                    var offsetMap:JsonValue = offsets.child; while (offsetMap != null) {
                        var slot:SlotData = skeletonData.findSlot(offsetMap.getString("slot"));
                        if (slot == null) throw new SerializationException("Slot not found: " + offsetMap.getString("slot"));
                        // Collect unchanged items.
                        while (originalIndex != slot.index) {
                            unchanged[unchangedIndex++] = originalIndex++; }
                        // Set changed items.
                        drawOrder[originalIndex + offsetMap.getInt("offset")] = originalIndex++;
                    offsetMap = offsetMap.next; }
                    // Collect remaining unchanged items.
                    while (originalIndex < slotCount) {
                        unchanged[unchangedIndex++] = originalIndex++; }
                    // Fill in unchanged items.
                    var i:Int = slotCount - 1; while (i >= 0) {
                        if (drawOrder[i] == -1) drawOrder[i] = unchanged[--unchangedIndex]; i--; }
                }
                timeline.setFrame(frameIndex++, drawOrderMap.getFloat("time"), drawOrder);
            drawOrderMap = drawOrderMap.next; }
            timelines.add(timeline);
            duration = MathUtils.max(duration, timeline.getFrames()[timeline.getFrameCount() - 1]);
        }

        // Event timeline.
        var eventsMap:JsonValue = map.get("events");
        if (eventsMap != null) {
            var timeline:EventTimeline = new EventTimeline(eventsMap.size);
            var frameIndex:Int = 0;
            var eventMap:JsonValue = eventsMap.child; while (eventMap != null) {
                var eventData:EventData = skeletonData.findEvent(eventMap.getString("name"));
                if (eventData == null) throw new SerializationException("Event not found: " + eventMap.getString("name"));
                var event:Event = new Event(eventMap.getFloat("time"), eventData);
                event.intValue = eventMap.getInt("int", eventData.intValue);
                event.floatValue = eventMap.getFloat("float", eventData.floatValue);
                event.stringValue = eventMap.getString("string", eventData.stringValue);
                if (event.getData().audioPath != null) {
                    event.volume = eventMap.getFloat("volume", eventData.volume);
                    event.balance = eventMap.getFloat("balance", eventData.balance);
                }
                timeline.setFrame(frameIndex++, event);
            eventMap = eventMap.next; }
            timelines.add(timeline);
            duration = MathUtils.max(duration, timeline.getFrames()[timeline.getFrameCount() - 1]);
        }

        timelines.shrink();
        skeletonData.animations.add(new Animation(name, timelines, duration));
    }

    #if !spine_no_inline inline #end public function readCurve(map:JsonValue, timeline:CurveTimeline, frameIndex:Int):Void {
        var curve:JsonValue = map.get("curve");
        if (curve == null) return;
        if (curve.isString() && curve.asString().equals("stepped"))
            timeline.setStepped(frameIndex);
        else if (curve.isArray()) {
            timeline.setCurve(frameIndex, curve.getFloat(0), curve.getFloat(1), curve.getFloat(2), curve.getFloat(3));
        }
    }
}

class LinkedMesh {
    public var parent:String; public var skin:String = null;
    public var slotIndex:Int = 0;
    public var mesh:MeshAttachment;

    public function new(mesh:MeshAttachment, skin:String, slotIndex:Int, parent:String) {
        this.mesh = mesh;
        this.skin = skin;
        this.slotIndex = slotIndex;
        this.parent = parent;
    }
}