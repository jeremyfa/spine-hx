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



import spine.support.utils.Array;
import spine.support.utils.FloatArray;

import spine.PathConstraintData.PositionMode;
import spine.PathConstraintData.PositionMode_enum;
import spine.PathConstraintData.RotateMode;
import spine.PathConstraintData.RotateMode_enum;
import spine.PathConstraintData.SpacingMode;
import spine.PathConstraintData.SpacingMode_enum;
import spine.attachments.Attachment;
import spine.attachments.PathAttachment;
import spine.utils.SpineUtils;

/** Stores the current pose for a path constraint. A path constraint adjusts the rotation, translation, and scale of the
 * constrained bones so they follow a {@link PathAttachment}.
 * <p>
 * See <a href="http://esotericsoftware.com/spine-path-constraints">Path constraints</a> in the Spine User Guide. */
class PathConstraint implements Updatable {
    inline private static var NONE:Int = -1; inline private static var BEFORE:Int = -2; inline private static var AFTER:Int = -3;
    private static var epsilon:Float = 0.00001;

    public var data:PathConstraintData;
    public var bones:Array<Bone>;
    public var target:Slot;
    public var position:Float = 0; public var spacing:Float = 0; public var mixRotate:Float = 0; public var mixX:Float = 0; public var mixY:Float = 0;

    public var active:Bool = false;

    private var spaces:FloatArray = new FloatArray(); private var positions:FloatArray = new FloatArray();
    private var world:FloatArray = new FloatArray(); private var curves:FloatArray = new FloatArray(); private var lengths:FloatArray = new FloatArray();
    private var segments:FloatArray = FloatArray.create(10);

    public function new(data:PathConstraintData, skeleton:Skeleton) {
        if (data == null) throw new IllegalArgumentException("data cannot be null.");
        if (skeleton == null) throw new IllegalArgumentException("skeleton cannot be null.");
        this.data = data;
        bones = new Array(data.bones.size);
        for (boneData in data.bones) {
            bones.add(skeleton.findBone(boneData.name)); }
        target = skeleton.findSlot(data.target.name);
        position = data.position;
        spacing = data.spacing;
        mixRotate = data.mixRotate;
        mixX = data.mixX;
        mixY = data.mixY;
    }

    /** Copy constructor. */
    /*public function new(constraint:PathConstraint, skeleton:Skeleton) {
        if (constraint == null) throw new IllegalArgumentException("constraint cannot be null.");
        if (skeleton == null) throw new IllegalArgumentException("skeleton cannot be null.");
        data = constraint.data;
        bones = new Array(constraint.bones.size);
        for (bone in constraint.bones) {
            bones.add(skeleton.bones.get(bone.data.index)); }
        target = skeleton.slots.get(constraint.target.data.index);
        position = constraint.position;
        spacing = constraint.spacing;
        mixRotate = constraint.mixRotate;
        mixX = constraint.mixX;
        mixY = constraint.mixY;
    }*/

    /** Applies the constraint to the constrained bones. */
    #if !spine_no_inline inline #end public function update():Void {
        var attachment:Attachment = target.attachment;
        if (!(#if (haxe_ver >= 4.0) Std.isOfType #else Std.is #end(attachment, PathAttachment))) return;

        var mixRotate:Float = this.mixRotate; var mixX:Float = this.mixX; var mixY:Float = this.mixY;
        if (mixRotate == 0 && mixX == 0 && mixY == 0) return;

        var data:PathConstraintData = this.data;
        var tangents:Bool = data.rotateMode == RotateMode.tangent; var scale:Bool = data.rotateMode == RotateMode.chainScale;
        var boneCount:Int = this.bones.size; var spacesCount:Int = tangents ? boneCount : boneCount + 1;
        var bones = this.bones.items;
        var spaces:FloatArray = this.spaces.setSize(spacesCount); var lengths:FloatArray = scale ? this.lengths.setSize(boneCount) : null;
        var spacing:Float = this.spacing;

        var _continueAfterSwitch0 = false; while(true) { var _switchCond0 = (data.spacingMode); {
        if (_switchCond0 == percent) {
            if (scale) {
                var i:Int = 0; var n:Int = spacesCount - 1; while (i < n) {
                    var bone:Bone = fastCast(bones[i], Bone);
                    var setupLength:Float = bone.data.length;
                    if (setupLength < epsilon)
                        lengths[i] = 0;
                    else {
                        var x:Float = setupLength * bone.a; var y:Float = setupLength * bone.c;
                        lengths[i] = Math.sqrt(x * x + y * y);
                    }
                i++; }
            }
            FloatArray.fill(spaces, 1, spacesCount, spacing);
            break;
        } else if (_switchCond0 == proportional) {
            var sum:Float = 0;
            var i:Int = 0; var n:Int = spacesCount - 1; while (i < n) {
                var bone:Bone = fastCast(bones[i], Bone);
                var setupLength:Float = bone.data.length;
                if (setupLength < epsilon) {
                    if (scale) lengths[i] = 0;
                    spaces[++i] = spacing;
                } else {
                    var x:Float = setupLength * bone.a; var y:Float = setupLength * bone.c;
                    var length:Float = Math.sqrt(x * x + y * y);
                    if (scale) lengths[i] = length;
                    spaces[++i] = length;
                    sum += length;
                }
            }
            if (sum > 0) {
                sum = spacesCount / sum * spacing;
                var i:Int = 1; while (i < spacesCount) {
                    spaces[i] *= sum; i++; }
            }
            break;
        } else {
            var lengthSpacing:Bool = data.spacingMode == SpacingMode.length;
            var i:Int = 0; var n:Int = spacesCount - 1; while (i < n) {
                var bone:Bone = fastCast(bones[i], Bone);
                var setupLength:Float = bone.data.length;
                if (setupLength < epsilon) {
                    if (scale) lengths[i] = 0;
                    spaces[++i] = spacing;
                } else {
                    var x:Float = setupLength * bone.a; var y:Float = setupLength * bone.c;
                    var length:Float = Math.sqrt(x * x + y * y);
                    if (scale) lengths[i] = length;
                    spaces[++i] = (lengthSpacing ? setupLength + spacing : spacing) * length / setupLength;
                }
            }
        } } break; }

        var positions:FloatArray = computeWorldPositions(fastCast(attachment, PathAttachment), spacesCount, tangents);
        var boneX:Float = positions[0]; var boneY:Float = positions[1]; var offsetRotation:Float = data.offsetRotation;
        var tip:Bool = false;
        if (offsetRotation == 0)
            tip = data.rotateMode == RotateMode.chain;
        else {
            tip = false;
            var p:Bone = target.bone;
            offsetRotation *= p.a * p.d - p.b * p.c > 0 ? SpineUtils.degRad : -SpineUtils.degRad;
        }
        var i:Int = 0; var p:Int = 3; while (i < boneCount) {
            var bone:Bone = fastCast(bones[i], Bone);
            bone.worldX += (boneX - bone.worldX) * mixX;
            bone.worldY += (boneY - bone.worldY) * mixY;
            var x:Float = positions[p]; var y:Float = positions[p + 1]; var dx:Float = x - boneX; var dy:Float = y - boneY;
            if (scale) {
                var length:Float = lengths[i];
                if (length >= epsilon) {
                    var s:Float = (Math.sqrt(dx * dx + dy * dy) / length - 1) * mixRotate + 1;
                    bone.a *= s;
                    bone.c *= s;
                }
            }
            boneX = x;
            boneY = y;
            if (mixRotate > 0) {
                var a:Float = bone.a; var b:Float = bone.b; var c:Float = bone.c; var d:Float = bone.d; var r:Float = 0; var cos:Float = 0; var sin:Float = 0;
                if (tangents)
                    r = positions[p - 1];
                else if (spaces[i + 1] < epsilon)
                    r = positions[p + 2];
                else
                    r = Math.atan2(dy, dx);
                r -= Math.atan2(c, a);
                if (tip) {
                    cos = Math.cos(r);
                    sin = Math.sin(r);
                    var length:Float = bone.data.length;
                    boneX += (length * (cos * a - sin * c) - dx) * mixRotate;
                    boneY += (length * (sin * a + cos * c) - dy) * mixRotate;
                } else
                    r += offsetRotation;
                if (r > SpineUtils.PI)
                    r -= SpineUtils.PI2;
                else if (r < -SpineUtils.PI) //
                    r += SpineUtils.PI2;
                r *= mixRotate;
                cos = Math.cos(r);
                sin = Math.sin(r);
                bone.a = cos * a - sin * c;
                bone.b = cos * b - sin * d;
                bone.c = sin * a + cos * c;
                bone.d = sin * b + cos * d;
            }
            bone.updateAppliedTransform();
        i++; p += 3; }
    }

    #if !spine_no_inline inline #end public function computeWorldPositions(path:PathAttachment, spacesCount:Int, tangents:Bool):FloatArray {
        var target:Slot = this.target;
        var position:Float = this.position;
        var spaces:FloatArray = this.spaces.items; var out:FloatArray = this.positions.setSize(spacesCount * 3 + 2); var world:FloatArray = null;
        var closed:Bool = path.getClosed();
        var verticesLength:Int = path.getWorldVerticesLength(); var curveCount:Int = Std.int(verticesLength / 6); var prevCurve:Int = NONE;

        if (!path.getConstantSpeed()) {
            var lengths:FloatArray = path.getLengths();
            curveCount -= closed ? 1 : 2;
            var pathLength:Float = lengths[curveCount];

            if (data.positionMode == PositionMode.percent) position *= pathLength;

            var multiplier:Float = 0;
            var _continueAfterSwitch1 = false; while(true) { var _switchCond1 = (data.spacingMode); {
            if (_switchCond1 == percent) {
                multiplier = pathLength;
                break;
            } else if (_switchCond1 == proportional) {
                multiplier = pathLength / spacesCount;
                break;
            } else {
                multiplier = 1;
            } } break; }

            world = this.world.setSize(8);
            var i:Int = 0; var o:Int = 0; var curve:Int = 0; while (i < spacesCount) {
                var space:Float = spaces[i] * multiplier;
                position += space;
                var p:Float = position;

                if (closed) {
                    p %= pathLength;
                    if (p < 0) p += pathLength;
                    curve = 0;
                } else if (p < 0) {
                    if (prevCurve != BEFORE) {
                        prevCurve = BEFORE;
                        path.computeWorldVertices(target, 2, 4, world, 0, 2);
                    }
                    addBeforePosition(p, world, 0, out, o);
                    { i++; o += 3; continue; }
                } else if (p > pathLength) {
                    if (prevCurve != AFTER) {
                        prevCurve = AFTER;
                        path.computeWorldVertices(target, verticesLength - 6, 4, world, 0, 2);
                    }
                    addAfterPosition(p - pathLength, world, 0, out, o);
                    { i++; o += 3; continue; }
                }

                // Determine curve containing position.
                while (true) {
                    var length:Float = lengths[curve];
                    if (p > length) { curve++; continue; }
                    if (curve == 0)
                        p /= length;
                    else {
                        var prev:Float = lengths[curve - 1];
                        p = (p - prev) / (length - prev);
                    }
                    break;
                curve++; }
                if (curve != prevCurve) {
                    prevCurve = curve;
                    if (closed && curve == curveCount) {
                        path.computeWorldVertices(target, verticesLength - 4, 4, world, 0, 2);
                        path.computeWorldVertices(target, 0, 4, world, 4, 2);
                    } else
                        path.computeWorldVertices(target, curve * 6 + 2, 8, world, 0, 2);
                }
                addCurvePosition(p, world[0], world[1], world[2], world[3], world[4], world[5], world[6], world[7], out, o,
                    tangents || (i > 0 && space < epsilon));
            i++; o += 3; }
            return out;
        }

        // World vertices.
        if (closed) {
            verticesLength += 2;
            world = this.world.setSize(verticesLength);
            path.computeWorldVertices(target, 2, verticesLength - 4, world, 0, 2);
            path.computeWorldVertices(target, 0, 2, world, verticesLength - 4, 2);
            world[verticesLength - 2] = world[0];
            world[verticesLength - 1] = world[1];
        } else {
            curveCount--;
            verticesLength -= 4;
            world = this.world.setSize(verticesLength);
            path.computeWorldVertices(target, 2, verticesLength, world, 0, 2);
        }

        // Curve lengths.
        var curves:FloatArray = this.curves.setSize(curveCount);
        var pathLength:Float = 0;
        var x1:Float = world[0]; var y1:Float = world[1]; var cx1:Float = 0; var cy1:Float = 0; var cx2:Float = 0; var cy2:Float = 0; var x2:Float = 0; var y2:Float = 0;
        var tmpx:Float = 0; var tmpy:Float = 0; var dddfx:Float = 0; var dddfy:Float = 0; var ddfx:Float = 0; var ddfy:Float = 0; var dfx:Float = 0; var dfy:Float = 0;
        var i:Int = 0; var w:Int = 2; while (i < curveCount) {
            cx1 = world[w];
            cy1 = world[w + 1];
            cx2 = world[w + 2];
            cy2 = world[w + 3];
            x2 = world[w + 4];
            y2 = world[w + 5];
            tmpx = (x1 - cx1 * 2 + cx2) * 0.1875;
            tmpy = (y1 - cy1 * 2 + cy2) * 0.1875;
            dddfx = ((cx1 - cx2) * 3 - x1 + x2) * 0.09375;
            dddfy = ((cy1 - cy2) * 3 - y1 + y2) * 0.09375;
            ddfx = tmpx * 2 + dddfx;
            ddfy = tmpy * 2 + dddfy;
            dfx = (cx1 - x1) * 0.75 + tmpx + dddfx * 0.16666667;
            dfy = (cy1 - y1) * 0.75 + tmpy + dddfy * 0.16666667;
            pathLength += Math.sqrt(dfx * dfx + dfy * dfy);
            dfx += ddfx;
            dfy += ddfy;
            ddfx += dddfx;
            ddfy += dddfy;
            pathLength += Math.sqrt(dfx * dfx + dfy * dfy);
            dfx += ddfx;
            dfy += ddfy;
            pathLength += Math.sqrt(dfx * dfx + dfy * dfy);
            dfx += ddfx + dddfx;
            dfy += ddfy + dddfy;
            pathLength += Math.sqrt(dfx * dfx + dfy * dfy);
            curves[i] = pathLength;
            x1 = x2;
            y1 = y2;
        i++; w += 6; }

        if (data.positionMode == PositionMode.percent) position *= pathLength;

        var multiplier:Float = 0;
        var _continueAfterSwitch2 = false; while(true) { var _switchCond2 = (data.spacingMode); {
        if (_switchCond2 == percent) {
            multiplier = pathLength;
            break;
        } else if (_switchCond2 == proportional) {
            multiplier = pathLength / spacesCount;
            break;
        } else {
            multiplier = 1;
        } } break; }

        var segments:FloatArray = this.segments;
        var curveLength:Float = 0;
        var i:Int = 0; var o:Int = 0; var curve:Int = 0; var segment:Int = 0; while (i < spacesCount) {
            var space:Float = spaces[i] * multiplier;
            position += space;
            var p:Float = position;

            if (closed) {
                p %= pathLength;
                if (p < 0) p += pathLength;
                curve = 0;
            } else if (p < 0) {
                addBeforePosition(p, world, 0, out, o);
                { i++; o += 3; continue; }
            } else if (p > pathLength) {
                addAfterPosition(p - pathLength, world, verticesLength - 4, out, o);
                { i++; o += 3; continue; }
            }

            // Determine curve containing position.
            while (true) {
                var length:Float = curves[curve];
                if (p > length) { curve++; continue; }
                if (curve == 0)
                    p /= length;
                else {
                    var prev:Float = curves[curve - 1];
                    p = (p - prev) / (length - prev);
                }
                break;
            curve++; }

            // Curve segment lengths.
            if (curve != prevCurve) {
                prevCurve = curve;
                var ii:Int = curve * 6;
                x1 = world[ii];
                y1 = world[ii + 1];
                cx1 = world[ii + 2];
                cy1 = world[ii + 3];
                cx2 = world[ii + 4];
                cy2 = world[ii + 5];
                x2 = world[ii + 6];
                y2 = world[ii + 7];
                tmpx = (x1 - cx1 * 2 + cx2) * 0.03;
                tmpy = (y1 - cy1 * 2 + cy2) * 0.03;
                dddfx = ((cx1 - cx2) * 3 - x1 + x2) * 0.006;
                dddfy = ((cy1 - cy2) * 3 - y1 + y2) * 0.006;
                ddfx = tmpx * 2 + dddfx;
                ddfy = tmpy * 2 + dddfy;
                dfx = (cx1 - x1) * 0.3 + tmpx + dddfx * 0.16666667;
                dfy = (cy1 - y1) * 0.3 + tmpy + dddfy * 0.16666667;
                curveLength = Math.sqrt(dfx * dfx + dfy * dfy);
                segments[0] = curveLength;
                ii = 1; while (ii < 8) {
                    dfx += ddfx;
                    dfy += ddfy;
                    ddfx += dddfx;
                    ddfy += dddfy;
                    curveLength += Math.sqrt(dfx * dfx + dfy * dfy);
                    segments[ii] = curveLength;
                ii++; }
                dfx += ddfx;
                dfy += ddfy;
                curveLength += Math.sqrt(dfx * dfx + dfy * dfy);
                segments[8] = curveLength;
                dfx += ddfx + dddfx;
                dfy += ddfy + dddfy;
                curveLength += Math.sqrt(dfx * dfx + dfy * dfy);
                segments[9] = curveLength;
                segment = 0;
            }

            // Weight by segment length.
            p *= curveLength;
            while (true) {
                var length:Float = segments[segment];
                if (p > length) { segment++; continue; }
                if (segment == 0)
                    p /= length;
                else {
                    var prev:Float = segments[segment - 1];
                    p = segment + (p - prev) / (length - prev);
                }
                break;
            segment++; }
            addCurvePosition(p * 0.1, x1, y1, cx1, cy1, cx2, cy2, x2, y2, out, o, tangents || (i > 0 && space < epsilon));
        i++; o += 3; }
        return out;
    }

    #if !spine_no_inline inline #end private function addBeforePosition(p:Float, temp:FloatArray, i:Int, out:FloatArray, o:Int):Void {
        var x1:Float = temp[i]; var y1:Float = temp[i + 1]; var dx:Float = temp[i + 2] - x1; var dy:Float = temp[i + 3] - y1; var r:Float = Math.atan2(dy, dx);
        out[o] = x1 + p * Math.cos(r);
        out[o + 1] = y1 + p * Math.sin(r);
        out[o + 2] = r;
    }

    #if !spine_no_inline inline #end private function addAfterPosition(p:Float, temp:FloatArray, i:Int, out:FloatArray, o:Int):Void {
        var x1:Float = temp[i + 2]; var y1:Float = temp[i + 3]; var dx:Float = x1 - temp[i]; var dy:Float = y1 - temp[i + 1]; var r:Float = Math.atan2(dy, dx);
        out[o] = x1 + p * Math.cos(r);
        out[o + 1] = y1 + p * Math.sin(r);
        out[o + 2] = r;
    }

    #if !spine_no_inline inline #end private function addCurvePosition(p:Float, x1:Float, y1:Float, cx1:Float, cy1:Float, cx2:Float, cy2:Float, x2:Float, y2:Float, out:FloatArray, o:Int, tangents:Bool):Void {
        if (p < epsilon || Math.isNaN(p)) {
            out[o] = x1;
            out[o + 1] = y1;
            out[o + 2] = Math.atan2(cy1 - y1, cx1 - x1);
            return;
        }
        var tt:Float = p * p; var ttt:Float = tt * p; var u:Float = 1 - p; var uu:Float = u * u; var uuu:Float = uu * u;
        var ut:Float = u * p; var ut3:Float = ut * 3; var uut3:Float = u * ut3; var utt3:Float = ut3 * p;
        var x:Float = x1 * uuu + cx1 * uut3 + cx2 * utt3 + x2 * ttt; var y:Float = y1 * uuu + cy1 * uut3 + cy2 * utt3 + y2 * ttt;
        out[o] = x;
        out[o + 1] = y;
        if (tangents) {
            if (p < 0.001)
                out[o + 2] = Math.atan2(cy1 - y1, cx1 - x1);
            else
                out[o + 2] = Math.atan2(y - (y1 * uu + cy1 * ut * 2 + cy2 * tt), x - (x1 * uu + cx1 * ut * 2 + cx2 * tt));
        }
    }

    /** The position along the path. */
    #if !spine_no_inline inline #end public function getPosition():Float {
        return position;
    }

    #if !spine_no_inline inline #end public function setPosition(position:Float):Void {
        this.position = position;
    }

    /** The spacing between bones. */
    #if !spine_no_inline inline #end public function getSpacing():Float {
        return spacing;
    }

    #if !spine_no_inline inline #end public function setSpacing(spacing:Float):Void {
        this.spacing = spacing;
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

    /** The bones that will be modified by this path constraint. */
    #if !spine_no_inline inline #end public function getBones():Array<Bone> {
        return bones;
    }

    /** The slot whose path attachment will be used to constrained the bones. */
    #if !spine_no_inline inline #end public function getTarget():Slot {
        return target;
    }

    #if !spine_no_inline inline #end public function setTarget(target:Slot):Void {
        if (target == null) throw new IllegalArgumentException("target cannot be null.");
        this.target = target;
    }

    #if !spine_no_inline inline #end public function isActive():Bool {
        return active;
    }

    /** The path constraint's setup pose data. */
    #if !spine_no_inline inline #end public function getData():PathConstraintData {
        return data;
    }

    #if !spine_no_inline inline #end public function toString():String {
        return data.name;
    }
}
