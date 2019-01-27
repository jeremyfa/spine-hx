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

import spine.support.utils.Array;

/** Stores the current pose for an IK constraint. An IK constraint adjusts the rotation of 1 or 2 constrained bones so the tip of
 * the last bone is as close to the target bone as possible.
 * <p>
 * See <a href="http://esotericsoftware.com/spine-ik-constraints">IK constraints</a> in the Spine User Guide. */
class IkConstraint implements Constraint {
    public var data:IkConstraintData;
    public var bones:Array<Bone>;
    public var target:Bone;
    public var bendDirection:Int = 0;
    public var compress:Bool = false; public var stretch:Bool = false;
    public var mix:Float = 1;

    public function new(data:IkConstraintData, skeleton:Skeleton) {
        if (data == null) throw new IllegalArgumentException("data cannot be null.");
        if (skeleton == null) throw new IllegalArgumentException("skeleton cannot be null.");
        this.data = data;
        mix = data.mix;
        bendDirection = data.bendDirection;
        compress = data.compress;
        stretch = data.stretch;

        bones = new Array(data.bones.size);
        for (boneData in data.bones) {
            bones.add(skeleton.findBone(boneData.name)); }
        target = skeleton.findBone(data.target.name);
    }

    /** Copy constructor. */
    /*public function new(constraint:IkConstraint, skeleton:Skeleton) {
        if (constraint == null) throw new IllegalArgumentException("constraint cannot be null.");
        if (skeleton == null) throw new IllegalArgumentException("skeleton cannot be null.");
        data = constraint.data;
        bones = new Array(constraint.bones.size);
        for (bone in constraint.bones) {
            bones.add(skeleton.bones.get(bone.data.index)); }
        target = skeleton.bones.get(constraint.target.data.index);
        mix = constraint.mix;
        bendDirection = constraint.bendDirection;
        compress = constraint.compress;
        stretch = constraint.stretch;
    }*/

    /** Applies the constraint to the constrained bones. */
    public function apply():Void {
        update();
    }

    #if !spine_no_inline inline #end public function update():Void {
        var target:Bone = this.target;
        var bones:Array<Bone> = this.bones;
        var _continueAfterSwitch0 = false; while(true) { var _switchCond0 = (bones.size); {
        if (_switchCond0 == 1) {
            applyOne(bones.first(), target.worldX, target.worldY, compress, stretch, data.uniform, mix);
            break;
        } else if (_switchCond0 == 2) {
            applyTwo(bones.first(), bones.get(1), target.worldX, target.worldY, bendDirection, stretch, mix);
            break;
        } } break; }
    }

    #if !spine_no_inline inline #end public function getOrder():Int {
        return data.order;
    }

    /** The bones that will be modified by this IK constraint. */
    #if !spine_no_inline inline #end public function getBones():Array<Bone> {
        return bones;
    }

    /** The bone that is the IK target. */
    #if !spine_no_inline inline #end public function getTarget():Bone {
        return target;
    }

    #if !spine_no_inline inline #end public function setTarget(target:Bone):Void {
        this.target = target;
    }

    /** A percentage (0-1) that controls the mix between the constrained and unconstrained rotations. */
    #if !spine_no_inline inline #end public function getMix():Float {
        return mix;
    }

    #if !spine_no_inline inline #end public function setMix(mix:Float):Void {
        this.mix = mix;
    }

    /** Controls the bend direction of the IK bones, either 1 or -1. */
    #if !spine_no_inline inline #end public function getBendDirection():Int {
        return bendDirection;
    }

    #if !spine_no_inline inline #end public function setBendDirection(bendDirection:Int):Void {
        this.bendDirection = bendDirection;
    }

    /** When true and only a single bone is being constrained, if the target is too close, the bone is scaled to reach it. */
    #if !spine_no_inline inline #end public function getCompress():Bool {
        return compress;
    }

    #if !spine_no_inline inline #end public function setCompress(compress:Bool):Void {
        this.compress = compress;
    }

    /** When true, if the target is out of range, the parent bone is scaled to reach it. If more than one bone is being constrained
     * and the parent bone has local nonuniform scale, stretch is not applied. */
    #if !spine_no_inline inline #end public function getStretch():Bool {
        return stretch;
    }

    #if !spine_no_inline inline #end public function setStretch(stretch:Bool):Void {
        this.stretch = stretch;
    }

    /** The IK constraint's setup pose data. */
    #if !spine_no_inline inline #end public function getData():IkConstraintData {
        return data;
    }

    #if !spine_no_inline inline #end public function toString():String {
        return data.name;
    }

    /** Applies 1 bone IK. The target is specified in the world coordinate system. */
    public static function applyOne(bone:Bone, targetX:Float, targetY:Float, compress:Bool, stretch:Bool, uniform:Bool, alpha:Float):Void {
        if (!bone.appliedValid) bone.updateAppliedTransform();
        var p:Bone = bone.parent;
        var id:Float = 1 / (p.a * p.d - p.b * p.c);
        var x:Float = targetX - p.worldX; var y:Float = targetY - p.worldY;
        var tx:Float = (x * p.d - y * p.b) * id - bone.ax; var ty:Float = (y * p.a - x * p.c) * id - bone.ay;
        var rotationIK:Float = atan2(ty, tx) * radDeg - bone.ashearX - bone.arotation;
        if (bone.ascaleX < 0) rotationIK += 180;
        if (rotationIK > 180)
            rotationIK -= 360;
        else if (rotationIK < -180) //
            rotationIK += 360;
        var sx:Float = bone.ascaleX; var sy:Float = bone.ascaleY;
        if (compress || stretch) {
            var b:Float = bone.data.length * sx; var dd:Float = cast(Math.sqrt(tx * tx + ty * ty), Float);
            if ((compress && dd < b) || (stretch && dd > b) && b > 0.0001) {
                var s:Float = (dd / b - 1) * alpha + 1;
                sx *= s;
                if (uniform) sy *= s;
            }
        }
        bone.updateWorldTransformWithData(bone.ax, bone.ay, bone.arotation + rotationIK * alpha, sx, sy, bone.ashearX, bone.ashearY);
    }

    /** Applies 2 bone IK. The target is specified in the world coordinate system.
     * @param child A direct descendant of the parent bone. */
    public static function applyTwo(parent:Bone, child:Bone, targetX:Float, targetY:Float, bendDir:Int, stretch:Bool, alpha:Float):Void {
        if (alpha == 0) {
            child.updateWorldTransform();
            return;
        }
        if (!parent.appliedValid) parent.updateAppliedTransform();
        if (!child.appliedValid) child.updateAppliedTransform();
        var px:Float = parent.ax; var py:Float = parent.ay; var psx:Float = parent.ascaleX; var sx:Float = psx; var psy:Float = parent.ascaleY; var csx:Float = child.ascaleX;
        var os1:Int = 0; var os2:Int = 0; var s2:Int = 0;
        if (psx < 0) {
            psx = -psx;
            os1 = 180;
            s2 = -1;
        } else {
            os1 = 0;
            s2 = 1;
        }
        if (psy < 0) {
            psy = -psy;
            s2 = -s2;
        }
        if (csx < 0) {
            csx = -csx;
            os2 = 180;
        } else
            os2 = 0;
        var cx:Float = child.ax; var cy:Float = 0; var cwx:Float = 0; var cwy:Float = 0; var a:Float = parent.a; var b:Float = parent.b; var c:Float = parent.c; var d:Float = parent.d;
        var u:Bool = Math.abs(psx - psy) <= 0.0001;
        if (!u) {
            cy = 0;
            cwx = a * cx + parent.worldX;
            cwy = c * cx + parent.worldY;
        } else {
            cy = child.ay;
            cwx = a * cx + b * cy + parent.worldX;
            cwy = c * cx + d * cy + parent.worldY;
        }
        var pp:Bone = parent.parent;
        a = pp.a;
        b = pp.b;
        c = pp.c;
        d = pp.d;
        var id:Float = 1 / (a * d - b * c); var x:Float = targetX - pp.worldX; var y:Float = targetY - pp.worldY;
        var tx:Float = (x * d - y * b) * id - px; var ty:Float = (y * a - x * c) * id - py; var dd:Float = tx * tx + ty * ty;
        x = cwx - pp.worldX;
        y = cwy - pp.worldY;
        var dx:Float = (x * d - y * b) * id - px; var dy:Float = (y * a - x * c) * id - py;
        var l1:Float = cast(Math.sqrt(dx * dx + dy * dy), Float); var l2:Float = child.data.length * csx; var a1:Float = 0; var a2:Float = 0;
        var _gotoLabel_outer:Int; while (true) { _gotoLabel_outer = 0; 
        if (u) {
            l2 *= psx;
            var cos:Float = (dd - l1 * l1 - l2 * l2) / (2 * l1 * l2);
            if (cos < -1)
                cos = -1;
            else if (cos > 1) {
                cos = 1;
                if (stretch && l1 + l2 > 0.0001) sx *= (cast(Math.sqrt(dd) / (l1 + l2) - 1, Float)) * alpha + 1;
            }
            a2 = cast(Math.acos(cos) * bendDir, Float);
            a = l1 + l2 * cos;
            b = l2 * sin(a2);
            a1 = atan2(ty * a - tx * b, tx * a + ty * b);
        } else {
            a = psx * l2;
            b = psy * l2;
            var aa:Float = a * a; var bb:Float = b * b; var ta:Float = atan2(ty, tx);
            c = bb * l1 * l1 + aa * dd - aa * bb;
            var c1:Float = -2 * bb * l1; var c2:Float = bb - aa;
            d = c1 * c1 - 4 * c2 * c;
            if (d >= 0) {
                var q:Float = cast(Math.sqrt(d), Float);
                if (c1 < 0) q = -q;
                q = -(c1 + q) / 2;
                var r0:Float = q / c2; var r1:Float = c / q;
                var r:Float = Math.abs(r0) < Math.abs(r1) ? r0 : r1;
                if (r * r <= dd) {
                    y = cast(Math.sqrt(dd - r * r) * bendDir, Float);
                    a1 = ta - atan2(y, r);
                    a2 = atan2(y / psy, (r - l1) / psx);
                    { _gotoLabel_outer = 1; break; }
                }
            }
            var minAngle:Float = PI; var minX:Float = l1 - a; var minDist:Float = minX * minX; var minY:Float = 0;
            var maxAngle:Float = 0; var maxX:Float = l1 + a; var maxDist:Float = maxX * maxX; var maxY:Float = 0;
            c = -a * l1 / (aa - bb);
            if (c >= -1 && c <= 1) {
                c = cast(Math.acos(c), Float);
                x = a * cos(c) + l1;
                y = b * sin(c);
                d = x * x + y * y;
                if (d < minDist) {
                    minAngle = c;
                    minDist = d;
                    minX = x;
                    minY = y;
                }
                if (d > maxDist) {
                    maxAngle = c;
                    maxDist = d;
                    maxX = x;
                    maxY = y;
                }
            }
            if (dd <= (minDist + maxDist) / 2) {
                a1 = ta - atan2(minY * bendDir, minX);
                a2 = minAngle * bendDir;
            } else {
                a1 = ta - atan2(maxY * bendDir, maxX);
                a2 = maxAngle * bendDir;
            }
        } if (_gotoLabel_outer == 0) break; }
        var os:Float = atan2(cy, cx) * s2;
        var rotation:Float = parent.arotation;
        a1 = (a1 - os) * radDeg + os1 - rotation;
        if (a1 > 180)
            a1 -= 360;
        else if (a1 < -180) a1 += 360;
        parent.updateWorldTransformWithData(px, py, rotation + a1 * alpha, sx, parent.ascaleY, 0, 0);
        rotation = child.arotation;
        a2 = ((a2 + os) * radDeg - child.ashearX) * s2 + os2 - rotation;
        if (a2 > 180)
            a2 -= 360;
        else if (a2 < -180) a2 += 360;
        child.updateWorldTransformWithData(cx, cy, rotation + a2 * alpha, child.ascaleX, child.ascaleY, child.ashearX, child.ashearY);
    }
}
