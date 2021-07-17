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

import spine.support.utils.Array;

/** Stores the current pose for an IK constraint. An IK constraint adjusts the rotation of 1 or 2 constrained bones so the tip of
 * the last bone is as close to the target bone as possible.
 * <p>
 * See <a href="http://esotericsoftware.com/spine-ik-constraints">IK constraints</a> in the Spine User Guide. */
class IkConstraint implements Updatable {
    public var data:IkConstraintData;
    public var bones:Array<Bone>;
    public var target:Bone;
    public var bendDirection:Int = 0;
    public var compress:Bool = false; public var stretch:Bool = false;
    public var mix:Float = 1; public var softness:Float = 0;

    public var active:Bool = false;

    public function new(data:IkConstraintData, skeleton:Skeleton) {
        if (data == null) throw new IllegalArgumentException("data cannot be null.");
        if (skeleton == null) throw new IllegalArgumentException("skeleton cannot be null.");
        this.data = data;
        mix = data.mix;
        softness = data.softness;
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
        softness = constraint.softness;
        bendDirection = constraint.bendDirection;
        compress = constraint.compress;
        stretch = constraint.stretch;
    }*/

    /** Applies the constraint to the constrained bones. */
    #if !spine_no_inline inline #end public function update():Void {
        if (mix == 0) return;
        var target:Bone = this.target;
        var bones = this.bones.items;
        var _continueAfterSwitch0 = false; while(true) { var _switchCond0 = (this.bones.size); {
        if (_switchCond0 == 1) {
            applyOne(fastCast(bones[0], Bone), target.worldX, target.worldY, compress, stretch, data.uniform, mix);
            break;
        } else if (_switchCond0 == 2) {
            apply(fastCast(bones[0], Bone), fastCast(bones[1], Bone), target.worldX, target.worldY, bendDirection, stretch, data.uniform, softness, mix);
            break;
        } } break; }
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
        if (target == null) throw new IllegalArgumentException("target cannot be null.");
        this.target = target;
    }

    /** A percentage (0-1) that controls the mix between the constrained and unconstrained rotation.
     * <p>
     * For two bone IK: if the parent bone has local nonuniform scale, the child bone's local Y translation is set to 0. */
    #if !spine_no_inline inline #end public function getMix():Float {
        return mix;
    }

    #if !spine_no_inline inline #end public function setMix(mix:Float):Void {
        this.mix = mix;
    }

    /** For two bone IK, the target bone's distance from the maximum reach of the bones where rotation begins to slow. The bones
     * will not straighten completely until the target is this far out of range. */
    #if !spine_no_inline inline #end public function getSoftness():Float {
        return softness;
    }

    #if !spine_no_inline inline #end public function setSoftness(softness:Float):Void {
        this.softness = softness;
    }

    /** For two bone IK, controls the bend direction of the IK bones, either 1 or -1. */
    #if !spine_no_inline inline #end public function getBendDirection():Int {
        return bendDirection;
    }

    #if !spine_no_inline inline #end public function setBendDirection(bendDirection:Int):Void {
        this.bendDirection = bendDirection;
    }

    /** For one bone IK, when true and the target is too close, the bone is scaled to reach it. */
    #if !spine_no_inline inline #end public function getCompress():Bool {
        return compress;
    }

    #if !spine_no_inline inline #end public function setCompress(compress:Bool):Void {
        this.compress = compress;
    }

    /** When true and the target is out of range, the parent bone is scaled to reach it.
     * <p>
     * For two bone IK: 1) the child bone's local Y translation is set to 0, 2) stretch is not applied if {@link #getSoftness()} is
     * > 0, and 3) if the parent bone has local nonuniform scale, stretch is not applied. */
    #if !spine_no_inline inline #end public function getStretch():Bool {
        return stretch;
    }

    #if !spine_no_inline inline #end public function setStretch(stretch:Bool):Void {
        this.stretch = stretch;
    }

    #if !spine_no_inline inline #end public function isActive():Bool {
        return active;
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
        if (bone == null) throw new IllegalArgumentException("bone cannot be null.");
        var p:Bone = bone.parent;
        var pa:Float = p.a; var pb:Float = p.b; var pc:Float = p.c; var pd:Float = p.d;
        var rotationIK:Float = -bone.ashearX - bone.arotation; var tx:Float = 0; var ty:Float = 0;
        var _continueAfterSwitch1 = false; while(true) { var _switchCond1 = (bone.data.transformMode); {
        if (_switchCond1 == onlyTranslation) {
            tx = targetX - bone.worldX;
            ty = targetY - bone.worldY;
            break;
        } else if (_switchCond1 == noRotationOrReflection) {
            var s:Float = Math.abs(pa * pd - pb * pc) / (pa * pa + pc * pc);
            var sa:Float = pa / bone.skeleton.scaleX;
            var sc:Float = pc / bone.skeleton.scaleY;
            pb = -sc * s * bone.skeleton.scaleX;
            pd = sa * s * bone.skeleton.scaleY;
            rotationIK += atan2(sc, sa) * radDeg;
            // Fall through.
            var x:Float = targetX - p.worldX; var y:Float = targetY - p.worldY;
            var d:Float = pa * pd - pb * pc;
            tx = (x * pd - y * pb) / d - bone.ax;
            ty = (y * pa - x * pc) / d - bone.ay;
        } else {
            var x:Float = targetX - p.worldX; var y:Float = targetY - p.worldY;
            var d:Float = pa * pd - pb * pc;
            tx = (x * pd - y * pb) / d - bone.ax;
            ty = (y * pa - x * pc) / d - bone.ay;
        } } break; }
        rotationIK += atan2(ty, tx) * radDeg;
        if (bone.ascaleX < 0) rotationIK += 180;
        if (rotationIK > 180)
            rotationIK -= 360;
        else if (rotationIK < -180) //
            rotationIK += 360;
        var sx:Float = bone.ascaleX; var sy:Float = bone.ascaleY;
        if (compress || stretch) {
            var _continueAfterSwitch2 = false; while(true) { var _switchCond2 = (bone.data.transformMode); {
            if (_switchCond2 == noScale) {
                    tx = targetX - bone.worldX;
                ty = targetY - bone.worldY;
            } else if (_switchCond2 == noScaleOrReflection) {
                tx = targetX - bone.worldX;
                ty = targetY - bone.worldY;
            } } break; }
            var b:Float = bone.data.length * sx; var dd:Float = Math.sqrt(tx * tx + ty * ty);
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
    public static function apply(parent:Bone, child:Bone, targetX:Float, targetY:Float, bendDir:Int, stretch:Bool, uniform:Bool, softness:Float, alpha:Float):Void {
        if (parent == null) throw new IllegalArgumentException("parent cannot be null.");
        if (child == null) throw new IllegalArgumentException("child cannot be null.");
        var px:Float = parent.ax; var py:Float = parent.ay; var psx:Float = parent.ascaleX; var psy:Float = parent.ascaleY; var sx:Float = psx; var sy:Float = psy; var csx:Float = child.ascaleX;
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
        if (!u || stretch) {
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
        var id:Float = 1 / (a * d - b * c); var x:Float = cwx - pp.worldX; var y:Float = cwy - pp.worldY;
        var dx:Float = (x * d - y * b) * id - px; var dy:Float = (y * a - x * c) * id - py;
        var l1:Float = Math.sqrt(dx * dx + dy * dy); var l2:Float = child.data.length * csx; var a1:Float = 0; var a2:Float = 0;
        if (l1 < 0.0001) {
            applyOne(parent, targetX, targetY, false, stretch, false, alpha);
            child.updateWorldTransformWithData(cx, cy, 0, child.ascaleX, child.ascaleY, child.ashearX, child.ashearY);
            return;
        }
        x = targetX - pp.worldX;
        y = targetY - pp.worldY;
        var tx:Float = (x * d - y * b) * id - px; var ty:Float = (y * a - x * c) * id - py;
        var dd:Float = tx * tx + ty * ty;
        if (softness != 0) {
            softness *= psx * (csx + 1) * 0.5;
            var td:Float = Math.sqrt(dd); var sd:Float = td - l1 - l2 * psx + softness;
            if (sd > 0) {
                var p:Float = MathUtils.min(1, Std.int(sd / (softness * 2))) - 1;
                p = (sd - softness * (1 - p * p)) / td;
                tx -= p * tx;
                ty -= p * ty;
                dd = tx * tx + ty * ty;
            }
        }
        var _gotoLabel_outer:Int; while (true) { _gotoLabel_outer = 0; 
        if (u) {
            l2 *= psx;
            var cos:Float = (dd - l1 * l1 - l2 * l2) / (2 * l1 * l2);
            if (cos < -1) {
                cos = -1;
                a2 = PI * bendDir;
            } else if (cos > 1) {
                cos = 1;
                a2 = 0;
                if (stretch) {
                    a = (Math.sqrt(dd) / (l1 + l2) - 1) * alpha + 1;
                    sx *= a;
                    if (uniform) sy *= a;
                }
            } else
                a2 = Math.acos(cos) * bendDir;
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
                var q:Float = Math.sqrt(d);
                if (c1 < 0) q = -q;
                q = -(c1 + q) * 0.5;
                var r0:Float = q / c2; var r1:Float = c / q;
                var r:Float = Math.abs(r0) < Math.abs(r1) ? r0 : r1;
                if (r * r <= dd) {
                    y = Math.sqrt(dd - r * r) * bendDir;
                    a1 = ta - atan2(y, r);
                    a2 = atan2(y / psy, (r - l1) / psx);
                    { _gotoLabel_outer = 1; break; }
                }
            }
            var minAngle:Float = PI; var minX:Float = l1 - a; var minDist:Float = minX * minX; var minY:Float = 0;
            var maxAngle:Float = 0; var maxX:Float = l1 + a; var maxDist:Float = maxX * maxX; var maxY:Float = 0;
            c = -a * l1 / (aa - bb);
            if (c >= -1 && c <= 1) {
                c = Math.acos(c);
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
            if (dd <= (minDist + maxDist) * 0.5) {
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
        else if (a1 < -180) //
            a1 += 360;
        parent.updateWorldTransformWithData(px, py, rotation + a1 * alpha, sx, sy, 0, 0);
        rotation = child.arotation;
        a2 = ((a2 + os) * radDeg - child.ashearX) * s2 + os2 - rotation;
        if (a2 > 180)
            a2 -= 360;
        else if (a2 < -180) //
            a2 += 360;
        child.updateWorldTransformWithData(cx, cy, rotation + a2 * alpha, child.ascaleX, child.ascaleY, child.ashearX, child.ashearY);
    }
}
