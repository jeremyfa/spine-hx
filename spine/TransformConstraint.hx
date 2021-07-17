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

import spine.support.math.Vector2;
import spine.support.utils.Array;

/** Stores the current pose for a transform constraint. A transform constraint adjusts the world transform of the constrained
 * bones to match that of the target bone.
 * <p>
 * See <a href="http://esotericsoftware.com/spine-transform-constraints">Transform constraints</a> in the Spine User Guide. */
class TransformConstraint implements Updatable {
    public var data:TransformConstraintData;
    public var bones:Array<Bone>;
    public var target:Bone;
    public var mixRotate:Float = 0; public var mixX:Float = 0; public var mixY:Float = 0; public var mixScaleX:Float = 0; public var mixScaleY:Float = 0; public var mixShearY:Float = 0;

    public var active:Bool = false;
    public var temp:Vector2 = new Vector2();

    public function new(data:TransformConstraintData, skeleton:Skeleton) {
        if (data == null) throw new IllegalArgumentException("data cannot be null.");
        if (skeleton == null) throw new IllegalArgumentException("skeleton cannot be null.");
        this.data = data;
        mixRotate = data.mixRotate;
        mixX = data.mixX;
        mixY = data.mixY;
        mixScaleX = data.mixScaleX;
        mixScaleY = data.mixScaleY;
        mixShearY = data.mixShearY;
        bones = new Array(data.bones.size);
        for (boneData in data.bones) {
            bones.add(skeleton.findBone(boneData.name)); }
        target = skeleton.findBone(data.target.name);
    }

    /** Copy constructor. */
    /*public function new(constraint:TransformConstraint, skeleton:Skeleton) {
        if (constraint == null) throw new IllegalArgumentException("constraint cannot be null.");
        if (skeleton == null) throw new IllegalArgumentException("skeleton cannot be null.");
        data = constraint.data;
        bones = new Array(constraint.bones.size);
        for (bone in constraint.bones) {
            bones.add(skeleton.bones.get(bone.data.index)); }
        target = skeleton.bones.get(constraint.target.data.index);
        mixRotate = constraint.mixRotate;
        mixX = constraint.mixX;
        mixY = constraint.mixY;
        mixScaleX = constraint.mixScaleX;
        mixScaleY = constraint.mixScaleY;
        mixShearY = constraint.mixShearY;
    }*/

    /** Applies the constraint to the constrained bones. */
    #if !spine_no_inline inline #end public function update():Void {
        if (mixRotate == 0 && mixX == 0 && mixY == 0 && mixScaleX == 0 && mixScaleX == 0 && mixShearY == 0) return;
        if (data.local) {
            if (data.relative)
                applyRelativeLocal();
            else
                applyAbsoluteLocal();
        } else {
            if (data.relative)
                applyRelativeWorld();
            else
                applyAbsoluteWorld();
        }
    }

    #if !spine_no_inline inline #end private function applyAbsoluteWorld():Void {
        var mixRotate:Float = this.mixRotate; var mixX:Float = this.mixX; var mixY:Float = this.mixY; var mixScaleX:Float = this.mixScaleX;
            var mixScaleY:Float = this.mixScaleY; var mixShearY:Float = this.mixShearY;
        var translate:Bool = mixX != 0 || mixY != 0;

        var target:Bone = this.target;
        var ta:Float = target.a; var tb:Float = target.b; var tc:Float = target.c; var td:Float = target.d;
        var degRadReflect:Float = ta * td - tb * tc > 0 ? degRad : -degRad;
        var offsetRotation:Float = data.offsetRotation * degRadReflect; var offsetShearY:Float = data.offsetShearY * degRadReflect;

        var bones = this.bones.items;
        var i:Int = 0; var n:Int = this.bones.size; while (i < n) {
            var bone:Bone = fastCast(bones[i], Bone);

            if (mixRotate != 0) {
                var a:Float = bone.a; var b:Float = bone.b; var c:Float = bone.c; var d:Float = bone.d;
                var r:Float = atan2(tc, ta) - atan2(c, a) + offsetRotation;
                if (r > PI)
                    r -= PI2;
                else if (r < -PI) //
                    r += PI2;
                r *= mixRotate;
                var cos:Float = cos(r); var sin:Float = sin(r);
                bone.a = cos * a - sin * c;
                bone.b = cos * b - sin * d;
                bone.c = sin * a + cos * c;
                bone.d = sin * b + cos * d;
            }

            if (translate) {
                var temp:Vector2 = this.temp;
                target.localToWorld(temp.set(data.offsetX, data.offsetY));
                bone.worldX += (temp.x - bone.worldX) * mixX;
                bone.worldY += (temp.y - bone.worldY) * mixY;
            }

            if (mixScaleX != 0) {
                var s:Float = Math.sqrt(bone.a * bone.a + bone.c * bone.c);
                if (s != 0) s = (s + (Math.sqrt(ta * ta + tc * tc) - s + data.offsetScaleX) * mixScaleX) / s;
                bone.a *= s;
                bone.c *= s;
            }
            if (mixScaleY != 0) {
                var s:Float = Math.sqrt(bone.b * bone.b + bone.d * bone.d);
                if (s != 0) s = (s + (Math.sqrt(tb * tb + td * td) - s + data.offsetScaleY) * mixScaleY) / s;
                bone.b *= s;
                bone.d *= s;
            }

            if (mixShearY > 0) {
                var b:Float = bone.b; var d:Float = bone.d;
                var by:Float = atan2(d, b);
                var r:Float = atan2(td, tb) - atan2(tc, ta) - (by - atan2(bone.c, bone.a));
                if (r > PI)
                    r -= PI2;
                else if (r < -PI) //
                    r += PI2;
                r = by + (r + offsetShearY) * mixShearY;
                var s:Float = Math.sqrt(b * b + d * d);
                bone.b = cos(r) * s;
                bone.d = sin(r) * s;
            }

            bone.updateAppliedTransform();
        i++; }
    }

    #if !spine_no_inline inline #end private function applyRelativeWorld():Void {
        var mixRotate:Float = this.mixRotate; var mixX:Float = this.mixX; var mixY:Float = this.mixY; var mixScaleX:Float = this.mixScaleX;
            var mixScaleY:Float = this.mixScaleY; var mixShearY:Float = this.mixShearY;
        var translate:Bool = mixX != 0 || mixY != 0;

        var target:Bone = this.target;
        var ta:Float = target.a; var tb:Float = target.b; var tc:Float = target.c; var td:Float = target.d;
        var degRadReflect:Float = ta * td - tb * tc > 0 ? degRad : -degRad;
        var offsetRotation:Float = data.offsetRotation * degRadReflect; var offsetShearY:Float = data.offsetShearY * degRadReflect;

        var bones = this.bones.items;
        var i:Int = 0; var n:Int = this.bones.size; while (i < n) {
            var bone:Bone = fastCast(bones[i], Bone);

            if (mixRotate != 0) {
                var a:Float = bone.a; var b:Float = bone.b; var c:Float = bone.c; var d:Float = bone.d;
                var r:Float = atan2(tc, ta) + offsetRotation;
                if (r > PI)
                    r -= PI2;
                else if (r < -PI) //
                    r += PI2;
                r *= mixRotate;
                var cos:Float = cos(r); var sin:Float = sin(r);
                bone.a = cos * a - sin * c;
                bone.b = cos * b - sin * d;
                bone.c = sin * a + cos * c;
                bone.d = sin * b + cos * d;
            }

            if (translate) {
                var temp:Vector2 = this.temp;
                target.localToWorld(temp.set(data.offsetX, data.offsetY));
                bone.worldX += temp.x * mixX;
                bone.worldY += temp.y * mixY;
            }

            if (mixScaleX != 0) {
                var s:Float = (Math.sqrt(ta * ta + tc * tc) - 1 + data.offsetScaleX) * mixScaleX + 1;
                bone.a *= s;
                bone.c *= s;
            }
            if (mixScaleY != 0) {
                var s:Float = (Math.sqrt(tb * tb + td * td) - 1 + data.offsetScaleY) * mixScaleY + 1;
                bone.b *= s;
                bone.d *= s;
            }

            if (mixShearY > 0) {
                var r:Float = atan2(td, tb) - atan2(tc, ta);
                if (r > PI)
                    r -= PI2;
                else if (r < -PI) //
                    r += PI2;
                var b:Float = bone.b; var d:Float = bone.d;
                r = atan2(d, b) + (r - PI / 2 + offsetShearY) * mixShearY;
                var s:Float = Math.sqrt(b * b + d * d);
                bone.b = cos(r) * s;
                bone.d = sin(r) * s;
            }

            bone.updateAppliedTransform();
        i++; }
    }

    #if !spine_no_inline inline #end private function applyAbsoluteLocal():Void {
        var mixRotate:Float = this.mixRotate; var mixX:Float = this.mixX; var mixY:Float = this.mixY; var mixScaleX:Float = this.mixScaleX;
            var mixScaleY:Float = this.mixScaleY; var mixShearY:Float = this.mixShearY;

        var target:Bone = this.target;

        var bones = this.bones.items;
        var i:Int = 0; var n:Int = this.bones.size; while (i < n) {
            var bone:Bone = fastCast(bones[i], Bone);

            var rotation:Float = bone.arotation;
            if (mixRotate != 0) {
                var r:Float = target.arotation - rotation + data.offsetRotation;
                r -= (16384 - Std.int((16384.499999999996 - r / 360))) * 360;
                rotation += r * mixRotate;
            }

            var x:Float = bone.ax; var y:Float = bone.ay;
            x += (target.ax - x + data.offsetX) * mixX;
            y += (target.ay - y + data.offsetY) * mixY;

            var scaleX:Float = bone.ascaleX; var scaleY:Float = bone.ascaleY;
            if (mixScaleX != 0 && scaleX != 0)
                scaleX = (scaleX + (target.ascaleX - scaleX + data.offsetScaleX) * mixScaleX) / scaleX;
            if (mixScaleY != 0 && scaleY != 0)
                scaleY = (scaleY + (target.ascaleY - scaleY + data.offsetScaleY) * mixScaleY) / scaleY;

            var shearY:Float = bone.ashearY;
            if (mixShearY != 0) {
                var r:Float = target.ashearY - shearY + data.offsetShearY;
                r -= (16384 - Std.int((16384.499999999996 - r / 360))) * 360;
                shearY += r * mixShearY;
            }

            bone.updateWorldTransformWithData(x, y, rotation, scaleX, scaleY, bone.ashearX, shearY);
        i++; }
    }

    #if !spine_no_inline inline #end private function applyRelativeLocal():Void {
        var mixRotate:Float = this.mixRotate; var mixX:Float = this.mixX; var mixY:Float = this.mixY; var mixScaleX:Float = this.mixScaleX;
            var mixScaleY:Float = this.mixScaleY; var mixShearY:Float = this.mixShearY;

        var target:Bone = this.target;

        var bones = this.bones.items;
        var i:Int = 0; var n:Int = this.bones.size; while (i < n) {
            var bone:Bone = fastCast(bones[i], Bone);

            var rotation:Float = bone.arotation + (target.arotation + data.offsetRotation) * mixRotate;
            var x:Float = bone.ax + (target.ax + data.offsetX) * mixX;
            var y:Float = bone.ay + (target.ay + data.offsetY) * mixY;
            var scaleX:Float = (bone.ascaleX * ((target.ascaleX - 1 + data.offsetScaleX) * mixScaleX) + 1);
            var scaleY:Float = (bone.ascaleY * ((target.ascaleY - 1 + data.offsetScaleY) * mixScaleY) + 1);
            var shearY:Float = bone.ashearY + (target.ashearY + data.offsetShearY) * mixShearY;

            bone.updateWorldTransformWithData(x, y, rotation, scaleX, scaleY, bone.ashearX, shearY);
        i++; }
    }

    /** The bones that will be modified by this transform constraint. */
    #if !spine_no_inline inline #end public function getBones():Array<Bone> {
        return bones;
    }

    /** The target bone whose world transform will be copied to the constrained bones. */
    #if !spine_no_inline inline #end public function getTarget():Bone {
        return target;
    }

    #if !spine_no_inline inline #end public function setTarget(target:Bone):Void {
        if (target == null) throw new IllegalArgumentException("target cannot be null.");
        this.target = target;
    }

    /** A percentage (0-1) that controls the mix between the constrained and unconstrained rotation. */
    #if !spine_no_inline inline #end public function getMixRotate():Float {
        return mixRotate;
    }

    #if !spine_no_inline inline #end public function setMixRotate(mixRotate:Float):Void {
        this.mixRotate = mixRotate;
    }

    /** A percentage (0-1) that controls the mix between the constrained and unconstrained translation X. */
    #if !spine_no_inline inline #end public function getMixX():Float {
        return mixX;
    }

    #if !spine_no_inline inline #end public function setMixX(mixX:Float):Void {
        this.mixX = mixX;
    }

    /** A percentage (0-1) that controls the mix between the constrained and unconstrained translation Y. */
    #if !spine_no_inline inline #end public function getMixY():Float {
        return mixY;
    }

    #if !spine_no_inline inline #end public function setMixY(mixY:Float):Void {
        this.mixY = mixY;
    }

    /** A percentage (0-1) that controls the mix between the constrained and unconstrained scale X. */
    #if !spine_no_inline inline #end public function getMixScaleX():Float {
        return mixScaleX;
    }

    #if !spine_no_inline inline #end public function setMixScaleX(mixScaleX:Float):Void {
        this.mixScaleX = mixScaleX;
    }

    /** A percentage (0-1) that controls the mix between the constrained and unconstrained scale X. */
    #if !spine_no_inline inline #end public function getMixScaleY():Float {
        return mixScaleY;
    }

    #if !spine_no_inline inline #end public function setMixScaleY(mixScaleY:Float):Void {
        this.mixScaleY = mixScaleY;
    }

    /** A percentage (0-1) that controls the mix between the constrained and unconstrained shear Y. */
    #if !spine_no_inline inline #end public function getMixShearY():Float {
        return mixShearY;
    }

    #if !spine_no_inline inline #end public function setMixShearY(mixShearY:Float):Void {
        this.mixShearY = mixShearY;
    }

    #if !spine_no_inline inline #end public function isActive():Bool {
        return active;
    }

    /** The transform constraint's setup pose data. */
    #if !spine_no_inline inline #end public function getData():TransformConstraintData {
        return data;
    }

    #if !spine_no_inline inline #end public function toString():String {
        return data.name;
    }
}
