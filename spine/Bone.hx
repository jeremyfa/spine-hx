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

import spine.support.math.Matrix3.*;
import spine.utils.SpineUtils.*;

import spine.support.math.Matrix3;
import spine.support.math.Vector2;
import spine.support.utils.Array;

import spine.BoneData.TransformMode;
import spine.BoneData.TransformMode_enum;

/** Stores a bone's current pose.
 * <p>
 * A bone has a local transform which is used to compute its world transform. A bone also has an applied transform, which is a
 * local transform that can be applied to compute the world transform. The local transform and applied transform may differ if a
 * constraint or application code modifies the world transform after it was computed from the local transform. */
class Bone implements Updatable {
    public var data:BoneData;
    public var skeleton:Skeleton;
    public var parent:Bone;
    public var children:Array<Bone> = new Array();
    public var x:Float = 0; public var y:Float = 0; public var rotation:Float = 0; public var scaleX:Float = 0; public var scaleY:Float = 0; public var shearX:Float = 0; public var shearY:Float = 0;
    public var ax:Float = 0; public var ay:Float = 0; public var arotation:Float = 0; public var ascaleX:Float = 0; public var ascaleY:Float = 0; public var ashearX:Float = 0; public var ashearY:Float = 0;
    public var appliedValid:Bool = false;
    public var a:Float = 0; public var b:Float = 0; public var worldX:Float = 0;
    public var c:Float = 0; public var d:Float = 0; public var worldY:Float = 0;

    public var sorted:Bool = false;

    /** @param parent May be null. */
    public function new(data:BoneData, skeleton:Skeleton, parent:Bone) {
        if (data == null) throw new IllegalArgumentException("data cannot be null.");
        if (skeleton == null) throw new IllegalArgumentException("skeleton cannot be null.");
        this.data = data;
        this.skeleton = skeleton;
        this.parent = parent;
        setToSetupPose();
    }

    /** Copy constructor. Does not copy the children bones.
     * @param parent May be null. */
    /*public function new(bone:Bone, skeleton:Skeleton, parent:Bone) {
        if (bone == null) throw new IllegalArgumentException("bone cannot be null.");
        if (skeleton == null) throw new IllegalArgumentException("skeleton cannot be null.");
        this.skeleton = skeleton;
        this.parent = parent;
        data = bone.data;
        x = bone.x;
        y = bone.y;
        rotation = bone.rotation;
        scaleX = bone.scaleX;
        scaleY = bone.scaleY;
        shearX = bone.shearX;
        shearY = bone.shearY;
    }*/

    /** Same as {@link #updateWorldTransform()}. This method exists for Bone to implement {@link Updatable}. */
    public function update():Void {
        updateWorldTransformWithData(x, y, rotation, scaleX, scaleY, shearX, shearY);
    }

    /** Computes the world transform using the parent bone and this bone's local transform.
     * <p>
     * See {@link #updateWorldTransformWithData(float, float, float, float, float, float, float)}. */
    public function updateWorldTransform():Void {
        updateWorldTransformWithData(x, y, rotation, scaleX, scaleY, shearX, shearY);
    }

    /** Computes the world transform using the parent bone and the specified local transform. Child bones are not updated.
     * <p>
     * See <a href="http://esotericsoftware.com/spine-runtime-skeletons#World-transforms">World transforms</a> in the Spine
     * Runtimes Guide. */
    public function updateWorldTransformWithData(x:Float, y:Float, rotation:Float, scaleX:Float, scaleY:Float, shearX:Float, shearY:Float):Void {
        ax = x;
        ay = y;
        arotation = rotation;
        ascaleX = scaleX;
        ascaleY = scaleY;
        ashearX = shearX;
        ashearY = shearY;
        appliedValid = true;

        var parent:Bone = this.parent;
        if (parent == null) { // Root bone.
            var skeleton:Skeleton = this.skeleton;
            var rotationY:Float = rotation + 90 + shearY; var sx:Float = skeleton.scaleX; var sy:Float = skeleton.scaleY;
            a = cosDeg(rotation + shearX) * scaleX * sx;
            b = cosDeg(rotationY) * scaleY * sy;
            c = sinDeg(rotation + shearX) * scaleX * sx;
            d = sinDeg(rotationY) * scaleY * sy;
            worldX = x * sx + skeleton.x;
            worldY = y * sy + skeleton.y;
            return;
        }

        var pa:Float = parent.a; var pb:Float = parent.b; var pc:Float = parent.c; var pd:Float = parent.d;
        worldX = pa * x + pb * y + parent.worldX;
        worldY = pc * x + pd * y + parent.worldY;

        var _continueAfterSwitch0 = false; while(true) { var _switchCond0 = (data.transformMode); {
        if (_switchCond0 == normal) {
            var rotationY:Float = rotation + 90 + shearY;
            var la:Float = cosDeg(rotation + shearX) * scaleX;
            var lb:Float = cosDeg(rotationY) * scaleY;
            var lc:Float = sinDeg(rotation + shearX) * scaleX;
            var ld:Float = sinDeg(rotationY) * scaleY;
            a = pa * la + pb * lc;
            b = pa * lb + pb * ld;
            c = pc * la + pd * lc;
            d = pc * lb + pd * ld;
            return;
        }
        else if (_switchCond0 == onlyTranslation) {
            var rotationY:Float = rotation + 90 + shearY;
            a = cosDeg(rotation + shearX) * scaleX;
            b = cosDeg(rotationY) * scaleY;
            c = sinDeg(rotation + shearX) * scaleX;
            d = sinDeg(rotationY) * scaleY;
            break;
        }
        else if (_switchCond0 == noRotationOrReflection) {
            var s:Float = pa * pa + pc * pc; var prx:Float = 0;
            if (s > 0.0001) {
                s = Math.abs(pa * pd - pb * pc) / s;
                pb = pc * s;
                pd = pa * s;
                prx = atan2(pc, pa) * radDeg;
            } else {
                pa = 0;
                pc = 0;
                prx = 90 - atan2(pd, pb) * radDeg;
            }
            var rx:Float = rotation + shearX - prx;
            var ry:Float = rotation + shearY - prx + 90;
            var la:Float = cosDeg(rx) * scaleX;
            var lb:Float = cosDeg(ry) * scaleY;
            var lc:Float = sinDeg(rx) * scaleX;
            var ld:Float = sinDeg(ry) * scaleY;
            a = pa * la - pb * lc;
            b = pa * lb - pb * ld;
            c = pc * la + pd * lc;
            d = pc * lb + pd * ld;
            break;
        }
        else if (_switchCond0 == noScale) {
            {
            var cos:Float = cosDeg(rotation); var sin:Float = sinDeg(rotation);
            var za:Float = (pa * cos + pb * sin) / skeleton.scaleX;
            var zc:Float = (pc * cos + pd * sin) / skeleton.scaleY;
            var s:Float = cast(Math.sqrt(za * za + zc * zc), Float);
            if (s > 0.00001) s = 1 / s;
            za *= s;
            zc *= s;
            s = cast(Math.sqrt(za * za + zc * zc), Float);
            if (data.transformMode == TransformMode.noScale
                && (pa * pd - pb * pc < 0) != ((skeleton.scaleX < 0) != (skeleton.scaleY < 0))) s = -s;
            var r:Float = PI / 2 + atan2(zc, za);
            var zb:Float = Math.cos(r) * s;
            var zd:Float = Math.sin(r) * s;
            var la:Float = cosDeg(shearX) * scaleX;
            var lb:Float = cosDeg(90 + shearY) * scaleY;
            var lc:Float = sinDeg(shearX) * scaleX;
            var ld:Float = sinDeg(90 + shearY) * scaleY;
            a = za * la + zb * lc;
            b = za * lb + zb * ld;
            c = zc * la + zd * lc;
            d = zc * lb + zd * ld;
            break;
        }
        } else if (_switchCond0 == noScaleOrReflection) {
            var cos:Float = cosDeg(rotation); var sin:Float = sinDeg(rotation);
            var za:Float = (pa * cos + pb * sin) / skeleton.scaleX;
            var zc:Float = (pc * cos + pd * sin) / skeleton.scaleY;
            var s:Float = cast(Math.sqrt(za * za + zc * zc), Float);
            if (s > 0.00001) s = 1 / s;
            za *= s;
            zc *= s;
            s = cast(Math.sqrt(za * za + zc * zc), Float);
            if (data.transformMode == TransformMode.noScale
                && (pa * pd - pb * pc < 0) != ((skeleton.scaleX < 0) != (skeleton.scaleY < 0))) s = -s;
            var r:Float = PI / 2 + atan2(zc, za);
            var zb:Float = Math.cos(r) * s;
            var zd:Float = Math.sin(r) * s;
            var la:Float = cosDeg(shearX) * scaleX;
            var lb:Float = cosDeg(90 + shearY) * scaleY;
            var lc:Float = sinDeg(shearX) * scaleX;
            var ld:Float = sinDeg(90 + shearY) * scaleY;
            a = za * la + zb * lc;
            b = za * lb + zb * ld;
            c = zc * la + zd * lc;
            d = zc * lb + zd * ld;
            break;
        }
        } break; }
        a *= skeleton.scaleX;
        b *= skeleton.scaleX;
        c *= skeleton.scaleY;
        d *= skeleton.scaleY;
    }

    /** Sets this bone's local transform to the setup pose. */
    #if !spine_no_inline inline #end public function setToSetupPose():Void {
        var data:BoneData = this.data;
        x = data.x;
        y = data.y;
        rotation = data.rotation;
        scaleX = data.scaleX;
        scaleY = data.scaleY;
        shearX = data.shearX;
        shearY = data.shearY;
    }

    /** The bone's setup pose data. */
    #if !spine_no_inline inline #end public function getData():BoneData {
        return data;
    }

    /** The skeleton this bone belongs to. */
    #if !spine_no_inline inline #end public function getSkeleton():Skeleton {
        return skeleton;
    }

    /** The parent bone, or null if this is the root bone. */
    #if !spine_no_inline inline #end public function getParent():Bone {
        return parent;
    }

    /** The immediate children of this bone. */
    #if !spine_no_inline inline #end public function getChildren():Array<Bone> {
        return children;
    }

    // -- Local transform

    /** The local x translation. */
    #if !spine_no_inline inline #end public function getX():Float {
        return x;
    }

    #if !spine_no_inline inline #end public function setX(x:Float):Void {
        this.x = x;
    }

    /** The local y translation. */
    #if !spine_no_inline inline #end public function getY():Float {
        return y;
    }

    #if !spine_no_inline inline #end public function setY(y:Float):Void {
        this.y = y;
    }

    #if !spine_no_inline inline #end public function setPosition(x:Float, y:Float):Void {
        this.x = x;
        this.y = y;
    }

    /** The local rotation. */
    #if !spine_no_inline inline #end public function getRotation():Float {
        return rotation;
    }

    #if !spine_no_inline inline #end public function setRotation(rotation:Float):Void {
        this.rotation = rotation;
    }

    /** The local scaleX. */
    #if !spine_no_inline inline #end public function getScaleX():Float {
        return scaleX;
    }

    #if !spine_no_inline inline #end public function setScaleX(scaleX:Float):Void {
        this.scaleX = scaleX;
    }

    /** The local scaleY. */
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

    #if !spine_no_inline inline #end public function setScale2(scale:Float):Void {
        scaleX = scale;
        scaleY = scale;
    }

    /** The local shearX. */
    #if !spine_no_inline inline #end public function getShearX():Float {
        return shearX;
    }

    #if !spine_no_inline inline #end public function setShearX(shearX:Float):Void {
        this.shearX = shearX;
    }

    /** The local shearY. */
    #if !spine_no_inline inline #end public function getShearY():Float {
        return shearY;
    }

    #if !spine_no_inline inline #end public function setShearY(shearY:Float):Void {
        this.shearY = shearY;
    }

    // -- Applied transform

    /** The applied local x translation. */
    #if !spine_no_inline inline #end public function getAX():Float {
        return ax;
    }

    #if !spine_no_inline inline #end public function setAX(ax:Float):Void {
        this.ax = ax;
    }

    /** The applied local y translation. */
    #if !spine_no_inline inline #end public function getAY():Float {
        return ay;
    }

    #if !spine_no_inline inline #end public function setAY(ay:Float):Void {
        this.ay = ay;
    }

    /** The applied local rotation. */
    #if !spine_no_inline inline #end public function getARotation():Float {
        return arotation;
    }

    #if !spine_no_inline inline #end public function setARotation(arotation:Float):Void {
        this.arotation = arotation;
    }

    /** The applied local scaleX. */
    #if !spine_no_inline inline #end public function getAScaleX():Float {
        return ascaleX;
    }

    #if !spine_no_inline inline #end public function setAScaleX(ascaleX:Float):Void {
        this.ascaleX = ascaleX;
    }

    /** The applied local scaleY. */
    #if !spine_no_inline inline #end public function getAScaleY():Float {
        return ascaleY;
    }

    #if !spine_no_inline inline #end public function setAScaleY(ascaleY:Float):Void {
        this.ascaleY = ascaleY;
    }

    /** The applied local shearX. */
    #if !spine_no_inline inline #end public function getAShearX():Float {
        return ashearX;
    }

    #if !spine_no_inline inline #end public function setAShearX(ashearX:Float):Void {
        this.ashearX = ashearX;
    }

    /** The applied local shearY. */
    #if !spine_no_inline inline #end public function getAShearY():Float {
        return ashearY;
    }

    #if !spine_no_inline inline #end public function setAShearY(ashearY:Float):Void {
        this.ashearY = ashearY;
    }

    /** If true, the applied transform matches the world transform. If false, the world transform has been modified since it was
     * computed and {@link #updateAppliedTransform()} must be called before accessing the applied transform. */
    #if !spine_no_inline inline #end public function isAppliedValid():Bool {
        return appliedValid;
    }

    #if !spine_no_inline inline #end public function setAppliedValid(appliedValid:Bool):Void {
        this.appliedValid = appliedValid;
    }

    /** Computes the applied transform values from the world transform. This allows the applied transform to be accessed after the
     * world transform has been modified (by a constraint, {@link #rotateWorld(float)}, etc).
     * <p>
     * If {@link #updateWorldTransform()} has been called for a bone and {@link #isAppliedValid()} is false, then
     * {@link #updateAppliedTransform()} must be called before accessing the applied transform.
     * <p>
     * Some information is ambiguous in the world transform, such as -1,-1 scale versus 180 rotation. The applied transform after
     * calling this method is equivalent to the local tranform used to compute the world transform, but may not be identical. */
    #if !spine_no_inline inline #end public function updateAppliedTransform():Void {
        appliedValid = true;
        var parent:Bone = this.parent;
        if (parent == null) {
            ax = worldX;
            ay = worldY;
            arotation = atan2(c, a) * radDeg;
            ascaleX = cast(Math.sqrt(a * a + c * c), Float);
            ascaleY = cast(Math.sqrt(b * b + d * d), Float);
            ashearX = 0;
            ashearY = atan2(a * b + c * d, a * d - b * c) * radDeg;
            return;
        }
        var pa:Float = parent.a; var pb:Float = parent.b; var pc:Float = parent.c; var pd:Float = parent.d;
        var pid:Float = 1 / (pa * pd - pb * pc);
        var dx:Float = worldX - parent.worldX; var dy:Float = worldY - parent.worldY;
        ax = (dx * pd * pid - dy * pb * pid);
        ay = (dy * pa * pid - dx * pc * pid);
        var ia:Float = pid * pd;
        var id:Float = pid * pa;
        var ib:Float = pid * pb;
        var ic:Float = pid * pc;
        var ra:Float = ia * a - ib * c;
        var rb:Float = ia * b - ib * d;
        var rc:Float = id * c - ic * a;
        var rd:Float = id * d - ic * b;
        ashearX = 0;
        ascaleX = cast(Math.sqrt(ra * ra + rc * rc), Float);
        if (ascaleX > 0.0001) {
            var det:Float = ra * rd - rb * rc;
            ascaleY = det / ascaleX;
            ashearY = atan2(ra * rb + rc * rd, det) * radDeg;
            arotation = atan2(rc, ra) * radDeg;
        } else {
            ascaleX = 0;
            ascaleY = cast(Math.sqrt(rb * rb + rd * rd), Float);
            ashearY = 0;
            arotation = 90 - atan2(rd, rb) * radDeg;
        }
    }

    // -- World transform

    /** Part of the world transform matrix for the X axis. If changed, {@link #setAppliedValid(boolean)} should be set to false. */
    #if !spine_no_inline inline #end public function getA():Float {
        return a;
    }

    #if !spine_no_inline inline #end public function setA(a:Float):Void {
        this.a = a;
    }

    /** Part of the world transform matrix for the Y axis. If changed, {@link #setAppliedValid(boolean)} should be set to false. */
    #if !spine_no_inline inline #end public function getB():Float {
        return b;
    }

    #if !spine_no_inline inline #end public function setB(b:Float):Void {
        this.b = b;
    }

    /** Part of the world transform matrix for the X axis. If changed, {@link #setAppliedValid(boolean)} should be set to false. */
    #if !spine_no_inline inline #end public function getC():Float {
        return c;
    }

    #if !spine_no_inline inline #end public function setC(c:Float):Void {
        this.c = c;
    }

    /** Part of the world transform matrix for the Y axis. If changed, {@link #setAppliedValid(boolean)} should be set to false. */
    #if !spine_no_inline inline #end public function getD():Float {
        return d;
    }

    #if !spine_no_inline inline #end public function setD(d:Float):Void {
        this.d = d;
    }

    /** The world X position. If changed, {@link #setAppliedValid(boolean)} should be set to false. */
    #if !spine_no_inline inline #end public function getWorldX():Float {
        return worldX;
    }

    #if !spine_no_inline inline #end public function setWorldX(worldX:Float):Void {
        this.worldX = worldX;
    }

    /** The world Y position. If changed, {@link #setAppliedValid(boolean)} should be set to false. */
    #if !spine_no_inline inline #end public function getWorldY():Float {
        return worldY;
    }

    #if !spine_no_inline inline #end public function setWorldY(worldY:Float):Void {
        this.worldY = worldY;
    }

    /** The world rotation for the X axis, calculated using {@link #a} and {@link #c}. */
    #if !spine_no_inline inline #end public function getWorldRotationX():Float {
        return atan2(c, a) * radDeg;
    }

    /** The world rotation for the Y axis, calculated using {@link #b} and {@link #d}. */
    #if !spine_no_inline inline #end public function getWorldRotationY():Float {
        return atan2(d, b) * radDeg;
    }

    /** The magnitude (always positive) of the world scale X, calculated using {@link #a} and {@link #c}. */
    #if !spine_no_inline inline #end public function getWorldScaleX():Float {
        return cast(Math.sqrt(a * a + c * c), Float);
    }

    /** The magnitude (always positive) of the world scale Y, calculated using {@link #b} and {@link #d}. */
    #if !spine_no_inline inline #end public function getWorldScaleY():Float {
        return cast(Math.sqrt(b * b + d * d), Float);
    }

    #if !spine_no_inline inline #end public function getWorldTransform(worldTransform:Matrix3):Matrix3 {
        if (worldTransform == null) throw new IllegalArgumentException("worldTransform cannot be null.");
        var val:FloatArray = worldTransform.val;
        val[M00] = a;
        val[M01] = b;
        val[M10] = c;
        val[M11] = d;
        val[M02] = worldX;
        val[M12] = worldY;
        val[M20] = 0;
        val[M21] = 0;
        val[M22] = 1;
        return worldTransform;
    }

    /** Transforms a point from world coordinates to the bone's local coordinates. */
    #if !spine_no_inline inline #end public function worldToLocal(world:Vector2):Vector2 {
        var invDet:Float = 1 / (a * d - b * c);
        var x:Float = world.x - worldX; var y:Float = world.y - worldY;
        world.x = x * d * invDet - y * b * invDet;
        world.y = y * a * invDet - x * c * invDet;
        return world;
    }

    /** Transforms a point from the bone's local coordinates to world coordinates. */
    #if !spine_no_inline inline #end public function localToWorld(local:Vector2):Vector2 {
        var x:Float = local.x; var y:Float = local.y;
        local.x = x * a + y * b + worldX;
        local.y = x * c + y * d + worldY;
        return local;
    }

    /** Transforms a world rotation to a local rotation. */
    #if !spine_no_inline inline #end public function worldToLocalRotation(worldRotation:Float):Float {
        var sin:Float = sinDeg(worldRotation); var cos:Float = cosDeg(worldRotation);
        return atan2(a * sin - c * cos, d * cos - b * sin) * radDeg + rotation - shearX;
    }

    /** Transforms a local rotation to a world rotation. */
    #if !spine_no_inline inline #end public function localToWorldRotation(localRotation:Float):Float {
        localRotation -= rotation - shearX;
        var sin:Float = sinDeg(localRotation); var cos:Float = cosDeg(localRotation);
        return atan2(cos * c + sin * d, cos * a + sin * b) * radDeg;
    }

    /** Rotates the world transform the specified amount and sets {@link #isAppliedValid()} to false.
     * {@link #updateWorldTransform()} will need to be called on any child bones, recursively, and any constraints reapplied. */
    #if !spine_no_inline inline #end public function rotateWorld(degrees:Float):Void {
        var cos:Float = cosDeg(degrees); var sin:Float = sinDeg(degrees);
        a = cos * a - sin * c;
        b = cos * b - sin * d;
        c = sin * a + cos * c;
        d = sin * b + cos * d;
        appliedValid = false;
    }

    // ---

    #if !spine_no_inline inline #end public function toString():String {
        return data.name;
    }
}
