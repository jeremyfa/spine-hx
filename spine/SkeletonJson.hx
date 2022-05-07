/******************************************************************************
 * Spine Runtimes License Agreement
 * Last updated January 1, 2020. Replaces all prior versions.
 *
 * Copyright (c) 2013-2020, Esoteric Software LLC
 *
 * Integration of the Spine Runtimes into software or otherwise creating
 * derivative works of the Spine Runtimes is permitted under the terms and
 * conditions of Section 2 of the Spine Editor License Agreement:
 * http://esotericsoftware.com/spine-editor-license
 *
 * Otherwise, it is permitted to integrate the Spine Runtimes into software
 * or otherwise create derivative works of the Spine Runtimes (collectively,
 * "Products"), provided that each user of the Products must obtain their own
 * Spine Editor license and redistribution of the Products in any form must
 * include this license and copyright notice.
 *
 * THE SPINE RUNTIMES ARE PROVIDED BY ESOTERIC SOFTWARE LLC "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL ESOTERIC SOFTWARE LLC BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES,
 * BUSINESS INTERRUPTION, OR LOSS OF USE, DATA, OR PROFITS) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THE SPINE RUNTIMES, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *****************************************************************************/

package spine;

import spine.utils.SpineUtils.*;



import spine.support.files.FileHandle;
import spine.support.graphics.Color;
import spine.support.graphics.TextureAtlas;
import spine.support.utils.Array;
import spine.support.utils.FloatArray;
import spine.support.utils.IntArray;
import spine.support.utils.JsonReader;
import spine.support.utils.JsonValue;
import spine.support.utils.SerializationException;

import spine.Animation.AlphaTimeline;
import spine.Animation.AttachmentTimeline;
import spine.Animation.CurveTimeline;
import spine.Animation.CurveTimeline1;
import spine.Animation.CurveTimeline2;
import spine.Animation.DeformTimeline;
import spine.Animation.DrawOrderTimeline;
import spine.Animation.EventTimeline;
import spine.Animation.IkConstraintTimeline;
import spine.Animation.PathConstraintMixTimeline;
import spine.Animation.PathConstraintPositionTimeline;
import spine.Animation.PathConstraintSpacingTimeline;
import spine.Animation.RGB2Timeline;
import spine.Animation.RGBA2Timeline;
import spine.Animation.RGBATimeline;
import spine.Animation.RGBTimeline;
import spine.Animation.RotateTimeline;
import spine.Animation.ScaleTimeline;
import spine.Animation.ScaleXTimeline;
import spine.Animation.ScaleYTimeline;
import spine.Animation.ShearTimeline;
import spine.Animation.ShearXTimeline;
import spine.Animation.ShearYTimeline;
import spine.Animation.Timeline;
import spine.Animation.TransformConstraintTimeline;
import spine.Animation.TranslateTimeline;
import spine.Animation.TranslateXTimeline;
import spine.Animation.TranslateYTimeline;
import spine.BoneData.TransformMode;
import spine.BoneData.TransformMode_enum;
import spine.PathConstraintData.PositionMode;
import spine.PathConstraintData.PositionMode_enum;
import spine.PathConstraintData.RotateMode;
import spine.PathConstraintData.RotateMode_enum;
import spine.PathConstraintData.SpacingMode;
import spine.PathConstraintData.SpacingMode_enum;
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
 * JSON is human readable but the binary format is much smaller on disk and faster to load. See {@link SkeletonBinary}.
 * <p>
 * See <a href="http://esotericsoftware.com/spine-json-format">Spine JSON format</a> and
 * <a href="http://esotericsoftware.com/spine-loading-skeleton-data#JSON-and-binary-data">JSON and binary data</a> in the Spine
 * Runtimes Guide. */
class SkeletonJson extends SkeletonLoader {
    public function new(attachmentLoader:AttachmentLoader) {
        super(attachmentLoader);
    }

    /*public function new(atlas:TextureAtlas) {
        super(atlas);
    }*/

    /*#if !spine_no_inline inline #end public function readSkeletonData(file:FileHandle):SkeletonData {
        if (file == null) throw new IllegalArgumentException("file cannot be null.");
        var skeletonData:SkeletonData = readSkeletonData(new JsonReader().parse(file));
        skeletonData.name = file.nameWithoutExtension();
        return skeletonData;
    }*/

    /*#if !spine_no_inline inline #end public function readSkeletonData(input:InputStream):SkeletonData {
        if (input == null) throw new IllegalArgumentException("dataInput cannot be null.");
        return readSkeletonData(new JsonReader().parse(input));
    }*/

    public function readSkeletonData(root:JsonValue):SkeletonData {
        if (root == null) throw new IllegalArgumentException("root cannot be null.");

        var scale:Float = this.scale;

        // Skeleton.
        var skeletonData:SkeletonData = new SkeletonData();
        var skeletonMap:JsonValue = root.get("skeleton");
        if (skeletonMap != null) {
            skeletonData.hash = skeletonMap.getString("hash", null);
            skeletonData.version = skeletonMap.getString("spine", null);
            skeletonData.x = skeletonMap.getFloat("x", 0);
            skeletonData.y = skeletonMap.getFloat("y", 0);
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
            data.skinRequired = boneMap.getBoolean("skin", false);

            var color:String = boneMap.getString("color", null);
            if (color != null) Color.valueOfIntoColor(color, data.getColor());

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
            if (color != null) Color.valueOfIntoColor(color, data.getColor());

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
            data.skinRequired = constraintMap.getBoolean("skin", false);

            var entry:JsonValue = constraintMap.getChild("bones"); while (entry != null) {
                var bone:BoneData = skeletonData.findBone(entry.asString());
                if (bone == null) throw new SerializationException("IK bone not found: " + entry);
                data.bones.add(bone);
            entry = entry.next; }

            var targetName:String = constraintMap.getString("target");
            data.target = skeletonData.findBone(targetName);
            if (data.target == null) throw new SerializationException("IK target bone not found: " + targetName);

            data.mix = constraintMap.getFloat("mix", 1);
            data.softness = constraintMap.getFloat("softness", 0) * scale;
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
            data.skinRequired = constraintMap.getBoolean("skin", false);

            var entry:JsonValue = constraintMap.getChild("bones"); while (entry != null) {
                var bone:BoneData = skeletonData.findBone(entry.asString());
                if (bone == null) throw new SerializationException("Transform constraint bone not found: " + entry);
                data.bones.add(bone);
            entry = entry.next; }

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

            data.mixRotate = constraintMap.getFloat("mixRotate", 1);
            data.mixX = constraintMap.getFloat("mixX", 1);
            data.mixY = constraintMap.getFloat("mixY", data.mixX);
            data.mixScaleX = constraintMap.getFloat("mixScaleX", 1);
            data.mixScaleY = constraintMap.getFloat("mixScaleY", data.mixScaleX);
            data.mixShearY = constraintMap.getFloat("mixShearY", 1);

            skeletonData.transformConstraints.add(data);
        constraintMap = constraintMap.next; }

        // Path constraints.
        var constraintMap:JsonValue = root.getChild("path"); while (constraintMap != null) {
            var data:PathConstraintData = new PathConstraintData(constraintMap.getString("name"));
            data.order = constraintMap.getInt("order", 0);
            data.skinRequired = constraintMap.getBoolean("skin", false);

            var entry:JsonValue = constraintMap.getChild("bones"); while (entry != null) {
                var bone:BoneData = skeletonData.findBone(entry.asString());
                if (bone == null) throw new SerializationException("Path bone not found: " + entry);
                data.bones.add(bone);
            entry = entry.next; }

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
            data.mixRotate = constraintMap.getFloat("mixRotate", 1);
            data.mixX = constraintMap.getFloat("mixX", 1);
            data.mixY = constraintMap.getFloat("mixY", 1);

            skeletonData.pathConstraints.add(data);
        constraintMap = constraintMap.next; }

        // Skins.
        var skinMap:JsonValue = root.getChild("skins"); while (skinMap != null) {
            var skin:Skin = new Skin(skinMap.getString("name"));
            var entry:JsonValue = skinMap.getChild("bones"); while (entry != null) {
                var bone:BoneData = skeletonData.findBone(entry.asString());
                if (bone == null) throw new SerializationException("Skin bone not found: " + entry);
                skin.bones.add(bone);
            entry = entry.next; }
            skin.bones.shrink();
            var entry:JsonValue = skinMap.getChild("ik"); while (entry != null) {
                var constraint:IkConstraintData = skeletonData.findIkConstraint(entry.asString());
                if (constraint == null) throw new SerializationException("Skin IK constraint not found: " + entry);
                skin.constraints.add(constraint);
            entry = entry.next; }
            var entry:JsonValue = skinMap.getChild("transform"); while (entry != null) {
                var constraint:TransformConstraintData = skeletonData.findTransformConstraint(entry.asString());
                if (constraint == null) throw new SerializationException("Skin transform constraint not found: " + entry);
                skin.constraints.add(constraint);
            entry = entry.next; }
            var entry:JsonValue = skinMap.getChild("path"); while (entry != null) {
                var constraint:PathConstraintData = skeletonData.findPathConstraint(entry.asString());
                if (constraint == null) throw new SerializationException("Skin path constraint not found: " + entry);
                skin.constraints.add(constraint);
            entry = entry.next; }
            skin.constraints.shrink();
            var slotEntry:JsonValue = skinMap.getChild("attachments"); while (slotEntry != null) {
                var slot:SlotData = skeletonData.findSlot(slotEntry.name);
                if (slot == null) throw new SerializationException("Slot not found: " + slotEntry.name);
                var entry:JsonValue = slotEntry.child; while (entry != null) {
                    try {
                        var attachment:Attachment = readAttachment(entry, skin, slot.index, entry.name, skeletonData);
                        if (attachment != null) skin.setAttachment(slot.index, entry.name, attachment);
                    } catch (ex:Dynamic) {
                        throw new SerializationException("Error reading attachment: " + entry.name + ", skin: " + skin, ex);
                    }
                entry = entry.next; }
            slotEntry = slotEntry.next; }
            skeletonData.skins.add(skin);
            if (skin.name.equals("default")) skeletonData.defaultSkin = skin;
        skinMap = skinMap.next; }

        // Linked meshes.
        var items = linkedMeshes.items;
        var i:Int = 0; var n:Int = linkedMeshes.size; while (i < n) {
            var linkedMesh:LinkedMesh = fastCast(items[i], LinkedMesh);
            var skin:Skin = linkedMesh.skin == null ? skeletonData.getDefaultSkin() : skeletonData.findSkin(linkedMesh.skin);
            if (skin == null) throw new SerializationException("Skin not found: " + linkedMesh.skin);
            var parent:Attachment = skin.getAttachment(linkedMesh.slotIndex, linkedMesh.parent);
            if (parent == null) throw new SerializationException("Parent mesh not found: " + linkedMesh.parent);
            linkedMesh.mesh.setDeformAttachment(linkedMesh.inheritDeform ? fastCast(parent , VertexAttachment): linkedMesh.mesh);
            linkedMesh.mesh.setParentMesh(fastCast(parent, MeshAttachment));
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

        var _continueAfterSwitch0 = false; while(true) { var _switchCond0 = (AttachmentType_enum.valueOf(map.getString("type", AttachmentType_enum.region_name))); {
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
            if (color != null) Color.valueOfIntoColor(color, region.getColor());

            region.updateOffset();
            return region;
        }
        else if (_switchCond0 == boundingbox) {
            var box:BoundingBoxAttachment = attachmentLoader.newBoundingBoxAttachment(skin, name);
            if (box == null) return null;
            readVertices(map, box, map.getInt("vertexCount") << 1);

            var color:String = map.getString("color", null);
            if (color != null) Color.valueOfIntoColor(color, box.getColor());
            return box;
        }
        else if (_switchCond0 == mesh) {
            {
            var path:String = map.getString("path", name);
            var mesh:MeshAttachment = attachmentLoader.newMeshAttachment(skin, name, path);
            if (mesh == null) return null;
            mesh.setPath(path);

            var color:String = map.getString("color", null);
            if (color != null) Color.valueOfIntoColor(color, mesh.getColor());

            mesh.setWidth(map.getFloat("width", 0) * scale);
            mesh.setHeight(map.getFloat("height", 0) * scale);

            var parent:String = map.getString("parent", null);
            if (parent != null) {
                linkedMeshes
                    .add(new LinkedMesh(mesh, map.getString("skin", null), slotIndex, parent, map.getBoolean("deform", true)));
                return mesh;
            }

            var uvs:FloatArray = map.require("uvs").asFloatArray();
            readVertices(map, mesh, uvs.length);
            mesh.setTriangles(map.require("triangles").asShortArray());
            mesh.setRegionUVs(uvs);
            mesh.updateUVs();

            if (map.has("hull")) mesh.setHullLength(map.require("hull").asInt() << 1);
            if (map.has("edges")) mesh.setEdges(map.require("edges").asShortArray());
            return mesh;
        }
        } else if (_switchCond0 == linkedmesh) {
            var path:String = map.getString("path", name);
            var mesh:MeshAttachment = attachmentLoader.newMeshAttachment(skin, name, path);
            if (mesh == null) return null;
            mesh.setPath(path);

            var color:String = map.getString("color", null);
            if (color != null) Color.valueOfIntoColor(color, mesh.getColor());

            mesh.setWidth(map.getFloat("width", 0) * scale);
            mesh.setHeight(map.getFloat("height", 0) * scale);

            var parent:String = map.getString("parent", null);
            if (parent != null) {
                linkedMeshes
                    .add(new LinkedMesh(mesh, map.getString("skin", null), slotIndex, parent, map.getBoolean("deform", true)));
                return mesh;
            }

            var uvs:FloatArray = map.require("uvs").asFloatArray();
            readVertices(map, mesh, uvs.length);
            mesh.setTriangles(map.require("triangles").asShortArray());
            mesh.setRegionUVs(uvs);
            mesh.updateUVs();

            if (map.has("hull")) mesh.setHullLength(map.require("hull").asInt() << 1);
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
            if (color != null) Color.valueOfIntoColor(color, path.getColor());
            return path;
        }
        else if (_switchCond0 == point) {
            var point:PointAttachment = attachmentLoader.newPointAttachment(skin, name);
            if (point == null) return null;
            point.setX(map.getFloat("x", 0) * scale);
            point.setY(map.getFloat("y", 0) * scale);
            point.setRotation(map.getFloat("rotation", 0));

            var color:String = map.getString("color", null);
            if (color != null) Color.valueOfIntoColor(color, point.getColor());
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
            if (color != null) Color.valueOfIntoColor(color, clip.getColor());
            return clip;
        } } break; }
        return null;
    }

    private function readVertices(map:JsonValue, attachment:VertexAttachment, verticesLength:Int):Void {
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
            var nn:Int = i + (boneCount << 2); while (i < nn) {
                bones.add(Std.int(vertices[i]));
                weights.add(vertices[i + 1] * scale);
                weights.add(vertices[i + 2] * scale);
                weights.add(vertices[i + 3]);
            i += 4; }
        }
        attachment.setBones(bones.toArray());
        attachment.setVertices(weights.toArray());
    }

    private function readAnimation(map:JsonValue, name:String, skeletonData:SkeletonData):Void {
        var scale:Float = this.scale;
        var timelines:Array<Timeline> = new Array();

        // Slot timelines.
        var slotMap:JsonValue = map.getChild("slots"); while (slotMap != null) {
            var slot:SlotData = skeletonData.findSlot(slotMap.name);
            if (slot == null) throw new SerializationException("Slot not found: " + slotMap.name);
            var timelineMap:JsonValue = slotMap.child; while (timelineMap != null) {
                var keyMap:JsonValue = timelineMap.child;
                if (keyMap == null) { timelineMap = timelineMap.next; continue; }

                var frames:Int = timelineMap.size;
                var timelineName:String = timelineMap.name;
                if (timelineName.equals("attachment")) {
                    var timeline:AttachmentTimeline = new AttachmentTimeline(frames, slot.index);
                    var frame:Int = 0; while (keyMap != null) {
                        timeline.setFrame(frame, keyMap.getFloat("time", 0), keyMap.getString("name")); keyMap = keyMap.next; frame++; }
                    timelines.add(timeline);

                } else if (timelineName.equals("rgba")) {
                    var timeline:RGBATimeline = new RGBATimeline(frames, frames << 2, slot.index);
                    var time:Float = keyMap.getFloat("time", 0);
                    var color:String = keyMap.getString("color");
                    var r:Float = StdEx.parseInt(color.substring(0, 2), 16) / 255;
                    var g:Float = StdEx.parseInt(color.substring(2, 4), 16) / 255;
                    var b:Float = StdEx.parseInt(color.substring(4, 6), 16) / 255;
                    var a:Float = StdEx.parseInt(color.substring(6, 8), 16) / 255;
                    var frame:Int = 0; var bezier:Int = 0; while (true) {
                        timeline.setFrame(frame, time, r, g, b, a);
                        var nextMap:JsonValue = keyMap.next;
                        if (nextMap == null) {
                            timeline.shrink(bezier);
                            break;
                        }
                        var time2:Float = nextMap.getFloat("time", 0);
                        color = nextMap.getString("color");
                        var nr:Float = StdEx.parseInt(color.substring(0, 2), 16) / 255;
                        var ng:Float = StdEx.parseInt(color.substring(2, 4), 16) / 255;
                        var nb:Float = StdEx.parseInt(color.substring(4, 6), 16) / 255;
                        var na:Float = StdEx.parseInt(color.substring(6, 8), 16) / 255;
                        var curve:JsonValue = keyMap.get("curve");
                        if (curve != null) {
                            bezier = readCurve(curve, timeline, bezier, frame, 0, time, time2, r, nr, 1);
                            bezier = readCurve(curve, timeline, bezier, frame, 1, time, time2, g, ng, 1);
                            bezier = readCurve(curve, timeline, bezier, frame, 2, time, time2, b, nb, 1);
                            bezier = readCurve(curve, timeline, bezier, frame, 3, time, time2, a, na, 1);
                        }
                        time = time2;
                        r = nr;
                        g = ng;
                        b = nb;
                        a = na;
                        keyMap = nextMap;
                    frame++; }
                    timelines.add(timeline);

                } else if (timelineName.equals("rgb")) {
                    var timeline:RGBTimeline = new RGBTimeline(frames, frames * 3, slot.index);
                    var time:Float = keyMap.getFloat("time", 0);
                    var color:String = keyMap.getString("color");
                    var r:Float = StdEx.parseInt(color.substring(0, 2), 16) / 255;
                    var g:Float = StdEx.parseInt(color.substring(2, 4), 16) / 255;
                    var b:Float = StdEx.parseInt(color.substring(4, 6), 16) / 255;
                    var frame:Int = 0; var bezier:Int = 0; while (true) {
                        timeline.setFrame(frame, time, r, g, b);
                        var nextMap:JsonValue = keyMap.next;
                        if (nextMap == null) {
                            timeline.shrink(bezier);
                            break;
                        }
                        var time2:Float = nextMap.getFloat("time", 0);
                        color = nextMap.getString("color");
                        var nr:Float = StdEx.parseInt(color.substring(0, 2), 16) / 255;
                        var ng:Float = StdEx.parseInt(color.substring(2, 4), 16) / 255;
                        var nb:Float = StdEx.parseInt(color.substring(4, 6), 16) / 255;
                        var curve:JsonValue = keyMap.get("curve");
                        if (curve != null) {
                            bezier = readCurve(curve, timeline, bezier, frame, 0, time, time2, r, nr, 1);
                            bezier = readCurve(curve, timeline, bezier, frame, 1, time, time2, g, ng, 1);
                            bezier = readCurve(curve, timeline, bezier, frame, 2, time, time2, b, nb, 1);
                        }
                        time = time2;
                        r = nr;
                        g = ng;
                        b = nb;
                        keyMap = nextMap;
                    frame++; }
                    timelines.add(timeline);

                } else if (timelineName.equals("alpha")) {
                    timelines.add(readTimeline(keyMap, new AlphaTimeline(frames, frames, slot.index), 0, 1));

                } else if (timelineName.equals("rgba2")) {
                    var timeline:RGBA2Timeline = new RGBA2Timeline(frames, frames * 7, slot.index);
                    var time:Float = keyMap.getFloat("time", 0);
                    var color:String = keyMap.getString("light");
                    var r:Float = StdEx.parseInt(color.substring(0, 2), 16) / 255;
                    var g:Float = StdEx.parseInt(color.substring(2, 4), 16) / 255;
                    var b:Float = StdEx.parseInt(color.substring(4, 6), 16) / 255;
                    var a:Float = StdEx.parseInt(color.substring(6, 8), 16) / 255;
                    color = keyMap.getString("dark");
                    var r2:Float = StdEx.parseInt(color.substring(0, 2), 16) / 255;
                    var g2:Float = StdEx.parseInt(color.substring(2, 4), 16) / 255;
                    var b2:Float = StdEx.parseInt(color.substring(4, 6), 16) / 255;
                    var frame:Int = 0; var bezier:Int = 0; while (true) {
                        timeline.setFrame(frame, time, r, g, b, a, r2, g2, b2);
                        var nextMap:JsonValue = keyMap.next;
                        if (nextMap == null) {
                            timeline.shrink(bezier);
                            break;
                        }
                        var time2:Float = nextMap.getFloat("time", 0);
                        color = nextMap.getString("light");
                        var nr:Float = StdEx.parseInt(color.substring(0, 2), 16) / 255;
                        var ng:Float = StdEx.parseInt(color.substring(2, 4), 16) / 255;
                        var nb:Float = StdEx.parseInt(color.substring(4, 6), 16) / 255;
                        var na:Float = StdEx.parseInt(color.substring(6, 8), 16) / 255;
                        color = nextMap.getString("dark");
                        var nr2:Float = StdEx.parseInt(color.substring(0, 2), 16) / 255;
                        var ng2:Float = StdEx.parseInt(color.substring(2, 4), 16) / 255;
                        var nb2:Float = StdEx.parseInt(color.substring(4, 6), 16) / 255;
                        var curve:JsonValue = keyMap.get("curve");
                        if (curve != null) {
                            bezier = readCurve(curve, timeline, bezier, frame, 0, time, time2, r, nr, 1);
                            bezier = readCurve(curve, timeline, bezier, frame, 1, time, time2, g, ng, 1);
                            bezier = readCurve(curve, timeline, bezier, frame, 2, time, time2, b, nb, 1);
                            bezier = readCurve(curve, timeline, bezier, frame, 3, time, time2, a, na, 1);
                            bezier = readCurve(curve, timeline, bezier, frame, 4, time, time2, r2, nr2, 1);
                            bezier = readCurve(curve, timeline, bezier, frame, 5, time, time2, g2, ng2, 1);
                            bezier = readCurve(curve, timeline, bezier, frame, 6, time, time2, b2, nb2, 1);
                        }
                        time = time2;
                        r = nr;
                        g = ng;
                        b = nb;
                        a = na;
                        r2 = nr2;
                        g2 = ng2;
                        b2 = nb2;
                        keyMap = nextMap;
                    frame++; }
                    timelines.add(timeline);

                } else if (timelineName.equals("rgb2")) {
                    var timeline:RGB2Timeline = new RGB2Timeline(frames, frames * 6, slot.index);
                    var time:Float = keyMap.getFloat("time", 0);
                    var color:String = keyMap.getString("light");
                    var r:Float = StdEx.parseInt(color.substring(0, 2), 16) / 255;
                    var g:Float = StdEx.parseInt(color.substring(2, 4), 16) / 255;
                    var b:Float = StdEx.parseInt(color.substring(4, 6), 16) / 255;
                    color = keyMap.getString("dark");
                    var r2:Float = StdEx.parseInt(color.substring(0, 2), 16) / 255;
                    var g2:Float = StdEx.parseInt(color.substring(2, 4), 16) / 255;
                    var b2:Float = StdEx.parseInt(color.substring(4, 6), 16) / 255;
                    var frame:Int = 0; var bezier:Int = 0; while (true) {
                        timeline.setFrame(frame, time, r, g, b, r2, g2, b2);
                        var nextMap:JsonValue = keyMap.next;
                        if (nextMap == null) {
                            timeline.shrink(bezier);
                            break;
                        }
                        var time2:Float = nextMap.getFloat("time", 0);
                        color = nextMap.getString("light");
                        var nr:Float = StdEx.parseInt(color.substring(0, 2), 16) / 255;
                        var ng:Float = StdEx.parseInt(color.substring(2, 4), 16) / 255;
                        var nb:Float = StdEx.parseInt(color.substring(4, 6), 16) / 255;
                        color = nextMap.getString("dark");
                        var nr2:Float = StdEx.parseInt(color.substring(0, 2), 16) / 255;
                        var ng2:Float = StdEx.parseInt(color.substring(2, 4), 16) / 255;
                        var nb2:Float = StdEx.parseInt(color.substring(4, 6), 16) / 255;
                        var curve:JsonValue = keyMap.get("curve");
                        if (curve != null) {
                            bezier = readCurve(curve, timeline, bezier, frame, 0, time, time2, r, nr, 1);
                            bezier = readCurve(curve, timeline, bezier, frame, 1, time, time2, g, ng, 1);
                            bezier = readCurve(curve, timeline, bezier, frame, 2, time, time2, b, nb, 1);
                            bezier = readCurve(curve, timeline, bezier, frame, 3, time, time2, r2, nr2, 1);
                            bezier = readCurve(curve, timeline, bezier, frame, 4, time, time2, g2, ng2, 1);
                            bezier = readCurve(curve, timeline, bezier, frame, 5, time, time2, b2, nb2, 1);
                        }
                        time = time2;
                        r = nr;
                        g = ng;
                        b = nb;
                        r2 = nr2;
                        g2 = ng2;
                        b2 = nb2;
                        keyMap = nextMap;
                    frame++; }
                    timelines.add(timeline);

                } else
                    throw new RuntimeException("Invalid timeline type for a slot: " + timelineName + " (" + slotMap.name + ")");
            timelineMap = timelineMap.next; }
        slotMap = slotMap.next; }

        // Bone timelines.
        var boneMap:JsonValue = map.getChild("bones"); while (boneMap != null) {
            var bone:BoneData = skeletonData.findBone(boneMap.name);
            if (bone == null) throw new SerializationException("Bone not found: " + boneMap.name);
            var timelineMap:JsonValue = boneMap.child; while (timelineMap != null) {
                var keyMap:JsonValue = timelineMap.child;
                if (keyMap == null) { timelineMap = timelineMap.next; continue; }

                var frames:Int = timelineMap.size;
                var timelineName:String = timelineMap.name;
                if (timelineName.equals("rotate"))
                    timelines.add(readTimeline(keyMap, new RotateTimeline(frames, frames, bone.index), 0, 1));
                else if (timelineName.equals("translate")) {
                    var timeline:TranslateTimeline = new TranslateTimeline(frames, frames << 1, bone.index);
                    timelines.add(readTimeline2(keyMap, timeline, "x", "y", 0, scale));
                } else if (timelineName.equals("translatex")) {
                    timelines.add(readTimeline(keyMap, new TranslateXTimeline(frames, frames, bone.index), 0, scale));
                } else if (timelineName.equals("translatey")) {
                    timelines.add(readTimeline(keyMap, new TranslateYTimeline(frames, frames, bone.index), 0, scale));
                } else if (timelineName.equals("scale")) {
                    var timeline:ScaleTimeline = new ScaleTimeline(frames, frames << 1, bone.index);
                    timelines.add(readTimeline2(keyMap, timeline, "x", "y", 1, 1));
                } else if (timelineName.equals("scalex"))
                    timelines.add(readTimeline(keyMap, new ScaleXTimeline(frames, frames, bone.index), 1, 1));
                else if (timelineName.equals("scaley"))
                    timelines.add(readTimeline(keyMap, new ScaleYTimeline(frames, frames, bone.index), 1, 1));
                else if (timelineName.equals("shear")) {
                    var timeline:ShearTimeline = new ShearTimeline(frames, frames << 1, bone.index);
                    timelines.add(readTimeline2(keyMap, timeline, "x", "y", 0, 1));
                } else if (timelineName.equals("shearx"))
                    timelines.add(readTimeline(keyMap, new ShearXTimeline(frames, frames, bone.index), 0, 1));
                else if (timelineName.equals("sheary"))
                    timelines.add(readTimeline(keyMap, new ShearYTimeline(frames, frames, bone.index), 0, 1));
                else
                    throw new RuntimeException("Invalid timeline type for a bone: " + timelineName + " (" + boneMap.name + ")");
            timelineMap = timelineMap.next; }
        boneMap = boneMap.next; }

        // IK constraint timelines.
        var timelineMap:JsonValue = map.getChild("ik"); while (timelineMap != null) {
            var keyMap:JsonValue = timelineMap.child;
            if (keyMap == null) { timelineMap = timelineMap.next; continue; }
            var constraint:IkConstraintData = skeletonData.findIkConstraint(timelineMap.name);
            var timeline:IkConstraintTimeline = new IkConstraintTimeline(timelineMap.size, timelineMap.size << 1,
                skeletonData.getIkConstraints().indexOf(constraint, true));
            var time:Float = keyMap.getFloat("time", 0);
            var mix:Float = keyMap.getFloat("mix", 1); var softness:Float = keyMap.getFloat("softness", 0) * scale;
            var frame:Int = 0; var bezier:Int = 0; while (true) {
                timeline.setFrame(frame, time, mix, softness, keyMap.getBoolean("bendPositive", true) ? 1 : -1,
                    keyMap.getBoolean("compress", false), keyMap.getBoolean("stretch", false));
                var nextMap:JsonValue = keyMap.next;
                if (nextMap == null) {
                    timeline.shrink(bezier);
                    break;
                }
                var time2:Float = nextMap.getFloat("time", 0);
                var mix2:Float = nextMap.getFloat("mix", 1); var softness2:Float = nextMap.getFloat("softness", 0) * scale;
                var curve:JsonValue = keyMap.get("curve");
                if (curve != null) {
                    bezier = readCurve(curve, timeline, bezier, frame, 0, time, time2, mix, mix2, 1);
                    bezier = readCurve(curve, timeline, bezier, frame, 1, time, time2, softness, softness2, scale);
                }
                time = time2;
                mix = mix2;
                softness = softness2;
                keyMap = nextMap;
            frame++; }
            timelines.add(timeline);
        timelineMap = timelineMap.next; }

        // Transform constraint timelines.
        var timelineMap:JsonValue = map.getChild("transform"); while (timelineMap != null) {
            var keyMap:JsonValue = timelineMap.child;
            if (keyMap == null) { timelineMap = timelineMap.next; continue; }
            var constraint:TransformConstraintData = skeletonData.findTransformConstraint(timelineMap.name);
            var timeline:TransformConstraintTimeline = new TransformConstraintTimeline(timelineMap.size, timelineMap.size * 6,
                skeletonData.getTransformConstraints().indexOf(constraint, true));
            var time:Float = keyMap.getFloat("time", 0);
            var mixRotate:Float = keyMap.getFloat("mixRotate", 1);
            var mixX:Float = keyMap.getFloat("mixX", 1); var mixY:Float = keyMap.getFloat("mixY", mixX);
            var mixScaleX:Float = keyMap.getFloat("mixScaleX", 1); var mixScaleY:Float = keyMap.getFloat("mixScaleY", mixScaleX);
            var mixShearY:Float = keyMap.getFloat("mixShearY", 1);
            var frame:Int = 0; var bezier:Int = 0; while (true) {
                timeline.setFrame(frame, time, mixRotate, mixX, mixY, mixScaleX, mixScaleY, mixShearY);
                var nextMap:JsonValue = keyMap.next;
                if (nextMap == null) {
                    timeline.shrink(bezier);
                    break;
                }
                var time2:Float = nextMap.getFloat("time", 0);
                var mixRotate2:Float = nextMap.getFloat("mixRotate", 1);
                var mixX2:Float = nextMap.getFloat("mixX", 1); var mixY2:Float = nextMap.getFloat("mixY", mixX2);
                var mixScaleX2:Float = nextMap.getFloat("mixScaleX", 1); var mixScaleY2:Float = nextMap.getFloat("mixScaleY", mixScaleX2);
                var mixShearY2:Float = nextMap.getFloat("mixShearY", 1);
                var curve:JsonValue = keyMap.get("curve");
                if (curve != null) {
                    bezier = readCurve(curve, timeline, bezier, frame, 0, time, time2, mixRotate, mixRotate2, 1);
                    bezier = readCurve(curve, timeline, bezier, frame, 1, time, time2, mixX, mixX2, 1);
                    bezier = readCurve(curve, timeline, bezier, frame, 2, time, time2, mixY, mixY2, 1);
                    bezier = readCurve(curve, timeline, bezier, frame, 3, time, time2, mixScaleX, mixScaleX2, 1);
                    bezier = readCurve(curve, timeline, bezier, frame, 4, time, time2, mixScaleY, mixScaleY2, 1);
                    bezier = readCurve(curve, timeline, bezier, frame, 5, time, time2, mixShearY, mixShearY2, 1);
                }
                time = time2;
                mixRotate = mixRotate2;
                mixX = mixX2;
                mixY = mixY2;
                mixScaleX = mixScaleX2;
                mixScaleY = mixScaleY2;
                mixScaleX = mixScaleX2;
                keyMap = nextMap;
            frame++; }
            timelines.add(timeline);
        timelineMap = timelineMap.next; }

        // Path constraint timelines.
        var constraintMap:JsonValue = map.getChild("path"); while (constraintMap != null) {
            var constraint:PathConstraintData = skeletonData.findPathConstraint(constraintMap.name);
            if (constraint == null) throw new SerializationException("Path constraint not found: " + constraintMap.name);
            var index:Int = skeletonData.pathConstraints.indexOf(constraint, true);
            var timelineMap:JsonValue = constraintMap.child; while (timelineMap != null) {
                var keyMap:JsonValue = timelineMap.child;
                if (keyMap == null) { timelineMap = timelineMap.next; continue; }

                var frames:Int = timelineMap.size;
                var timelineName:String = timelineMap.name;
                if (timelineName.equals("position")) {
                    var timeline:CurveTimeline1 = new PathConstraintPositionTimeline(frames, frames, index);
                    timelines.add(readTimeline(keyMap, timeline, 0, constraint.positionMode == PositionMode.fixed ? scale : 1));
                } else if (timelineName.equals("spacing")) {
                    var timeline:CurveTimeline1 = new PathConstraintSpacingTimeline(frames, frames, index);
                    timelines.add(readTimeline(keyMap, timeline, 0,
                        constraint.spacingMode == SpacingMode.length || constraint.spacingMode == SpacingMode.fixed ? scale : 1));
                } else if (timelineName.equals("mix")) {
                    var timeline:PathConstraintMixTimeline = new PathConstraintMixTimeline(frames, frames * 3, index);
                    var time:Float = keyMap.getFloat("time", 0);
                    var mixRotate:Float = keyMap.getFloat("mixRotate", 1);
                    var mixX:Float = keyMap.getFloat("mixX", 1); var mixY:Float = keyMap.getFloat("mixY", mixX);
                    var frame:Int = 0; var bezier:Int = 0; while (true) {
                        timeline.setFrame(frame, time, mixRotate, mixX, mixY);
                        var nextMap:JsonValue = keyMap.next;
                        if (nextMap == null) {
                            timeline.shrink(bezier);
                            break;
                        }
                        var time2:Float = nextMap.getFloat("time", 0);
                        var mixRotate2:Float = nextMap.getFloat("mixRotate", 1);
                        var mixX2:Float = nextMap.getFloat("mixX", 1); var mixY2:Float = nextMap.getFloat("mixY", mixX2);
                        var curve:JsonValue = keyMap.get("curve");
                        if (curve != null) {
                            bezier = readCurve(curve, timeline, bezier, frame, 0, time, time2, mixRotate, mixRotate2, 1);
                            bezier = readCurve(curve, timeline, bezier, frame, 1, time, time2, mixX, mixX2, 1);
                            bezier = readCurve(curve, timeline, bezier, frame, 2, time, time2, mixY, mixY2, 1);
                        }
                        time = time2;
                        mixRotate = mixRotate2;
                        mixX = mixX2;
                        mixY = mixY2;
                        keyMap = nextMap;
                    frame++; }
                    timelines.add(timeline);
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
                    var keyMap:JsonValue = timelineMap.child;
                    if (keyMap == null) { timelineMap = timelineMap.next; continue; }

                    var attachment:VertexAttachment = fastCast(skin.getAttachment(slot.index, timelineMap.name), VertexAttachment);
                    if (attachment == null) throw new SerializationException("Deform attachment not found: " + timelineMap.name);
                    var weighted:Bool = attachment.getBones() != null;
                    var vertices:FloatArray = attachment.getVertices();
                    var deformLength:Int = weighted ? Std.int((vertices.length / 3)) << 1 : vertices.length;

                    var timeline:DeformTimeline = new DeformTimeline(timelineMap.size, timelineMap.size, slot.index, attachment);
                    var time:Float = keyMap.getFloat("time", 0);
                    var frame:Int = 0; var bezier:Int = 0; while (true) {
                        var deform:FloatArray = null;
                        var verticesValue:JsonValue = keyMap.get("vertices");
                        if (verticesValue == null)
                            deform = weighted ?  FloatArray.create(deformLength): vertices;
                        else {
                            deform = FloatArray.create(deformLength);
                            var start:Int = keyMap.getInt("offset", 0);
                            arraycopy(verticesValue.asFloatArray(), 0, deform, start, verticesValue.size);
                            if (scale != 1) {
                                var i:Int = start; var n:Int = i + verticesValue.size; while (i < n) {
                                    deform[i] *= scale; i++; }
                            }
                            if (!weighted) {
                                var i:Int = 0; while (i < deformLength) {
                                    deform[i] += vertices[i]; i++; }
                            }
                        }

                        timeline.setFrame(frame, time, deform);
                        var nextMap:JsonValue = keyMap.next;
                        if (nextMap == null) {
                            timeline.shrink(bezier);
                            break;
                        }
                        var time2:Float = nextMap.getFloat("time", 0);
                        var curve:JsonValue = keyMap.get("curve");
                        if (curve != null) bezier = readCurve(curve, timeline, bezier, frame, 0, time, time2, 0, 1, 1);
                        time = time2;
                        keyMap = nextMap;
                    frame++; }
                    timelines.add(timeline);
                timelineMap = timelineMap.next; }
            slotMap = slotMap.next; }
        deformMap = deformMap.next; }

        // Draw order timeline.
        var drawOrdersMap:JsonValue = map.get("drawOrder");
        if (drawOrdersMap != null) {
            var timeline:DrawOrderTimeline = new DrawOrderTimeline(drawOrdersMap.size);
            var slotCount:Int = skeletonData.slots.size;
            var frame:Int = 0;
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
                timeline.setFrame(frame, drawOrderMap.getFloat("time", 0), drawOrder);
            drawOrderMap = drawOrderMap.next; frame++; }
            timelines.add(timeline);
        }

        // Event timeline.
        var eventsMap:JsonValue = map.get("events");
        if (eventsMap != null) {
            var timeline:EventTimeline = new EventTimeline(eventsMap.size);
            var frame:Int = 0;
            var eventMap:JsonValue = eventsMap.child; while (eventMap != null) {
                var eventData:EventData = skeletonData.findEvent(eventMap.getString("name"));
                if (eventData == null) throw new SerializationException("Event not found: " + eventMap.getString("name"));
                var event:Event = new Event(eventMap.getFloat("time", 0), eventData);
                event.intValue = eventMap.getInt("int", eventData.intValue);
                event.floatValue = eventMap.getFloat("float", eventData.floatValue);
                event.stringValue = eventMap.getString("string", eventData.stringValue);
                if (event.getData().audioPath != null) {
                    event.volume = eventMap.getFloat("volume", eventData.volume);
                    event.balance = eventMap.getFloat("balance", eventData.balance);
                }
                timeline.setFrame(frame, event);
            eventMap = eventMap.next; frame++; }
            timelines.add(timeline);
        }

        timelines.shrink();
        var duration:Float = 0;
        var items = timelines.items;
        var i:Int = 0; var n:Int = timelines.size; while (i < n) {
            duration = MathUtils.max(duration, (fastCast(items[i], Timeline)).getDuration()); i++; }
        skeletonData.animations.add(new Animation(name, timelines, duration));
    }

    private function readTimeline(keyMap:JsonValue, timeline:CurveTimeline1, defaultValue:Float, scale:Float):Timeline {
        var time:Float = keyMap.getFloat("time", 0); var value:Float = keyMap.getFloat("value", defaultValue) * scale;
        var frame:Int = 0; var bezier:Int = 0; while (true) {
            timeline.setFrame(frame, time, value);
            var nextMap:JsonValue = keyMap.next;
            if (nextMap == null) {
                timeline.shrink(bezier);
                return timeline;
            }
            var time2:Float = nextMap.getFloat("time", 0);
            var value2:Float = nextMap.getFloat("value", defaultValue) * scale;
            var curve:JsonValue = keyMap.get("curve");
            if (curve != null) bezier = readCurve(curve, timeline, bezier, frame, 0, time, time2, value, value2, scale);
            time = time2;
            value = value2;
            keyMap = nextMap;
        frame++; }
    }

    private function readTimeline2(keyMap:JsonValue, timeline:CurveTimeline2, name1:String, name2:String, defaultValue:Float, scale:Float):Timeline {
        var time:Float = keyMap.getFloat("time", 0);
        var value1:Float = keyMap.getFloat(name1, defaultValue) * scale; var value2:Float = keyMap.getFloat(name2, defaultValue) * scale;
        var frame:Int = 0; var bezier:Int = 0; while (true) {
            timeline.setFrame(frame, time, value1, value2);
            var nextMap:JsonValue = keyMap.next;
            if (nextMap == null) {
                timeline.shrink(bezier);
                return timeline;
            }
            var time2:Float = nextMap.getFloat("time", 0);
            var nvalue1:Float = nextMap.getFloat(name1, defaultValue) * scale; var nvalue2:Float = nextMap.getFloat(name2, defaultValue) * scale;
            var curve:JsonValue = keyMap.get("curve");
            if (curve != null) {
                bezier = readCurve(curve, timeline, bezier, frame, 0, time, time2, value1, nvalue1, scale);
                bezier = readCurve(curve, timeline, bezier, frame, 1, time, time2, value2, nvalue2, scale);
            }
            time = time2;
            value1 = nvalue1;
            value2 = nvalue2;
            keyMap = nextMap;
        frame++; }
    }

    #if !spine_no_inline inline #end public function readCurve(curve:JsonValue, timeline:CurveTimeline, bezier:Int, frame:Int, value:Int, time1:Float, time2:Float, value1:Float, value2:Float, scale:Float):Int {
        if (curve.isString()) {
            if (curve.asString().equals("stepped")) timeline.setStepped(frame);
            return bezier;
        }
        curve = curve.getAtIndex(value << 2);
        var cx1:Float = curve.asFloat();
        curve = curve.next;
        var cy1:Float = curve.asFloat() * scale;
        curve = curve.next;
        var cx2:Float = curve.asFloat();
        curve = curve.next;
        var cy2:Float = curve.asFloat() * scale;
        setBezier(timeline, frame, value, bezier, time1, value1, cx1, cy1, cx2, cy2, time2, value2);
        return bezier + 1;
    }

    #if !spine_no_inline inline #end static public function setBezier(timeline:CurveTimeline, frame:Int, value:Int, bezier:Int, time1:Float, value1:Float, cx1:Float, cy1:Float, cx2:Float, cy2:Float, time2:Float, value2:Float):Void {
        timeline.setBezier(bezier, frame, value, time1, value1, cx1, cy1, cx2, cy2, time2, value2);
    }
}

class LinkedMesh {
    public var parent:String; public var skin:String = null;
    public var slotIndex:Int = 0;
    public var mesh:MeshAttachment;
    public var inheritDeform:Bool = false;

    public function new(mesh:MeshAttachment, skin:String, slotIndex:Int, parent:String, inheritDeform:Bool) {
        this.mesh = mesh;
        this.skin = skin;
        this.slotIndex = slotIndex;
        this.parent = parent;
        this.inheritDeform = inheritDeform;
    }
}