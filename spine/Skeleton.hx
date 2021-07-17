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

import spine.support.graphics.Color;
import spine.support.math.Vector2;
import spine.support.utils.Array;
import spine.support.utils.FloatArray;


import spine.Skin.SkinEntry;
import spine.attachments.Attachment;
import spine.attachments.MeshAttachment;
import spine.attachments.PathAttachment;
import spine.attachments.RegionAttachment;

/** Stores the current pose for a skeleton.
 * <p>
 * See <a href="http://esotericsoftware.com/spine-runtime-architecture#Instance-objects">Instance objects</a> in the Spine
 * Runtimes Guide. */
class Skeleton {
    public var data:SkeletonData;
    public var bones:Array<Bone>;
    public var slots:Array<Slot>;
    public var drawOrder:Array<Slot>;
    public var ikConstraints:Array<IkConstraint>;
    public var transformConstraints:Array<TransformConstraint>;
    public var pathConstraints:Array<PathConstraint>;
    public var cache:Array<Updatable> = new Array();
    public var skin:Skin;
    public var color:Color;
    public var time:Float = 0;
    public var scaleX:Float = 1; public var scaleY:Float = 1;
    public var x:Float = 0; public var y:Float = 0;

    public function new(data:SkeletonData) {
        if (data == null) throw new IllegalArgumentException("data cannot be null.");
        this.data = data;

        bones = new Array(data.bones.size);
        var bones = this.bones.items;
        for (boneData in data.bones) {
            var bone:Bone = null;
            if (boneData.parent == null)
                bone = new Bone(boneData, this, null);
            else {
                var parent:Bone = fastCast(bones[boneData.parent.index], Bone);
                bone = new Bone(boneData, this, parent);
                parent.children.add(bone);
            }
            this.bones.add(bone);
        }

        slots = new Array(data.slots.size);
        drawOrder = new Array(data.slots.size);
        for (slotData in data.slots) {
            var bone:Bone = fastCast(bones[slotData.boneData.index], Bone);
            var slot:Slot = new Slot(slotData, bone);
            slots.add(slot);
            drawOrder.add(slot);
        }

        ikConstraints = new Array(data.ikConstraints.size);
        for (ikConstraintData in data.ikConstraints) {
            ikConstraints.add(new IkConstraint(ikConstraintData, this)); }

        transformConstraints = new Array(data.transformConstraints.size);
        for (transformConstraintData in data.transformConstraints) {
            transformConstraints.add(new TransformConstraint(transformConstraintData, this)); }

        pathConstraints = new Array(data.pathConstraints.size);
        for (pathConstraintData in data.pathConstraints) {
            pathConstraints.add(new PathConstraint(pathConstraintData, this)); }

        color = new Color(1, 1, 1, 1);

        updateCache();
    }

    /** Copy constructor. */
    /*public function new(skeleton:Skeleton) {
        if (skeleton == null) throw new IllegalArgumentException("skeleton cannot be null.");
        data = skeleton.data;

        bones = new Array(skeleton.bones.size);
        for (bone in skeleton.bones) {
            var newBone:Bone = null;
            if (bone.parent == null)
                newBone = new Bone(bone, this, null);
            else {
                var parent:Bone = bones.get(bone.parent.data.index);
                newBone = new Bone(bone, this, parent);
                parent.children.add(newBone);
            }
            bones.add(newBone);
        }

        slots = new Array(skeleton.slots.size);
        for (slot in skeleton.slots) {
            var bone:Bone = bones.get(slot.bone.data.index);
            slots.add(new Slot(slot, bone));
        }

        drawOrder = new Array(slots.size);
        for (slot in skeleton.drawOrder) {
            drawOrder.add(slots.get(slot.data.index)); }

        ikConstraints = new Array(skeleton.ikConstraints.size);
        for (ikConstraint in skeleton.ikConstraints) {
            ikConstraints.add(new IkConstraint(ikConstraint, this)); }

        transformConstraints = new Array(skeleton.transformConstraints.size);
        for (transformConstraint in skeleton.transformConstraints) {
            transformConstraints.add(new TransformConstraint(transformConstraint, this)); }

        pathConstraints = new Array(skeleton.pathConstraints.size);
        for (pathConstraint in skeleton.pathConstraints) {
            pathConstraints.add(new PathConstraint(pathConstraint, this)); }

        skin = skeleton.skin;
        color = new Color(skeleton.color);
        time = skeleton.time;
        scaleX = skeleton.scaleX;
        scaleY = skeleton.scaleY;

        updateCache();
    }*/

    /** Caches information about bones and constraints. Must be called if the {@link #getSkin()} is modified or if bones,
     * constraints, or weighted path attachments are added or removed. */
    #if !spine_no_inline inline #end public function updateCache():Void {
        var cache:Array<Updatable> = this.cache;
        cache.clear();

        var boneCount:Int = bones.size;
        var bones = this.bones.items;
        var i:Int = 0; while (i < boneCount) {
            var bone:Bone = fastCast(bones[i], Bone);
            bone.sorted = bone.data.skinRequired;
            bone.active = !bone.sorted;
        i++; }
        if (skin != null) {
            var skinBones = skin.bones.items;
            var i:Int = 0; var n:Int = skin.bones.size; while (i < n) {
                var bone:Bone = fastCast(bones[(fastCast(skinBones[i], BoneData)).index], Bone);
                do {
                    bone.sorted = false;
                    bone.active = true;
                    bone = bone.parent;
                } while (bone != null);
            i++; }
        }

        var ikCount:Int = ikConstraints.size; var transformCount:Int = transformConstraints.size; var pathCount:Int = pathConstraints.size;
        var ikConstraints = this.ikConstraints.items;
        var transformConstraints = this.transformConstraints.items;
        var pathConstraints = this.pathConstraints.items;
        var constraintCount:Int = ikCount + transformCount + pathCount;
        var _gotoLabel_outer:Int; while (true) { _gotoLabel_outer = 0; 
        var i:Int = 0; while (i < constraintCount) {
            var ii:Int = 0; while (ii < ikCount) {
                var constraint:IkConstraint = fastCast(ikConstraints[ii], IkConstraint);
                if (constraint.data.order == i) {
                    sortIkConstraint(constraint);
                    { ii++; _gotoLabel_outer = 2; break; }
                }
            ii++; } if (_gotoLabel_outer == 2) { _gotoLabel_outer = 0; { i++; continue; } } if (_gotoLabel_outer >= 1) break;
            var ii:Int = 0; while (ii < transformCount) {
                var constraint:TransformConstraint = fastCast(transformConstraints[ii], TransformConstraint);
                if (constraint.data.order == i) {
                    sortTransformConstraint(constraint);
                    { ii++; _gotoLabel_outer = 2; break; }
                }
            ii++; } if (_gotoLabel_outer == 2) { _gotoLabel_outer = 0; { i++; continue; } } if (_gotoLabel_outer >= 1) break;
            var ii:Int = 0; while (ii < pathCount) {
                var constraint:PathConstraint = fastCast(pathConstraints[ii], PathConstraint);
                if (constraint.data.order == i) {
                    sortPathConstraint(constraint);
                    { ii++; _gotoLabel_outer = 2; break; }
                }
            ii++; } if (_gotoLabel_outer == 2) { _gotoLabel_outer = 0; { i++; continue; } } if (_gotoLabel_outer >= 1) break;
        i++; } if (_gotoLabel_outer == 0) break; }

        var i:Int = 0; while (i < boneCount) {
            sortBone(fastCast(bones[i], Bone)); i++; }
    }

    #if !spine_no_inline inline #end private function sortIkConstraint(constraint:IkConstraint):Void {
        constraint.active = constraint.target.active
            && (!constraint.data.skinRequired || (skin != null && skin.constraints.contains(constraint.data, true)));
        if (!constraint.active) return;

        var target:Bone = constraint.target;
        sortBone(target);

        var constrained:Array<Bone> = constraint.bones;
        var parent:Bone = constrained.first();
        sortBone(parent);
        if (constrained.size == 1) {
            cache.add(constraint);
            sortReset(parent.children);
        } else {
            var child:Bone = constrained.peek();
            sortBone(child);

            cache.add(constraint);

            sortReset(parent.children);
            child.sorted = true;
        }
    }

    #if !spine_no_inline inline #end private function sortPathConstraint(constraint:PathConstraint):Void {
        constraint.active = constraint.target.bone.active
            && (!constraint.data.skinRequired || (skin != null && skin.constraints.contains(constraint.data, true)));
        if (!constraint.active) return;

        var slot:Slot = constraint.target;
        var slotIndex:Int = slot.getData().index;
        var slotBone:Bone = slot.bone;
        if (skin != null) sortPathConstraintAttachmentWithSkin(skin, slotIndex, slotBone);
        if (data.defaultSkin != null && data.defaultSkin != skin)
            sortPathConstraintAttachmentWithSkin(data.defaultSkin, slotIndex, slotBone);

        var attachment:Attachment = slot.attachment;
        if (#if (haxe_ver >= 4.0) Std.isOfType #else Std.is #end(attachment, PathAttachment)) sortPathConstraintAttachment(attachment, slotBone);

        var constrained = constraint.bones.items;
        var boneCount:Int = constraint.bones.size;
        var i:Int = 0; while (i < boneCount) {
            sortBone(fastCast(constrained[i], Bone)); i++; }

        cache.add(constraint);

        var i:Int = 0; while (i < boneCount) {
            sortReset((fastCast(constrained[i], Bone)).children); i++; }
        var i:Int = 0; while (i < boneCount) {
            (fastCast(constrained[i], Bone)).sorted = true; i++; }
    }

    #if !spine_no_inline inline #end private function sortTransformConstraint(constraint:TransformConstraint):Void {
        constraint.active = constraint.target.active
            && (!constraint.data.skinRequired || (skin != null && skin.constraints.contains(constraint.data, true)));
        if (!constraint.active) return;

        sortBone(constraint.target);

        var constrained = constraint.bones.items;
        var boneCount:Int = constraint.bones.size;
        if (constraint.data.local) {
            var i:Int = 0; while (i < boneCount) {
                var child:Bone = fastCast(constrained[i], Bone);
                sortBone(child.parent);
                sortBone(child);
            i++; }
        } else {
            var i:Int = 0; while (i < boneCount) {
                sortBone(fastCast(constrained[i], Bone)); i++; }
        }

        cache.add(constraint);

        var i:Int = 0; while (i < boneCount) {
            sortReset((fastCast(constrained[i], Bone)).children); i++; }
        var i:Int = 0; while (i < boneCount) {
            (fastCast(constrained[i], Bone)).sorted = true; i++; }
    }

    #if !spine_no_inline inline #end private function sortPathConstraintAttachmentWithSkin(skin:Skin, slotIndex:Int, slotBone:Bone):Void {
        var entries = skin.attachments.orderedItems().items;
        var i:Int = 0; var n:Int = skin.attachments.size; while (i < n) {
            var entry:SkinEntry = fastCast(entries[i], SkinEntry);
            if (entry.slotIndex == slotIndex) sortPathConstraintAttachment(entry.attachment, slotBone);
        i++; }
    }

    #if !spine_no_inline inline #end private function sortPathConstraintAttachment(attachment:Attachment, slotBone:Bone):Void {
        if (!(#if (haxe_ver >= 4.0) Std.isOfType #else Std.is #end(attachment, PathAttachment))) return;
        var pathBones:IntArray = (fastCast(attachment, PathAttachment)).getBones();
        if (pathBones == null)
            sortBone(slotBone);
        else {
            var bones = this.bones.items;
            var i:Int = 0; var n:Int = pathBones.length; while (i < n) {
                var nn:Int = pathBones[i++];
                nn += i;
                while (i < nn) {
                    sortBone(fastCast(bones[pathBones[i++]], Bone)); }
            }
        }
    }

    #if !spine_no_inline inline #end private function sortBone(bone:Bone):Void {
        if (bone.sorted) return;
        var parent:Bone = bone.parent;
        if (parent != null) sortBone(parent);
        bone.sorted = true;
        cache.add(bone);
    }

    #if !spine_no_inline inline #end private function sortReset(bones:Array<Bone>):Void {
        var items = bones.items;
        var i:Int = 0; var n:Int = bones.size; while (i < n) {
            var bone:Bone = fastCast(items[i], Bone);
            if (!bone.active) { i++; continue; }
            if (bone.sorted) sortReset(bone.children);
            bone.sorted = false;
        i++; }
    }

    /** Updates the world transform for each bone and applies all constraints.
     * <p>
     * See <a href="http://esotericsoftware.com/spine-runtime-skeletons#World-transforms">World transforms</a> in the Spine
     * Runtimes Guide. */
    #if !spine_no_inline inline #end public function updateWorldTransform():Void {
        var bones = this.bones.items;
        var i:Int = 0; var n:Int = this.bones.size; while (i < n) {
            var bone:Bone = fastCast(bones[i], Bone);
            bone.ax = bone.x;
            bone.ay = bone.y;
            bone.arotation = bone.rotation;
            bone.ascaleX = bone.scaleX;
            bone.ascaleY = bone.scaleY;
            bone.ashearX = bone.shearX;
            bone.ashearY = bone.shearY;
        i++; }

        var cache = this.cache.items;
        var i:Int = 0; var n:Int = this.cache.size; while (i < n) {
            (fastCast(cache[i], Updatable)).update(); i++; }
    }

    /** Temporarily sets the root bone as a child of the specified bone, then updates the world transform for each bone and applies
     * all constraints.
     * <p>
     * See <a href="http://esotericsoftware.com/spine-runtime-skeletons#World-transforms">World transforms</a> in the Spine
     * Runtimes Guide. */
    #if !spine_no_inline inline #end public function updateWorldTransformWithParent(parent:Bone):Void {
        if (parent == null) throw new IllegalArgumentException("parent cannot be null.");

        // Apply the parent bone transform to the root bone. The root bone always inherits scale, rotation and reflection.
        var rootBone:Bone = getRootBone();
        var pa:Float = parent.a; var pb:Float = parent.b; var pc:Float = parent.c; var pd:Float = parent.d;
        rootBone.worldX = pa * x + pb * y + parent.worldX;
        rootBone.worldY = pc * x + pd * y + parent.worldY;

        var rotationY:Float = rootBone.rotation + 90 + rootBone.shearY;
        var la:Float = cosDeg(rootBone.rotation + rootBone.shearX) * rootBone.scaleX;
        var lb:Float = cosDeg(rotationY) * rootBone.scaleY;
        var lc:Float = sinDeg(rootBone.rotation + rootBone.shearX) * rootBone.scaleX;
        var ld:Float = sinDeg(rotationY) * rootBone.scaleY;
        rootBone.a = (pa * la + pb * lc) * scaleX;
        rootBone.b = (pa * lb + pb * ld) * scaleX;
        rootBone.c = (pc * la + pd * lc) * scaleY;
        rootBone.d = (pc * lb + pd * ld) * scaleY;

        // Update everything except root bone.
        var cache = this.cache.items;
        var i:Int = 0; var n:Int = this.cache.size; while (i < n) {
            var updatable:Updatable = fastCast(cache[i], Updatable);
            if (updatable != rootBone) updatable.update();
        i++; }
    }

    /** Sets the bones, constraints, slots, and draw order to their setup pose values. */
    #if !spine_no_inline inline #end public function setToSetupPose():Void {
        setBonesToSetupPose();
        setSlotsToSetupPose();
    }

    /** Sets the bones and constraints to their setup pose values. */
    #if !spine_no_inline inline #end public function setBonesToSetupPose():Void {
        var bones = this.bones.items;
        var i:Int = 0; var n:Int = this.bones.size; while (i < n) {
            (fastCast(bones[i], Bone)).setToSetupPose(); i++; }

        var ikConstraints = this.ikConstraints.items;
        var i:Int = 0; var n:Int = this.ikConstraints.size; while (i < n) {
            var constraint:IkConstraint = fastCast(ikConstraints[i], IkConstraint);
            constraint.mix = constraint.data.mix;
            constraint.softness = constraint.data.softness;
            constraint.bendDirection = constraint.data.bendDirection;
            constraint.compress = constraint.data.compress;
            constraint.stretch = constraint.data.stretch;
        i++; }

        var transformConstraints = this.transformConstraints.items;
        var i:Int = 0; var n:Int = this.transformConstraints.size; while (i < n) {
            var constraint:TransformConstraint = fastCast(transformConstraints[i], TransformConstraint);
            var data:TransformConstraintData = constraint.data;
            constraint.mixRotate = data.mixRotate;
            constraint.mixX = data.mixX;
            constraint.mixY = data.mixY;
            constraint.mixScaleX = data.mixScaleX;
            constraint.mixScaleY = data.mixScaleY;
            constraint.mixShearY = data.mixShearY;
        i++; }

        var pathConstraints = this.pathConstraints.items;
        var i:Int = 0; var n:Int = this.pathConstraints.size; while (i < n) {
            var constraint:PathConstraint = fastCast(pathConstraints[i], PathConstraint);
            var data:PathConstraintData = constraint.data;
            constraint.position = data.position;
            constraint.spacing = data.spacing;
            constraint.mixRotate = data.mixRotate;
            constraint.mixX = data.mixX;
            constraint.mixY = data.mixY;
        i++; }
    }

    /** Sets the slots and draw order to their setup pose values. */
    #if !spine_no_inline inline #end public function setSlotsToSetupPose():Void {
        var slots = this.slots.items;
        var n:Int = this.slots.size;
        arraycopy(slots, 0, drawOrder.items, 0, n);
        var i:Int = 0; while (i < n) {
            (fastCast(slots[i], Slot)).setToSetupPose(); i++; }
    }

    /** The skeleton's setup pose data. */
    public function getData():SkeletonData {
        return data;
    }

    /** The skeleton's bones, sorted parent first. The root bone is always the first bone. */
    public function getBones():Array<Bone> {
        return bones;
    }

    /** The list of bones and constraints, sorted in the order they should be updated, as computed by {@link #updateCache()}. */
    public function getUpdateCache():Array<Updatable> {
        return cache;
    }

    /** Returns the root bone, or null if the skeleton has no bones. */
    public function getRootBone():Bone {
        return bones.size == 0 ? null : bones.first();
    }

    /** Finds a bone by comparing each bone's name. It is more efficient to cache the results of this method than to call it
     * repeatedly. */
    public function findBone(boneName:String):Bone {
        if (boneName == null) throw new IllegalArgumentException("boneName cannot be null.");
        var bones = this.bones.items;
        var i:Int = 0; var n:Int = this.bones.size; while (i < n) {
            var bone:Bone = fastCast(bones[i], Bone);
            if (bone.data.name.equals(boneName)) return bone;
        i++; }
        return null;
    }

    /** The skeleton's slots. */
    #if !spine_no_inline inline #end public function getSlots():Array<Slot> {
        return slots;
    }

    /** Finds a slot by comparing each slot's name. It is more efficient to cache the results of this method than to call it
     * repeatedly. */
    public function findSlot(slotName:String):Slot {
        if (slotName == null) throw new IllegalArgumentException("slotName cannot be null.");
        var slots = this.slots.items;
        var i:Int = 0; var n:Int = this.slots.size; while (i < n) {
            var slot:Slot = fastCast(slots[i], Slot);
            if (slot.data.name.equals(slotName)) return slot;
        i++; }
        return null;
    }

    /** The skeleton's slots in the order they should be drawn. The returned array may be modified to change the draw order. */
    #if !spine_no_inline inline #end public function getDrawOrder():Array<Slot> {
        return drawOrder;
    }

    #if !spine_no_inline inline #end public function setDrawOrder(drawOrder:Array<Slot>):Void {
        if (drawOrder == null) throw new IllegalArgumentException("drawOrder cannot be null.");
        this.drawOrder = drawOrder;
    }

    /** The skeleton's current skin. */
    #if !spine_no_inline inline #end public function getSkin():Skin {
        return skin;
    }

    /** Sets a skin by name.
     * <p>
     * See {@link #setSkin(Skin)}. */
    #if !spine_no_inline inline #end public function setSkinByName(skinName:String):Void {
        var skin:Skin = data.findSkin(skinName);
        if (skin == null) throw new IllegalArgumentException("Skin not found: " + skinName);
        setSkin(skin);
    }

    /** Sets the skin used to look up attachments before looking in the {@link SkeletonData#getDefaultSkin() default skin}. If the
     * skin is changed, {@link #updateCache()} is called.
     * <p>
     * Attachments from the new skin are attached if the corresponding attachment from the old skin was attached. If there was no
     * old skin, each slot's setup mode attachment is attached from the new skin.
     * <p>
     * After changing the skin, the visible attachments can be reset to those attached in the setup pose by calling
     * {@link #setSlotsToSetupPose()}. Also, often {@link AnimationState#apply(Skeleton)} is called before the next time the
     * skeleton is rendered to allow any attachment keys in the current animation(s) to hide or show attachments from the new
     * skin. */
    #if !spine_no_inline inline #end public function setSkin(newSkin:Skin):Void {
        if (newSkin == skin) return;
        if (newSkin != null) {
            if (skin != null)
                newSkin.attachAll(this, skin);
            else {
                var slots = this.slots.items;
                var i:Int = 0; var n:Int = this.slots.size; while (i < n) {
                    var slot:Slot = fastCast(slots[i], Slot);
                    var name:String = slot.data.attachmentName;
                    if (name != null) {
                        var attachment:Attachment = newSkin.getAttachment(i, name);
                        if (attachment != null) slot.setAttachment(attachment);
                    }
                i++; }
            }
        }
        skin = newSkin;
        updateCache();
    }

    /** Finds an attachment by looking in the {@link #skin} and {@link SkeletonData#defaultSkin} using the slot name and attachment
     * name.
     * <p>
     * See {@link #getAttachment(int, String)}. */
    #if !spine_no_inline inline #end public function getAttachmentWithSlotName(slotName:String, attachmentName:String):Attachment {
        var slot:SlotData = data.findSlot(slotName);
        if (slot == null) throw new IllegalArgumentException("Slot not found: " + slotName);
        return getAttachment(slot.getIndex(), attachmentName);
    }

    /** Finds an attachment by looking in the {@link #skin} and {@link SkeletonData#defaultSkin} using the slot index and
     * attachment name. First the skin is checked and if the attachment was not found, the default skin is checked.
     * <p>
     * See <a href="http://esotericsoftware.com/spine-runtime-skins">Runtime skins</a> in the Spine Runtimes Guide. */
    public function getAttachment(slotIndex:Int, attachmentName:String):Attachment {
        if (attachmentName == null) throw new IllegalArgumentException("attachmentName cannot be null.");
        if (skin != null) {
            var attachment:Attachment = skin.getAttachment(slotIndex, attachmentName);
            if (attachment != null) return attachment;
        }
        if (data.defaultSkin != null) return data.defaultSkin.getAttachment(slotIndex, attachmentName);
        return null;
    }

    /** A convenience method to set an attachment by finding the slot with {@link #findSlot(String)}, finding the attachment with
     * {@link #getAttachment(int, String)}, then setting the slot's {@link Slot#attachment}.
     * @param attachmentName May be null to clear the slot's attachment. */
    #if !spine_no_inline inline #end public function setAttachment(slotName:String, attachmentName:String):Void {
        if (slotName == null) throw new IllegalArgumentException("slotName cannot be null.");
        var slot:Slot = findSlot(slotName);
        if (slot == null) throw new IllegalArgumentException("Slot not found: " + slotName);
        var attachment:Attachment = null;
        if (attachmentName != null) {
            attachment = getAttachment(slot.data.index, attachmentName);
            if (attachment == null)
                throw new IllegalArgumentException("Attachment not found: " + attachmentName + ", for slot: " + slotName);
        }
        slot.setAttachment(attachment);
    }

    /** The skeleton's IK constraints. */
    #if !spine_no_inline inline #end public function getIkConstraints():Array<IkConstraint> {
        return ikConstraints;
    }

    /** Finds an IK constraint by comparing each IK constraint's name. It is more efficient to cache the results of this method
     * than to call it repeatedly. */
    #if !spine_no_inline inline #end public function findIkConstraint(constraintName:String):IkConstraint {
        if (constraintName == null) throw new IllegalArgumentException("constraintName cannot be null.");
        var ikConstraints = this.ikConstraints.items;
        var i:Int = 0; var n:Int = this.ikConstraints.size; while (i < n) {
            var ikConstraint:IkConstraint = fastCast(ikConstraints[i], IkConstraint);
            if (ikConstraint.data.name.equals(constraintName)) return ikConstraint;
        i++; }
        return null;
    }

    /** The skeleton's transform constraints. */
    #if !spine_no_inline inline #end public function getTransformConstraints():Array<TransformConstraint> {
        return transformConstraints;
    }

    /** Finds a transform constraint by comparing each transform constraint's name. It is more efficient to cache the results of
     * this method than to call it repeatedly. */
    #if !spine_no_inline inline #end public function findTransformConstraint(constraintName:String):TransformConstraint {
        if (constraintName == null) throw new IllegalArgumentException("constraintName cannot be null.");
        var transformConstraints = this.transformConstraints.items;
        var i:Int = 0; var n:Int = this.transformConstraints.size; while (i < n) {
            var constraint:TransformConstraint = fastCast(transformConstraints[i], TransformConstraint);
            if (constraint.data.name.equals(constraintName)) return constraint;
        i++; }
        return null;
    }

    /** The skeleton's path constraints. */
    #if !spine_no_inline inline #end public function getPathConstraints():Array<PathConstraint> {
        return pathConstraints;
    }

    /** Finds a path constraint by comparing each path constraint's name. It is more efficient to cache the results of this method
     * than to call it repeatedly. */
    #if !spine_no_inline inline #end public function findPathConstraint(constraintName:String):PathConstraint {
        if (constraintName == null) throw new IllegalArgumentException("constraintName cannot be null.");
        var pathConstraints = this.pathConstraints.items;
        var i:Int = 0; var n:Int = this.pathConstraints.size; while (i < n) {
            var constraint:PathConstraint = fastCast(pathConstraints[i], PathConstraint);
            if (constraint.data.name.equals(constraintName)) return constraint;
        i++; }
        return null;
    }

    /** Returns the axis aligned bounding box (AABB) of the region and mesh attachments for the current pose.
     * @param offset An output value, the distance from the skeleton origin to the bottom left corner of the AABB.
     * @param size An output value, the width and height of the AABB.
     * @param temp Working memory to temporarily store attachments' computed world vertices. */
    #if !spine_no_inline inline #end public function getBounds(offset:Vector2, size:Vector2, temp:FloatArray):Void {
        if (offset == null) throw new IllegalArgumentException("offset cannot be null.");
        if (size == null) throw new IllegalArgumentException("size cannot be null.");
        if (temp == null) throw new IllegalArgumentException("temp cannot be null.");
        var drawOrder = this.drawOrder.items;
        var minX:Float = 999999999; var minY:Float = 999999999; var maxX:Float = -999999999; var maxY:Float = -999999999;
        var i:Int = 0; var n:Int = this.drawOrder.size; while (i < n) {
            var slot:Slot = fastCast(drawOrder[i], Slot);
            if (!slot.bone.active) { i++; continue; }
            var verticesLength:Int = 0;
            var vertices:FloatArray = null;
            var attachment:Attachment = slot.attachment;
            if (#if (haxe_ver >= 4.0) Std.isOfType #else Std.is #end(attachment, RegionAttachment)) {
                verticesLength = 8;
                vertices = temp.setSize(8);
                (fastCast(attachment, RegionAttachment)).computeWorldVertices(slot.getBone(), vertices, 0, 2);
            } else if (#if (haxe_ver >= 4.0) Std.isOfType #else Std.is #end(attachment, MeshAttachment)) {
                var mesh:MeshAttachment = fastCast(attachment, MeshAttachment);
                verticesLength = mesh.getWorldVerticesLength();
                vertices = temp.setSize(verticesLength);
                mesh.computeWorldVertices(slot, 0, verticesLength, vertices, 0, 2);
            }
            if (vertices != null) {
                var ii:Int = 0; while (ii < verticesLength) {
                    var x:Float = vertices[ii]; var y:Float = vertices[ii + 1];
                    minX = MathUtils.min(minX, x);
                    minY = MathUtils.min(minY, y);
                    maxX = MathUtils.max(maxX, x);
                    maxY = MathUtils.max(maxY, y);
                ii += 2; }
            }
        i++; }
        offset.set(minX, minY);
        size.set(maxX - minX, maxY - minY);
    }

    /** The color to tint all the skeleton's attachments. */
    #if !spine_no_inline inline #end public function getColor():Color {
        return color;
    }

    /** A convenience method for setting the skeleton color. The color can also be set by modifying {@link #getColor()}. */
    #if !spine_no_inline inline #end public function setColor(color:Color):Void {
        if (color == null) throw new IllegalArgumentException("color cannot be null.");
        this.color.setColor(color);
    }

    /** A convenience method for setting the skeleton color. The color can also be set by modifying {@link #getColor()}. */
    #if !spine_no_inline inline #end public function setColorWithRGBA(r:Float, g:Float, b:Float, a:Float):Void {
        color.set(r, g, b, a);
    }

    /** Scales the entire skeleton on the X axis. This affects all bones, even if the bone's transform mode disallows scale
     * inheritance. */
    #if !spine_no_inline inline #end public function getScaleX():Float {
        return scaleX;
    }

    #if !spine_no_inline inline #end public function setScaleX(scaleX:Float):Void {
        this.scaleX = scaleX;
    }

    /** Scales the entire skeleton on the Y axis. This affects all bones, even if the bone's transform mode disallows scale
     * inheritance. */
    #if !spine_no_inline inline #end public function getScaleY():Float {
        return scaleY;
    }

    #if !spine_no_inline inline #end public function setScaleY(scaleY:Float):Void {
        this.scaleY = scaleY;
    }

    #if !spine_no_inline inline #end public function setScale(scaleX:Float, scaleY:Float):Void {
        this.scaleX = scaleX;
        this.scaleY = scaleY;
    }

    /** Sets the skeleton X position, which is added to the root bone worldX position. */
    #if !spine_no_inline inline #end public function getX():Float {
        return x;
    }

    #if !spine_no_inline inline #end public function setX(x:Float):Void {
        this.x = x;
    }

    /** Sets the skeleton Y position, which is added to the root bone worldY position. */
    #if !spine_no_inline inline #end public function getY():Float {
        return y;
    }

    #if !spine_no_inline inline #end public function setY(y:Float):Void {
        this.y = y;
    }

    /** Sets the skeleton X and Y position, which is added to the root bone worldX and worldY position. */
    #if !spine_no_inline inline #end public function setPosition(x:Float, y:Float):Void {
        this.x = x;
        this.y = y;
    }

    /** Returns the skeleton's time. This can be used for tracking, such as with Slot {@link Slot#getAttachmentTime()}.
     * <p>
     * See {@link #update(float)}. */
    #if !spine_no_inline inline #end public function getTime():Float {
        return time;
    }

    #if !spine_no_inline inline #end public function setTime(time:Float):Void {
        this.time = time;
    }

    /** Increments the skeleton's {@link #time}. */
    #if !spine_no_inline inline #end public function update(delta:Float):Void {
        time += delta;
    }

    #if !spine_no_inline inline #end public function toString():String {
        return data.name != null ? data.name : Type.getClassName(Type.getClass(this));
    }
}
