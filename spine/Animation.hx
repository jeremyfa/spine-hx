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

import spine.Animation.MixBlend.*;
import spine.Animation.MixDirection.*;
import spine.utils.SpineUtils.*;

import spine.support.graphics.Color;
import spine.support.utils.Array;
import spine.support.utils.FloatArray;

import spine.support.utils.ObjectSet;

import spine.attachments.Attachment;
import spine.attachments.VertexAttachment;

/** Stores a list of timelines to animate a skeleton's pose over time. */
class Animation {
    private var hashCode = Std.int(Math.random() * 99999999);

    public var name:String;
    public var timelines:Array<Timeline>;
    public var timelineIds:ObjectSet<String>;
    public var duration:Float = 0;

    public function new(name:String, timelines:Array<Timeline>, duration:Float) {
        if (name == null) throw new IllegalArgumentException("name cannot be null.");
        this.name = name;
        this.duration = duration;
        timelineIds = new ObjectSet(timelines.size);
        setTimelines(timelines);
    }

    /** If the returned array or the timelines it contains are modified, {@link #setTimelines(Array)} must be called. */
    public function getTimelines():Array<Timeline> {
        return timelines;
    }

    public function setTimelines(timelines:Array<Timeline>):Void {
        if (timelines == null) throw new IllegalArgumentException("timelines cannot be null.");
        this.timelines = timelines;

        var n:Int = timelines.size;
        timelineIds.clear(n);
        var items = timelines.items;
        var i:Int = 0; while (i < n) {
            timelineIds.addAll((fastCast(items[i], Timeline)).getPropertyIds()); i++; }
    }

    /** Returns true if this animation contains a timeline with any of the specified property IDs. */
    public function hasTimeline(propertyIds:StringArray):Bool {
        for (id in propertyIds) {
            if (timelineIds.contains(id)) return true; }
        return false;
    }

    /** The duration of the animation in seconds, which is usually the highest time of all frames in the timeline. The duration is
     * used to know when it has completed and when it should loop back to the start. */
    public function getDuration():Float {
        return duration;
    }

    public function setDuration(duration:Float):Void {
        this.duration = duration;
    }

    /** Applies the animation's timelines to the specified skeleton.
     * <p>
     * See Timeline {@link Timeline#apply(Skeleton, float, float, Array, float, MixBlend, MixDirection)}.
     * @param skeleton The skeleton the animation is being applied to. This provides access to the bones, slots, and other skeleton
     *           components the timelines may change.
     * @param lastTime The last time in seconds this animation was applied. Some timelines trigger only at specific times rather
     *           than every frame. Pass -1 the first time an animation is applied to ensure frame 0 is triggered.
     * @param time The time in seconds the skeleton is being posed for. Most timelines find the frame before and the frame after
     *           this time and interpolate between the frame values. If beyond the {@link #getDuration()} and <code>loop</code> is
     *           true then the animation will repeat, else the last frame will be applied.
     * @param loop If true, the animation repeats after the {@link #getDuration()}.
     * @param events If any events are fired, they are added to this list. Can be null to ignore fired events or if no timelines
     *           fire events.
     * @param alpha 0 applies the current or setup values (depending on <code>blend</code>). 1 applies the timeline values. Between
     *           0 and 1 applies values between the current or setup values and the timeline values. By adjusting
     *           <code>alpha</code> over time, an animation can be mixed in or out. <code>alpha</code> can also be useful to apply
     *           animations on top of each other (layering).
     * @param blend Controls how mixing is applied when <code>alpha</code> < 1.
     * @param direction Indicates whether the timelines are mixing in or out. Used by timelines which perform instant transitions,
     *           such as {@link DrawOrderTimeline} or {@link AttachmentTimeline}. */
    public function apply(skeleton:Skeleton, lastTime:Float, time:Float, loop:Bool, events:Array<Event>, alpha:Float, blend:MixBlend, direction:MixDirection):Void {
        if (skeleton == null) throw new IllegalArgumentException("skeleton cannot be null.");

        if (loop && duration != 0) {
            time %= duration;
            if (lastTime > 0) lastTime %= duration;
        }

        var timelines = this.timelines.items;
        var i:Int = 0; var n:Int = this.timelines.size; while (i < n) {
            (fastCast(timelines[i], Timeline)).apply(skeleton, lastTime, time, events, alpha, blend, direction); i++; }
    }

    /** The animation's name, which is unique across all animations in the skeleton. */
    public function getName():String {
        return name;
    }

    public function toString():String {
        return name;
    }
}

/** Controls how timeline values are mixed with setup pose values or current pose values when a timeline is applied with
 * <code>alpha</code> < 1.
 * <p>
 * See Timeline {@link Timeline#apply(Skeleton, float, float, Array, float, MixBlend, MixDirection)}. */
enum abstract MixBlend(Int) from Int to Int {
    /** Transitions from the setup value to the timeline value (the current value is not used). Before the first frame, the
     * setup value is set. */
    var setup = 0;
    /** Transitions from the current value to the timeline value. Before the first frame, transitions from the current value to
     * the setup value. Timelines which perform instant transitions, such as {@link DrawOrderTimeline} or
     * {@link AttachmentTimeline}, use the setup value before the first frame.
     * <p>
     * <code>first</code> is intended for the first animations applied, not for animations layered on top of those. */
    var first = 1;
    /** Transitions from the current value to the timeline value. No change is made before the first frame (the current value is
     * kept until the first frame).
     * <p>
     * <code>replace</code> is intended for animations layered on top of others, not for the first animations applied. */
    var replace = 2;
    /** Transitions from the current value to the current value plus the timeline value. No change is made before the first
     * frame (the current value is kept until the first frame).
     * <p>
     * <code>add</code> is intended for animations layered on top of others, not for the first animations applied. Properties
     * set by additive animations must be set manually or by another animation before applying the additive animations, else the
     * property values will increase each time the additive animations are applied. */
    var add = 3;
}

/** Indicates whether a timeline's <code>alpha</code> is mixing out over time toward 0 (the setup or current pose value) or
 * mixing in toward 1 (the timeline's value). Some timelines use this to decide how values are applied.
 * <p>
 * See Timeline {@link Timeline#apply(Skeleton, float, float, Array, float, MixBlend, MixDirection)}. */
enum abstract MixDirection(Int) from Int to Int {
    var directionIn = 0; var directionOut = 1;
}

enum abstract Property(Int) from Int to Int {
    var rotate = 0; var x = 1; var y = 2; var scaleX = 3; var scaleY = 4; var shearX = 5; var shearY = 6; //
    var rgb = 7; var alpha = 8; var rgb2 = 9; //
    var attachment = 10; var deform = 11; //
    var event = 12; var drawOrder = 13; //
    var ikConstraint = 14; var transformConstraint = 15; //
    var pathConstraintPosition = 16; var pathConstraintSpacing = 17; var pathConstraintMix = 18;
}

/** The base class for all timelines. */
class Timeline {
    private var _propertyIds:StringArray;
    public var frames:FloatArray;

    /** @param propertyIds Unique identifiers for the properties the timeline modifies. */
    public function new(frameCount:Int, propertyIds:StringArray) {
        if (propertyIds == null) throw new IllegalArgumentException("propertyIds cannot be null.");
        this._propertyIds = propertyIds;
        frames = FloatArray.create(frameCount * getFrameEntries());
    }

    /** Uniquely encodes both the type of this timeline and the skeleton properties that it affects. */
    public function getPropertyIds():StringArray {
        return _propertyIds;
    }

    /** The time in seconds and any other values for each frame. */
    public function getFrames():FloatArray {
        return frames;
    }

    /** The number of entries stored per frame. */
    public function getFrameEntries():Int {
        return 1;
    }

    /** The number of frames for this timeline. */
    public function getFrameCount():Int {
        return Std.int(frames.length / getFrameEntries());
    }

    public function getDuration():Float {
        return frames[frames.length - getFrameEntries()];
    }

    /** Applies this timeline to the skeleton.
     * @param skeleton The skeleton to which the timeline is being applied. This provides access to the bones, slots, and other
     *           skeleton components that the timeline may change.
     * @param lastTime The last time in seconds this timeline was applied. Timelines such as {@link EventTimeline} trigger only
     *           at specific times rather than every frame. In that case, the timeline triggers everything between
     *           <code>lastTime</code> (exclusive) and <code>time</code> (inclusive). Pass -1 the first time an animation is
     *           applied to ensure frame 0 is triggered.
     * @param time The time in seconds that the skeleton is being posed for. Most timelines find the frame before and the frame
     *           after this time and interpolate between the frame values. If beyond the last frame, the last frame will be
     *           applied.
     * @param events If any events are fired, they are added to this list. Can be null to ignore fired events or if the timeline
     *           does not fire events.
     * @param alpha 0 applies the current or setup value (depending on <code>blend</code>). 1 applies the timeline value.
     *           Between 0 and 1 applies a value between the current or setup value and the timeline value. By adjusting
     *           <code>alpha</code> over time, an animation can be mixed in or out. <code>alpha</code> can also be useful to
     *           apply animations on top of each other (layering).
     * @param blend Controls how mixing is applied when <code>alpha</code> < 1.
     * @param direction Indicates whether the timeline is mixing in or out. Used by timelines which perform instant transitions,
     *           such as {@link DrawOrderTimeline} or {@link AttachmentTimeline}, and others such as {@link ScaleTimeline}. */
    public function apply(skeleton:Skeleton, lastTime:Float, time:Float, events:Array<Event>, alpha:Float, blend:MixBlend, direction:MixDirection):Void { }

    /** Linear search using a stride of 1.
     * @param time Must be >= the first value in <code>frames</code>.
     * @return The index of the first value <= <code>time</code>. */
    static public function search(frames:FloatArray, time:Float):Int {
        var n:Int = frames.length;
        var i:Int = 1; while (i < n) {
            if (frames[i] > time) return i - 1; i++; }
        return n - 1;
    }

    /** Linear search using the specified stride.
     * @param time Must be >= the first value in <code>frames</code>.
     * @return The index of the first value <= <code>time</code>. */
    static public function searchWithStep(frames:FloatArray, time:Float, step:Int):Int {
        var n:Int = frames.length;
        var i:Int = step; while (i < n) {
            if (frames[i] > time) return i - step; i += step; }
        return n - step;
    }
}

/** An interface for timelines which change the property of a bone. */
interface BoneTimeline {
    /** The index of the bone in {@link Skeleton#getBones()} that will be changed when this timeline is applied. */
    public function getBoneIndex():Int;
}

/** An interface for timelines which change the property of a slot. */
interface SlotTimeline {
    /** The index of the slot in {@link Skeleton#getSlots()} that will be changed when this timeline is applied. */
    public function getSlotIndex():Int;
}

/** The base class for timelines that interpolate between frame values using stepped, linear, or a Bezier curve. */
class CurveTimeline extends Timeline {
    inline public static var LINEAR:Int = 0; inline public static var STEPPED:Int = 1; inline public static var BEZIER:Int = 2; inline public static var BEZIER_SIZE:Int = 18;

    public var curves:FloatArray;

    /** @param bezierCount The maximum number of Bezier curves. See {@link #shrink(int)}.
     * @param propertyIds Unique identifiers for the properties the timeline modifies. */
    public function new(frameCount:Int, bezierCount:Int, propertyIds:StringArray) {
        super(frameCount, propertyIds);
        curves = FloatArray.create(frameCount + bezierCount * BEZIER_SIZE);
        curves[frameCount - 1] = STEPPED;
    }

    /** Sets the specified frame to linear interpolation.
     * @param frame Between 0 and <code>frameCount - 1</code>, inclusive. */
    public function setLinear(frame:Int):Void {
        curves[frame] = LINEAR;
    }

    /** Sets the specified frame to stepped interpolation.
     * @param frame Between 0 and <code>frameCount - 1</code>, inclusive. */
    public function setStepped(frame:Int):Void {
        curves[frame] = STEPPED;
    }

    /** Returns the interpolation type for the specified frame.
     * @param frame Between 0 and <code>frameCount - 1</code>, inclusive.
     * @return {@link #LINEAR}, {@link #STEPPED}, or {@link #BEZIER} + the index of the Bezier segments. */
    public function getCurveType(frame:Int):Int {
        return Std.int(curves[frame]);
    }

    /** Shrinks the storage for Bezier curves, for use when <code>bezierCount</code> (specified in the constructor) was larger
     * than the actual number of Bezier curves. */
    public function shrink(bezierCount:Int):Void {
        var size:Int = getFrameCount() + bezierCount * BEZIER_SIZE;
        if (curves.length > size) {
            var newCurves:FloatArray = FloatArray.create(size);
            arraycopy(curves, 0, newCurves, 0, size);
            curves = newCurves;
        }
    }

    /** Stores the segments for the specified Bezier curve. For timelines that modify multiple values, there may be more than
     * one curve per frame.
     * @param bezier The ordinal of this Bezier curve for this timeline, between 0 and <code>bezierCount - 1</code> (specified
     *           in the constructor), inclusive.
     * @param frame Between 0 and <code>frameCount - 1</code>, inclusive.
     * @param value The index of the value for the frame this curve is used for.
     * @param time1 The time for the first key.
     * @param value1 The value for the first key.
     * @param cx1 The time for the first Bezier handle.
     * @param cy1 The value for the first Bezier handle.
     * @param cx2 The time of the second Bezier handle.
     * @param cy2 The value for the second Bezier handle.
     * @param time2 The time for the second key.
     * @param value2 The value for the second key. */
    public function setBezier(bezier:Int, frame:Int, value:Int, time1:Float, value1:Float, cx1:Float, cy1:Float, cx2:Float, cy2:Float, time2:Float, value2:Float):Void {
        var curves:FloatArray = this.curves;
        var i:Int = getFrameCount() + bezier * BEZIER_SIZE;
        if (value == 0) curves[frame] = BEZIER + i;
        var tmpx:Float = (time1 - cx1 * 2 + cx2) * 0.03; var tmpy:Float = (value1 - cy1 * 2 + cy2) * 0.03;
        var dddx:Float = ((cx1 - cx2) * 3 - time1 + time2) * 0.006; var dddy:Float = ((cy1 - cy2) * 3 - value1 + value2) * 0.006;
        var ddx:Float = tmpx * 2 + dddx; var ddy:Float = tmpy * 2 + dddy;
        var dx:Float = (cx1 - time1) * 0.3 + tmpx + dddx * 0.16666667; var dy:Float = (cy1 - value1) * 0.3 + tmpy + dddy * 0.16666667;
        var x:Float = time1 + dx; var y:Float = value1 + dy;
        var n:Int = i + BEZIER_SIZE; while (i < n) {
            curves[i] = x;
            curves[i + 1] = y;
            dx += ddx;
            dy += ddy;
            ddx += dddx;
            ddy += dddy;
            x += dx;
            y += dy;
        i += 2; }
    }

    /** Returns the Bezier interpolated value for the specified time.
     * @param frameIndex The index into {@link #getFrames()} for the values of the frame before <code>time</code>.
     * @param valueOffset The offset from <code>frameIndex</code> to the value this curve is used for.
     * @param i The index of the Bezier segments. See {@link #getCurveType(int)}. */
    public function getBezierValue(time:Float, frameIndex:Int, valueOffset:Int, i:Int):Float {
        var curves:FloatArray = this.curves;
        if (curves[i] > time) {
            var x:Float = frames[frameIndex]; var y:Float = frames[frameIndex + valueOffset];
            return y + (time - x) / (curves[i] - x) * (curves[i + 1] - y);
        }
        var n:Int = i + BEZIER_SIZE;
        i += 2; while (i < n) {
            if (curves[i] >= time) {
                var x:Float = curves[i - 2]; var y:Float = curves[i - 1];
                return y + (time - x) / (curves[i] - x) * (curves[i + 1] - y);
            }
        i += 2; }
        frameIndex += getFrameEntries();
        var x:Float = curves[n - 2]; var y:Float = curves[n - 1];
        return y + (time - x) / (frames[frameIndex] - x) * (frames[frameIndex + valueOffset] - y);
    }
}

/** The base class for a {@link CurveTimeline} that sets one property. */
class CurveTimeline1 extends CurveTimeline {
    inline public static var ENTRIES:Int = 2;
    inline public static var VALUE:Int = 1;

    /** @param bezierCount The maximum number of Bezier curves. See {@link #shrink(int)}.
     * @param propertyId Unique identifier for the property the timeline modifies. */
    public function new(frameCount:Int, bezierCount:Int, propertyId:String) {
        super(frameCount, bezierCount, [propertyId]);
    }

    override public function getFrameEntries():Int {
        return ENTRIES;
    }

    /** Sets the time and value for the specified frame.
     * @param frame Between 0 and <code>frameCount</code>, inclusive.
     * @param time The frame time in seconds. */
    public function setFrame(frame:Int, time:Float, value:Float):Void {
        frame <<= 1;
        frames[frame] = time;
        frames[frame + VALUE] = value;
    }

    /** Returns the interpolated value for the specified time. */
    public function getCurveValue(time:Float):Float {
        var frames:FloatArray = this.frames;
        var i:Int = frames.length - 2;
        var ii:Int = 2; while (ii <= i) {
            if (frames[ii] > time) {
                i = ii - 2;
                break;
            }
        ii += 2; }

        var curveType:Int = Std.int(curves[i >> 1]);
        var _continueAfterSwitch0 = false; while(true) { var _switchCond0 = (curveType); {
        if (_switchCond0 == LINEAR) {
            var before:Float = frames[i]; var value:Float = frames[i + VALUE];
            return value + (time - before) / (frames[i + ENTRIES] - before) * (frames[i + ENTRIES + VALUE] - value);
        } else if (_switchCond0 == STEPPED) {
            return frames[i + VALUE];
        } } break; }
        return getBezierValue(time, i, VALUE, curveType - BEZIER);
    }

    inline public static var LINEAR:Int = CurveTimeline.LINEAR;

    inline public static var STEPPED:Int = CurveTimeline.STEPPED;

    inline public static var BEZIER:Int = CurveTimeline.BEZIER;

    inline public static var BEZIER_SIZE:Int = CurveTimeline.BEZIER_SIZE;
}

/** The base class for a {@link CurveTimeline} which sets two properties. */
class CurveTimeline2 extends CurveTimeline {
    inline public static var ENTRIES:Int = 3;
    inline public static var VALUE1:Int = 1; inline public static var VALUE2:Int = 2;

    /** @param bezierCount The maximum number of Bezier curves. See {@link #shrink(int)}.
     * @param propertyId1 Unique identifier for the first property the timeline modifies.
     * @param propertyId2 Unique identifier for the second property the timeline modifies. */
    public function new(frameCount:Int, bezierCount:Int, propertyId1:String, propertyId2:String) {
        super(frameCount, bezierCount, [propertyId1, propertyId2]);
    }

    override #if !spine_no_inline inline #end public function getFrameEntries():Int {
        return ENTRIES;
    }

    /** Sets the time and values for the specified frame.
     * @param frame Between 0 and <code>frameCount</code>, inclusive.
     * @param time The frame time in seconds. */
    #if !spine_no_inline inline #end public function setFrame(frame:Int, time:Float, value1:Float, value2:Float):Void {
        frame *= ENTRIES;
        frames[frame] = time;
        frames[frame + VALUE1] = value1;
        frames[frame + VALUE2] = value2;
    }

    inline public static var LINEAR:Int = CurveTimeline.LINEAR;

    inline public static var STEPPED:Int = CurveTimeline.STEPPED;

    inline public static var BEZIER:Int = CurveTimeline.BEZIER;

    inline public static var BEZIER_SIZE:Int = CurveTimeline.BEZIER_SIZE;
}

/** Changes a bone's local {@link Bone#getRotation()}. */
class RotateTimeline extends CurveTimeline1 implements BoneTimeline {
    public var boneIndex:Int = 0;

    public function new(frameCount:Int, bezierCount:Int, boneIndex:Int) {
        super(frameCount, bezierCount, Property.rotate + "|" + boneIndex);
        this.boneIndex = boneIndex;
    }

    #if !spine_no_inline inline #end public function getBoneIndex():Int {
        return boneIndex;
    }

    override public function apply(skeleton:Skeleton, lastTime:Float, time:Float, events:Array<Event>, alpha:Float, blend:MixBlend, direction:MixDirection):Void {

        var bone:Bone = skeleton.bones.get(boneIndex);
        if (!bone.active) return;

        if (time < frames[0]) { // Time is before first frame.
            var _continueAfterSwitch1 = false; while(true) { var _switchCond1 = (blend); {
            if (_switchCond1 == setup) {
                bone.rotation = bone.data.rotation;
                return;
            } else if (_switchCond1 == first) {
                bone.rotation += (bone.data.rotation - bone.rotation) * alpha;
            } } break; }
            return;
        }

        var r:Float = getCurveValue(time);
        var _continueAfterSwitch2 = false; while(true) { var _switchCond2 = (blend); {
        if (_switchCond2 == setup) {
            bone.rotation = bone.data.rotation + r * alpha;
            break;
        } else if (_switchCond2 == first) {
                r += bone.data.rotation - bone.rotation;
            // Fall through.
            bone.rotation += r * alpha;
        } else if (_switchCond2 == replace) {
            r += bone.data.rotation - bone.rotation;
            // Fall through.
            bone.rotation += r * alpha;
        } else if (_switchCond2 == add) {
            bone.rotation += r * alpha;
        } } break; }
    }

    inline public static var ENTRIES:Int = CurveTimeline1.ENTRIES;

    inline public static var VALUE:Int = CurveTimeline1.VALUE;

    inline public static var LINEAR:Int = CurveTimeline.LINEAR;

    inline public static var STEPPED:Int = CurveTimeline.STEPPED;

    inline public static var BEZIER:Int = CurveTimeline.BEZIER;

    inline public static var BEZIER_SIZE:Int = CurveTimeline.BEZIER_SIZE;
}

/** Changes a bone's local {@link Bone#getX()} and {@link Bone#getY()}. */
class TranslateTimeline extends CurveTimeline2 implements BoneTimeline {
    public var boneIndex:Int = 0;

    public function new(frameCount:Int, bezierCount:Int, boneIndex:Int) {
        super(frameCount, bezierCount, //
            Property.x + "|" + boneIndex, //
            Property.y + "|" + boneIndex);
        this.boneIndex = boneIndex;
    }

    #if !spine_no_inline inline #end public function getBoneIndex():Int {
        return boneIndex;
    }

    override public function apply(skeleton:Skeleton, lastTime:Float, time:Float, events:Array<Event>, alpha:Float, blend:MixBlend, direction:MixDirection):Void {

        var bone:Bone = skeleton.bones.get(boneIndex);
        if (!bone.active) return;

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
        var i:Int = Timeline.searchWithStep(frames, time, ENTRIES); var curveType:Int = Std.int(curves[Std.int(i / ENTRIES)]);
        var _continueAfterSwitch4 = false; while(true) { var _switchCond4 = (curveType); {
        if (_switchCond4 == LINEAR) {
            var before:Float = frames[i];
            x = frames[i + VALUE1];
            y = frames[i + VALUE2];
            var t:Float = (time - before) / (frames[i + ENTRIES] - before);
            x += (frames[i + ENTRIES + VALUE1] - x) * t;
            y += (frames[i + ENTRIES + VALUE2] - y) * t;
            break;
        } else if (_switchCond4 == STEPPED) {
            x = frames[i + VALUE1];
            y = frames[i + VALUE2];
            break;
        } else {
            x = getBezierValue(time, i, VALUE1, Std.int(curveType - BEZIER));
            y = getBezierValue(time, i, VALUE2, curveType + BEZIER_SIZE - BEZIER);
        } } break; }

        var _continueAfterSwitch5 = false; while(true) { var _switchCond5 = (blend); {
        if (_switchCond5 == setup) {
            bone.x = bone.data.x + x * alpha;
            bone.y = bone.data.y + y * alpha;
            break;
        } else if (_switchCond5 == first) {
                bone.x += (bone.data.x + x - bone.x) * alpha;
            bone.y += (bone.data.y + y - bone.y) * alpha;
            break;
        } else if (_switchCond5 == replace) {
            bone.x += (bone.data.x + x - bone.x) * alpha;
            bone.y += (bone.data.y + y - bone.y) * alpha;
            break;
        } else if (_switchCond5 == add) {
            bone.x += x * alpha;
            bone.y += y * alpha;
        } } break; }
    }

    inline public static var ENTRIES:Int = CurveTimeline2.ENTRIES;

    inline public static var VALUE1:Int = CurveTimeline2.VALUE1;

    inline public static var VALUE2:Int = CurveTimeline2.VALUE2;

    inline public static var LINEAR:Int = CurveTimeline.LINEAR;

    inline public static var STEPPED:Int = CurveTimeline.STEPPED;

    inline public static var BEZIER:Int = CurveTimeline.BEZIER;

    inline public static var BEZIER_SIZE:Int = CurveTimeline.BEZIER_SIZE;
}

/** Changes a bone's local {@link Bone#getX()}. */
class TranslateXTimeline extends CurveTimeline1 implements BoneTimeline {
    public var boneIndex:Int = 0;

    public function new(frameCount:Int, bezierCount:Int, boneIndex:Int) {
        super(frameCount, bezierCount, Property.x + "|" + boneIndex);
        this.boneIndex = boneIndex;
    }

    #if !spine_no_inline inline #end public function getBoneIndex():Int {
        return boneIndex;
    }

    override public function apply(skeleton:Skeleton, lastTime:Float, time:Float, events:Array<Event>, alpha:Float, blend:MixBlend, direction:MixDirection):Void {

        var bone:Bone = skeleton.bones.get(boneIndex);
        if (!bone.active) return;

        var frames:FloatArray = this.frames;
        if (time < frames[0]) { // Time is before first frame.
            var _continueAfterSwitch6 = false; while(true) { var _switchCond6 = (blend); {
            if (_switchCond6 == setup) {
                bone.x = bone.data.x;
                return;
            } else if (_switchCond6 == first) {
                bone.x += (bone.data.x - bone.x) * alpha;
            } } break; }
            return;
        }

        var x:Float = getCurveValue(time);
        var _continueAfterSwitch7 = false; while(true) { var _switchCond7 = (blend); {
        if (_switchCond7 == setup) {
            bone.x = bone.data.x + x * alpha;
            break;
        } else if (_switchCond7 == first) {
                bone.x += (bone.data.x + x - bone.x) * alpha;
            break;
        } else if (_switchCond7 == replace) {
            bone.x += (bone.data.x + x - bone.x) * alpha;
            break;
        } else if (_switchCond7 == add) {
            bone.x += x * alpha;
        } } break; }
    }

    inline public static var ENTRIES:Int = CurveTimeline1.ENTRIES;

    inline public static var VALUE:Int = CurveTimeline1.VALUE;

    inline public static var LINEAR:Int = CurveTimeline.LINEAR;

    inline public static var STEPPED:Int = CurveTimeline.STEPPED;

    inline public static var BEZIER:Int = CurveTimeline.BEZIER;

    inline public static var BEZIER_SIZE:Int = CurveTimeline.BEZIER_SIZE;
}

/** Changes a bone's local {@link Bone#getY()}. */
class TranslateYTimeline extends CurveTimeline1 implements BoneTimeline {
    public var boneIndex:Int = 0;

    public function new(frameCount:Int, bezierCount:Int, boneIndex:Int) {
        super(frameCount, bezierCount, Property.y + "|" + boneIndex);
        this.boneIndex = boneIndex;
    }

    #if !spine_no_inline inline #end public function getBoneIndex():Int {
        return boneIndex;
    }

    override public function apply(skeleton:Skeleton, lastTime:Float, time:Float, events:Array<Event>, alpha:Float, blend:MixBlend, direction:MixDirection):Void {

        var bone:Bone = skeleton.bones.get(boneIndex);
        if (!bone.active) return;

        var frames:FloatArray = this.frames;
        if (time < frames[0]) { // Time is before first frame.
            var _continueAfterSwitch8 = false; while(true) { var _switchCond8 = (blend); {
            if (_switchCond8 == setup) {
                bone.y = bone.data.y;
                return;
            } else if (_switchCond8 == first) {
                bone.y += (bone.data.y - bone.y) * alpha;
            } } break; }
            return;
        }

        var y:Float = getCurveValue(time);
        var _continueAfterSwitch9 = false; while(true) { var _switchCond9 = (blend); {
        if (_switchCond9 == setup) {
            bone.y = bone.data.y + y * alpha;
            break;
        } else if (_switchCond9 == first) {
                bone.y += (bone.data.y + y - bone.y) * alpha;
            break;
        } else if (_switchCond9 == replace) {
            bone.y += (bone.data.y + y - bone.y) * alpha;
            break;
        } else if (_switchCond9 == add) {
            bone.y += y * alpha;
        } } break; }
    }

    inline public static var ENTRIES:Int = CurveTimeline1.ENTRIES;

    inline public static var VALUE:Int = CurveTimeline1.VALUE;

    inline public static var LINEAR:Int = CurveTimeline.LINEAR;

    inline public static var STEPPED:Int = CurveTimeline.STEPPED;

    inline public static var BEZIER:Int = CurveTimeline.BEZIER;

    inline public static var BEZIER_SIZE:Int = CurveTimeline.BEZIER_SIZE;
}

/** Changes a bone's local {@link Bone#getScaleX()} and {@link Bone#getScaleY()}. */
class ScaleTimeline extends CurveTimeline2 implements BoneTimeline {
    public var boneIndex:Int = 0;

    public function new(frameCount:Int, bezierCount:Int, boneIndex:Int) {
        super(frameCount, bezierCount, //
            Property.scaleX + "|" + boneIndex, //
            Property.scaleY + "|" + boneIndex);
        this.boneIndex = boneIndex;
    }

    #if !spine_no_inline inline #end public function getBoneIndex():Int {
        return boneIndex;
    }

    override public function apply(skeleton:Skeleton, lastTime:Float, time:Float, events:Array<Event>, alpha:Float, blend:MixBlend, direction:MixDirection):Void {

        var bone:Bone = skeleton.bones.get(boneIndex);
        if (!bone.active) return;

        var frames:FloatArray = this.frames;
        if (time < frames[0]) { // Time is before first frame.
            var _continueAfterSwitch10 = false; while(true) { var _switchCond10 = (blend); {
            if (_switchCond10 == setup) {
                bone.scaleX = bone.data.scaleX;
                bone.scaleY = bone.data.scaleY;
                return;
            } else if (_switchCond10 == first) {
                bone.scaleX += (bone.data.scaleX - bone.scaleX) * alpha;
                bone.scaleY += (bone.data.scaleY - bone.scaleY) * alpha;
            } } break; }
            return;
        }

        var x:Float = 0; var y:Float = 0;
        var i:Int = Timeline.searchWithStep(frames, time, ENTRIES); var curveType:Int = Std.int(curves[Std.int(i / ENTRIES)]);
        var _continueAfterSwitch11 = false; while(true) { var _switchCond11 = (curveType); {
        if (_switchCond11 == LINEAR) {
            var before:Float = frames[i];
            x = frames[i + VALUE1];
            y = frames[i + VALUE2];
            var t:Float = (time - before) / (frames[i + ENTRIES] - before);
            x += (frames[i + ENTRIES + VALUE1] - x) * t;
            y += (frames[i + ENTRIES + VALUE2] - y) * t;
            break;
        } else if (_switchCond11 == STEPPED) {
            x = frames[i + VALUE1];
            y = frames[i + VALUE2];
            break;
        } else {
            x = getBezierValue(time, i, VALUE1, Std.int(curveType - BEZIER));
            y = getBezierValue(time, i, VALUE2, curveType + BEZIER_SIZE - BEZIER);
        } } break; }
        x *= bone.data.scaleX;
        y *= bone.data.scaleY;

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
                var _continueAfterSwitch12 = false; while(true) { var _switchCond12 = (blend); {
                if (_switchCond12 == setup) {
                    bx = bone.data.scaleX;
                    by = bone.data.scaleY;
                    bone.scaleX = bx + (Math.abs(x) * MathUtils.signum(bx) - bx) * alpha;
                    bone.scaleY = by + (Math.abs(y) * MathUtils.signum(by) - by) * alpha;
                    break;
                } else if (_switchCond12 == first) {
                        bx = bone.scaleX;
                    by = bone.scaleY;
                    bone.scaleX = bx + (Math.abs(x) * MathUtils.signum(bx) - bx) * alpha;
                    bone.scaleY = by + (Math.abs(y) * MathUtils.signum(by) - by) * alpha;
                    break;
                } else if (_switchCond12 == replace) {
                    bx = bone.scaleX;
                    by = bone.scaleY;
                    bone.scaleX = bx + (Math.abs(x) * MathUtils.signum(bx) - bx) * alpha;
                    bone.scaleY = by + (Math.abs(y) * MathUtils.signum(by) - by) * alpha;
                    break;
                } else if (_switchCond12 == add) {
                    bone.scaleX += (x - bone.data.scaleX) * alpha;
                    bone.scaleY += (y - bone.data.scaleY) * alpha;
                } } break; }
            } else {
                var _continueAfterSwitch13 = false; while(true) { var _switchCond13 = (blend); {
                if (_switchCond13 == setup) {
                    bx = Math.abs(bone.data.scaleX) * MathUtils.signum(x);
                    by = Math.abs(bone.data.scaleY) * MathUtils.signum(y);
                    bone.scaleX = bx + (x - bx) * alpha;
                    bone.scaleY = by + (y - by) * alpha;
                    break;
                } else if (_switchCond13 == first) {
                        bx = Math.abs(bone.scaleX) * MathUtils.signum(x);
                    by = Math.abs(bone.scaleY) * MathUtils.signum(y);
                    bone.scaleX = bx + (x - bx) * alpha;
                    bone.scaleY = by + (y - by) * alpha;
                    break;
                } else if (_switchCond13 == replace) {
                    bx = Math.abs(bone.scaleX) * MathUtils.signum(x);
                    by = Math.abs(bone.scaleY) * MathUtils.signum(y);
                    bone.scaleX = bx + (x - bx) * alpha;
                    bone.scaleY = by + (y - by) * alpha;
                    break;
                } else if (_switchCond13 == add) {
                    bone.scaleX += (x - bone.data.scaleX) * alpha;
                    bone.scaleY += (y - bone.data.scaleY) * alpha;
                } } break; }
            }
        }
    }

    inline public static var ENTRIES:Int = CurveTimeline2.ENTRIES;

    inline public static var VALUE1:Int = CurveTimeline2.VALUE1;

    inline public static var VALUE2:Int = CurveTimeline2.VALUE2;

    inline public static var LINEAR:Int = CurveTimeline.LINEAR;

    inline public static var STEPPED:Int = CurveTimeline.STEPPED;

    inline public static var BEZIER:Int = CurveTimeline.BEZIER;

    inline public static var BEZIER_SIZE:Int = CurveTimeline.BEZIER_SIZE;
}

/** Changes a bone's local {@link Bone#getScaleX()}. */
class ScaleXTimeline extends CurveTimeline1 implements BoneTimeline {
    public var boneIndex:Int = 0;

    public function new(frameCount:Int, bezierCount:Int, boneIndex:Int) {
        super(frameCount, bezierCount, Property.scaleX + "|" + boneIndex);
        this.boneIndex = boneIndex;
    }

    #if !spine_no_inline inline #end public function getBoneIndex():Int {
        return boneIndex;
    }

    override public function apply(skeleton:Skeleton, lastTime:Float, time:Float, events:Array<Event>, alpha:Float, blend:MixBlend, direction:MixDirection):Void {

        var bone:Bone = skeleton.bones.get(boneIndex);
        if (!bone.active) return;

        var frames:FloatArray = this.frames;
        if (time < frames[0]) { // Time is before first frame.
            var _continueAfterSwitch14 = false; while(true) { var _switchCond14 = (blend); {
            if (_switchCond14 == setup) {
                bone.scaleX = bone.data.scaleX;
                return;
            } else if (_switchCond14 == first) {
                bone.scaleX += (bone.data.scaleX - bone.scaleX) * alpha;
            } } break; }
            return;
        }

        var x:Float = getCurveValue(time) * bone.data.scaleX;
        if (alpha == 1) {
            if (blend == add)
                bone.scaleX += x - bone.data.scaleX;
            else
                bone.scaleX = x;
        } else {
            // Mixing out uses sign of setup or current pose, else use sign of key.
            var bx:Float = 0;
            if (direction == spine.MixDirection.directionOut) {
                var _continueAfterSwitch15 = false; while(true) { var _switchCond15 = (blend); {
                if (_switchCond15 == setup) {
                    bx = bone.data.scaleX;
                    bone.scaleX = bx + (Math.abs(x) * MathUtils.signum(bx) - bx) * alpha;
                    break;
                } else if (_switchCond15 == first) {
                        bx = bone.scaleX;
                    bone.scaleX = bx + (Math.abs(x) * MathUtils.signum(bx) - bx) * alpha;
                    break;
                } else if (_switchCond15 == replace) {
                    bx = bone.scaleX;
                    bone.scaleX = bx + (Math.abs(x) * MathUtils.signum(bx) - bx) * alpha;
                    break;
                } else if (_switchCond15 == add) {
                    bone.scaleX += (x - bone.data.scaleX) * alpha;
                } } break; }
            } else {
                var _continueAfterSwitch16 = false; while(true) { var _switchCond16 = (blend); {
                if (_switchCond16 == setup) {
                    bx = Math.abs(bone.data.scaleX) * MathUtils.signum(x);
                    bone.scaleX = bx + (x - bx) * alpha;
                    break;
                } else if (_switchCond16 == first) {
                        bx = Math.abs(bone.scaleX) * MathUtils.signum(x);
                    bone.scaleX = bx + (x - bx) * alpha;
                    break;
                } else if (_switchCond16 == replace) {
                    bx = Math.abs(bone.scaleX) * MathUtils.signum(x);
                    bone.scaleX = bx + (x - bx) * alpha;
                    break;
                } else if (_switchCond16 == add) {
                    bone.scaleX += (x - bone.data.scaleX) * alpha;
                } } break; }
            }
        }
    }

    inline public static var ENTRIES:Int = CurveTimeline1.ENTRIES;

    inline public static var VALUE:Int = CurveTimeline1.VALUE;

    inline public static var LINEAR:Int = CurveTimeline.LINEAR;

    inline public static var STEPPED:Int = CurveTimeline.STEPPED;

    inline public static var BEZIER:Int = CurveTimeline.BEZIER;

    inline public static var BEZIER_SIZE:Int = CurveTimeline.BEZIER_SIZE;
}

/** Changes a bone's local {@link Bone#getScaleY()}. */
class ScaleYTimeline extends CurveTimeline1 implements BoneTimeline {
    public var boneIndex:Int = 0;

    public function new(frameCount:Int, bezierCount:Int, boneIndex:Int) {
        super(frameCount, bezierCount, Property.scaleY + "|" + boneIndex);
        this.boneIndex = boneIndex;
    }

    #if !spine_no_inline inline #end public function getBoneIndex():Int {
        return boneIndex;
    }

    override public function apply(skeleton:Skeleton, lastTime:Float, time:Float, events:Array<Event>, alpha:Float, blend:MixBlend, direction:MixDirection):Void {

        var bone:Bone = skeleton.bones.get(boneIndex);
        if (!bone.active) return;

        var frames:FloatArray = this.frames;
        if (time < frames[0]) { // Time is before first frame.
            var _continueAfterSwitch17 = false; while(true) { var _switchCond17 = (blend); {
            if (_switchCond17 == setup) {
                bone.scaleY = bone.data.scaleY;
                return;
            } else if (_switchCond17 == first) {
                bone.scaleY += (bone.data.scaleY - bone.scaleY) * alpha;
            } } break; }
            return;
        }

        var y:Float = getCurveValue(time) * bone.data.scaleY;
        if (alpha == 1) {
            if (blend == add)
                bone.scaleY += y - bone.data.scaleY;
            else
                bone.scaleY = y;
        } else {
            // Mixing out uses sign of setup or current pose, else use sign of key.
            var by:Float = 0;
            if (direction == spine.MixDirection.directionOut) {
                var _continueAfterSwitch18 = false; while(true) { var _switchCond18 = (blend); {
                if (_switchCond18 == setup) {
                    by = bone.data.scaleY;
                    bone.scaleY = by + (Math.abs(y) * MathUtils.signum(by) - by) * alpha;
                    break;
                } else if (_switchCond18 == first) {
                        by = bone.scaleY;
                    bone.scaleY = by + (Math.abs(y) * MathUtils.signum(by) - by) * alpha;
                    break;
                } else if (_switchCond18 == replace) {
                    by = bone.scaleY;
                    bone.scaleY = by + (Math.abs(y) * MathUtils.signum(by) - by) * alpha;
                    break;
                } else if (_switchCond18 == add) {
                    bone.scaleY += (y - bone.data.scaleY) * alpha;
                } } break; }
            } else {
                var _continueAfterSwitch19 = false; while(true) { var _switchCond19 = (blend); {
                if (_switchCond19 == setup) {
                    by = Math.abs(bone.data.scaleY) * MathUtils.signum(y);
                    bone.scaleY = by + (y - by) * alpha;
                    break;
                } else if (_switchCond19 == first) {
                        by = Math.abs(bone.scaleY) * MathUtils.signum(y);
                    bone.scaleY = by + (y - by) * alpha;
                    break;
                } else if (_switchCond19 == replace) {
                    by = Math.abs(bone.scaleY) * MathUtils.signum(y);
                    bone.scaleY = by + (y - by) * alpha;
                    break;
                } else if (_switchCond19 == add) {
                    bone.scaleY += (y - bone.data.scaleY) * alpha;
                } } break; }
            }
        }
    }

    inline public static var ENTRIES:Int = CurveTimeline1.ENTRIES;

    inline public static var VALUE:Int = CurveTimeline1.VALUE;

    inline public static var LINEAR:Int = CurveTimeline.LINEAR;

    inline public static var STEPPED:Int = CurveTimeline.STEPPED;

    inline public static var BEZIER:Int = CurveTimeline.BEZIER;

    inline public static var BEZIER_SIZE:Int = CurveTimeline.BEZIER_SIZE;
}

/** Changes a bone's local {@link Bone#getShearX()} and {@link Bone#getShearY()}. */
class ShearTimeline extends CurveTimeline2 implements BoneTimeline {
    public var boneIndex:Int = 0;

    public function new(frameCount:Int, bezierCount:Int, boneIndex:Int) {
        super(frameCount, bezierCount, //
            Property.shearX + "|" + boneIndex, //
            Property.shearY + "|" + boneIndex);
        this.boneIndex = boneIndex;
    }

    #if !spine_no_inline inline #end public function getBoneIndex():Int {
        return boneIndex;
    }

    override public function apply(skeleton:Skeleton, lastTime:Float, time:Float, events:Array<Event>, alpha:Float, blend:MixBlend, direction:MixDirection):Void {

        var bone:Bone = skeleton.bones.get(boneIndex);
        if (!bone.active) return;

        var frames:FloatArray = this.frames;
        if (time < frames[0]) { // Time is before first frame.
            var _continueAfterSwitch20 = false; while(true) { var _switchCond20 = (blend); {
            if (_switchCond20 == setup) {
                bone.shearX = bone.data.shearX;
                bone.shearY = bone.data.shearY;
                return;
            } else if (_switchCond20 == first) {
                bone.shearX += (bone.data.shearX - bone.shearX) * alpha;
                bone.shearY += (bone.data.shearY - bone.shearY) * alpha;
            } } break; }
            return;
        }

        var x:Float = 0; var y:Float = 0;
        var i:Int = Timeline.searchWithStep(frames, time, ENTRIES); var curveType:Int = Std.int(curves[Std.int(i / ENTRIES)]);
        var _continueAfterSwitch21 = false; while(true) { var _switchCond21 = (curveType); {
        if (_switchCond21 == LINEAR) {
            var before:Float = frames[i];
            x = frames[i + VALUE1];
            y = frames[i + VALUE2];
            var t:Float = (time - before) / (frames[i + ENTRIES] - before);
            x += (frames[i + ENTRIES + VALUE1] - x) * t;
            y += (frames[i + ENTRIES + VALUE2] - y) * t;
            break;
        } else if (_switchCond21 == STEPPED) {
            x = frames[i + VALUE1];
            y = frames[i + VALUE2];
            break;
        } else {
            x = getBezierValue(time, i, VALUE1, Std.int(curveType - BEZIER));
            y = getBezierValue(time, i, VALUE2, curveType + BEZIER_SIZE - BEZIER);
        } } break; }

        var _continueAfterSwitch22 = false; while(true) { var _switchCond22 = (blend); {
        if (_switchCond22 == setup) {
            bone.shearX = bone.data.shearX + x * alpha;
            bone.shearY = bone.data.shearY + y * alpha;
            break;
        } else if (_switchCond22 == first) {
                bone.shearX += (bone.data.shearX + x - bone.shearX) * alpha;
            bone.shearY += (bone.data.shearY + y - bone.shearY) * alpha;
            break;
        } else if (_switchCond22 == replace) {
            bone.shearX += (bone.data.shearX + x - bone.shearX) * alpha;
            bone.shearY += (bone.data.shearY + y - bone.shearY) * alpha;
            break;
        } else if (_switchCond22 == add) {
            bone.shearX += x * alpha;
            bone.shearY += y * alpha;
        } } break; }
    }

    inline public static var ENTRIES:Int = CurveTimeline2.ENTRIES;

    inline public static var VALUE1:Int = CurveTimeline2.VALUE1;

    inline public static var VALUE2:Int = CurveTimeline2.VALUE2;

    inline public static var LINEAR:Int = CurveTimeline.LINEAR;

    inline public static var STEPPED:Int = CurveTimeline.STEPPED;

    inline public static var BEZIER:Int = CurveTimeline.BEZIER;

    inline public static var BEZIER_SIZE:Int = CurveTimeline.BEZIER_SIZE;
}

/** Changes a bone's local {@link Bone#getShearX()}. */
class ShearXTimeline extends CurveTimeline1 implements BoneTimeline {
    public var boneIndex:Int = 0;

    public function new(frameCount:Int, bezierCount:Int, boneIndex:Int) {
        super(frameCount, bezierCount, Property.shearX + "|" + boneIndex);
        this.boneIndex = boneIndex;
    }

    #if !spine_no_inline inline #end public function getBoneIndex():Int {
        return boneIndex;
    }

    override public function apply(skeleton:Skeleton, lastTime:Float, time:Float, events:Array<Event>, alpha:Float, blend:MixBlend, direction:MixDirection):Void {

        var bone:Bone = skeleton.bones.get(boneIndex);
        if (!bone.active) return;

        var frames:FloatArray = this.frames;
        if (time < frames[0]) { // Time is before first frame.
            var _continueAfterSwitch23 = false; while(true) { var _switchCond23 = (blend); {
            if (_switchCond23 == setup) {
                bone.shearX = bone.data.shearX;
                return;
            } else if (_switchCond23 == first) {
                bone.shearX += (bone.data.shearX - bone.shearX) * alpha;
            } } break; }
            return;
        }

        var x:Float = getCurveValue(time);
        var _continueAfterSwitch24 = false; while(true) { var _switchCond24 = (blend); {
        if (_switchCond24 == setup) {
            bone.shearX = bone.data.shearX + x * alpha;
            break;
        } else if (_switchCond24 == first) {
                bone.shearX += (bone.data.shearX + x - bone.shearX) * alpha;
            break;
        } else if (_switchCond24 == replace) {
            bone.shearX += (bone.data.shearX + x - bone.shearX) * alpha;
            break;
        } else if (_switchCond24 == add) {
            bone.shearX += x * alpha;
        } } break; }
    }

    inline public static var ENTRIES:Int = CurveTimeline1.ENTRIES;

    inline public static var VALUE:Int = CurveTimeline1.VALUE;

    inline public static var LINEAR:Int = CurveTimeline.LINEAR;

    inline public static var STEPPED:Int = CurveTimeline.STEPPED;

    inline public static var BEZIER:Int = CurveTimeline.BEZIER;

    inline public static var BEZIER_SIZE:Int = CurveTimeline.BEZIER_SIZE;
}

/** Changes a bone's local {@link Bone#getShearY()}. */
class ShearYTimeline extends CurveTimeline1 implements BoneTimeline {
    public var boneIndex:Int = 0;

    public function new(frameCount:Int, bezierCount:Int, boneIndex:Int) {
        super(frameCount, bezierCount, Property.shearY + "|" + boneIndex);
        this.boneIndex = boneIndex;
    }

    #if !spine_no_inline inline #end public function getBoneIndex():Int {
        return boneIndex;
    }

    override public function apply(skeleton:Skeleton, lastTime:Float, time:Float, events:Array<Event>, alpha:Float, blend:MixBlend, direction:MixDirection):Void {

        var bone:Bone = skeleton.bones.get(boneIndex);
        if (!bone.active) return;

        var frames:FloatArray = this.frames;
        if (time < frames[0]) { // Time is before first frame.
            var _continueAfterSwitch25 = false; while(true) { var _switchCond25 = (blend); {
            if (_switchCond25 == setup) {
                bone.shearY = bone.data.shearY;
                return;
            } else if (_switchCond25 == first) {
                bone.shearY += (bone.data.shearY - bone.shearY) * alpha;
            } } break; }
            return;
        }

        var y:Float = getCurveValue(time);
        var _continueAfterSwitch26 = false; while(true) { var _switchCond26 = (blend); {
        if (_switchCond26 == setup) {
            bone.shearY = bone.data.shearY + y * alpha;
            break;
        } else if (_switchCond26 == first) {
                bone.shearY += (bone.data.shearY + y - bone.shearY) * alpha;
            break;
        } else if (_switchCond26 == replace) {
            bone.shearY += (bone.data.shearY + y - bone.shearY) * alpha;
            break;
        } else if (_switchCond26 == add) {
            bone.shearY += y * alpha;
        } } break; }
    }

    inline public static var ENTRIES:Int = CurveTimeline1.ENTRIES;

    inline public static var VALUE:Int = CurveTimeline1.VALUE;

    inline public static var LINEAR:Int = CurveTimeline.LINEAR;

    inline public static var STEPPED:Int = CurveTimeline.STEPPED;

    inline public static var BEZIER:Int = CurveTimeline.BEZIER;

    inline public static var BEZIER_SIZE:Int = CurveTimeline.BEZIER_SIZE;
}

/** Changes a slot's {@link Slot#getColor()}. */
class RGBATimeline extends CurveTimeline implements SlotTimeline {
    inline public static var ENTRIES:Int = 5;
    inline private static var R:Int = 1; inline private static var G:Int = 2; inline private static var B:Int = 3; inline private static var A:Int = 4;

    public var slotIndex:Int = 0;

    public function new(frameCount:Int, bezierCount:Int, slotIndex:Int) {
        super(frameCount, bezierCount, //
            [Property.rgb + "|" + slotIndex, //
            Property.alpha + "|" + slotIndex]);
        this.slotIndex = slotIndex;
    }

    override #if !spine_no_inline inline #end public function getFrameEntries():Int {
        return ENTRIES;
    }

    #if !spine_no_inline inline #end public function getSlotIndex():Int {
        return slotIndex;
    }

    /** Sets the time and color for the specified frame.
     * @param frame Between 0 and <code>frameCount</code>, inclusive.
     * @param time The frame time in seconds. */
    #if !spine_no_inline inline #end public function setFrame(frame:Int, time:Float, r:Float, g:Float, b:Float, a:Float):Void {
        frame *= ENTRIES;
        frames[frame] = time;
        frames[frame + R] = r;
        frames[frame + G] = g;
        frames[frame + B] = b;
        frames[frame + A] = a;
    }

    override public function apply(skeleton:Skeleton, lastTime:Float, time:Float, events:Array<Event>, alpha:Float, blend:MixBlend, direction:MixDirection):Void {

        var slot:Slot = skeleton.slots.get(slotIndex);
        if (!slot.bone.active) return;

        var frames:FloatArray = this.frames;
        var color:Color = slot.color;
        if (time < frames[0]) { // Time is before first frame.
            var setup:Color = slot.data.color;
            var _continueAfterSwitch27 = false; while(true) { var _switchCond27 = (blend); {
            if (_switchCond27 == spine.MixBlend.setup) {
                color.setColor(setup);
                return;
            } else if (_switchCond27 == first) {
                color.add((setup.r - color.r) * alpha, (setup.g - color.g) * alpha, (setup.b - color.b) * alpha,
                    (setup.a - color.a) * alpha);
            } } break; }
            return;
        }

        var r:Float = 0; var g:Float = 0; var b:Float = 0; var a:Float = 0;
        var i:Int = Timeline.searchWithStep(frames, time, ENTRIES); var curveType:Int = Std.int(curves[Std.int(i / ENTRIES)]);
        var _continueAfterSwitch28 = false; while(true) { var _switchCond28 = (curveType); {
        if (_switchCond28 == LINEAR) {
            var before:Float = frames[i];
            r = frames[i + R];
            g = frames[i + G];
            b = frames[i + B];
            a = frames[i + A];
            var t:Float = (time - before) / (frames[i + ENTRIES] - before);
            r += (frames[i + ENTRIES + R] - r) * t;
            g += (frames[i + ENTRIES + G] - g) * t;
            b += (frames[i + ENTRIES + B] - b) * t;
            a += (frames[i + ENTRIES + A] - a) * t;
            break;
        } else if (_switchCond28 == STEPPED) {
            r = frames[i + R];
            g = frames[i + G];
            b = frames[i + B];
            a = frames[i + A];
            break;
        } else {
            r = getBezierValue(time, i, R, Std.int(curveType - BEZIER));
            g = getBezierValue(time, i, G, curveType + BEZIER_SIZE - BEZIER);
            b = getBezierValue(time, i, B, curveType + BEZIER_SIZE * 2 - BEZIER);
            a = getBezierValue(time, i, A, curveType + BEZIER_SIZE * 3 - BEZIER);
        } } break; }

        if (alpha == 1)
            color.set(r, g, b, a);
        else {
            if (blend == setup) color.setColor(slot.data.color);
            color.add((r - color.r) * alpha, (g - color.g) * alpha, (b - color.b) * alpha, (a - color.a) * alpha);
        }
    }

    inline public static var LINEAR:Int = CurveTimeline.LINEAR;

    inline public static var STEPPED:Int = CurveTimeline.STEPPED;

    inline public static var BEZIER:Int = CurveTimeline.BEZIER;

    inline public static var BEZIER_SIZE:Int = CurveTimeline.BEZIER_SIZE;
}

/** Changes the RGB for a slot's {@link Slot#getColor()}. */
class RGBTimeline extends CurveTimeline implements SlotTimeline {
    inline public static var ENTRIES:Int = 4;
    inline private static var R:Int = 1; inline private static var G:Int = 2; inline private static var B:Int = 3;

    public var slotIndex:Int = 0;

    public function new(frameCount:Int, bezierCount:Int, slotIndex:Int) {
        super(frameCount, bezierCount, [Property.rgb + "|" + slotIndex]);
        this.slotIndex = slotIndex;
    }

    override #if !spine_no_inline inline #end public function getFrameEntries():Int {
        return ENTRIES;
    }

    #if !spine_no_inline inline #end public function getSlotIndex():Int {
        return slotIndex;
    }

    /** Sets the time and color for the specified frame.
     * @param frame Between 0 and <code>frameCount</code>, inclusive.
     * @param time The frame time in seconds. */
    #if !spine_no_inline inline #end public function setFrame(frame:Int, time:Float, r:Float, g:Float, b:Float):Void {
        frame <<= 2;
        frames[frame] = time;
        frames[frame + R] = r;
        frames[frame + G] = g;
        frames[frame + B] = b;
    }

    override public function apply(skeleton:Skeleton, lastTime:Float, time:Float, events:Array<Event>, alpha:Float, blend:MixBlend, direction:MixDirection):Void {

        var slot:Slot = skeleton.slots.get(slotIndex);
        if (!slot.bone.active) return;

        var frames:FloatArray = this.frames;
        var color:Color = slot.color;
        if (time < frames[0]) { // Time is before first frame.
            var setup:Color = slot.data.color;
            var _continueAfterSwitch29 = false; while(true) { var _switchCond29 = (blend); {
            if (_switchCond29 == spine.MixBlend.setup) {
                color.r = setup.r;
                color.g = setup.g;
                color.b = setup.b;
                return;
            } else if (_switchCond29 == first) {
                color.r += (setup.r - color.r) * alpha;
                color.g += (setup.g - color.g) * alpha;
                color.b += (setup.b - color.b) * alpha;
            } } break; }
            return;
        }

        var r:Float = 0; var g:Float = 0; var b:Float = 0;
        var i:Int = Timeline.searchWithStep(frames, time, ENTRIES); var curveType:Int = Std.int(curves[i >> 2]);
        var _continueAfterSwitch30 = false; while(true) { var _switchCond30 = (curveType); {
        if (_switchCond30 == LINEAR) {
            var before:Float = frames[i];
            r = frames[i + R];
            g = frames[i + G];
            b = frames[i + B];
            var t:Float = (time - before) / (frames[i + ENTRIES] - before);
            r += (frames[i + ENTRIES + R] - r) * t;
            g += (frames[i + ENTRIES + G] - g) * t;
            b += (frames[i + ENTRIES + B] - b) * t;
            break;
        } else if (_switchCond30 == STEPPED) {
            r = frames[i + R];
            g = frames[i + G];
            b = frames[i + B];
            break;
        } else {
            r = getBezierValue(time, i, R, curveType - BEZIER);
            g = getBezierValue(time, i, G, curveType + BEZIER_SIZE - BEZIER);
            b = getBezierValue(time, i, B, curveType + BEZIER_SIZE * 2 - BEZIER);
        } } break; }

        if (alpha == 1) {
            color.r = r;
            color.g = g;
            color.b = b;
        } else {
            if (blend == setup) {
                var setup:Color = slot.data.color;
                color.r = setup.r;
                color.g = setup.g;
                color.b = setup.b;
            }
            color.r += (r - color.r) * alpha;
            color.g += (g - color.g) * alpha;
            color.b += (b - color.b) * alpha;
        }
    }

    inline public static var LINEAR:Int = CurveTimeline.LINEAR;

    inline public static var STEPPED:Int = CurveTimeline.STEPPED;

    inline public static var BEZIER:Int = CurveTimeline.BEZIER;

    inline public static var BEZIER_SIZE:Int = CurveTimeline.BEZIER_SIZE;
}

/** Changes the alpha for a slot's {@link Slot#getColor()}. */
class AlphaTimeline extends CurveTimeline1 implements SlotTimeline {
    public var slotIndex:Int = 0;

    public function new(frameCount:Int, bezierCount:Int, slotIndex:Int) {
        super(frameCount, bezierCount, Property.alpha + "|" + slotIndex);
        this.slotIndex = slotIndex;
    }

    #if !spine_no_inline inline #end public function getSlotIndex():Int {
        return slotIndex;
    }

    override public function apply(skeleton:Skeleton, lastTime:Float, time:Float, events:Array<Event>, alpha:Float, blend:MixBlend, direction:MixDirection):Void {

        var slot:Slot = skeleton.slots.get(slotIndex);
        if (!slot.bone.active) return;

        var frames:FloatArray = this.frames;
        var color:Color = slot.color;
        if (time < frames[0]) { // Time is before first frame.
            var setup:Color = slot.data.color;
            var _continueAfterSwitch31 = false; while(true) { var _switchCond31 = (blend); {
            if (_switchCond31 == spine.MixBlend.setup) {
                color.a = setup.a;
                return;
            } else if (_switchCond31 == first) {
                color.a += (setup.a - color.a) * alpha;
            } } break; }
            return;
        }

        var a:Float = getCurveValue(time);
        if (alpha == 1)
            color.a = a;
        else {
            if (blend == setup) color.a = slot.data.color.a;
            color.a += (a - color.a) * alpha;
        }
    }

    inline public static var ENTRIES:Int = CurveTimeline1.ENTRIES;

    inline public static var VALUE:Int = CurveTimeline1.VALUE;

    inline public static var LINEAR:Int = CurveTimeline.LINEAR;

    inline public static var STEPPED:Int = CurveTimeline.STEPPED;

    inline public static var BEZIER:Int = CurveTimeline.BEZIER;

    inline public static var BEZIER_SIZE:Int = CurveTimeline.BEZIER_SIZE;
}

/** Changes a slot's {@link Slot#getColor()} and {@link Slot#getDarkColor()} for two color tinting. */
class RGBA2Timeline extends CurveTimeline implements SlotTimeline {
    inline public static var ENTRIES:Int = 8;
    inline private static var R:Int = 1; inline private static var G:Int = 2; inline private static var B:Int = 3; inline private static var A:Int = 4; inline private static var R2:Int = 5; inline private static var G2:Int = 6; inline private static var B2:Int = 7;

    public var slotIndex:Int = 0;

    public function new(frameCount:Int, bezierCount:Int, slotIndex:Int) {
        super(frameCount, bezierCount, //
            [Property.rgb + "|" + slotIndex, //
            Property.alpha + "|" + slotIndex, //
            Property.rgb2 + "|" + slotIndex]);
        this.slotIndex = slotIndex;
    }

    override #if !spine_no_inline inline #end public function getFrameEntries():Int {
        return ENTRIES;
    }

    /** The index of the slot in {@link Skeleton#getSlots()} that will be changed when this timeline is applied. The
     * {@link Slot#getDarkColor()} must not be null. */
    #if !spine_no_inline inline #end public function getSlotIndex():Int {
        return slotIndex;
    }

    /** Sets the time, light color, and dark color for the specified frame.
     * @param frame Between 0 and <code>frameCount</code>, inclusive.
     * @param time The frame time in seconds. */
    #if !spine_no_inline inline #end public function setFrame(frame:Int, time:Float, r:Float, g:Float, b:Float, a:Float, r2:Float, g2:Float, b2:Float):Void {
        frame <<= 3;
        frames[frame] = time;
        frames[frame + R] = r;
        frames[frame + G] = g;
        frames[frame + B] = b;
        frames[frame + A] = a;
        frames[frame + R2] = r2;
        frames[frame + G2] = g2;
        frames[frame + B2] = b2;
    }

    override public function apply(skeleton:Skeleton, lastTime:Float, time:Float, events:Array<Event>, alpha:Float, blend:MixBlend, direction:MixDirection):Void {

        var slot:Slot = skeleton.slots.get(slotIndex);
        if (!slot.bone.active) return;

        var frames:FloatArray = this.frames;
        var light:Color = slot.color; var dark:Color = slot.darkColor;
        if (time < frames[0]) { // Time is before first frame.
            var setupLight:Color = slot.data.color; var setupDark:Color = slot.data.darkColor;
            var _continueAfterSwitch32 = false; while(true) { var _switchCond32 = (blend); {
            if (_switchCond32 == setup) {
                light.setColor(setupLight);
                dark.r = setupDark.r;
                dark.g = setupDark.g;
                dark.b = setupDark.b;
                return;
            } else if (_switchCond32 == first) {
                light.add((setupLight.r - light.r) * alpha, (setupLight.g - light.g) * alpha, (setupLight.b - light.b) * alpha,
                    (setupLight.a - light.a) * alpha);
                dark.r += (setupDark.r - dark.r) * alpha;
                dark.g += (setupDark.g - dark.g) * alpha;
                dark.b += (setupDark.b - dark.b) * alpha;
            } } break; }
            return;
        }

        var r:Float = 0; var g:Float = 0; var b:Float = 0; var a:Float = 0; var r2:Float = 0; var g2:Float = 0; var b2:Float = 0;
        var i:Int = Timeline.searchWithStep(frames, time, ENTRIES); var curveType:Int = Std.int(curves[i >> 3]);
        var _continueAfterSwitch33 = false; while(true) { var _switchCond33 = (curveType); {
        if (_switchCond33 == LINEAR) {
            var before:Float = frames[i];
            r = frames[i + R];
            g = frames[i + G];
            b = frames[i + B];
            a = frames[i + A];
            r2 = frames[i + R2];
            g2 = frames[i + G2];
            b2 = frames[i + B2];
            var t:Float = (time - before) / (frames[i + ENTRIES] - before);
            r += (frames[i + ENTRIES + R] - r) * t;
            g += (frames[i + ENTRIES + G] - g) * t;
            b += (frames[i + ENTRIES + B] - b) * t;
            a += (frames[i + ENTRIES + A] - a) * t;
            r2 += (frames[i + ENTRIES + R2] - r2) * t;
            g2 += (frames[i + ENTRIES + G2] - g2) * t;
            b2 += (frames[i + ENTRIES + B2] - b2) * t;
            break;
        } else if (_switchCond33 == STEPPED) {
            r = frames[i + R];
            g = frames[i + G];
            b = frames[i + B];
            a = frames[i + A];
            r2 = frames[i + R2];
            g2 = frames[i + G2];
            b2 = frames[i + B2];
            break;
        } else {
            r = getBezierValue(time, i, R, curveType - BEZIER);
            g = getBezierValue(time, i, G, curveType + BEZIER_SIZE - BEZIER);
            b = getBezierValue(time, i, B, curveType + BEZIER_SIZE * 2 - BEZIER);
            a = getBezierValue(time, i, A, curveType + BEZIER_SIZE * 3 - BEZIER);
            r2 = getBezierValue(time, i, R2, curveType + BEZIER_SIZE * 4 - BEZIER);
            g2 = getBezierValue(time, i, G2, curveType + BEZIER_SIZE * 5 - BEZIER);
            b2 = getBezierValue(time, i, B2, curveType + BEZIER_SIZE * 6 - BEZIER);
        } } break; }

        if (alpha == 1) {
            light.set(r, g, b, a);
            dark.r = r2;
            dark.g = g2;
            dark.b = b2;
        } else {
            if (blend == setup) {
                light.setColor(slot.data.color);
                var setupDark:Color = slot.data.darkColor;
                dark.r = setupDark.r;
                dark.g = setupDark.g;
                dark.b = setupDark.b;
            }
            light.add((r - light.r) * alpha, (g - light.g) * alpha, (b - light.b) * alpha, (a - light.a) * alpha);
            dark.r += (r2 - dark.r) * alpha;
            dark.g += (g2 - dark.g) * alpha;
            dark.b += (b2 - dark.b) * alpha;
        }
    }

    inline public static var LINEAR:Int = CurveTimeline.LINEAR;

    inline public static var STEPPED:Int = CurveTimeline.STEPPED;

    inline public static var BEZIER:Int = CurveTimeline.BEZIER;

    inline public static var BEZIER_SIZE:Int = CurveTimeline.BEZIER_SIZE;
}

/** Changes the RGB for a slot's {@link Slot#getColor()} and {@link Slot#getDarkColor()} for two color tinting. */
class RGB2Timeline extends CurveTimeline implements SlotTimeline {
    inline public static var ENTRIES:Int = 7;
    inline private static var R:Int = 1; inline private static var G:Int = 2; inline private static var B:Int = 3; inline private static var R2:Int = 4; inline private static var G2:Int = 5; inline private static var B2:Int = 6;

    public var slotIndex:Int = 0;

    public function new(frameCount:Int, bezierCount:Int, slotIndex:Int) {
        super(frameCount, bezierCount, //
            [Property.rgb + "|" + slotIndex, //
            Property.rgb2 + "|" + slotIndex]);
        this.slotIndex = slotIndex;
    }

    override #if !spine_no_inline inline #end public function getFrameEntries():Int {
        return ENTRIES;
    }

    /** The index of the slot in {@link Skeleton#getSlots()} that will be changed when this timeline is applied. The
     * {@link Slot#getDarkColor()} must not be null. */
    #if !spine_no_inline inline #end public function getSlotIndex():Int {
        return slotIndex;
    }

    /** Sets the time, light color, and dark color for the specified frame.
     * @param frame Between 0 and <code>frameCount</code>, inclusive.
     * @param time The frame time in seconds. */
    #if !spine_no_inline inline #end public function setFrame(frame:Int, time:Float, r:Float, g:Float, b:Float, r2:Float, g2:Float, b2:Float):Void {
        frame *= ENTRIES;
        frames[frame] = time;
        frames[frame + R] = r;
        frames[frame + G] = g;
        frames[frame + B] = b;
        frames[frame + R2] = r2;
        frames[frame + G2] = g2;
        frames[frame + B2] = b2;
    }

    override public function apply(skeleton:Skeleton, lastTime:Float, time:Float, events:Array<Event>, alpha:Float, blend:MixBlend, direction:MixDirection):Void {

        var slot:Slot = skeleton.slots.get(slotIndex);
        if (!slot.bone.active) return;

        var frames:FloatArray = this.frames;
        var light:Color = slot.color; var dark:Color = slot.darkColor;
        if (time < frames[0]) { // Time is before first frame.
            var setupLight:Color = slot.data.color; var setupDark:Color = slot.data.darkColor;
            var _continueAfterSwitch34 = false; while(true) { var _switchCond34 = (blend); {
            if (_switchCond34 == setup) {
                light.r = setupLight.r;
                light.g = setupLight.g;
                light.b = setupLight.b;
                dark.r = setupDark.r;
                dark.g = setupDark.g;
                dark.b = setupDark.b;
                return;
            } else if (_switchCond34 == first) {
                light.r += (setupLight.r - light.r) * alpha;
                light.g += (setupLight.g - light.g) * alpha;
                light.b += (setupLight.b - light.b) * alpha;
                dark.r += (setupDark.r - dark.r) * alpha;
                dark.g += (setupDark.g - dark.g) * alpha;
                dark.b += (setupDark.b - dark.b) * alpha;
            } } break; }
            return;
        }

        var r:Float = 0; var g:Float = 0; var b:Float = 0; var r2:Float = 0; var g2:Float = 0; var b2:Float = 0;
        var i:Int = Timeline.searchWithStep(frames, time, ENTRIES); var curveType:Int = Std.int(curves[Std.int(i / ENTRIES)]);
        var _continueAfterSwitch35 = false; while(true) { var _switchCond35 = (curveType); {
        if (_switchCond35 == LINEAR) {
            var before:Float = frames[i];
            r = frames[i + R];
            g = frames[i + G];
            b = frames[i + B];
            r2 = frames[i + R2];
            g2 = frames[i + G2];
            b2 = frames[i + B2];
            var t:Float = (time - before) / (frames[i + ENTRIES] - before);
            r += (frames[i + ENTRIES + R] - r) * t;
            g += (frames[i + ENTRIES + G] - g) * t;
            b += (frames[i + ENTRIES + B] - b) * t;
            r2 += (frames[i + ENTRIES + R2] - r2) * t;
            g2 += (frames[i + ENTRIES + G2] - g2) * t;
            b2 += (frames[i + ENTRIES + B2] - b2) * t;
            break;
        } else if (_switchCond35 == STEPPED) {
            r = frames[i + R];
            g = frames[i + G];
            b = frames[i + B];
            r2 = frames[i + R2];
            g2 = frames[i + G2];
            b2 = frames[i + B2];
            break;
        } else {
            r = getBezierValue(time, i, R, Std.int(curveType - BEZIER));
            g = getBezierValue(time, i, G, curveType + BEZIER_SIZE - BEZIER);
            b = getBezierValue(time, i, B, curveType + BEZIER_SIZE * 2 - BEZIER);
            r2 = getBezierValue(time, i, R2, curveType + BEZIER_SIZE * 3 - BEZIER);
            g2 = getBezierValue(time, i, G2, curveType + BEZIER_SIZE * 4 - BEZIER);
            b2 = getBezierValue(time, i, B2, curveType + BEZIER_SIZE * 5 - BEZIER);
        } } break; }

        if (alpha == 1) {
            light.r = r;
            light.g = g;
            light.b = b;
            dark.r = r2;
            dark.g = g2;
            dark.b = b2;
        } else {
            if (blend == setup) {
                var setupLight:Color = slot.data.color; var setupDark:Color = slot.data.darkColor;
                light.r = setupLight.r;
                light.g = setupLight.g;
                light.b = setupLight.b;
                dark.r = setupDark.r;
                dark.g = setupDark.g;
                dark.b = setupDark.b;
            }
            light.r += (r - light.r) * alpha;
            light.g += (g - light.g) * alpha;
            light.b += (b - light.b) * alpha;
            dark.r += (r2 - dark.r) * alpha;
            dark.g += (g2 - dark.g) * alpha;
            dark.b += (b2 - dark.b) * alpha;
        }
    }

    inline public static var LINEAR:Int = CurveTimeline.LINEAR;

    inline public static var STEPPED:Int = CurveTimeline.STEPPED;

    inline public static var BEZIER:Int = CurveTimeline.BEZIER;

    inline public static var BEZIER_SIZE:Int = CurveTimeline.BEZIER_SIZE;
}

/** Changes a slot's {@link Slot#getAttachment()}. */
class AttachmentTimeline extends Timeline implements SlotTimeline {
    public var slotIndex:Int = 0;
    public var attachmentNames:StringArray;

    public function new(frameCount:Int, slotIndex:Int) {
        super(frameCount, [Property.attachment + "|" + slotIndex]);
        this.slotIndex = slotIndex;
        attachmentNames = StringArray.create(frameCount);
    }

    override #if !spine_no_inline inline #end public function getFrameCount():Int {
        return frames.length;
    }

    #if !spine_no_inline inline #end public function getSlotIndex():Int {
        return slotIndex;
    }

    /** The attachment name for each frame. May contain null values to clear the attachment. */
    #if !spine_no_inline inline #end public function getAttachmentNames():StringArray {
        return attachmentNames;
    }

    /** Sets the time and attachment name for the specified frame.
     * @param frame Between 0 and <code>frameCount</code>, inclusive.
     * @param time The frame time in seconds. */
    #if !spine_no_inline inline #end public function setFrame(frame:Int, time:Float, attachmentName:String):Void {
        frames[frame] = time;
        attachmentNames[frame] = attachmentName;
    }

    override public function apply(skeleton:Skeleton, lastTime:Float, time:Float, events:Array<Event>, alpha:Float, blend:MixBlend, direction:MixDirection):Void {

        var slot:Slot = skeleton.slots.get(slotIndex);
        if (!slot.bone.active) return;

        if (direction == spine.MixDirection.directionOut) {
            if (blend == setup) setAttachment(skeleton, slot, slot.data.attachmentName);
            return;
        }

        if (time < this.frames[0]) { // Time is before first frame.
            if (blend == setup || blend == first) setAttachment(skeleton, slot, slot.data.attachmentName);
            return;
        }

        setAttachment(skeleton, slot, attachmentNames[Timeline.search(this.frames, time)]);
    }

    #if !spine_no_inline inline #end private function setAttachment(skeleton:Skeleton, slot:Slot, attachmentName:String):Void {
        slot.setAttachment(attachmentName == null ? null : skeleton.getAttachment(slotIndex, attachmentName));
    }
}

/** Changes a slot's {@link Slot#getDeform()} to deform a {@link VertexAttachment}. */
class DeformTimeline extends CurveTimeline implements SlotTimeline {
    public var slotIndex:Int = 0;
    public var attachment:VertexAttachment;
    private var vertices:FloatArray2D;

    public function new(frameCount:Int, bezierCount:Int, slotIndex:Int, attachment:VertexAttachment) {
        super(frameCount, bezierCount, [Property.deform + "|" + slotIndex + "|" + attachment.getId()]);
        this.slotIndex = slotIndex;
        this.attachment = attachment;
        vertices = Array.createFloatArray2D(frameCount, 0);
    }

    override #if !spine_no_inline inline #end public function getFrameCount():Int {
        return frames.length;
    }

    #if !spine_no_inline inline #end public function getSlotIndex():Int {
        return slotIndex;
    }

    /** The attachment that will be deformed.
     * <p>
     * See {@link VertexAttachment#getDeformAttachment()}. */
    #if !spine_no_inline inline #end public function getAttachment():VertexAttachment {
        return attachment;
    }

    /** The vertices for each frame. */
    #if !spine_no_inline inline #end public function getVertices():FloatArray2D {
        return vertices;
    }

    /** Sets the time and vertices for the specified frame.
     * @param frame Between 0 and <code>frameCount</code>, inclusive.
     * @param time The frame time in seconds.
     * @param vertices Vertex positions for an unweighted VertexAttachment, or deform offsets if it has weights. */
    #if !spine_no_inline inline #end public function setFrame(frame:Int, time:Float, vertices:FloatArray):Void {
        frames[frame] = time;
        this.vertices[frame] = vertices;
    }

    /** @param value1 Ignored (0 is used for a deform timeline).
     * @param value2 Ignored (1 is used for a deform timeline). */
    override #if !spine_no_inline inline #end public function setBezier(bezier:Int, frame:Int, value:Int, time1:Float, value1:Float, cx1:Float, cy1:Float, cx2:Float, cy2:Float, time2:Float, value2:Float):Void {
        var curves:FloatArray = this.curves;
        var i:Int = getFrameCount() + bezier * BEZIER_SIZE;
        if (value == 0) curves[frame] = BEZIER + i;
        var tmpx:Float = (time1 - cx1 * 2 + cx2) * 0.03; var tmpy:Float = cy2 * 0.03 - cy1 * 0.06;
        var dddx:Float = ((cx1 - cx2) * 3 - time1 + time2) * 0.006; var dddy:Float = (cy1 - cy2 + 0.33333333) * 0.018;
        var ddx:Float = tmpx * 2 + dddx; var ddy:Float = tmpy * 2 + dddy;
        var dx:Float = (cx1 - time1) * 0.3 + tmpx + dddx * 0.16666667; var dy:Float = cy1 * 0.3 + tmpy + dddy * 0.16666667;
        var x:Float = time1 + dx; var y:Float = dy;
        var n:Int = i + BEZIER_SIZE; while (i < n) {
            curves[i] = x;
            curves[i + 1] = y;
            dx += ddx;
            dy += ddy;
            ddx += dddx;
            ddy += dddy;
            x += dx;
            y += dy;
        i += 2; }
    }

    /** Returns the interpolated percentage for the specified time.
     * @param frame The frame before <code>time</code>. */
    private function getCurvePercent(time:Float, frame:Int):Float {
        var curves:FloatArray = this.curves;
        var i:Int = Std.int(curves[frame]);
        var _continueAfterSwitch36 = false; while(true) { var _switchCond36 = (i); {
        if (_switchCond36 == LINEAR) {
            var x:Float = frames[frame];
            return (time - x) / (frames[frame + getFrameEntries()] - x);
            return 0;
        } else if (_switchCond36 == STEPPED) {
            return 0;
        } } break; }
        i -= BEZIER;
        if (curves[i] > time) {
            var x:Float = frames[frame];
            return curves[i + 1] * (time - x) / (curves[i] - x);
        }
        var n:Int = i + BEZIER_SIZE;
        i += 2; while (i < n) {
            if (curves[i] >= time) {
                var x:Float = curves[i - 2]; var y:Float = curves[i - 1];
                return y + (time - x) / (curves[i] - x) * (curves[i + 1] - y);
            }
        i += 2; }
        var x:Float = curves[n - 2]; var y:Float = curves[n - 1];
        return y + (1 - y) * (time - x) / (frames[frame + getFrameEntries()] - x);
    }

    override public function apply(skeleton:Skeleton, lastTime:Float, time:Float, events:Array<Event>, alpha:Float, blend:MixBlend, direction:MixDirection):Void {

        var slot:Slot = skeleton.slots.get(slotIndex);
        if (!slot.bone.active) return;
        var slotAttachment:Attachment = slot.attachment;
        if (!(#if (haxe_ver >= 4.0) Std.isOfType #else Std.is #end(slotAttachment, VertexAttachment))
            || (fastCast(slotAttachment, VertexAttachment)).getDeformAttachment() != attachment) return;

        var deformArray:FloatArray = slot.getDeform();
        if (deformArray.size == 0) blend = setup;

        var vertices:FloatArray2D = this.vertices;
        var vertexCount:Int = vertices[0].length;

        var frames:FloatArray = this.frames;
        if (time < frames[0]) { // Time is before first frame.
            var vertexAttachment:VertexAttachment = fastCast(slotAttachment, VertexAttachment);
            var _continueAfterSwitch37 = false; while(true) { var _switchCond37 = (blend); {
            if (_switchCond37 == setup) {
                deformArray.clear();
                return;
            } else if (_switchCond37 == first) {
                if (alpha == 1) {
                    deformArray.clear();
                    return;
                }
                var deform:FloatArray = deformArray.setSize(vertexCount);
                if (vertexAttachment.getBones() == null) {
                    // Unweighted vertex positions.
                    var setupVertices:FloatArray = vertexAttachment.getVertices();
                    var i:Int = 0; while (i < vertexCount) {
                        deform[i] += (setupVertices[i] - deform[i]) * alpha; i++; }
                } else {
                    // Weighted deform offsets.
                    alpha = 1 - alpha;
                    var i:Int = 0; while (i < vertexCount) {
                        deform[i] *= alpha; i++; }
                }
            } } break; }
            return;
        }

        var deform:FloatArray = deformArray.setSize(vertexCount);

        if (time >= frames[frames.length - 1]) { // Time is after last frame.
            var lastVertices:FloatArray = vertices[frames.length - 1];
            if (alpha == 1) {
                if (blend == add) {
                    var vertexAttachment:VertexAttachment = fastCast(slotAttachment, VertexAttachment);
                    if (vertexAttachment.getBones() == null) {
                        // Unweighted vertex positions, no alpha.
                        var setupVertices:FloatArray = vertexAttachment.getVertices();
                        var i:Int = 0; while (i < vertexCount) {
                            deform[i] += lastVertices[i] - setupVertices[i]; i++; }
                    } else {
                        // Weighted deform offsets, no alpha.
                        var i:Int = 0; while (i < vertexCount) {
                            deform[i] += lastVertices[i]; i++; }
                    }
                } else {
                    // Vertex positions or deform offsets, no alpha.
                    arraycopy(lastVertices, 0, deform, 0, vertexCount);
                }
            } else {
                var _continueAfterSwitch38 = false; while(true) { var _switchCond38 = (blend); {
                if (_switchCond38 == setup) {
                    var vertexAttachment:VertexAttachment = fastCast(slotAttachment, VertexAttachment);
                    if (vertexAttachment.getBones() == null) {
                        // Unweighted vertex positions, with alpha.
                        var setupVertices:FloatArray = vertexAttachment.getVertices();
                        var i:Int = 0; while (i < vertexCount) {
                            var setup:Float = setupVertices[i];
                            deform[i] = setup + (lastVertices[i] - setup) * alpha;
                        i++; }
                    } else {
                        // Weighted deform offsets, with alpha.
                        var i:Int = 0; while (i < vertexCount) {
                            deform[i] = lastVertices[i] * alpha; i++; }
                    }
                    break;
                }
                else if (_switchCond38 == first) {
                        // Vertex positions or deform offsets, with alpha.
                    var i:Int = 0; while (i < vertexCount) {
                        deform[i] += (lastVertices[i] - deform[i]) * alpha; i++; }
                    break;
                } else if (_switchCond38 == replace) {
                    // Vertex positions or deform offsets, with alpha.
                    var i:Int = 0; while (i < vertexCount) {
                        deform[i] += (lastVertices[i] - deform[i]) * alpha; i++; }
                    break;
                } else if (_switchCond38 == add) {
                    var vertexAttachment:VertexAttachment = fastCast(slotAttachment, VertexAttachment);
                    if (vertexAttachment.getBones() == null) {
                        // Unweighted vertex positions, no alpha.
                        var setupVertices:FloatArray = vertexAttachment.getVertices();
                        var i:Int = 0; while (i < vertexCount) {
                            deform[i] += (lastVertices[i] - setupVertices[i]) * alpha; i++; }
                    } else {
                        // Weighted deform offsets, alpha.
                        var i:Int = 0; while (i < vertexCount) {
                            deform[i] += lastVertices[i] * alpha; i++; }
                    }
                } } break; }
            }
            return;
        }

        var frame:Int = Timeline.search(frames, time);
        var percent:Float = getCurvePercent(time, frame);
        var prevVertices:FloatArray = vertices[frame];
        var nextVertices:FloatArray = vertices[frame + 1];

        if (alpha == 1) {
            if (blend == add) {
                var vertexAttachment:VertexAttachment = fastCast(slotAttachment, VertexAttachment);
                if (vertexAttachment.getBones() == null) {
                    // Unweighted vertex positions, no alpha.
                    var setupVertices:FloatArray = vertexAttachment.getVertices();
                    var i:Int = 0; while (i < vertexCount) {
                        var prev:Float = prevVertices[i];
                        deform[i] += prev + (nextVertices[i] - prev) * percent - setupVertices[i];
                    i++; }
                } else {
                    // Weighted deform offsets, no alpha.
                    var i:Int = 0; while (i < vertexCount) {
                        var prev:Float = prevVertices[i];
                        deform[i] += prev + (nextVertices[i] - prev) * percent;
                    i++; }
                }
            } else {
                // Vertex positions or deform offsets, no alpha.
                var i:Int = 0; while (i < vertexCount) {
                    var prev:Float = prevVertices[i];
                    deform[i] = prev + (nextVertices[i] - prev) * percent;
                i++; }
            }
        } else {
            var _continueAfterSwitch39 = false; while(true) { var _switchCond39 = (blend); {
            if (_switchCond39 == setup) {
                var vertexAttachment:VertexAttachment = fastCast(slotAttachment, VertexAttachment);
                if (vertexAttachment.getBones() == null) {
                    // Unweighted vertex positions, with alpha.
                    var setupVertices:FloatArray = vertexAttachment.getVertices();
                    var i:Int = 0; while (i < vertexCount) {
                        var prev:Float = prevVertices[i]; var setup:Float = setupVertices[i];
                        deform[i] = setup + (prev + (nextVertices[i] - prev) * percent - setup) * alpha;
                    i++; }
                } else {
                    // Weighted deform offsets, with alpha.
                    var i:Int = 0; while (i < vertexCount) {
                        var prev:Float = prevVertices[i];
                        deform[i] = (prev + (nextVertices[i] - prev) * percent) * alpha;
                    i++; }
                }
                break;
            }
            else if (_switchCond39 == first) {
                    // Vertex positions or deform offsets, with alpha.
                var i:Int = 0; while (i < vertexCount) {
                    var prev:Float = prevVertices[i];
                    deform[i] += (prev + (nextVertices[i] - prev) * percent - deform[i]) * alpha;
                i++; }
                break;
            } else if (_switchCond39 == replace) {
                // Vertex positions or deform offsets, with alpha.
                var i:Int = 0; while (i < vertexCount) {
                    var prev:Float = prevVertices[i];
                    deform[i] += (prev + (nextVertices[i] - prev) * percent - deform[i]) * alpha;
                i++; }
                break;
            } else if (_switchCond39 == add) {
                var vertexAttachment:VertexAttachment = fastCast(slotAttachment, VertexAttachment);
                if (vertexAttachment.getBones() == null) {
                    // Unweighted vertex positions, with alpha.
                    var setupVertices:FloatArray = vertexAttachment.getVertices();
                    var i:Int = 0; while (i < vertexCount) {
                        var prev:Float = prevVertices[i];
                        deform[i] += (prev + (nextVertices[i] - prev) * percent - setupVertices[i]) * alpha;
                    i++; }
                } else {
                    // Weighted deform offsets, with alpha.
                    var i:Int = 0; while (i < vertexCount) {
                        var prev:Float = prevVertices[i];
                        deform[i] += (prev + (nextVertices[i] - prev) * percent) * alpha;
                    i++; }
                }
            } } break; }
        }
    }

    inline public static var LINEAR:Int = CurveTimeline.LINEAR;

    inline public static var STEPPED:Int = CurveTimeline.STEPPED;

    inline public static var BEZIER:Int = CurveTimeline.BEZIER;

    inline public static var BEZIER_SIZE:Int = CurveTimeline.BEZIER_SIZE;
}

/** Fires an {@link Event} when specific animation times are reached. */
class EventTimeline extends Timeline {
    private static var propertyIds:StringArray = [Std.string(Property.event)];

    private var events:Array<Event>;

    public function new(frameCount:Int) {
        super(frameCount, propertyIds);
        events = Array.create(frameCount);
    }

    override #if !spine_no_inline inline #end public function getFrameCount():Int {
        return frames.length;
    }

    /** The event for each frame. */
    #if !spine_no_inline inline #end public function getEvents():Array<Event> {
        return events;
    }

    /** Sets the time and event for the specified frame.
     * @param frame Between 0 and <code>frameCount</code>, inclusive. */
    #if !spine_no_inline inline #end public function setFrame(frame:Int, event:Event):Void {
        frames[frame] = event.time;
        events[frame] = event;
    }

    /** Fires events for frames > <code>lastTime</code> and <= <code>time</code>. */
    override public function apply(skeleton:Skeleton, lastTime:Float, time:Float, firedEvents:Array<Event>, alpha:Float, blend:MixBlend, direction:MixDirection):Void {

        if (firedEvents == null) return;

        var frames:FloatArray = this.frames;
        var frameCount:Int = frames.length;

        if (lastTime > time) { // Fire events after last time for looped animations.
            apply(skeleton, lastTime, 999999999, firedEvents, alpha, blend, direction);
            lastTime = -1;
        } else if (lastTime >= frames[frameCount - 1]) // Last time is after last frame.
            return;
        if (time < frames[0]) return; // Time is before first frame.

        var i:Int = 0;
        if (lastTime < frames[0])
            i = 0;
        else {
            i = Timeline.search(frames, lastTime) + 1;
            var frameTime:Float = frames[i];
            while (i > 0) { // Fire multiple events with the same frame.
                if (frames[i - 1] != frameTime) break;
                i--;
            }
        }
        while (i < frameCount && time >= frames[i]) {
            firedEvents.add(events[i]); i++; }
    }
}

/** Changes a skeleton's {@link Skeleton#getDrawOrder()}. */
class DrawOrderTimeline extends Timeline {
    private static var propertyIds:StringArray = [Std.string(Property.drawOrder)];

    private var drawOrders:IntArray2D;

    public function new(frameCount:Int) {
        super(frameCount, propertyIds);
        drawOrders = Array.createIntArray2D(frameCount, 0);
    }

    override #if !spine_no_inline inline #end public function getFrameCount():Int {
        return frames.length;
    }

    /** The draw order for each frame. See {@link #setFrame(int, float, int[])}. */
    #if !spine_no_inline inline #end public function getDrawOrders():IntArray2D {
        return drawOrders;
    }

    /** Sets the time and draw order for the specified frame.
     * @param frame Between 0 and <code>frameCount</code>, inclusive.
     * @param time The frame time in seconds.
     * @param drawOrder For each slot in {@link Skeleton#slots}, the index of the slot in the new draw order. May be null to use
     *           setup pose draw order. */
    #if !spine_no_inline inline #end public function setFrame(frame:Int, time:Float, drawOrder:IntArray):Void {
        frames[frame] = time;
        drawOrders[frame] = drawOrder;
    }

    override public function apply(skeleton:Skeleton, lastTime:Float, time:Float, events:Array<Event>, alpha:Float, blend:MixBlend, direction:MixDirection):Void {

        if (direction == spine.MixDirection.directionOut) {
            if (blend == setup) arraycopy(skeleton.slots.items, 0, skeleton.drawOrder.items, 0, skeleton.slots.size);
            return;
        }

        if (time < frames[0]) { // Time is before first frame.
            if (blend == setup || blend == first)
                arraycopy(skeleton.slots.items, 0, skeleton.drawOrder.items, 0, skeleton.slots.size);
            return;
        }

        var drawOrderToSetupIndex:IntArray = drawOrders[Timeline.search(frames, time)];
        if (drawOrderToSetupIndex == null)
            arraycopy(skeleton.slots.items, 0, skeleton.drawOrder.items, 0, skeleton.slots.size);
        else {
            var slots = skeleton.slots.items;
            var drawOrder = skeleton.drawOrder.items;
            var i:Int = 0; var n:Int = drawOrderToSetupIndex.length; while (i < n) {
                drawOrder[i] = slots[drawOrderToSetupIndex[i]]; i++; }
        }
    }
}

/** Changes an IK constraint's {@link IkConstraint#getMix()}, {@link IkConstraint#getSoftness()},
 * {@link IkConstraint#getBendDirection()}, {@link IkConstraint#getStretch()}, and {@link IkConstraint#getCompress()}. */
class IkConstraintTimeline extends CurveTimeline {
    inline public static var ENTRIES:Int = 6;
    inline private static var MIX:Int = 1; inline private static var SOFTNESS:Int = 2; inline private static var BEND_DIRECTION:Int = 3; inline private static var COMPRESS:Int = 4; inline private static var STRETCH:Int = 5;

    public var ikConstraintIndex:Int = 0;

    public function new(frameCount:Int, bezierCount:Int, ikConstraintIndex:Int) {
        super(frameCount, bezierCount, [Property.ikConstraint + "|" + ikConstraintIndex]);
        this.ikConstraintIndex = ikConstraintIndex;
    }

    override #if !spine_no_inline inline #end public function getFrameEntries():Int {
        return ENTRIES;
    }

    /** The index of the IK constraint slot in {@link Skeleton#getIkConstraints()} that will be changed when this timeline is
     * applied. */
    #if !spine_no_inline inline #end public function getIkConstraintIndex():Int {
        return ikConstraintIndex;
    }

    /** Sets the time, mix, softness, bend direction, compress, and stretch for the specified frame.
     * @param frame Between 0 and <code>frameCount</code>, inclusive.
     * @param time The frame time in seconds.
     * @param bendDirection 1 or -1. */
    #if !spine_no_inline inline #end public function setFrame(frame:Int, time:Float, mix:Float, softness:Float, bendDirection:Int, compress:Bool, stretch:Bool):Void {
        frame *= ENTRIES;
        frames[frame] = time;
        frames[frame + MIX] = mix;
        frames[frame + SOFTNESS] = softness;
        frames[frame + BEND_DIRECTION] = bendDirection;
        frames[frame + COMPRESS] = compress ? 1 : 0;
        frames[frame + STRETCH] = stretch ? 1 : 0;
    }

    override public function apply(skeleton:Skeleton, lastTime:Float, time:Float, events:Array<Event>, alpha:Float, blend:MixBlend, direction:MixDirection):Void {

        var constraint:IkConstraint = skeleton.ikConstraints.get(ikConstraintIndex);
        if (!constraint.active) return;

        var frames:FloatArray = this.frames;
        if (time < frames[0]) { // Time is before first frame.
            var _continueAfterSwitch40 = false; while(true) { var _switchCond40 = (blend); {
            if (_switchCond40 == setup) {
                constraint.mix = constraint.data.mix;
                constraint.softness = constraint.data.softness;
                constraint.bendDirection = constraint.data.bendDirection;
                constraint.compress = constraint.data.compress;
                constraint.stretch = constraint.data.stretch;
                return;
            } else if (_switchCond40 == first) {
                constraint.mix += (constraint.data.mix - constraint.mix) * alpha;
                constraint.softness += (constraint.data.softness - constraint.softness) * alpha;
                constraint.bendDirection = constraint.data.bendDirection;
                constraint.compress = constraint.data.compress;
                constraint.stretch = constraint.data.stretch;
            } } break; }
            return;
        }

        var mix:Float = 0; var softness:Float = 0;
        var i:Int = Timeline.searchWithStep(frames, time, ENTRIES); var curveType:Int = Std.int(curves[Std.int(i / ENTRIES)]);
        var _continueAfterSwitch41 = false; while(true) { var _switchCond41 = (curveType); {
        if (_switchCond41 == LINEAR) {
            var before:Float = frames[i];
            mix = frames[i + MIX];
            softness = frames[i + SOFTNESS];
            var t:Float = (time - before) / (frames[i + ENTRIES] - before);
            mix += (frames[i + ENTRIES + MIX] - mix) * t;
            softness += (frames[i + ENTRIES + SOFTNESS] - softness) * t;
            break;
        } else if (_switchCond41 == STEPPED) {
            mix = frames[i + MIX];
            softness = frames[i + SOFTNESS];
            break;
        } else {
            mix = getBezierValue(time, i, MIX, Std.int(curveType - BEZIER));
            softness = getBezierValue(time, i, SOFTNESS, curveType + BEZIER_SIZE - BEZIER);
        } } break; }

        if (blend == setup) {
            constraint.mix = constraint.data.mix + (mix - constraint.data.mix) * alpha;
            constraint.softness = constraint.data.softness + (softness - constraint.data.softness) * alpha;
            if (direction == spine.MixDirection.directionOut) {
                constraint.bendDirection = constraint.data.bendDirection;
                constraint.compress = constraint.data.compress;
                constraint.stretch = constraint.data.stretch;
            } else {
                constraint.bendDirection = Std.int(frames[i + BEND_DIRECTION]);
                constraint.compress = frames[i + COMPRESS] != 0;
                constraint.stretch = frames[i + STRETCH] != 0;
            }
        } else {
            constraint.mix += (mix - constraint.mix) * alpha;
            constraint.softness += (softness - constraint.softness) * alpha;
            if (direction == spine.MixDirection.directionIn) {
                constraint.bendDirection = Std.int(frames[i + BEND_DIRECTION]);
                constraint.compress = frames[i + COMPRESS] != 0;
                constraint.stretch = frames[i + STRETCH] != 0;
            }
        }
    }

    inline public static var LINEAR:Int = CurveTimeline.LINEAR;

    inline public static var STEPPED:Int = CurveTimeline.STEPPED;

    inline public static var BEZIER:Int = CurveTimeline.BEZIER;

    inline public static var BEZIER_SIZE:Int = CurveTimeline.BEZIER_SIZE;
}

/** Changes a transform constraint's {@link TransformConstraint#getMixRotate()}, {@link TransformConstraint#getMixX()},
 * {@link TransformConstraint#getMixY()}, {@link TransformConstraint#getMixScaleX()},
 * {@link TransformConstraint#getMixScaleY()}, and {@link TransformConstraint#getMixShearY()}. */
class TransformConstraintTimeline extends CurveTimeline {
    inline public static var ENTRIES:Int = 7;
    inline private static var ROTATE:Int = 1; inline private static var X:Int = 2; inline private static var Y:Int = 3; inline private static var SCALEX:Int = 4; inline private static var SCALEY:Int = 5; inline private static var SHEARY:Int = 6;

    public var transformConstraintIndex:Int = 0;

    public function new(frameCount:Int, bezierCount:Int, transformConstraintIndex:Int) {
        super(frameCount, bezierCount, [Property.transformConstraint + "|" + transformConstraintIndex]);
        this.transformConstraintIndex = transformConstraintIndex;
    }

    override #if !spine_no_inline inline #end public function getFrameEntries():Int {
        return ENTRIES;
    }

    /** The index of the transform constraint slot in {@link Skeleton#getTransformConstraints()} that will be changed when this
     * timeline is applied. */
    #if !spine_no_inline inline #end public function getTransformConstraintIndex():Int {
        return transformConstraintIndex;
    }

    /** Sets the time, rotate mix, translate mix, scale mix, and shear mix for the specified frame.
     * @param frame Between 0 and <code>frameCount</code>, inclusive.
     * @param time The frame time in seconds. */
    #if !spine_no_inline inline #end public function setFrame(frame:Int, time:Float, mixRotate:Float, mixX:Float, mixY:Float, mixScaleX:Float, mixScaleY:Float, mixShearY:Float):Void {
        frame *= ENTRIES;
        frames[frame] = time;
        frames[frame + ROTATE] = mixRotate;
        frames[frame + X] = mixX;
        frames[frame + Y] = mixY;
        frames[frame + SCALEX] = mixScaleX;
        frames[frame + SCALEY] = mixScaleY;
        frames[frame + SHEARY] = mixShearY;
    }

    override public function apply(skeleton:Skeleton, lastTime:Float, time:Float, events:Array<Event>, alpha:Float, blend:MixBlend, direction:MixDirection):Void {

        var constraint:TransformConstraint = skeleton.transformConstraints.get(transformConstraintIndex);
        if (!constraint.active) return;

        var frames:FloatArray = this.frames;
        if (time < frames[0]) { // Time is before first frame.
            var data:TransformConstraintData = constraint.data;
            var _continueAfterSwitch42 = false; while(true) { var _switchCond42 = (blend); {
            if (_switchCond42 == setup) {
                constraint.mixRotate = data.mixRotate;
                constraint.mixX = data.mixX;
                constraint.mixY = data.mixY;
                constraint.mixScaleX = data.mixScaleX;
                constraint.mixScaleY = data.mixScaleY;
                constraint.mixShearY = data.mixShearY;
                return;
            } else if (_switchCond42 == first) {
                constraint.mixRotate += (data.mixRotate - constraint.mixRotate) * alpha;
                constraint.mixX += (data.mixX - constraint.mixX) * alpha;
                constraint.mixY += (data.mixY - constraint.mixY) * alpha;
                constraint.mixScaleX += (data.mixScaleX - constraint.mixScaleX) * alpha;
                constraint.mixScaleY += (data.mixScaleY - constraint.mixScaleY) * alpha;
                constraint.mixShearY += (data.mixShearY - constraint.mixShearY) * alpha;
            } } break; }
            return;
        }

        var rotate:Float = 0; var x:Float = 0; var y:Float = 0; var scaleX:Float = 0; var scaleY:Float = 0; var shearY:Float = 0;
        var i:Int = Timeline.searchWithStep(frames, time, ENTRIES); var curveType:Int = Std.int(curves[Std.int(i / ENTRIES)]);
        var _continueAfterSwitch43 = false; while(true) { var _switchCond43 = (curveType); {
        if (_switchCond43 == LINEAR) {
            var before:Float = frames[i];
            rotate = frames[i + ROTATE];
            x = frames[i + X];
            y = frames[i + Y];
            scaleX = frames[i + SCALEX];
            scaleY = frames[i + SCALEY];
            shearY = frames[i + SHEARY];
            var t:Float = (time - before) / (frames[i + ENTRIES] - before);
            rotate += (frames[i + ENTRIES + ROTATE] - rotate) * t;
            x += (frames[i + ENTRIES + X] - x) * t;
            y += (frames[i + ENTRIES + Y] - y) * t;
            scaleX += (frames[i + ENTRIES + SCALEX] - scaleX) * t;
            scaleY += (frames[i + ENTRIES + SCALEY] - scaleY) * t;
            shearY += (frames[i + ENTRIES + SHEARY] - shearY) * t;
            break;
        } else if (_switchCond43 == STEPPED) {
            rotate = frames[i + ROTATE];
            x = frames[i + X];
            y = frames[i + Y];
            scaleX = frames[i + SCALEX];
            scaleY = frames[i + SCALEY];
            shearY = frames[i + SHEARY];
            break;
        } else {
            rotate = getBezierValue(time, i, ROTATE, Std.int(curveType - BEZIER));
            x = getBezierValue(time, i, X, curveType + BEZIER_SIZE - BEZIER);
            y = getBezierValue(time, i, Y, curveType + BEZIER_SIZE * 2 - BEZIER);
            scaleX = getBezierValue(time, i, SCALEX, curveType + BEZIER_SIZE * 3 - BEZIER);
            scaleY = getBezierValue(time, i, SCALEY, curveType + BEZIER_SIZE * 4 - BEZIER);
            shearY = getBezierValue(time, i, SHEARY, curveType + BEZIER_SIZE * 5 - BEZIER);
        } } break; }

        if (blend == setup) {
            var data:TransformConstraintData = constraint.data;
            constraint.mixRotate = data.mixRotate + (rotate - data.mixRotate) * alpha;
            constraint.mixX = data.mixX + (x - data.mixX) * alpha;
            constraint.mixY = data.mixY + (y - data.mixY) * alpha;
            constraint.mixScaleX = data.mixScaleX + (scaleX - data.mixScaleX) * alpha;
            constraint.mixScaleY = data.mixScaleY + (scaleY - data.mixScaleY) * alpha;
            constraint.mixShearY = data.mixShearY + (shearY - data.mixShearY) * alpha;
        } else {
            constraint.mixRotate += (rotate - constraint.mixRotate) * alpha;
            constraint.mixX += (x - constraint.mixX) * alpha;
            constraint.mixY += (y - constraint.mixY) * alpha;
            constraint.mixScaleX += (scaleX - constraint.mixScaleX) * alpha;
            constraint.mixScaleY += (scaleY - constraint.mixScaleY) * alpha;
            constraint.mixShearY += (shearY - constraint.mixShearY) * alpha;
        }
    }

    inline public static var LINEAR:Int = CurveTimeline.LINEAR;

    inline public static var STEPPED:Int = CurveTimeline.STEPPED;

    inline public static var BEZIER:Int = CurveTimeline.BEZIER;

    inline public static var BEZIER_SIZE:Int = CurveTimeline.BEZIER_SIZE;
}

/** Changes a path constraint's {@link PathConstraint#getPosition()}. */
class PathConstraintPositionTimeline extends CurveTimeline1 {
    public var pathConstraintIndex:Int = 0;

    public function new(frameCount:Int, bezierCount:Int, pathConstraintIndex:Int) {
        super(frameCount, bezierCount, Property.pathConstraintPosition + "|" + pathConstraintIndex);
        this.pathConstraintIndex = pathConstraintIndex;
    }

    /** The index of the path constraint slot in {@link Skeleton#getPathConstraints()} that will be changed when this timeline
     * is applied. */
    #if !spine_no_inline inline #end public function getPathConstraintIndex():Int {
        return pathConstraintIndex;
    }

    override public function apply(skeleton:Skeleton, lastTime:Float, time:Float, events:Array<Event>, alpha:Float, blend:MixBlend, direction:MixDirection):Void {

        var constraint:PathConstraint = skeleton.pathConstraints.get(pathConstraintIndex);
        if (!constraint.active) return;

        if (time < frames[0]) { // Time is before first frame.
            var _continueAfterSwitch44 = false; while(true) { var _switchCond44 = (blend); {
            if (_switchCond44 == setup) {
                constraint.position = constraint.data.position;
                return;
            } else if (_switchCond44 == first) {
                constraint.position += (constraint.data.position - constraint.position) * alpha;
            } } break; }
            return;
        }

        var position:Float = getCurveValue(time);
        if (blend == setup)
            constraint.position = constraint.data.position + (position - constraint.data.position) * alpha;
        else
            constraint.position += (position - constraint.position) * alpha;
    }

    inline public static var ENTRIES:Int = CurveTimeline1.ENTRIES;

    inline public static var VALUE:Int = CurveTimeline1.VALUE;

    inline public static var LINEAR:Int = CurveTimeline.LINEAR;

    inline public static var STEPPED:Int = CurveTimeline.STEPPED;

    inline public static var BEZIER:Int = CurveTimeline.BEZIER;

    inline public static var BEZIER_SIZE:Int = CurveTimeline.BEZIER_SIZE;
}

/** Changes a path constraint's {@link PathConstraint#getSpacing()}. */
class PathConstraintSpacingTimeline extends CurveTimeline1 {
    public var pathConstraintIndex:Int = 0;

    public function new(frameCount:Int, bezierCount:Int, pathConstraintIndex:Int) {
        super(frameCount, bezierCount, Property.pathConstraintSpacing + "|" + pathConstraintIndex);
        this.pathConstraintIndex = pathConstraintIndex;
    }

    /** The index of the path constraint slot in {@link Skeleton#getPathConstraints()} that will be changed when this timeline
     * is applied. */
    #if !spine_no_inline inline #end public function getPathConstraintIndex():Int {
        return pathConstraintIndex;
    }

    override public function apply(skeleton:Skeleton, lastTime:Float, time:Float, events:Array<Event>, alpha:Float, blend:MixBlend, direction:MixDirection):Void {

        var constraint:PathConstraint = skeleton.pathConstraints.get(pathConstraintIndex);
        if (!constraint.active) return;

        if (time < frames[0]) { // Time is before first frame.
            var _continueAfterSwitch45 = false; while(true) { var _switchCond45 = (blend); {
            if (_switchCond45 == setup) {
                constraint.spacing = constraint.data.spacing;
                return;
            } else if (_switchCond45 == first) {
                constraint.spacing += (constraint.data.spacing - constraint.spacing) * alpha;
            } } break; }
            return;
        }

        var spacing:Float = getCurveValue(time);
        if (blend == setup)
            constraint.spacing = constraint.data.spacing + (spacing - constraint.data.spacing) * alpha;
        else
            constraint.spacing += (spacing - constraint.spacing) * alpha;
    }

    inline public static var ENTRIES:Int = CurveTimeline1.ENTRIES;

    inline public static var VALUE:Int = CurveTimeline1.VALUE;

    inline public static var LINEAR:Int = CurveTimeline.LINEAR;

    inline public static var STEPPED:Int = CurveTimeline.STEPPED;

    inline public static var BEZIER:Int = CurveTimeline.BEZIER;

    inline public static var BEZIER_SIZE:Int = CurveTimeline.BEZIER_SIZE;
}

/** Changes a transform constraint's {@link PathConstraint#getMixRotate()}, {@link PathConstraint#getMixX()}, and
 * {@link PathConstraint#getMixY()}. */
class PathConstraintMixTimeline extends CurveTimeline {
    inline public static var ENTRIES:Int = 4;
    inline private static var ROTATE:Int = 1; inline private static var X:Int = 2; inline private static var Y:Int = 3;

    public var pathConstraintIndex:Int = 0;

    public function new(frameCount:Int, bezierCount:Int, pathConstraintIndex:Int) {
        super(frameCount, bezierCount, [Property.pathConstraintMix + "|" + pathConstraintIndex]);
        this.pathConstraintIndex = pathConstraintIndex;
    }

    override #if !spine_no_inline inline #end public function getFrameEntries():Int {
        return ENTRIES;
    }

    /** The index of the path constraint slot in {@link Skeleton#getPathConstraints()} that will be changed when this timeline
     * is applied. */
    #if !spine_no_inline inline #end public function getPathConstraintIndex():Int {
        return pathConstraintIndex;
    }

    /** Sets the time and color for the specified frame.
     * @param frame Between 0 and <code>frameCount</code>, inclusive.
     * @param time The frame time in seconds. */
    #if !spine_no_inline inline #end public function setFrame(frame:Int, time:Float, mixRotate:Float, mixX:Float, mixY:Float):Void {
        frame <<= 2;
        frames[frame] = time;
        frames[frame + ROTATE] = mixRotate;
        frames[frame + X] = mixX;
        frames[frame + Y] = mixY;
    }

    override public function apply(skeleton:Skeleton, lastTime:Float, time:Float, events:Array<Event>, alpha:Float, blend:MixBlend, direction:MixDirection):Void {

        var constraint:PathConstraint = skeleton.pathConstraints.get(pathConstraintIndex);
        if (!constraint.active) return;

        var frames:FloatArray = this.frames;
        if (time < frames[0]) { // Time is before first frame.
            var data:PathConstraintData = constraint.data;
            var _continueAfterSwitch46 = false; while(true) { var _switchCond46 = (blend); {
            if (_switchCond46 == setup) {
                constraint.mixRotate = data.mixRotate;
                constraint.mixX = data.mixX;
                constraint.mixY = data.mixY;
                return;
            } else if (_switchCond46 == first) {
                constraint.mixRotate += (data.mixRotate - constraint.mixRotate) * alpha;
                constraint.mixX += (data.mixX - constraint.mixX) * alpha;
                constraint.mixY += (data.mixY - constraint.mixY) * alpha;
            } } break; }
            return;
        }

        var rotate:Float = 0; var x:Float = 0; var y:Float = 0;
        var i:Int = Timeline.searchWithStep(frames, time, ENTRIES); var curveType:Int = Std.int(curves[i >> 2]);
        var _continueAfterSwitch47 = false; while(true) { var _switchCond47 = (curveType); {
        if (_switchCond47 == LINEAR) {
            var before:Float = frames[i];
            rotate = frames[i + ROTATE];
            x = frames[i + X];
            y = frames[i + Y];
            var t:Float = (time - before) / (frames[i + ENTRIES] - before);
            rotate += (frames[i + ENTRIES + ROTATE] - rotate) * t;
            x += (frames[i + ENTRIES + X] - x) * t;
            y += (frames[i + ENTRIES + Y] - y) * t;
            break;
        } else if (_switchCond47 == STEPPED) {
            rotate = frames[i + ROTATE];
            x = frames[i + X];
            y = frames[i + Y];
            break;
        } else {
            rotate = getBezierValue(time, i, ROTATE, curveType - BEZIER);
            x = getBezierValue(time, i, X, curveType + BEZIER_SIZE - BEZIER);
            y = getBezierValue(time, i, Y, curveType + BEZIER_SIZE * 2 - BEZIER);
        } } break; }

        if (blend == setup) {
            var data:PathConstraintData = constraint.data;
            constraint.mixRotate = data.mixRotate + (rotate - data.mixRotate) * alpha;
            constraint.mixX = data.mixX + (x - data.mixX) * alpha;
            constraint.mixY = data.mixY + (y - data.mixY) * alpha;
        } else {
            constraint.mixRotate += (rotate - constraint.mixRotate) * alpha;
            constraint.mixX += (x - constraint.mixX) * alpha;
            constraint.mixY += (y - constraint.mixY) * alpha;
        }
    }

    inline public static var LINEAR:Int = CurveTimeline.LINEAR;

    inline public static var STEPPED:Int = CurveTimeline.STEPPED;

    inline public static var BEZIER:Int = CurveTimeline.BEZIER;

    inline public static var BEZIER_SIZE:Int = CurveTimeline.BEZIER_SIZE;
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

class Property_enum {

    public inline static var rotate_value = 0;
    public inline static var x_value = 1;
    public inline static var y_value = 2;
    public inline static var scaleX_value = 3;
    public inline static var scaleY_value = 4;
    public inline static var shearX_value = 5;
    public inline static var shearY_value = 6;
    public inline static var rgb_value = 7;
    public inline static var alpha_value = 8;
    public inline static var rgb2_value = 9;
    public inline static var attachment_value = 10;
    public inline static var deform_value = 11;
    public inline static var event_value = 12;
    public inline static var drawOrder_value = 13;
    public inline static var ikConstraint_value = 14;
    public inline static var transformConstraint_value = 15;
    public inline static var pathConstraintPosition_value = 16;
    public inline static var pathConstraintSpacing_value = 17;
    public inline static var pathConstraintMix_value = 18;

    public inline static var rotate_name = "rotate";
    public inline static var x_name = "x";
    public inline static var y_name = "y";
    public inline static var scaleX_name = "scaleX";
    public inline static var scaleY_name = "scaleY";
    public inline static var shearX_name = "shearX";
    public inline static var shearY_name = "shearY";
    public inline static var rgb_name = "rgb";
    public inline static var alpha_name = "alpha";
    public inline static var rgb2_name = "rgb2";
    public inline static var attachment_name = "attachment";
    public inline static var deform_name = "deform";
    public inline static var event_name = "event";
    public inline static var drawOrder_name = "drawOrder";
    public inline static var ikConstraint_name = "ikConstraint";
    public inline static var transformConstraint_name = "transformConstraint";
    public inline static var pathConstraintPosition_name = "pathConstraintPosition";
    public inline static var pathConstraintSpacing_name = "pathConstraintSpacing";
    public inline static var pathConstraintMix_name = "pathConstraintMix";

    public inline static function valueOf(value:String):Property {
        return switch (value) {
            case "rotate": Property.rotate;
            case "x": Property.x;
            case "y": Property.y;
            case "scaleX": Property.scaleX;
            case "scaleY": Property.scaleY;
            case "shearX": Property.shearX;
            case "shearY": Property.shearY;
            case "rgb": Property.rgb;
            case "alpha": Property.alpha;
            case "rgb2": Property.rgb2;
            case "attachment": Property.attachment;
            case "deform": Property.deform;
            case "event": Property.event;
            case "drawOrder": Property.drawOrder;
            case "ikConstraint": Property.ikConstraint;
            case "transformConstraint": Property.transformConstraint;
            case "pathConstraintPosition": Property.pathConstraintPosition;
            case "pathConstraintSpacing": Property.pathConstraintSpacing;
            case "pathConstraintMix": Property.pathConstraintMix;
            default: Property.rotate;
        };
    }

}
