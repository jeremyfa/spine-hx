/******************************************************************************
 * Spine Runtimes Software License
 * Version 2.3
 *
 * Copyright (c) 2013-2015, Esoteric Software
 * All rights reserved.
 *
 * You are granted a perpetual, non-exclusive, non-sublicensable and
 * non-transferable license to use, install, execute and perform the Spine
 * Runtimes Software (the "Software") and derivative works solely for personal
 * or internal use. Without the written permission of Esoteric Software (see
 * Section 2 of the Spine Software License Agreement), you may not (a) modify,
 * translate, adapt or otherwise create derivative works, improvements of the
 * Software or develop new applications using the Software or (b) remove,
 * delete, alter or obscure any trademarks or any copyright, trademark, patent
 * or other intellectual property or proprietary rights notices on or in the
 * Software, including any copy thereof. Redistributions in binary or source
 * form must include this license and terms.
 *
 * THIS SOFTWARE IS PROVIDED BY ESOTERIC SOFTWARE "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL ESOTERIC SOFTWARE BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *****************************************************************************/

package spine.animation;

import spine.Bone;
import spine.Event;
import spine.Skeleton;

class RotateTimeline extends CurveTimeline
{
    public static inline var ENTRIES : Int = 2;
    private static var PREV_TIME : Int = -2;private static var PREV_ROTATION : Int = -1;
    private static inline var ROTATION : Int = 1;

    public var boneIndex : Int;
    public var frames : Array<Float>;  // time, value, ...

    public function new(frameCount : Int)
    {
        super(frameCount);
        frames = new Array<Float>();
        for (i in 0...frameCount * ENTRIES) frames.push(0);
    }

    /** Sets the time and angle of the specified keyframe. */
    public function setFrame(frameIndex : Int, time : Float, degrees : Float) : Void
    {
        frameIndex <<= 1;
        frames[frameIndex] = time;
        frames[spine.as3hx.Compat.parseInt(frameIndex + ROTATION)] = degrees;
    }

    override public function apply(skeleton : Skeleton, lastTime : Float, time : Float, firedEvents : Array<Event>, alpha : Float) : Void
    {
        if (time < frames[0])
        {
            return;
        }  // Time is before first frame.

        var bone : Bone = skeleton.bones[boneIndex];

        if (time >= frames[spine.as3hx.Compat.parseInt(frames.length - 2)])
        {
            // Time is after last frame.
            var amount : Float = bone.data.rotation + frames[spine.as3hx.Compat.parseInt(frames.length + PREV_ROTATION)] - bone.rotation;
            while (amount > 180)
            {
                amount -= 360;
            }
            while (amount < -180)
            {
                amount += 360;
            }
            bone.rotation += amount * alpha;
            return;
        }

        // Interpolate between the previous frame and the current frame.
        var frame : Int = Animation.binarySearch(frames, time, ENTRIES);
        var prevRotation : Float = frames[spine.as3hx.Compat.parseInt(frame + PREV_ROTATION)];
        var frameTime : Float = frames[frame];
        var percent : Float = getCurvePercent((frame >> 1) - 1, 1 - (time - frameTime) / (frames[frame + PREV_TIME] - frameTime));

        var amount = frames[spine.as3hx.Compat.parseInt(frame + ROTATION)] - prevRotation;
        while (amount > 180)
        {
            amount -= 360;
        }
        while (amount < -180)
        {
            amount += 360;
        }
        amount = bone.data.rotation + (prevRotation + amount * percent) - bone.rotation;
        while (amount > 180)
        {
            amount -= 360;
        }
        while (amount < -180)
        {
            amount += 360;
        }
        bone.rotation += amount * alpha;
    }
}
