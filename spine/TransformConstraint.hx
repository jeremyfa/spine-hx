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

import spine.utils.SpineUtils.*;

import spine.support.math.Vector2;
import spine.support.utils.Array;

/** Stores the current pose for a transform constraint. A transform constraint adjusts the world transform of the constrained
 * bones to match that of the target bone.
 * <p>
 * See <a href="http://esotericsoftware.com/spine-transform-constraints">Transform constraints</a> in the Spine User Guide. */
class TransformConstraint implements Constraint {
    public var data:TransformConstraintData;
    public var bones:Array<Bone>;
    public var target:Bone;
    public var rotateMix:Float = 0; public var translateMix:Float = 0; public var scaleMix:Float = 0; public var shearMix:Float = 0;
    public var temp:Vector2 = new Vector2();

    public function new(data:TransformConstraintData, skeleton:Skeleton) {
        if (data == null) throw new IllegalArgumentException("data cannot be null.");
        if (skeleton == null) throw new IllegalArgumentException("skeleton cannot be null.");
        this.data = data;
        rotateMix = data.rotateMix;
        translateMix = data.translateMix;
        scaleMix = data.scaleMix;
        shearMix = data.shearMix;
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
        rotateMix = constraint.rotateMix;
        translateMix = constraint.translateMix;
        scaleMix = constraint.scaleMix;
        shearMix = constraint.shearMix;
    }*/

    /** Applies the constraint to the constrained bones. */
    public function apply():Void {
        update();
    }

    #if !spine_no_inline inline #end public function update():Void {
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
        var rotateMix:Float = this.rotateMix; var translateMix:Float = this.translateMix; var scaleMix:Float = this.scaleMix; var shearMix:Float = this.shearMix;
        var target:Bone = this.target;
        var ta:Float = target.a; var tb:Float = target.b; var tc:Float = target.c; var td:Float = target.d;
        var degRadReflect:Float = ta * td - tb * tc > 0 ? degRad : -degRad;
        var offsetRotation:Float = data.offsetRotation * degRadReflect; var offsetShearY:Float = data.offsetShearY * degRadReflect;
        var bones:Array<Bone> = this.bones;
        var i:Int = 0; var n:Int = bones.size; while (i < n) {
            var bone:Bone = bones.get(i);
            var modified:Bool = false;

            if (rotateMix != 0) {
                var a:Float = bone.a; var b:Float = bone.b; var c:Float = bone.c; var d:Float = bone.d;
                var r:Float = atan2(tc, ta) - atan2(c, a) + offsetRotation;
                if (r > PI)
                    r -= PI2;
                else if (r < -PI) r += PI2;
                r *= rotateMix;
                var cos:Float = cos(r); var sin:Float = sin(r);
                bone.a = cos * a - sin * c;
                bone.b = cos * b - sin * d;
                bone.c = sin * a + cos * c;
                bone.d = sin * b + cos * d;
                modified = true;
            }

            if (translateMix != 0) {
                var temp:Vector2 = this.temp;
                target.localToWorld(temp.set(data.offsetX, data.offsetY));
                bone.worldX += (temp.x - bone.worldX) * translateMix;
                bone.worldY += (temp.y - bone.worldY) * translateMix;
                modified = true;
            }

            if (scaleMix > 0) {
                var s:Float = cast(Math.sqrt(bone.a * bone.a + bone.c * bone.c), Float);
                if (s != 0) s = (s + (cast(Math.sqrt(ta * ta + tc * tc) - s + data.offsetScaleX, Float)) * scaleMix) / s;
                bone.a *= s;
                bone.c *= s;
                s = cast(Math.sqrt(bone.b * bone.b + bone.d * bone.d), Float);
                if (s != 0) s = (s + (cast(Math.sqrt(tb * tb + td * td) - s + data.offsetScaleY, Float)) * scaleMix) / s;
                bone.b *= s;
                bone.d *= s;
                modified = true;
            }

            if (shearMix > 0) {
                var b:Float = bone.b; var d:Float = bone.d;
                var by:Float = atan2(d, b);
                var r:Float = atan2(td, tb) - atan2(tc, ta) - (by - atan2(bone.c, bone.a));
                if (r > PI)
                    r -= PI2;
                else if (r < -PI) r += PI2;
                r = by + (r + offsetShearY) * shearMix;
                var s:Float = cast(Math.sqrt(b * b + d * d), Float);
                bone.b = cos(r) * s;
                bone.d = sin(r) * s;
                modified = true;
            }

            if (modified) bone.appliedValid = false;
        i++; }
    }

    #if !spine_no_inline inline #end private function applyRelativeWorld():Void {
        var rotateMix:Float = this.rotateMix; var translateMix:Float = this.translateMix; var scaleMix:Float = this.scaleMix; var shearMix:Float = this.shearMix;
        var target:Bone = this.target;
        var ta:Float = target.a; var tb:Float = target.b; var tc:Float = target.c; var td:Float = target.d;
        var degRadReflect:Float = ta * td - tb * tc > 0 ? degRad : -degRad;
        var offsetRotation:Float = data.offsetRotation * degRadReflect; var offsetShearY:Float = data.offsetShearY * degRadReflect;
        var bones:Array<Bone> = this.bones;
        var i:Int = 0; var n:Int = bones.size; while (i < n) {
            var bone:Bone = bones.get(i);
            var modified:Bool = false;

            if (rotateMix != 0) {
                var a:Float = bone.a; var b:Float = bone.b; var c:Float = bone.c; var d:Float = bone.d;
                var r:Float = atan2(tc, ta) + offsetRotation;
                if (r > PI)
                    r -= PI2;
                else if (r < -PI) r += PI2;
                r *= rotateMix;
                var cos:Float = cos(r); var sin:Float = sin(r);
                bone.a = cos * a - sin * c;
                bone.b = cos * b - sin * d;
                bone.c = sin * a + cos * c;
                bone.d = sin * b + cos * d;
                modified = true;
            }

            if (translateMix != 0) {
                var temp:Vector2 = this.temp;
                target.localToWorld(temp.set(data.offsetX, data.offsetY));
                bone.worldX += temp.x * translateMix;
                bone.worldY += temp.y * translateMix;
                modified = true;
            }

            if (scaleMix > 0) {
                var s:Float = (cast(Math.sqrt(ta * ta + tc * tc) - 1 + data.offsetScaleX, Float)) * scaleMix + 1;
                bone.a *= s;
                bone.c *= s;
                s = (cast(Math.sqrt(tb * tb + td * td) - 1 + data.offsetScaleY, Float)) * scaleMix + 1;
                bone.b *= s;
                bone.d *= s;
                modified = true;
            }

            if (shearMix > 0) {
                var r:Float = atan2(td, tb) - atan2(tc, ta);
                if (r > PI)
                    r -= PI2;
                else if (r < -PI) r += PI2;
                var b:Float = bone.b; var d:Float = bone.d;
                r = atan2(d, b) + (r - PI / 2 + offsetShearY) * shearMix;
                var s:Float = cast(Math.sqrt(b * b + d * d), Float);
                bone.b = cos(r) * s;
                bone.d = sin(r) * s;
                modified = true;
            }

            if (modified) bone.appliedValid = false;
        i++; }
    }

    #if !spine_no_inline inline #end private function applyAbsoluteLocal():Void {
        var rotateMix:Float = this.rotateMix; var translateMix:Float = this.translateMix; var scaleMix:Float = this.scaleMix; var shearMix:Float = this.shearMix;
        var target:Bone = this.target;
        if (!target.appliedValid) target.updateAppliedTransform();
        var bones:Array<Bone> = this.bones;
        var i:Int = 0; var n:Int = bones.size; while (i < n) {
            var bone:Bone = bones.get(i);
            if (!bone.appliedValid) bone.updateAppliedTransform();

            var rotation:Float = bone.arotation;
            if (rotateMix != 0) {
                var r:Float = target.arotation - rotation + data.offsetRotation;
                r -= (16384 - Std.int((16384.499999999996 - r / 360))) * 360;
                rotation += r * rotateMix;
            }

            var x:Float = bone.ax; var y:Float = bone.ay;
            if (translateMix != 0) {
                x += (target.ax - x + data.offsetX) * translateMix;
                y += (target.ay - y + data.offsetY) * translateMix;
            }

            var scaleX:Float = bone.ascaleX; var scaleY:Float = bone.ascaleY;
            if (scaleMix != 0) {
                if (scaleX != 0) scaleX = (scaleX + (target.ascaleX - scaleX + data.offsetScaleX) * scaleMix) / scaleX;
                if (scaleY != 0) scaleY = (scaleY + (target.ascaleY - scaleY + data.offsetScaleY) * scaleMix) / scaleY;
            }

            var shearY:Float = bone.ashearY;
            if (shearMix != 0) {
                var r:Float = target.ashearY - shearY + data.offsetShearY;
                r -= (16384 - Std.int((16384.499999999996 - r / 360))) * 360;
                shearY += r * shearMix;
            }

            bone.updateWorldTransformWithData(x, y, rotation, scaleX, scaleY, bone.ashearX, shearY);
        i++; }
    }

    #if !spine_no_inline inline #end private function applyRelativeLocal():Void {
        var rotateMix:Float = this.rotateMix; var translateMix:Float = this.translateMix; var scaleMix:Float = this.scaleMix; var shearMix:Float = this.shearMix;
        var target:Bone = this.target;
        if (!target.appliedValid) target.updateAppliedTransform();
        var bones:Array<Bone> = this.bones;
        var i:Int = 0; var n:Int = bones.size; while (i < n) {
            var bone:Bone = bones.get(i);
            if (!bone.appliedValid) bone.updateAppliedTransform();

            var rotation:Float = bone.arotation;
            if (rotateMix != 0) rotation += (target.arotation + data.offsetRotation) * rotateMix;

            var x:Float = bone.ax; var y:Float = bone.ay;
            if (translateMix != 0) {
                x += (target.ax + data.offsetX) * translateMix;
                y += (target.ay + data.offsetY) * translateMix;
            }

            var scaleX:Float = bone.ascaleX; var scaleY:Float = bone.ascaleY;
            if (scaleMix != 0) {
                scaleX *= ((target.ascaleX - 1 + data.offsetScaleX) * scaleMix) + 1;
                scaleY *= ((target.ascaleY - 1 + data.offsetScaleY) * scaleMix) + 1;
            }

            var shearY:Float = bone.ashearY;
            if (shearMix != 0) shearY += (target.ashearY + data.offsetShearY) * shearMix;

            bone.updateWorldTransformWithData(x, y, rotation, scaleX, scaleY, bone.ashearX, shearY);
        i++; }
    }

    #if !spine_no_inline inline #end public function getOrder():Int {
        return data.order;
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
        this.target = target;
    }

    /** A percentage (0-1) that controls the mix between the constrained and unconstrained rotations. */
    #if !spine_no_inline inline #end public function getRotateMix():Float {
        return rotateMix;
    }

    #if !spine_no_inline inline #end public function setRotateMix(rotateMix:Float):Void {
        this.rotateMix = rotateMix;
    }

    /** A percentage (0-1) that controls the mix between the constrained and unconstrained translations. */
    #if !spine_no_inline inline #end public function getTranslateMix():Float {
        return translateMix;
    }

    #if !spine_no_inline inline #end public function setTranslateMix(translateMix:Float):Void {
        this.translateMix = translateMix;
    }

    /** A percentage (0-1) that controls the mix between the constrained and unconstrained scales. */
    #if !spine_no_inline inline #end public function getScaleMix():Float {
        return scaleMix;
    }

    #if !spine_no_inline inline #end public function setScaleMix(scaleMix:Float):Void {
        this.scaleMix = scaleMix;
    }

    /** A percentage (0-1) that controls the mix between the constrained and unconstrained scales. */
    #if !spine_no_inline inline #end public function getShearMix():Float {
        return shearMix;
    }

    #if !spine_no_inline inline #end public function setShearMix(shearMix:Float):Void {
        this.shearMix = shearMix;
    }

    /** The transform constraint's setup pose data. */
    #if !spine_no_inline inline #end public function getData():TransformConstraintData {
        return data;
    }

    #if !spine_no_inline inline #end public function toString():String {
        return data.name;
    }
}
