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

import spine.Animation.MixBlend.*;
import spine.Animation.MixDirection.*;

import spine.support.graphics.Color;
import spine.support.math.MathUtils;
import spine.support.utils.Array;
import spine.support.utils.FloatArray;

import spine.attachments.Attachment;
import spine.attachments.VertexAttachment;

/** A simple container for a list of timelines and a name. */
class Animation {
    private var hashCode = Std.int(Math.random() * 99999999);

    public var name:String;
    public var timelines:Array<Timeline>;
    public var duration:Float = 0;

    public function new(name:String, timelines:Array<Timeline>, duration:Float) {
        if (name == null) throw new IllegalArgumentException("name cannot be null.");
        if (timelines == null) throw new IllegalArgumentException("timelines cannot be null.");
        this.name = name;
        this.timelines = timelines;
        this.duration = duration;
    }

    public function getTimelines():Array<Timeline> {
        return timelines;
    }

    /** The duration of the animation in seconds, which is the highest time of all keys in the timeline. */
    public function getDuration():Float {
        return duration;
    }

    public function setDuration(duration:Float):Void {
        this.duration = duration;
    }

    /** Applies all the animation's timelines to the specified skeleton.
     * <p>
     * See Timeline {@link Timeline#apply(Skeleton, float, float, Array, float, MixBlend, MixDirection)}.
     * @param loop If true, the animation repeats after {@link #getDuration()}. */
    public function apply(skeleton:Skeleton, lastTime:Float, time:Float, loop:Bool, events:Array<Event>, alpha:Float, blend:MixBlend, direction:MixDirection):Void {
        if (skeleton == null) throw new IllegalArgumentException("skeleton cannot be null.");

        if (loop && duration != 0) {
            time %= duration;
            if (lastTime > 0) lastTime %= duration;
        }

        var timelines:Array<Timeline> = this.timelines;
        var i:Int = 0; var n:Int = timelines.size; while (i < n) {
            timelines.get(i).apply(skeleton, lastTime, time, events, alpha, blend, direction); i++; }
    }

    /** The animation's name, which is unique within the skeleton. */
    public function getName():String {
        return name;
    }

    public function toString():String {
        return name;
    }

    /** @param target After the first and before the last value.
     * @return index of first value greater than the target. */
    static public function binarySearchWithStep(values:FloatArray, target:Float, step:Int):Int {
        var low:Int = 0;
        var high:Int = Std.int(values.length / step - 2);
        if (high == 0) return step;
        var current:Int = high >>> 1;
        while (true) {
            if (values[(current + 1) * step] <= target)
                low = current + 1;
            else
                high = current;
            if (low == high) return (low + 1) * step;
            current = (low + high) >>> 1;
        }
    }

    /** @param target After the first and before the last value.
     * @return index of first value greater than the target. */
    static public function binarySearch(values:FloatArray, target:Float):Int {
        var low:Int = 0;
        var high:Int = values.length - 2;
        if (high == 0) return 1;
        var current:Int = high >>> 1;
        while (true) {
            if (values[current + 1] <= target)
                low = current + 1;
            else
                high = current;
            if (low == high) return low + 1;
            current = (low + high) >>> 1;
        }
    }

    #if !spine_no_inline inline #end static public function linearSearch(values:FloatArray, target:Float, step:Int):Int {
        var i:Int = 0; var last:Int = values.length - step; while (i <= last) {
            if (values[i] > target) return i; i += step; }
        return -1;
    }
}

/** The interface for all timelines. */
interface Timeline {
    /** Applies this timeline to the skeleton.
     * @param skeleton The skeleton the timeline is being applied to. This provides access to the bones, slots, and other
     *           skeleton components the timeline may change.
     * @param lastTime The time this timeline was last applied. Timelines such as {@link EventTimeline} trigger only at specific
     *           times rather than every frame. In that case, the timeline triggers everything between <code>lastTime</code>
     *           (exclusive) and <code>time</code> (inclusive).
     * @param time The time within the animation. Most timelines find the key before and the key after this time so they can
     *           interpolate between the keys.
     * @param events If any events are fired, they are added to this list. Can be null to ignore firing events or if the
     *           timeline does not fire events.
     * @param alpha 0 applies the current or setup value (depending on <code>blend</code>). 1 applies the timeline value.
     *           Between 0 and 1 applies a value between the current or setup value and the timeline value. By adjusting
     *           <code>alpha</code> over time, an animation can be mixed in or out. <code>alpha</code> can also be useful to
     *           apply animations on top of each other (layered).
     * @param blend Controls how mixing is applied when <code>alpha</code> < 1.
     * @param direction Indicates whether the timeline is mixing in or out. Used by timelines which perform instant transitions,
     *           such as {@link DrawOrderTimeline} or {@link AttachmentTimeline}. */
    public function apply(skeleton:Skeleton, lastTime:Float, time:Float, events:Array<Event>, alpha:Float, blend:MixBlend, direction:MixDirection):Void;

    /** Uniquely encodes both the type of this timeline and the skeleton property that it affects. */
    public function getPropertyId():Int;
}

/** Controls how a timeline value is mixed with the setup pose value or current pose value.
 * <p>
 * See Timeline {@link Timeline#apply(Skeleton, float, float, Array, float, MixBlend, MixDirection)}. */
@:enum abstract MixBlend(Int) from Int to Int {
    /** Transitions from the setup value to the timeline value (the current value is not used). Before the first key, the setup
     * value is set. */
    var setup = 0;
    /** Transitions from the current value to the timeline value. Before the first key, transitions from the current value to
     * the setup value. Timelines which perform instant transitions, such as {@link DrawOrderTimeline} or
     * {@link AttachmentTimeline}, use the setup value before the first key.
     * <p>
     * <code>first</code> is intended for the first animations applied, not for animations layered on top of those. */
    var first = 1;
    /** Transitions from the current value to the timeline value. No change is made before the first key (the current value is
     * kept until the first key).
     * <p>
     * <code>replace</code> is intended for animations layered on top of others, not for the first animations applied. */
    var replace = 2;
    /** Transitions from the current value to the current value plus the timeline value. No change is made before the first key
     * (the current value is kept until the first key).
     * <p>
     * <code>add</code> is intended for animations layered on top of others, not for the first animations applied. */
    var add = 3;
}

/** Indicates whether a timeline's <code>alpha</code> is mixing out over time toward 0 (the setup or current pose value) or
 * mixing in toward 1 (the timeline's value).
 * <p>
 * See Timeline {@link Timeline#apply(Skeleton, float, float, Array, float, MixBlend, MixDirection)}. */
@:enum abstract MixDirection(Int) from Int to Int {
    var directionIn = 0; var directionOut = 1;
}

@:enum abstract TimelineType(Int) from Int to Int {
    var rotate = 0; var translate = 1; var scale = 2; var shear = 3; //
    var attachment = 4; var color = 5; var deform = 6; //
    var event = 7; var drawOrder = 8; //
    var ikConstraint = 9; var transformConstraint = 10; //
    var pathConstraintPosition = 11; var pathConstraintSpacing = 12; var pathConstraintMix = 13; //
    var twoColor = 14;
}

/** An interface for timelines which change the property of a bone. */
interface BoneTimeline extends Timeline {
    public function setBoneIndex(index:Int):Void;

    /** The index of the bone in {@link Skeleton#getBones()} that will be changed. */
    public function getBoneIndex():Int;
}

/** An interface for timelines which change the property of a slot. */
interface SlotTimeline extends Timeline {
    public function setSlotIndex(index:Int):Void;

    /** The index of the slot in {@link Skeleton#getSlots()} that will be changed. */
    public function getSlotIndex():Int;
}

/** The base class for timelines that use interpolation between key frame values. */
class CurveTimeline implements Timeline {
    public function getPropertyId():Int { return 0; }
    public function apply(skeleton:Skeleton, lastTime:Float, time:Float, events:Array<Event>, alpha:Float, blend:MixBlend, direction:MixDirection):Void {  }
    inline public static var LINEAR:Float = 0; inline public static var STEPPED:Float = 1; inline public static var BEZIER:Float = 2;
    inline private static var BEZIER_SIZE:Int = 10 * 2 - 1;

    private var curves:FloatArray; // type, x, y, ...

    public function new(frameCount:Int) {
        if (frameCount <= 0) throw new IllegalArgumentException("frameCount must be > 0: " + frameCount);
        curves = FloatArray.create((frameCount - 1) * BEZIER_SIZE);
    }

    /** The number of key frames for this timeline. */
    #if !spine_no_inline inline #end public function getFrameCount():Int {
        return Std.int(curves.length / BEZIER_SIZE + 1);
    }

    /** Sets the specified key frame to linear interpolation. */
    #if !spine_no_inline inline #end public function setLinear(frameIndex:Int):Void {
        curves[frameIndex * BEZIER_SIZE] = LINEAR;
    }

    /** Sets the specified key frame to stepped interpolation. */
    #if !spine_no_inline inline #end public function setStepped(frameIndex:Int):Void {
        curves[frameIndex * BEZIER_SIZE] = STEPPED;
    }

    /** Returns the interpolation type for the specified key frame.
     * @return Linear is 0, stepped is 1, Bezier is 2. */
    #if !spine_no_inline inline #end public function getCurveType(frameIndex:Int):Float {
        var index:Int = frameIndex * BEZIER_SIZE;
        if (index == curves.length) return LINEAR;
        var type:Float = curves[index];
        if (type == LINEAR) return LINEAR;
        if (type == STEPPED) return STEPPED;
        return BEZIER;
    }

    /** Sets the specified key frame to Bezier interpolation. <code>cx1</code> and <code>cx2</code> are from 0 to 1,
     * representing the percent of time between the two key frames. <code>cy1</code> and <code>cy2</code> are the percent of the
     * difference between the key frame's values. */
    public function setCurve(frameIndex:Int, cx1:Float, cy1:Float, cx2:Float, cy2:Float):Void {
        var tmpx:Float = (-cx1 * 2 + cx2) * 0.03; var tmpy:Float = (-cy1 * 2 + cy2) * 0.03;
        var dddfx:Float = ((cx1 - cx2) * 3 + 1) * 0.006; var dddfy:Float = ((cy1 - cy2) * 3 + 1) * 0.006;
        var ddfx:Float = tmpx * 2 + dddfx; var ddfy:Float = tmpy * 2 + dddfy;
        var dfx:Float = cx1 * 0.3 + tmpx + dddfx * 0.16666667; var dfy:Float = cy1 * 0.3 + tmpy + dddfy * 0.16666667;

        var i:Int = frameIndex * BEZIER_SIZE;
        var curves:FloatArray = this.curves;
        curves[i++] = BEZIER;

        var x:Float = dfx; var y:Float = dfy;
        var n:Int = i + BEZIER_SIZE - 1; while (i < n) {
            curves[i] = x;
            curves[i + 1] = y;
            dfx += ddfx;
            dfy += ddfy;
            ddfx += dddfx;
            ddfy += dddfy;
            x += dfx;
            y += dfy;
        i += 2; }
    }

    /** Returns the interpolated percentage for the specified key frame and linear percentage. */
    public function getCurvePercent(frameIndex:Int, percent:Float):Float {
        percent = MathUtils.clamp(percent, 0, 1);
        var curves:FloatArray = this.curves;
        var i:Int = frameIndex * BEZIER_SIZE;
        var type:Float = curves[i];
        if (type == LINEAR) return percent;
        if (type == STEPPED) return 0;
        i++;
        var x:Float = 0;
        var start:Int = i; var n:Int = i + BEZIER_SIZE - 1; while (i < n) {
            x = curves[i];
            if (x >= percent) {
                if (i == start) return curves[i + 1] * percent / x; // First point is 0,0.
                var prevX:Float = curves[i - 2]; var prevY:Float = curves[i - 1];
                return prevY + (curves[i + 1] - prevY) * (percent - prevX) / (x - prevX);
            }
        i += 2; }
        var y:Float = curves[i - 1];
        return y + (1 - y) * (percent - x) / (1 - x); // Last point is 1,1.
    }
}

/** Changes a bone's local {@link Bone#getRotation()}. */
class RotateTimeline extends CurveTimeline implements BoneTimeline {
    inline public static var ENTRIES:Int = 2;
    inline public static var PREV_TIME:Int = -2; inline public static var PREV_ROTATION:Int = -1;
    inline public static var ROTATION:Int = 1;

    public var boneIndex:Int = 0;
    public var frames:FloatArray; // time, degrees, ...

    public function new(frameCount:Int) {
        super(frameCount);
        frames = FloatArray.create(frameCount << 1);
    }

    override public function getPropertyId():Int {
        return (TimelineType.rotate << 24) + boneIndex;
    }

    #if !spine_no_inline inline #end public function setBoneIndex(index:Int):Void {
        if (index < 0) throw new IllegalArgumentException("index must be >= 0.");
        this.boneIndex = index;
    }

    /** The index of the bone in {@link Skeleton#getBones()} that will be changed. */
    #if !spine_no_inline inline #end public function getBoneIndex():Int {
        return boneIndex;
    }

    /** The time in seconds and rotation in degrees for each key frame. */
    #if !spine_no_inline inline #end public function getFrames():FloatArray {
        return frames;
    }

    /** Sets the time in seconds and the rotation in degrees for the specified key frame. */
    #if !spine_no_inline inline #end public function setFrame(frameIndex:Int, time:Float, degrees:Float):Void {
        frameIndex <<= 1;
        frames[frameIndex] = time;
        frames[frameIndex + ROTATION] = degrees;
    }

    override public function apply(skeleton:Skeleton, lastTime:Float, time:Float, events:Array<Event>, alpha:Float, blend:MixBlend, direction:MixDirection):Void {

        var bone:Bone = skeleton.bones.get(boneIndex);
        var frames:FloatArray = this.frames;
        if (time < frames[0]) { // Time is before first frame.
            var _continueAfterSwitch0 = false; while(true) { var _switchCond0 = (blend); {
            if (_switchCond0 == setup) {
                bone.rotation = bone.data.rotation;
                return;
            } else if (_switchCond0 == first) {
                var r:Float = bone.data.rotation - bone.rotation;
                bone.rotation += (r - (16384 - Std.int((16384.499999999996 - r / 360))) * 360) * alpha;
            } } break; }
            return;
        }

        if (time >= frames[frames.length - ENTRIES]) { // Time is after last frame.
            var r:Float = frames[frames.length + PREV_ROTATION];
            var _continueAfterSwitch1 = false; while(true) { var _switchCond1 = (blend); {
            if (_switchCond1 == setup) {
                bone.rotation = bone.data.rotation + r * alpha;
                break;
            } else if (_switchCond1 == first) {
                    r += bone.data.rotation - bone.rotation;
                r -= (16384 - Std.int((16384.499999999996 - r / 360))) * 360;
                // Fall through.
                bone.rotation += r * alpha;
            } else if (_switchCond1 == replace) {
                r += bone.data.rotation - bone.rotation;
                r -= (16384 - Std.int((16384.499999999996 - r / 360))) * 360;
                // Fall through.
                bone.rotation += r * alpha;
            } else if (_switchCond1 == add) {
                bone.rotation += r * alpha;
            } } break; }
            return;
        }

        // Interpolate between the previous frame and the current frame.
        var frame:Int = Animation.binarySearchWithStep(frames, time, ENTRIES);
        var prevRotation:Float = frames[frame + PREV_ROTATION];
        var frameTime:Float = frames[frame];
        var percent:Float = getCurvePercent((frame >> 1) - 1, 1 - (time - frameTime) / (frames[frame + PREV_TIME] - frameTime));

        var r:Float = frames[frame + ROTATION] - prevRotation;
        r = prevRotation + (r - (16384 - Std.int((16384.499999999996 - r / 360))) * 360) * percent;
        var _continueAfterSwitch2 = false; while(true) { var _switchCond2 = (blend); {
        if (_switchCond2 == setup) {
            bone.rotation = bone.data.rotation + (r - (16384 - Std.int((16384.499999999996 - r / 360))) * 360) * alpha;
            break;
        } else if (_switchCond2 == first) {
                r += bone.data.rotation - bone.rotation;
            // Fall through.
            bone.rotation += (r - (16384 - Std.int((16384.499999999996 - r / 360))) * 360) * alpha;
        } else if (_switchCond2 == replace) {
            r += bone.data.rotation - bone.rotation;
            // Fall through.
            bone.rotation += (r - (16384 - Std.int((16384.499999999996 - r / 360))) * 360) * alpha;
        } else if (_switchCond2 == add) {
            bone.rotation += (r - (16384 - Std.int((16384.499999999996 - r / 360))) * 360) * alpha;
        } } break; }
    }

    inline public static var LINEAR:Float = CurveTimeline.LINEAR;

    inline public static var STEPPED:Float = CurveTimeline.STEPPED;

    inline public static var BEZIER:Float = CurveTimeline.BEZIER;

    inline private static var BEZIER_SIZE:Int = CurveTimeline.BEZIER_SIZE;
}

/** Changes a bone's local {@link Bone#getX()} and {@link Bone#getY()}. */
class TranslateTimeline extends CurveTimeline implements BoneTimeline {
    inline public static var ENTRIES:Int = 3;
    inline public static var PREV_TIME:Int = -3; inline public static var PREV_X:Int = -2; inline public static var PREV_Y:Int = -1;
    inline public static var X:Int = 1; inline public static var Y:Int = 2;

    public var boneIndex:Int = 0;
    public var frames:FloatArray; // time, x, y, ...

    public function new(frameCount:Int) {
        super(frameCount);
        frames = FloatArray.create(frameCount * ENTRIES);
    }

    override public function getPropertyId():Int {
        return (TimelineType.translate << 24) + boneIndex;
    }

    #if !spine_no_inline inline #end public function setBoneIndex(index:Int):Void {
        if (index < 0) throw new IllegalArgumentException("index must be >= 0.");
        this.boneIndex = index;
    }

    /** The index of the bone in {@link Skeleton#getBones()} that will be changed. */
    #if !spine_no_inline inline #end public function getBoneIndex():Int {
        return boneIndex;
    }

    /** The time in seconds, x, and y values for each key frame. */
    #if !spine_no_inline inline #end public function getFrames():FloatArray {
        return frames;
    }

    /** Sets the time in seconds, x, and y values for the specified key frame. */
    #if !spine_no_inline inline #end public function setFrame(frameIndex:Int, time:Float, x:Float, y:Float):Void {
        frameIndex *= ENTRIES;
        frames[frameIndex] = time;
        frames[frameIndex + X] = x;
        frames[frameIndex + Y] = y;
    }

    override public function apply(skeleton:Skeleton, lastTime:Float, time:Float, events:Array<Event>, alpha:Float, blend:MixBlend, direction:MixDirection):Void {

        var bone:Bone = skeleton.bones.get(boneIndex);
        var frames:FloatArray = this.frames;
        if (time < frames[0]) { // Time is before first frame.
            var _continueAfterSwitch3 = false; while(true) { var _switchCond3 = (blend); {
            if (_switchCond3 == setup) {
                bone.x = bone.data.x;
                bone.y = bone.data.y;
                return;
            } else if (_switchCond3 == first) {
                bone.x += (bone.data.x - bone.x) * alpha;
                bone.y += (bone.data.y - bone.y) * alpha;
            } } break; }
            return;
        }

        var x:Float = 0; var y:Float = 0;
        if (time >= frames[frames.length - ENTRIES]) { // Time is after last frame.
            x = frames[frames.length + PREV_X];
            y = frames[frames.length + PREV_Y];
        } else {
            // Interpolate between the previous frame and the current frame.
            var frame:Int = Animation.binarySearchWithStep(frames, time, ENTRIES);
            x = frames[frame + PREV_X];
            y = frames[frame + PREV_Y];
            var frameTime:Float = frames[frame];
            var percent:Float = getCurvePercent(Std.int(frame / ENTRIES - 1),
                1 - (time - frameTime) / (frames[frame + PREV_TIME] - frameTime));

            x += (frames[frame + X] - x) * percent;
            y += (frames[frame + Y] - y) * percent;
        }
        var _continueAfterSwitch4 = false; while(true) { var _switchCond4 = (blend); {
        if (_switchCond4 == setup) {
            bone.x = bone.data.x + x * alpha;
            bone.y = bone.data.y + y * alpha;
            break;
        } else if (_switchCond4 == first) {
                bone.x += (bone.data.x + x - bone.x) * alpha;
            bone.y += (bone.data.y + y - bone.y) * alpha;
            break;
        } else if (_switchCond4 == replace) {
            bone.x += (bone.data.x + x - bone.x) * alpha;
            bone.y += (bone.data.y + y - bone.y) * alpha;
            break;
        } else if (_switchCond4 == add) {
            bone.x += x * alpha;
            bone.y += y * alpha;
        } } break; }
    }

    inline public static var LINEAR:Float = CurveTimeline.LINEAR;

    inline public static var STEPPED:Float = CurveTimeline.STEPPED;

    inline public static var BEZIER:Float = CurveTimeline.BEZIER;

    inline private static var BEZIER_SIZE:Int = CurveTimeline.BEZIER_SIZE;
}

/** Changes a bone's local {@link Bone#getScaleX()} and {@link Bone#getScaleY()}. */
class ScaleTimeline extends TranslateTimeline {
    public function new(frameCount:Int) {
        super(frameCount);
    }

    override public function getPropertyId():Int {
        return (TimelineType.scale << 24) + boneIndex;
    }

    override public function apply(skeleton:Skeleton, lastTime:Float, time:Float, events:Array<Event>, alpha:Float, blend:MixBlend, direction:MixDirection):Void {

        var bone:Bone = skeleton.bones.get(boneIndex);
        var frames:FloatArray = this.frames;
        if (time < frames[0]) { // Time is before first frame.
            var _continueAfterSwitch5 = false; while(true) { var _switchCond5 = (blend); {
            if (_switchCond5 == setup) {
                bone.scaleX = bone.data.scaleX;
                bone.scaleY = bone.data.scaleY;
                return;
            } else if (_switchCond5 == first) {
                bone.scaleX += (bone.data.scaleX - bone.scaleX) * alpha;
                bone.scaleY += (bone.data.scaleY - bone.scaleY) * alpha;
            } } break; }
            return;
        }

        var x:Float = 0; var y:Float = 0;
        if (time >= frames[frames.length - ENTRIES]) { // Time is after last frame.
            x = frames[frames.length + PREV_X] * bone.data.scaleX;
            y = frames[frames.length + PREV_Y] * bone.data.scaleY;
        } else {
            // Interpolate between the previous frame and the current frame.
            var frame:Int = Animation.binarySearchWithStep(frames, time, ENTRIES);
            x = frames[frame + PREV_X];
            y = frames[frame + PREV_Y];
            var frameTime:Float = frames[frame];
            var percent:Float = getCurvePercent(Std.int(frame / ENTRIES - 1),
                1 - (time - frameTime) / (frames[frame + PREV_TIME] - frameTime));

            x = (x + (frames[frame + X] - x) * percent) * bone.data.scaleX;
            y = (y + (frames[frame + Y] - y) * percent) * bone.data.scaleY;
        }
        if (alpha == 1) {
            if (blend == add) {
                bone.scaleX += x - bone.data.scaleX;
                bone.scaleY += y - bone.data.scaleY;
            } else {
                bone.scaleX = x;
                bone.scaleY = y;
            }
        } else {
            // Mixing out uses sign of setup or current pose, else use sign of key.
            var bx:Float = 0; var by:Float = 0;
            if (direction == spine.MixDirection.directionOut) {
                var _continueAfterSwitch6 = false; while(true) { var _switchCond6 = (blend); {
                if (_switchCond6 == setup) {
                    bx = bone.data.scaleX;
                    by = bone.data.scaleY;
                    bone.scaleX = bx + (Math.abs(x) * MathUtils.signum(bx) - bx) * alpha;
                    bone.scaleY = by + (Math.abs(y) * MathUtils.signum(by) - by) * alpha;
                    break;
                } else if (_switchCond6 == first) {
                        bx = bone.scaleX;
                    by = bone.scaleY;
                    bone.scaleX = bx + (Math.abs(x) * MathUtils.signum(bx) - bx) * alpha;
                    bone.scaleY = by + (Math.abs(y) * MathUtils.signum(by) - by) * alpha;
                    break;
                } else if (_switchCond6 == replace) {
                    bx = bone.scaleX;
                    by = bone.scaleY;
                    bone.scaleX = bx + (Math.abs(x) * MathUtils.signum(bx) - bx) * alpha;
                    bone.scaleY = by + (Math.abs(y) * MathUtils.signum(by) - by) * alpha;
                    break;
                } else if (_switchCond6 == add) {
                    bx = bone.scaleX;
                    by = bone.scaleY;
                    bone.scaleX = bx + (Math.abs(x) * MathUtils.signum(bx) - bone.data.scaleX) * alpha;
                    bone.scaleY = by + (Math.abs(y) * MathUtils.signum(by) - bone.data.scaleY) * alpha;
                } } break; }
            } else {
                var _continueAfterSwitch7 = false; while(true) { var _switchCond7 = (blend); {
                if (_switchCond7 == setup) {
                    bx = Math.abs(bone.data.scaleX) * MathUtils.signum(x);
                    by = Math.abs(bone.data.scaleY) * MathUtils.signum(y);
                    bone.scaleX = bx + (x - bx) * alpha;
                    bone.scaleY = by + (y - by) * alpha;
                    break;
                } else if (_switchCond7 == first) {
                        bx = Math.abs(bone.scaleX) * MathUtils.signum(x);
                    by = Math.abs(bone.scaleY) * MathUtils.signum(y);
                    bone.scaleX = bx + (x - bx) * alpha;
                    bone.scaleY = by + (y - by) * alpha;
                    break;
                } else if (_switchCond7 == replace) {
                    bx = Math.abs(bone.scaleX) * MathUtils.signum(x);
                    by = Math.abs(bone.scaleY) * MathUtils.signum(y);
                    bone.scaleX = bx + (x - bx) * alpha;
                    bone.scaleY = by + (y - by) * alpha;
                    break;
                } else if (_switchCond7 == add) {
                    bx = MathUtils.signum(x);
                    by = MathUtils.signum(y);
                    bone.scaleX = Math.abs(bone.scaleX) * bx + (x - Math.abs(bone.data.scaleX) * bx) * alpha;
                    bone.scaleY = Math.abs(bone.scaleY) * by + (y - Math.abs(bone.data.scaleY) * by) * alpha;
                } } break; }
            }
        }
    }

    inline public static var ENTRIES:Int = TranslateTimeline.ENTRIES;

    inline public static var PREV_TIME:Int = TranslateTimeline.PREV_TIME;

    inline public static var PREV_X:Int = TranslateTimeline.PREV_X;

    inline public static var PREV_Y:Int = TranslateTimeline.PREV_Y;

    inline public static var X:Int = TranslateTimeline.X;

    inline public static var Y:Int = TranslateTimeline.Y;

    inline public static var LINEAR:Float = CurveTimeline.LINEAR;

    inline public static var STEPPED:Float = CurveTimeline.STEPPED;

    inline public static var BEZIER:Float = CurveTimeline.BEZIER;

    inline private static var BEZIER_SIZE:Int = CurveTimeline.BEZIER_SIZE;
}

/** Changes a bone's local {@link Bone#getShearX()} and {@link Bone#getShearY()}. */
class ShearTimeline extends TranslateTimeline {
    public function new(frameCount:Int) {
        super(frameCount);
    }

    override public function getPropertyId():Int {
        return (TimelineType.shear << 24) + boneIndex;
    }

    override public function apply(skeleton:Skeleton, lastTime:Float, time:Float, events:Array<Event>, alpha:Float, blend:MixBlend, direction:MixDirection):Void {

        var bone:Bone = skeleton.bones.get(boneIndex);
        var frames:FloatArray = this.frames;
        if (time < frames[0]) { // Time is before first frame.
            var _continueAfterSwitch8 = false; while(true) { var _switchCond8 = (blend); {
            if (_switchCond8 == setup) {
                bone.shearX = bone.data.shearX;
                bone.shearY = bone.data.shearY;
                return;
            } else if (_switchCond8 == first) {
                bone.shearX += (bone.data.shearX - bone.shearX) * alpha;
                bone.shearY += (bone.data.shearY - bone.shearY) * alpha;
            } } break; }
            return;
        }

        var x:Float = 0; var y:Float = 0;
        if (time >= frames[frames.length - ENTRIES]) { // Time is after last frame.
            x = frames[frames.length + PREV_X];
            y = frames[frames.length + PREV_Y];
        } else {
            // Interpolate between the previous frame and the current frame.
            var frame:Int = Animation.binarySearchWithStep(frames, time, ENTRIES);
            x = frames[frame + PREV_X];
            y = frames[frame + PREV_Y];
            var frameTime:Float = frames[frame];
            var percent:Float = getCurvePercent(Std.int(frame / ENTRIES - 1),
                1 - (time - frameTime) / (frames[frame + PREV_TIME] - frameTime));

            x = x + (frames[frame + X] - x) * percent;
            y = y + (frames[frame + Y] - y) * percent;
        }
        var _continueAfterSwitch9 = false; while(true) { var _switchCond9 = (blend); {
        if (_switchCond9 == setup) {
            bone.shearX = bone.data.shearX + x * alpha;
            bone.shearY = bone.data.shearY + y * alpha;
            break;
        } else if (_switchCond9 == first) {
                bone.shearX += (bone.data.shearX + x - bone.shearX) * alpha;
            bone.shearY += (bone.data.shearY + y - bone.shearY) * alpha;
            break;
        } else if (_switchCond9 == replace) {
            bone.shearX += (bone.data.shearX + x - bone.shearX) * alpha;
            bone.shearY += (bone.data.shearY + y - bone.shearY) * alpha;
            break;
        } else if (_switchCond9 == add) {
            bone.shearX += x * alpha;
            bone.shearY += y * alpha;
        } } break; }
    }

    inline public static var ENTRIES:Int = TranslateTimeline.ENTRIES;

    inline public static var PREV_TIME:Int = TranslateTimeline.PREV_TIME;

    inline public static var PREV_X:Int = TranslateTimeline.PREV_X;

    inline public static var PREV_Y:Int = TranslateTimeline.PREV_Y;

    inline public static var X:Int = TranslateTimeline.X;

    inline public static var Y:Int = TranslateTimeline.Y;

    inline public static var LINEAR:Float = CurveTimeline.LINEAR;

    inline public static var STEPPED:Float = CurveTimeline.STEPPED;

    inline public static var BEZIER:Float = CurveTimeline.BEZIER;

    inline private static var BEZIER_SIZE:Int = CurveTimeline.BEZIER_SIZE;
}

/** Changes a slot's {@link Slot#getColor()}. */
class ColorTimeline extends CurveTimeline implements SlotTimeline {
    inline public static var ENTRIES:Int = 5;
    inline private static var PREV_TIME:Int = -5; inline private static var PREV_R:Int = -4; inline private static var PREV_G:Int = -3; inline private static var PREV_B:Int = -2; inline private static var PREV_A:Int = -1;
    inline private static var R:Int = 1; inline private static var G:Int = 2; inline private static var B:Int = 3; inline private static var A:Int = 4;

    public var slotIndex:Int = 0;
    private var frames:FloatArray; // time, r, g, b, a, ...

    public function new(frameCount:Int) {
        super(frameCount);
        frames = FloatArray.create(frameCount * ENTRIES);
    }

    override public function getPropertyId():Int {
        return (TimelineType.color << 24) + slotIndex;
    }

    #if !spine_no_inline inline #end public function setSlotIndex(index:Int):Void {
        if (index < 0) throw new IllegalArgumentException("index must be >= 0.");
        this.slotIndex = index;
    }

    /** The index of the slot in {@link Skeleton#getSlots()} that will be changed. */
    #if !spine_no_inline inline #end public function getSlotIndex():Int {
        return slotIndex;
    }

    /** The time in seconds, red, green, blue, and alpha values for each key frame. */
    #if !spine_no_inline inline #end public function getFrames():FloatArray {
        return frames;
    }

    /** Sets the time in seconds, red, green, blue, and alpha for the specified key frame. */
    #if !spine_no_inline inline #end public function setFrame(frameIndex:Int, time:Float, r:Float, g:Float, b:Float, a:Float):Void {
        frameIndex *= ENTRIES;
        frames[frameIndex] = time;
        frames[frameIndex + R] = r;
        frames[frameIndex + G] = g;
        frames[frameIndex + B] = b;
        frames[frameIndex + A] = a;
    }

    override public function apply(skeleton:Skeleton, lastTime:Float, time:Float, events:Array<Event>, alpha:Float, blend:MixBlend, direction:MixDirection):Void {

        var slot:Slot = skeleton.slots.get(slotIndex);
        var frames:FloatArray = this.frames;
        if (time < frames[0]) { // Time is before first frame.
            var _continueAfterSwitch10 = false; while(true) { var _switchCond10 = (blend); {
            if (_switchCond10 == setup) {
                slot.color.set(slot.data.color);
                return;
            } else if (_switchCond10 == first) {
                var color:Color = slot.color; var setup:Color = slot.data.color;
                color.add((setup.r - color.r) * alpha, (setup.g - color.g) * alpha, (setup.b - color.b) * alpha,
                    (setup.a - color.a) * alpha);
            } } break; }
            return;
        }

        var r:Float = 0; var g:Float = 0; var b:Float = 0; var a:Float = 0;
        if (time >= frames[frames.length - ENTRIES]) { // Time is after last frame.
            var i:Int = frames.length;
            r = frames[i + PREV_R];
            g = frames[i + PREV_G];
            b = frames[i + PREV_B];
            a = frames[i + PREV_A];
        } else {
            // Interpolate between the previous frame and the current frame.
            var frame:Int = Animation.binarySearchWithStep(frames, time, ENTRIES);
            r = frames[frame + PREV_R];
            g = frames[frame + PREV_G];
            b = frames[frame + PREV_B];
            a = frames[frame + PREV_A];
            var frameTime:Float = frames[frame];
            var percent:Float = getCurvePercent(Std.int(frame / ENTRIES - 1),
                1 - (time - frameTime) / (frames[frame + PREV_TIME] - frameTime));

            r += (frames[frame + R] - r) * percent;
            g += (frames[frame + G] - g) * percent;
            b += (frames[frame + B] - b) * percent;
            a += (frames[frame + A] - a) * percent;
        }
        if (alpha == 1)
            slot.color.set(r, g, b, a);
        else {
            var color:Color = slot.color;
            if (blend == setup) color.set(slot.data.color);
            color.add((r - color.r) * alpha, (g - color.g) * alpha, (b - color.b) * alpha, (a - color.a) * alpha);
        }
    }

    inline public static var LINEAR:Float = CurveTimeline.LINEAR;

    inline public static var STEPPED:Float = CurveTimeline.STEPPED;

    inline public static var BEZIER:Float = CurveTimeline.BEZIER;

    inline private static var BEZIER_SIZE:Int = CurveTimeline.BEZIER_SIZE;
}

/** Changes a slot's {@link Slot#getColor()} and {@link Slot#getDarkColor()} for two color tinting. */
class TwoColorTimeline extends CurveTimeline implements SlotTimeline {
    inline public static var ENTRIES:Int = 8;
    inline private static var PREV_TIME:Int = -8; inline private static var PREV_R:Int = -7; inline private static var PREV_G:Int = -6; inline private static var PREV_B:Int = -5; inline private static var PREV_A:Int = -4;
    inline private static var PREV_R2:Int = -3; inline private static var PREV_G2:Int = -2; inline private static var PREV_B2:Int = -1;
    inline private static var R:Int = 1; inline private static var G:Int = 2; inline private static var B:Int = 3; inline private static var A:Int = 4; inline private static var R2:Int = 5; inline private static var G2:Int = 6; inline private static var B2:Int = 7;

    public var slotIndex:Int = 0;
    private var frames:FloatArray; // time, r, g, b, a, r2, g2, b2, ...

    public function new(frameCount:Int) {
        super(frameCount);
        frames = FloatArray.create(frameCount * ENTRIES);
    }

    override public function getPropertyId():Int {
        return (TimelineType.twoColor << 24) + slotIndex;
    }

    #if !spine_no_inline inline #end public function setSlotIndex(index:Int):Void {
        if (index < 0) throw new IllegalArgumentException("index must be >= 0.");
        this.slotIndex = index;
    }

    /** The index of the slot in {@link Skeleton#getSlots()} that will be changed. */
    #if !spine_no_inline inline #end public function getSlotIndex():Int {
        return slotIndex;
    }

    /** The time in seconds, red, green, blue, and alpha values for each key frame. */
    #if !spine_no_inline inline #end public function getFrames():FloatArray {
        return frames;
    }

    /** Sets the time in seconds, light, and dark colors for the specified key frame. */
    #if !spine_no_inline inline #end public function setFrame(frameIndex:Int, time:Float, r:Float, g:Float, b:Float, a:Float, r2:Float, g2:Float, b2:Float):Void {
        frameIndex *= ENTRIES;
        frames[frameIndex] = time;
        frames[frameIndex + R] = r;
        frames[frameIndex + G] = g;
        frames[frameIndex + B] = b;
        frames[frameIndex + A] = a;
        frames[frameIndex + R2] = r2;
        frames[frameIndex + G2] = g2;
        frames[frameIndex + B2] = b2;
    }

    override public function apply(skeleton:Skeleton, lastTime:Float, time:Float, events:Array<Event>, alpha:Float, blend:MixBlend, direction:MixDirection):Void {

        var slot:Slot = skeleton.slots.get(slotIndex);
        var frames:FloatArray = this.frames;
        if (time < frames[0]) { // Time is before first frame.
            var _continueAfterSwitch11 = false; while(true) { var _switchCond11 = (blend); {
            if (_switchCond11 == setup) {
                slot.color.set(slot.data.color);
                slot.darkColor.set(slot.data.darkColor);
                return;
            } else if (_switchCond11 == first) {
                var light:Color = slot.color; var dark:Color = slot.darkColor; var setupLight:Color = slot.data.color; var setupDark:Color = slot.data.darkColor;
                light.add((setupLight.r - light.r) * alpha, (setupLight.g - light.g) * alpha, (setupLight.b - light.b) * alpha,
                    (setupLight.a - light.a) * alpha);
                dark.add((setupDark.r - dark.r) * alpha, (setupDark.g - dark.g) * alpha, (setupDark.b - dark.b) * alpha, 0);
            } } break; }
            return;
        }

        var r:Float = 0; var g:Float = 0; var b:Float = 0; var a:Float = 0; var r2:Float = 0; var g2:Float = 0; var b2:Float = 0;
        if (time >= frames[frames.length - ENTRIES]) { // Time is after last frame.
            var i:Int = frames.length;
            r = frames[i + PREV_R];
            g = frames[i + PREV_G];
            b = frames[i + PREV_B];
            a = frames[i + PREV_A];
            r2 = frames[i + PREV_R2];
            g2 = frames[i + PREV_G2];
            b2 = frames[i + PREV_B2];
        } else {
            // Interpolate between the previous frame and the current frame.
            var frame:Int = Animation.binarySearchWithStep(frames, time, ENTRIES);
            r = frames[frame + PREV_R];
            g = frames[frame + PREV_G];
            b = frames[frame + PREV_B];
            a = frames[frame + PREV_A];
            r2 = frames[frame + PREV_R2];
            g2 = frames[frame + PREV_G2];
            b2 = frames[frame + PREV_B2];
            var frameTime:Float = frames[frame];
            var percent:Float = getCurvePercent(Std.int(frame / ENTRIES - 1),
                1 - (time - frameTime) / (frames[frame + PREV_TIME] - frameTime));

            r += (frames[frame + R] - r) * percent;
            g += (frames[frame + G] - g) * percent;
            b += (frames[frame + B] - b) * percent;
            a += (frames[frame + A] - a) * percent;
            r2 += (frames[frame + R2] - r2) * percent;
            g2 += (frames[frame + G2] - g2) * percent;
            b2 += (frames[frame + B2] - b2) * percent;
        }
        if (alpha == 1) {
            slot.color.set(r, g, b, a);
            slot.darkColor.set(r2, g2, b2, 1);
        } else {
            var light:Color = slot.color; var dark:Color = slot.darkColor;
            if (blend == setup) {
                light.set(slot.data.color);
                dark.set(slot.data.darkColor);
            }
            light.add((r - light.r) * alpha, (g - light.g) * alpha, (b - light.b) * alpha, (a - light.a) * alpha);
            dark.add((r2 - dark.r) * alpha, (g2 - dark.g) * alpha, (b2 - dark.b) * alpha, 0);
        }
    }

    inline public static var LINEAR:Float = CurveTimeline.LINEAR;

    inline public static var STEPPED:Float = CurveTimeline.STEPPED;

    inline public static var BEZIER:Float = CurveTimeline.BEZIER;

    inline private static var BEZIER_SIZE:Int = CurveTimeline.BEZIER_SIZE;
}

/** Changes a slot's {@link Slot#getAttachment()}. */
class AttachmentTimeline implements SlotTimeline {
    public var slotIndex:Int = 0;
    public var frames:FloatArray; // time, ...
    public var attachmentNames:StringArray;

    public function new(frameCount:Int) {
        frames = FloatArray.create(frameCount);
        attachmentNames = StringArray.create(frameCount);
    }

    public function getPropertyId():Int {
        return (TimelineType.attachment << 24) + slotIndex;
    }

    /** The number of key frames for this timeline. */
    #if !spine_no_inline inline #end public function getFrameCount():Int {
        return frames.length;
    }

    #if !spine_no_inline inline #end public function setSlotIndex(index:Int):Void {
        if (index < 0) throw new IllegalArgumentException("index must be >= 0.");
        this.slotIndex = index;
    }

    /** The index of the slot in {@link Skeleton#getSlots()} that will be changed. */
    #if !spine_no_inline inline #end public function getSlotIndex():Int {
        return slotIndex;
    }

    /** The time in seconds for each key frame. */
    #if !spine_no_inline inline #end public function getFrames():FloatArray {
        return frames;
    }

    /** The attachment name for each key frame. May contain null values to clear the attachment. */
    #if !spine_no_inline inline #end public function getAttachmentNames():StringArray {
        return attachmentNames;
    }

    /** Sets the time in seconds and the attachment name for the specified key frame. */
    #if !spine_no_inline inline #end public function setFrame(frameIndex:Int, time:Float, attachmentName:String):Void {
        frames[frameIndex] = time;
        attachmentNames[frameIndex] = attachmentName;
    }

    public function apply(skeleton:Skeleton, lastTime:Float, time:Float, events:Array<Event>, alpha:Float, blend:MixBlend, direction:MixDirection):Void {

        var slot:Slot = skeleton.slots.get(slotIndex);
        if (direction == spine.MixDirection.directionOut && blend == setup) {
            var attachmentName:String = slot.data.attachmentName;
            slot.setAttachment(attachmentName == null ? null : skeleton.getAttachment(slotIndex, attachmentName));
            return;
        }

        var frames:FloatArray = this.frames;
        if (time < frames[0]) { // Time is before first frame.
            if (blend == setup || blend == first) {
                var attachmentName:String = slot.data.attachmentName;
                slot.setAttachment(attachmentName == null ? null : skeleton.getAttachment(slotIndex, attachmentName));
            }
            return;
        }

        var frameIndex:Int = 0;
        if (time >= frames[frames.length - 1]) // Time is after last frame.
            frameIndex = frames.length - 1;
        else
            frameIndex = Animation.binarySearch(frames, time) - 1;

        var attachmentName:String = attachmentNames[frameIndex];
        slot.setAttachment(attachmentName == null ? null : skeleton.getAttachment(slotIndex, attachmentName));
    }
}

/** Changes a slot's {@link Slot#getAttachmentVertices()} to deform a {@link VertexAttachment}. */
class DeformTimeline extends CurveTimeline implements SlotTimeline {
    public var slotIndex:Int = 0;
    public var attachment:VertexAttachment;
    private var frames:FloatArray; // time, ...
    private var frameVertices:FloatArray2D;

    public function new(frameCount:Int) {
        super(frameCount);
        frames = FloatArray.create(frameCount);
        frameVertices = Array.createFloatArray2D(frameCount, 0);
    }

    override public function getPropertyId():Int {
        return (TimelineType.deform << 27) + attachment.getId() + slotIndex;
    }

    #if !spine_no_inline inline #end public function setSlotIndex(index:Int):Void {
        if (index < 0) throw new IllegalArgumentException("index must be >= 0.");
        this.slotIndex = index;
    }

    /** The index of the slot in {@link Skeleton#getSlots()} that will be changed. */
    #if !spine_no_inline inline #end public function getSlotIndex():Int {
        return slotIndex;
    }

    #if !spine_no_inline inline #end public function setAttachment(attachment:VertexAttachment):Void {
        this.attachment = attachment;
    }

    /** The attachment that will be deformed. */
    #if !spine_no_inline inline #end public function getAttachment():VertexAttachment {
        return attachment;
    }

    /** The time in seconds for each key frame. */
    #if !spine_no_inline inline #end public function getFrames():FloatArray {
        return frames;
    }

    /** The vertices for each key frame. */
    #if !spine_no_inline inline #end public function getVertices():FloatArray2D {
        return frameVertices;
    }

    /** Sets the time in seconds and the vertices for the specified key frame.
     * @param vertices Vertex positions for an unweighted VertexAttachment, or deform offsets if it has weights. */
    #if !spine_no_inline inline #end public function setFrame(frameIndex:Int, time:Float, vertices:FloatArray):Void {
        frames[frameIndex] = time;
        frameVertices[frameIndex] = vertices;
    }

    override public function apply(skeleton:Skeleton, lastTime:Float, time:Float, events:Array<Event>, alpha:Float, blend:MixBlend, direction:MixDirection):Void {

        var slot:Slot = skeleton.slots.get(slotIndex);
        var slotAttachment:Attachment = slot.attachment;
        if (!(Std.is(slotAttachment, VertexAttachment)) || !(cast(slotAttachment, VertexAttachment)).applyDeform(attachment)) return;

        var verticesArray:FloatArray = slot.getAttachmentVertices();
        if (verticesArray.size == 0) blend = setup;

        var frameVertices:FloatArray2D = this.frameVertices;
        var vertexCount:Int = frameVertices[0].length;

        var frames:FloatArray = this.frames;
        if (time < frames[0]) { // Time is before first frame.
            var vertexAttachment:VertexAttachment = cast(slotAttachment, VertexAttachment);
            var _continueAfterSwitch12 = false; while(true) { var _switchCond12 = (blend); {
            if (_switchCond12 == setup) {
                verticesArray.clear();
                return;
            } else if (_switchCond12 == first) {
                if (alpha == 1) {
                    verticesArray.clear();
                    return;
                }
                var vertices:FloatArray = verticesArray.setSize(vertexCount);
                if (vertexAttachment.getBones() == null) {
                    // Unweighted vertex positions.
                    var setupVertices:FloatArray = vertexAttachment.getVertices();
                    var i:Int = 0; while (i < vertexCount) {
                        vertices[i] += (setupVertices[i] - vertices[i]) * alpha; i++; }
                } else {
                    // Weighted deform offsets.
                    alpha = 1 - alpha;
                    var i:Int = 0; while (i < vertexCount) {
                        vertices[i] *= alpha; i++; }
                }
            } } break; }
            return;
        }

        var vertices:FloatArray = verticesArray.setSize(vertexCount);

        if (time >= frames[frames.length - 1]) { // Time is after last frame.
            var lastVertices:FloatArray = frameVertices[frames.length - 1];
            if (alpha == 1) {
                if (blend == add) {
                    var vertexAttachment:VertexAttachment = cast(slotAttachment, VertexAttachment);
                    if (vertexAttachment.getBones() == null) {
                        // Unweighted vertex positions, no alpha.
                        var setupVertices:FloatArray = vertexAttachment.getVertices();
                        var i:Int = 0; while (i < vertexCount) {
                            vertices[i] += lastVertices[i] - setupVertices[i]; i++; }
                    } else {
                        // Weighted deform offsets, no alpha.
                        var i:Int = 0; while (i < vertexCount) {
                            vertices[i] += lastVertices[i]; i++; }
                    }
                } else {
                    // Vertex positions or deform offsets, no alpha.
                    Array.copyFloats(lastVertices, 0, vertices, 0, vertexCount);
                }
            } else {
                var _continueAfterSwitch13 = false; while(true) { var _switchCond13 = (blend); {
                if (_switchCond13 == setup) {
                    var vertexAttachment:VertexAttachment = cast(slotAttachment, VertexAttachment);
                    if (vertexAttachment.getBones() == null) {
                        // Unweighted vertex positions, with alpha.
                        var setupVertices:FloatArray = vertexAttachment.getVertices();
                        var i:Int = 0; while (i < vertexCount) {
                            var setup:Float = setupVertices[i];
                            vertices[i] = setup + (lastVertices[i] - setup) * alpha;
                        i++; }
                    } else {
                        // Weighted deform offsets, with alpha.
                        var i:Int = 0; while (i < vertexCount) {
                            vertices[i] = lastVertices[i] * alpha; i++; }
                    }
                    break;
                }
                else if (_switchCond13 == first) {
                        // Vertex positions or deform offsets, with alpha.
                    var i:Int = 0; while (i < vertexCount) {
                        vertices[i] += (lastVertices[i] - vertices[i]) * alpha; i++; }
                    break;
                } else if (_switchCond13 == replace) {
                    // Vertex positions or deform offsets, with alpha.
                    var i:Int = 0; while (i < vertexCount) {
                        vertices[i] += (lastVertices[i] - vertices[i]) * alpha; i++; }
                    break;
                } else if (_switchCond13 == add) {
                    var vertexAttachment:VertexAttachment = cast(slotAttachment, VertexAttachment);
                    if (vertexAttachment.getBones() == null) {
                        // Unweighted vertex positions, no alpha.
                        var setupVertices:FloatArray = vertexAttachment.getVertices();
                        var i:Int = 0; while (i < vertexCount) {
                            vertices[i] += (lastVertices[i] - setupVertices[i]) * alpha; i++; }
                    } else {
                        // Weighted deform offsets, alpha.
                        var i:Int = 0; while (i < vertexCount) {
                            vertices[i] += lastVertices[i] * alpha; i++; }
                    }
                } } break; }
            }
            return;
        }

        // Interpolate between the previous frame and the current frame.
        var frame:Int = Animation.binarySearch(frames, time);
        var prevVertices:FloatArray = frameVertices[Std.int(frame - 1)];
        var nextVertices:FloatArray = frameVertices[frame];
        var frameTime:Float = frames[frame];
        var percent:Float = getCurvePercent(Std.int(frame - 1), 1 - (time - frameTime) / (frames[Std.int(frame - 1)] - frameTime));

        if (alpha == 1) {
            if (blend == add) {
                var vertexAttachment:VertexAttachment = cast(slotAttachment, VertexAttachment);
                if (vertexAttachment.getBones() == null) {
                    // Unweighted vertex positions, no alpha.
                    var setupVertices:FloatArray = vertexAttachment.getVertices();
                    var i:Int = 0; while (i < vertexCount) {
                        var prev:Float = prevVertices[i];
                        vertices[i] += prev + (nextVertices[i] - prev) * percent - setupVertices[i];
                    i++; }
                } else {
                    // Weighted deform offsets, no alpha.
                    var i:Int = 0; while (i < vertexCount) {
                        var prev:Float = prevVertices[i];
                        vertices[i] += prev + (nextVertices[i] - prev) * percent;
                    i++; }
                }
            } else {
                // Vertex positions or deform offsets, no alpha.
                var i:Int = 0; while (i < vertexCount) {
                    var prev:Float = prevVertices[i];
                    vertices[i] = prev + (nextVertices[i] - prev) * percent;
                i++; }
            }
        } else {
            var _continueAfterSwitch14 = false; while(true) { var _switchCond14 = (blend); {
            if (_switchCond14 == setup) {
                var vertexAttachment:VertexAttachment = cast(slotAttachment, VertexAttachment);
                if (vertexAttachment.getBones() == null) {
                    // Unweighted vertex positions, with alpha.
                    var setupVertices:FloatArray = vertexAttachment.getVertices();
                    var i:Int = 0; while (i < vertexCount) {
                        var prev:Float = prevVertices[i]; var setup:Float = setupVertices[i];
                        vertices[i] = setup + (prev + (nextVertices[i] - prev) * percent - setup) * alpha;
                    i++; }
                } else {
                    // Weighted deform offsets, with alpha.
                    var i:Int = 0; while (i < vertexCount) {
                        var prev:Float = prevVertices[i];
                        vertices[i] = (prev + (nextVertices[i] - prev) * percent) * alpha;
                    i++; }
                }
                break;
            }
            else if (_switchCond14 == first) {
                    // Vertex positions or deform offsets, with alpha.
                var i:Int = 0; while (i < vertexCount) {
                    var prev:Float = prevVertices[i];
                    vertices[i] += (prev + (nextVertices[i] - prev) * percent - vertices[i]) * alpha;
                i++; }
                break;
            } else if (_switchCond14 == replace) {
                // Vertex positions or deform offsets, with alpha.
                var i:Int = 0; while (i < vertexCount) {
                    var prev:Float = prevVertices[i];
                    vertices[i] += (prev + (nextVertices[i] - prev) * percent - vertices[i]) * alpha;
                i++; }
                break;
            } else if (_switchCond14 == add) {
                var vertexAttachment:VertexAttachment = cast(slotAttachment, VertexAttachment);
                if (vertexAttachment.getBones() == null) {
                    // Unweighted vertex positions, with alpha.
                    var setupVertices:FloatArray = vertexAttachment.getVertices();
                    var i:Int = 0; while (i < vertexCount) {
                        var prev:Float = prevVertices[i];
                        vertices[i] += (prev + (nextVertices[i] - prev) * percent - setupVertices[i]) * alpha;
                    i++; }
                } else {
                    // Weighted deform offsets, with alpha.
                    var i:Int = 0; while (i < vertexCount) {
                        var prev:Float = prevVertices[i];
                        vertices[i] += (prev + (nextVertices[i] - prev) * percent) * alpha;
                    i++; }
                }
            } } break; }
        }
    }

    inline public static var LINEAR:Float = CurveTimeline.LINEAR;

    inline public static var STEPPED:Float = CurveTimeline.STEPPED;

    inline public static var BEZIER:Float = CurveTimeline.BEZIER;

    inline private static var BEZIER_SIZE:Int = CurveTimeline.BEZIER_SIZE;
}

/** Fires an {@link Event} when specific animation times are reached. */
class EventTimeline implements Timeline {
    private var frames:FloatArray; // time, ...
    private var events:Array<Event>;

    public function new(frameCount:Int) {
        frames = FloatArray.create(frameCount);
        events = Array.create(frameCount);
    }

    public function getPropertyId():Int {
        return TimelineType.event << 24;
    }

    /** The number of key frames for this timeline. */
    #if !spine_no_inline inline #end public function getFrameCount():Int {
        return frames.length;
    }

    /** The time in seconds for each key frame. */
    #if !spine_no_inline inline #end public function getFrames():FloatArray {
        return frames;
    }

    /** The event for each key frame. */
    #if !spine_no_inline inline #end public function getEvents():Array<Event> {
        return events;
    }

    /** Sets the time in seconds and the event for the specified key frame. */
    #if !spine_no_inline inline #end public function setFrame(frameIndex:Int, event:Event):Void {
        frames[frameIndex] = event.time;
        events[frameIndex] = event;
    }

    /** Fires events for frames > <code>lastTime</code> and <= <code>time</code>. */
    public function apply(skeleton:Skeleton, lastTime:Float, time:Float, firedEvents:Array<Event>, alpha:Float, blend:MixBlend, direction:MixDirection):Void {

        if (firedEvents == null) return;
        var frames:FloatArray = this.frames;
        var frameCount:Int = frames.length;

        if (lastTime > time) { // Fire events after last time for looped animations.
            apply(skeleton, lastTime, 999999999, firedEvents, alpha, blend, direction);
            lastTime = -1;
        } else if (lastTime >= frames[frameCount - 1]) // Last time is after last frame.
            return;
        if (time < frames[0]) return; // Time is before first frame.

        var frame:Int = 0;
        if (lastTime < frames[0])
            frame = 0;
        else {
            frame = Animation.binarySearch(frames, lastTime);
            var frameTime:Float = frames[frame];
            while (frame > 0) { // Fire multiple events with the same frame.
                if (frames[frame - 1] != frameTime) break;
                frame--;
            }
        }
        while (frame < frameCount && time >= frames[frame]) {
            firedEvents.add(events[frame]); frame++; }
    }
}

/** Changes a skeleton's {@link Skeleton#getDrawOrder()}. */
class DrawOrderTimeline implements Timeline {
    private var frames:FloatArray; // time, ...
    private var drawOrders:IntArray2D;

    public function new(frameCount:Int) {
        frames = FloatArray.create(frameCount);
        drawOrders = Array.createIntArray2D(frameCount, 0);
    }

    public function getPropertyId():Int {
        return TimelineType.drawOrder << 24;
    }

    /** The number of key frames for this timeline. */
    #if !spine_no_inline inline #end public function getFrameCount():Int {
        return frames.length;
    }

    /** The time in seconds for each key frame. */
    #if !spine_no_inline inline #end public function getFrames():FloatArray {
        return frames;
    }

    /** The draw order for each key frame. See {@link #setFrame(int, float, int[])}. */
    #if !spine_no_inline inline #end public function getDrawOrders():IntArray2D {
        return drawOrders;
    }

    /** Sets the time in seconds and the draw order for the specified key frame.
     * @param drawOrder For each slot in {@link Skeleton#slots}, the index of the new draw order. May be null to use setup pose
     *           draw order. */
    #if !spine_no_inline inline #end public function setFrame(frameIndex:Int, time:Float, drawOrder:IntArray):Void {
        frames[frameIndex] = time;
        drawOrders[frameIndex] = drawOrder;
    }

    public function apply(skeleton:Skeleton, lastTime:Float, time:Float, events:Array<Event>, alpha:Float, blend:MixBlend, direction:MixDirection):Void {

        var drawOrder:Array<Slot> = skeleton.drawOrder;
        var slots:Array<Slot> = skeleton.slots;
        if (direction == spine.MixDirection.directionOut && blend == setup) {
            Array.copy(slots.items, 0, drawOrder.items, 0, slots.size);
            return;
        }

        var frames:FloatArray = this.frames;
        if (time < frames[0]) { // Time is before first frame.
            if (blend == setup || blend == first) Array.copy(slots.items, 0, drawOrder.items, 0, slots.size);
            return;
        }

        var frame:Int = 0;
        if (time >= frames[frames.length - 1]) // Time is after last frame.
            frame = frames.length - 1;
        else
            frame = Animation.binarySearch(frames, time) - 1;

        var drawOrderToSetupIndex:IntArray = drawOrders[frame];
        if (drawOrderToSetupIndex == null)
            Array.copy(slots.items, 0, drawOrder.items, 0, slots.size);
        else {
            var i:Int = 0; var n:Int = drawOrderToSetupIndex.length; while (i < n) {
                drawOrder.set(i, slots.get(drawOrderToSetupIndex[i])); i++; }
        }
    }
}

/** Changes an IK constraint's {@link IkConstraint#getMix()}, {@link IkConstraint#getBendDirection()},
 * {@link IkConstraint#getStretch()}, and {@link IkConstraint#getCompress()}. */
class IkConstraintTimeline extends CurveTimeline {
    inline public static var ENTRIES:Int = 5;
    inline private static var PREV_TIME:Int = -5; inline private static var PREV_MIX:Int = -4; inline private static var PREV_BEND_DIRECTION:Int = -3; inline private static var PREV_COMPRESS:Int = -2; inline private static var PREV_STRETCH:Int = -1;
    inline private static var MIX:Int = 1; inline private static var BEND_DIRECTION:Int = 2; inline private static var COMPRESS:Int = 3; inline private static var STRETCH:Int = 4;

    public var ikConstraintIndex:Int = 0;
    private var frames:FloatArray; // time, mix, bendDirection, compress, stretch, ...

    public function new(frameCount:Int) {
        super(frameCount);
        frames = FloatArray.create(frameCount * ENTRIES);
    }

    override public function getPropertyId():Int {
        return (TimelineType.ikConstraint << 24) + ikConstraintIndex;
    }

    #if !spine_no_inline inline #end public function setIkConstraintIndex(index:Int):Void {
        if (index < 0) throw new IllegalArgumentException("index must be >= 0.");
        this.ikConstraintIndex = index;
    }

    /** The index of the IK constraint slot in {@link Skeleton#getIkConstraints()} that will be changed. */
    #if !spine_no_inline inline #end public function getIkConstraintIndex():Int {
        return ikConstraintIndex;
    }

    /** The time in seconds, mix, bend direction, compress, and stretch for each key frame. */
    #if !spine_no_inline inline #end public function getFrames():FloatArray {
        return frames;
    }

    /** Sets the time in seconds, mix, bend direction, compress, and stretch for the specified key frame. */
    #if !spine_no_inline inline #end public function setFrame(frameIndex:Int, time:Float, mix:Float, bendDirection:Int, compress:Bool, stretch:Bool):Void {
        frameIndex *= ENTRIES;
        frames[frameIndex] = time;
        frames[frameIndex + MIX] = mix;
        frames[frameIndex + BEND_DIRECTION] = bendDirection;
        frames[frameIndex + COMPRESS] = compress ? 1 : 0;
        frames[frameIndex + STRETCH] = stretch ? 1 : 0;
    }

    override public function apply(skeleton:Skeleton, lastTime:Float, time:Float, events:Array<Event>, alpha:Float, blend:MixBlend, direction:MixDirection):Void {

        var constraint:IkConstraint = skeleton.ikConstraints.get(ikConstraintIndex);
        var frames:FloatArray = this.frames;
        if (time < frames[0]) { // Time is before first frame.
            var _continueAfterSwitch15 = false; while(true) { var _switchCond15 = (blend); {
            if (_switchCond15 == setup) {
                constraint.mix = constraint.data.mix;
                constraint.bendDirection = constraint.data.bendDirection;
                constraint.compress = constraint.data.compress;
                constraint.stretch = constraint.data.stretch;
                return;
            } else if (_switchCond15 == first) {
                constraint.mix += (constraint.data.mix - constraint.mix) * alpha;
                constraint.bendDirection = constraint.data.bendDirection;
                constraint.compress = constraint.data.compress;
                constraint.stretch = constraint.data.stretch;
            } } break; }
            return;
        }

        if (time >= frames[frames.length - ENTRIES]) { // Time is after last frame.
            if (blend == setup) {
                constraint.mix = constraint.data.mix + (frames[frames.length + PREV_MIX] - constraint.data.mix) * alpha;
                if (direction == spine.MixDirection.directionOut) {
                    constraint.bendDirection = constraint.data.bendDirection;
                    constraint.compress = constraint.data.compress;
                    constraint.stretch = constraint.data.stretch;
                } else {
                    constraint.bendDirection = Std.int(frames[frames.length + PREV_BEND_DIRECTION]);
                    constraint.compress = frames[frames.length + PREV_COMPRESS] != 0;
                    constraint.stretch = frames[frames.length + PREV_STRETCH] != 0;
                }
            } else {
                constraint.mix += (frames[frames.length + PREV_MIX] - constraint.mix) * alpha;
                if (direction == spine.MixDirection.directionIn) {
                    constraint.bendDirection = Std.int(frames[frames.length + PREV_BEND_DIRECTION]);
                    constraint.compress = frames[frames.length + PREV_COMPRESS] != 0;
                    constraint.stretch = frames[frames.length + PREV_STRETCH] != 0;
                }
            }
            return;
        }

        // Interpolate between the previous frame and the current frame.
        var frame:Int = Animation.binarySearchWithStep(frames, time, ENTRIES);
        var mix:Float = frames[frame + PREV_MIX];
        var frameTime:Float = frames[frame];
        var percent:Float = getCurvePercent(Std.int(frame / ENTRIES - 1), 1 - (time - frameTime) / (frames[frame + PREV_TIME] - frameTime));

        if (blend == setup) {
            constraint.mix = constraint.data.mix + (mix + (frames[frame + MIX] - mix) * percent - constraint.data.mix) * alpha;
            if (direction == spine.MixDirection.directionOut) {
                constraint.bendDirection = constraint.data.bendDirection;
                constraint.compress = constraint.data.compress;
                constraint.stretch = constraint.data.stretch;
            } else {
                constraint.bendDirection = Std.int(frames[frame + PREV_BEND_DIRECTION]);
                constraint.compress = frames[frame + PREV_COMPRESS] != 0;
                constraint.stretch = frames[frame + PREV_STRETCH] != 0;
            }
        } else {
            constraint.mix += (mix + (frames[frame + MIX] - mix) * percent - constraint.mix) * alpha;
            if (direction == spine.MixDirection.directionIn) {
                constraint.bendDirection = Std.int(frames[frame + PREV_BEND_DIRECTION]);
                constraint.compress = frames[frame + PREV_COMPRESS] != 0;
                constraint.stretch = frames[frame + PREV_STRETCH] != 0;
            }
        }
    }

    inline public static var LINEAR:Float = CurveTimeline.LINEAR;

    inline public static var STEPPED:Float = CurveTimeline.STEPPED;

    inline public static var BEZIER:Float = CurveTimeline.BEZIER;

    inline private static var BEZIER_SIZE:Int = CurveTimeline.BEZIER_SIZE;
}

/** Changes a transform constraint's mixes. */
class TransformConstraintTimeline extends CurveTimeline {
    inline public static var ENTRIES:Int = 5;
    inline private static var PREV_TIME:Int = -5; inline private static var PREV_ROTATE:Int = -4; inline private static var PREV_TRANSLATE:Int = -3; inline private static var PREV_SCALE:Int = -2; inline private static var PREV_SHEAR:Int = -1;
    inline private static var ROTATE:Int = 1; inline private static var TRANSLATE:Int = 2; inline private static var SCALE:Int = 3; inline private static var SHEAR:Int = 4;

    public var transformConstraintIndex:Int = 0;
    private var frames:FloatArray; // time, rotate mix, translate mix, scale mix, shear mix, ...

    public function new(frameCount:Int) {
        super(frameCount);
        frames = FloatArray.create(frameCount * ENTRIES);
    }

    override public function getPropertyId():Int {
        return (TimelineType.transformConstraint << 24) + transformConstraintIndex;
    }

    #if !spine_no_inline inline #end public function setTransformConstraintIndex(index:Int):Void {
        if (index < 0) throw new IllegalArgumentException("index must be >= 0.");
        this.transformConstraintIndex = index;
    }

    /** The index of the transform constraint slot in {@link Skeleton#getTransformConstraints()} that will be changed. */
    #if !spine_no_inline inline #end public function getTransformConstraintIndex():Int {
        return transformConstraintIndex;
    }

    /** The time in seconds, rotate mix, translate mix, scale mix, and shear mix for each key frame. */
    #if !spine_no_inline inline #end public function getFrames():FloatArray {
        return frames;
    }

    /** The time in seconds, rotate mix, translate mix, scale mix, and shear mix for the specified key frame. */
    #if !spine_no_inline inline #end public function setFrame(frameIndex:Int, time:Float, rotateMix:Float, translateMix:Float, scaleMix:Float, shearMix:Float):Void {
        frameIndex *= ENTRIES;
        frames[frameIndex] = time;
        frames[frameIndex + ROTATE] = rotateMix;
        frames[frameIndex + TRANSLATE] = translateMix;
        frames[frameIndex + SCALE] = scaleMix;
        frames[frameIndex + SHEAR] = shearMix;
    }

    override public function apply(skeleton:Skeleton, lastTime:Float, time:Float, events:Array<Event>, alpha:Float, blend:MixBlend, direction:MixDirection):Void {

        var constraint:TransformConstraint = skeleton.transformConstraints.get(transformConstraintIndex);
        var frames:FloatArray = this.frames;
        if (time < frames[0]) { // Time is before first frame.
            var data:TransformConstraintData = constraint.data;
            var _continueAfterSwitch16 = false; while(true) { var _switchCond16 = (blend); {
            if (_switchCond16 == setup) {
                constraint.rotateMix = data.rotateMix;
                constraint.translateMix = data.translateMix;
                constraint.scaleMix = data.scaleMix;
                constraint.shearMix = data.shearMix;
                return;
            } else if (_switchCond16 == first) {
                constraint.rotateMix += (data.rotateMix - constraint.rotateMix) * alpha;
                constraint.translateMix += (data.translateMix - constraint.translateMix) * alpha;
                constraint.scaleMix += (data.scaleMix - constraint.scaleMix) * alpha;
                constraint.shearMix += (data.shearMix - constraint.shearMix) * alpha;
            } } break; }
            return;
        }

        var rotate:Float = 0; var translate:Float = 0; var scale:Float = 0; var shear:Float = 0;
        if (time >= frames[frames.length - ENTRIES]) { // Time is after last frame.
            var i:Int = frames.length;
            rotate = frames[i + PREV_ROTATE];
            translate = frames[i + PREV_TRANSLATE];
            scale = frames[i + PREV_SCALE];
            shear = frames[i + PREV_SHEAR];
        } else {
            // Interpolate between the previous frame and the current frame.
            var frame:Int = Animation.binarySearchWithStep(frames, time, ENTRIES);
            rotate = frames[frame + PREV_ROTATE];
            translate = frames[frame + PREV_TRANSLATE];
            scale = frames[frame + PREV_SCALE];
            shear = frames[frame + PREV_SHEAR];
            var frameTime:Float = frames[frame];
            var percent:Float = getCurvePercent(Std.int(frame / ENTRIES - 1),
                1 - (time - frameTime) / (frames[frame + PREV_TIME] - frameTime));

            rotate += (frames[frame + ROTATE] - rotate) * percent;
            translate += (frames[frame + TRANSLATE] - translate) * percent;
            scale += (frames[frame + SCALE] - scale) * percent;
            shear += (frames[frame + SHEAR] - shear) * percent;
        }
        if (blend == setup) {
            var data:TransformConstraintData = constraint.data;
            constraint.rotateMix = data.rotateMix + (rotate - data.rotateMix) * alpha;
            constraint.translateMix = data.translateMix + (translate - data.translateMix) * alpha;
            constraint.scaleMix = data.scaleMix + (scale - data.scaleMix) * alpha;
            constraint.shearMix = data.shearMix + (shear - data.shearMix) * alpha;
        } else {
            constraint.rotateMix += (rotate - constraint.rotateMix) * alpha;
            constraint.translateMix += (translate - constraint.translateMix) * alpha;
            constraint.scaleMix += (scale - constraint.scaleMix) * alpha;
            constraint.shearMix += (shear - constraint.shearMix) * alpha;
        }
    }

    inline public static var LINEAR:Float = CurveTimeline.LINEAR;

    inline public static var STEPPED:Float = CurveTimeline.STEPPED;

    inline public static var BEZIER:Float = CurveTimeline.BEZIER;

    inline private static var BEZIER_SIZE:Int = CurveTimeline.BEZIER_SIZE;
}

/** Changes a path constraint's {@link PathConstraint#getPosition()}. */
class PathConstraintPositionTimeline extends CurveTimeline {
    inline public static var ENTRIES:Int = 2;
    inline public static var PREV_TIME:Int = -2; inline public static var PREV_VALUE:Int = -1;
    inline public static var VALUE:Int = 1;

    public var pathConstraintIndex:Int = 0;

    public var frames:FloatArray; // time, position, ...

    public function new(frameCount:Int) {
        super(frameCount);
        frames = FloatArray.create(frameCount * ENTRIES);
    }

    override public function getPropertyId():Int {
        return (TimelineType.pathConstraintPosition << 24) + pathConstraintIndex;
    }

    #if !spine_no_inline inline #end public function setPathConstraintIndex(index:Int):Void {
        if (index < 0) throw new IllegalArgumentException("index must be >= 0.");
        this.pathConstraintIndex = index;
    }

    /** The index of the path constraint slot in {@link Skeleton#getPathConstraints()} that will be changed. */
    #if !spine_no_inline inline #end public function getPathConstraintIndex():Int {
        return pathConstraintIndex;
    }

    /** The time in seconds and path constraint position for each key frame. */
    #if !spine_no_inline inline #end public function getFrames():FloatArray {
        return frames;
    }

    /** Sets the time in seconds and path constraint position for the specified key frame. */
    #if !spine_no_inline inline #end public function setFrame(frameIndex:Int, time:Float, position:Float):Void {
        frameIndex *= ENTRIES;
        frames[frameIndex] = time;
        frames[frameIndex + VALUE] = position;
    }

    override public function apply(skeleton:Skeleton, lastTime:Float, time:Float, events:Array<Event>, alpha:Float, blend:MixBlend, direction:MixDirection):Void {

        var constraint:PathConstraint = skeleton.pathConstraints.get(pathConstraintIndex);
        var frames:FloatArray = this.frames;
        if (time < frames[0]) { // Time is before first frame.
            var _continueAfterSwitch17 = false; while(true) { var _switchCond17 = (blend); {
            if (_switchCond17 == setup) {
                constraint.position = constraint.data.position;
                return;
            } else if (_switchCond17 == first) {
                constraint.position += (constraint.data.position - constraint.position) * alpha;
            } } break; }
            return;
        }

        var position:Float = 0;
        if (time >= frames[frames.length - ENTRIES]) // Time is after last frame.
            position = frames[frames.length + PREV_VALUE];
        else {
            // Interpolate between the previous frame and the current frame.
            var frame:Int = Animation.binarySearchWithStep(frames, time, ENTRIES);
            position = frames[frame + PREV_VALUE];
            var frameTime:Float = frames[frame];
            var percent:Float = getCurvePercent(Std.int(frame / ENTRIES - 1),
                1 - (time - frameTime) / (frames[frame + PREV_TIME] - frameTime));

            position += (frames[frame + VALUE] - position) * percent;
        }
        if (blend == setup)
            constraint.position = constraint.data.position + (position - constraint.data.position) * alpha;
        else
            constraint.position += (position - constraint.position) * alpha;
    }

    inline public static var LINEAR:Float = CurveTimeline.LINEAR;

    inline public static var STEPPED:Float = CurveTimeline.STEPPED;

    inline public static var BEZIER:Float = CurveTimeline.BEZIER;

    inline private static var BEZIER_SIZE:Int = CurveTimeline.BEZIER_SIZE;
}

/** Changes a path constraint's {@link PathConstraint#getSpacing()}. */
class PathConstraintSpacingTimeline extends PathConstraintPositionTimeline {
    public function new(frameCount:Int) {
        super(frameCount);
    }

    override public function getPropertyId():Int {
        return (TimelineType.pathConstraintSpacing << 24) + pathConstraintIndex;
    }

    override public function apply(skeleton:Skeleton, lastTime:Float, time:Float, events:Array<Event>, alpha:Float, blend:MixBlend, direction:MixDirection):Void {

        var constraint:PathConstraint = skeleton.pathConstraints.get(pathConstraintIndex);
        var frames:FloatArray = this.frames;
        if (time < frames[0]) { // Time is before first frame.
            var _continueAfterSwitch18 = false; while(true) { var _switchCond18 = (blend); {
            if (_switchCond18 == setup) {
                constraint.spacing = constraint.data.spacing;
                return;
            } else if (_switchCond18 == first) {
                constraint.spacing += (constraint.data.spacing - constraint.spacing) * alpha;
            } } break; }
            return;
        }

        var spacing:Float = 0;
        if (time >= frames[frames.length - ENTRIES]) // Time is after last frame.
            spacing = frames[frames.length + PREV_VALUE];
        else {
            // Interpolate between the previous frame and the current frame.
            var frame:Int = Animation.binarySearchWithStep(frames, time, ENTRIES);
            spacing = frames[frame + PREV_VALUE];
            var frameTime:Float = frames[frame];
            var percent:Float = getCurvePercent(Std.int(frame / ENTRIES - 1),
                1 - (time - frameTime) / (frames[frame + PREV_TIME] - frameTime));

            spacing += (frames[frame + VALUE] - spacing) * percent;
        }

        if (blend == setup)
            constraint.spacing = constraint.data.spacing + (spacing - constraint.data.spacing) * alpha;
        else
            constraint.spacing += (spacing - constraint.spacing) * alpha;
    }

    inline public static var ENTRIES:Int = PathConstraintPositionTimeline.ENTRIES;

    inline public static var PREV_TIME:Int = PathConstraintPositionTimeline.PREV_TIME;

    inline public static var PREV_VALUE:Int = PathConstraintPositionTimeline.PREV_VALUE;

    inline public static var VALUE:Int = PathConstraintPositionTimeline.VALUE;

    inline public static var LINEAR:Float = CurveTimeline.LINEAR;

    inline public static var STEPPED:Float = CurveTimeline.STEPPED;

    inline public static var BEZIER:Float = CurveTimeline.BEZIER;

    inline private static var BEZIER_SIZE:Int = CurveTimeline.BEZIER_SIZE;
}

/** Changes a path constraint's mixes. */
class PathConstraintMixTimeline extends CurveTimeline {
    inline public static var ENTRIES:Int = 3;
    inline private static var PREV_TIME:Int = -3; inline private static var PREV_ROTATE:Int = -2; inline private static var PREV_TRANSLATE:Int = -1;
    inline private static var ROTATE:Int = 1; inline private static var TRANSLATE:Int = 2;

    public var pathConstraintIndex:Int = 0;

    private var frames:FloatArray; // time, rotate mix, translate mix, ...

    public function new(frameCount:Int) {
        super(frameCount);
        frames = FloatArray.create(frameCount * ENTRIES);
    }

    override public function getPropertyId():Int {
        return (TimelineType.pathConstraintMix << 24) + pathConstraintIndex;
    }

    #if !spine_no_inline inline #end public function setPathConstraintIndex(index:Int):Void {
        if (index < 0) throw new IllegalArgumentException("index must be >= 0.");
        this.pathConstraintIndex = index;
    }

    /** The index of the path constraint slot in {@link Skeleton#getPathConstraints()} that will be changed. */
    #if !spine_no_inline inline #end public function getPathConstraintIndex():Int {
        return pathConstraintIndex;
    }

    /** The time in seconds, rotate mix, and translate mix for each key frame. */
    #if !spine_no_inline inline #end public function getFrames():FloatArray {
        return frames;
    }

    /** The time in seconds, rotate mix, and translate mix for the specified key frame. */
    #if !spine_no_inline inline #end public function setFrame(frameIndex:Int, time:Float, rotateMix:Float, translateMix:Float):Void {
        frameIndex *= ENTRIES;
        frames[frameIndex] = time;
        frames[frameIndex + ROTATE] = rotateMix;
        frames[frameIndex + TRANSLATE] = translateMix;
    }

    override public function apply(skeleton:Skeleton, lastTime:Float, time:Float, events:Array<Event>, alpha:Float, blend:MixBlend, direction:MixDirection):Void {

        var constraint:PathConstraint = skeleton.pathConstraints.get(pathConstraintIndex);
        var frames:FloatArray = this.frames;
        if (time < frames[0]) { // Time is before first frame.
            var _continueAfterSwitch19 = false; while(true) { var _switchCond19 = (blend); {
            if (_switchCond19 == setup) {
                constraint.rotateMix = constraint.data.rotateMix;
                constraint.translateMix = constraint.data.translateMix;
                return;
            } else if (_switchCond19 == first) {
                constraint.rotateMix += (constraint.data.rotateMix - constraint.rotateMix) * alpha;
                constraint.translateMix += (constraint.data.translateMix - constraint.translateMix) * alpha;
            } } break; }
            return;
        }

        var rotate:Float = 0; var translate:Float = 0;
        if (time >= frames[frames.length - ENTRIES]) { // Time is after last frame.
            rotate = frames[frames.length + PREV_ROTATE];
            translate = frames[frames.length + PREV_TRANSLATE];
        } else {
            // Interpolate between the previous frame and the current frame.
            var frame:Int = Animation.binarySearchWithStep(frames, time, ENTRIES);
            rotate = frames[frame + PREV_ROTATE];
            translate = frames[frame + PREV_TRANSLATE];
            var frameTime:Float = frames[frame];
            var percent:Float = getCurvePercent(Std.int(frame / ENTRIES - 1),
                1 - (time - frameTime) / (frames[frame + PREV_TIME] - frameTime));

            rotate += (frames[frame + ROTATE] - rotate) * percent;
            translate += (frames[frame + TRANSLATE] - translate) * percent;
        }

        if (blend == setup) {
            constraint.rotateMix = constraint.data.rotateMix + (rotate - constraint.data.rotateMix) * alpha;
            constraint.translateMix = constraint.data.translateMix + (translate - constraint.data.translateMix) * alpha;
        } else {
            constraint.rotateMix += (rotate - constraint.rotateMix) * alpha;
            constraint.translateMix += (translate - constraint.translateMix) * alpha;
        }
    }

    inline public static var LINEAR:Float = CurveTimeline.LINEAR;

    inline public static var STEPPED:Float = CurveTimeline.STEPPED;

    inline public static var BEZIER:Float = CurveTimeline.BEZIER;

    inline private static var BEZIER_SIZE:Int = CurveTimeline.BEZIER_SIZE;
}

class MixBlend_enum {

    public inline static var setup_value = 0;
    public inline static var first_value = 1;
    public inline static var replace_value = 2;
    public inline static var add_value = 3;

    public inline static var setup_name = "setup";
    public inline static var first_name = "first";
    public inline static var replace_name = "replace";
    public inline static var add_name = "add";

    public inline static function valueOf(value:String):MixBlend {
        return switch (value) {
            case "setup": MixBlend.setup;
            case "first": MixBlend.first;
            case "replace": MixBlend.replace;
            case "add": MixBlend.add;
            default: MixBlend.setup;
        };
    }

}

class MixDirection_enum {

    public inline static var directionIn_value = 0;
    public inline static var directionOut_value = 1;

    public inline static var directionIn_name = "directionIn";
    public inline static var directionOut_name = "directionOut";

    public inline static function valueOf(value:String):MixDirection {
        return switch (value) {
            case "directionIn": MixDirection.directionIn;
            case "directionOut": MixDirection.directionOut;
            default: MixDirection.directionIn;
        };
    }

}

class TimelineType_enum {

    public inline static var rotate_value = 0;
    public inline static var translate_value = 1;
    public inline static var scale_value = 2;
    public inline static var shear_value = 3;
    public inline static var attachment_value = 4;
    public inline static var color_value = 5;
    public inline static var deform_value = 6;
    public inline static var event_value = 7;
    public inline static var drawOrder_value = 8;
    public inline static var ikConstraint_value = 9;
    public inline static var transformConstraint_value = 10;
    public inline static var pathConstraintPosition_value = 11;
    public inline static var pathConstraintSpacing_value = 12;
    public inline static var pathConstraintMix_value = 13;
    public inline static var twoColor_value = 14;

    public inline static var rotate_name = "rotate";
    public inline static var translate_name = "translate";
    public inline static var scale_name = "scale";
    public inline static var shear_name = "shear";
    public inline static var attachment_name = "attachment";
    public inline static var color_name = "color";
    public inline static var deform_name = "deform";
    public inline static var event_name = "event";
    public inline static var drawOrder_name = "drawOrder";
    public inline static var ikConstraint_name = "ikConstraint";
    public inline static var transformConstraint_name = "transformConstraint";
    public inline static var pathConstraintPosition_name = "pathConstraintPosition";
    public inline static var pathConstraintSpacing_name = "pathConstraintSpacing";
    public inline static var pathConstraintMix_name = "pathConstraintMix";
    public inline static var twoColor_name = "twoColor";

    public inline static function valueOf(value:String):TimelineType {
        return switch (value) {
            case "rotate": TimelineType.rotate;
            case "translate": TimelineType.translate;
            case "scale": TimelineType.scale;
            case "shear": TimelineType.shear;
            case "attachment": TimelineType.attachment;
            case "color": TimelineType.color;
            case "deform": TimelineType.deform;
            case "event": TimelineType.event;
            case "drawOrder": TimelineType.drawOrder;
            case "ikConstraint": TimelineType.ikConstraint;
            case "transformConstraint": TimelineType.transformConstraint;
            case "pathConstraintPosition": TimelineType.pathConstraintPosition;
            case "pathConstraintSpacing": TimelineType.pathConstraintSpacing;
            case "pathConstraintMix": TimelineType.pathConstraintMix;
            case "twoColor": TimelineType.twoColor;
            default: TimelineType.rotate;
        };
    }

}
