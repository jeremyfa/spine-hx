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

import spine.Event;
import spine.Skeleton;
import spine.PathConstraint;

class PathConstraintMixTimeline extends CurveTimeline
{
    public static inline var ENTRIES : Int = 3;
    @:allow(spine.animation)
    private static var PREV_TIME : Int = -3;@:allow(spine.animation)
    private static var PREV_ROTATE : Int = -2;@:allow(spine.animation)
    private static var PREV_TRANSLATE : Int = -1;
    @:allow(spine.animation)
    private static inline var ROTATE : Int = 1;@:allow(spine.animation)
    private static inline var TRANSLATE : Int = 2;
    
    public var pathConstraintIndex : Int;
    
    public var frames : Array<Float>;  // time, rotate mix, translate mix, ...  
    
    public function new(frameCount : Int)
    {
        super(frameCount);
        frames = new Array<Float>();
    }
    
    /** Sets the time and mixes of the specified keyframe. */
    public function setFrame(frameIndex : Int, time : Float, rotateMix : Float, translateMix : Float) : Void
    {
        frameIndex *= ENTRIES;
        frames[frameIndex] = time;
        frames[frameIndex + ROTATE] = rotateMix;
        frames[frameIndex + TRANSLATE] = translateMix;
    }
    
    override public function apply(skeleton : Skeleton, lastTime : Float, time : Float, firedEvents : Array<Event>, alpha : Float) : Void
    {
        if (time < frames[0])
        {
            return;
        }  // Time is before first frame.  
        
        var constraint : PathConstraint = skeleton.pathConstraints[pathConstraintIndex];
        
        if (time >= frames[frames.length - ENTRIES])
        {
            // Time is after last frame.
            var i : Int = frames.length;
            constraint.rotateMix += (frames[i + PREV_ROTATE] - constraint.rotateMix) * alpha;
            constraint.translateMix += (frames[i + PREV_TRANSLATE] - constraint.translateMix) * alpha;
            return;
        }
        
        // Interpolate between the previous frame and the current frame.
        var frame : Int = Animation.binarySearch(frames, time, ENTRIES);
        var rotate : Float = frames[frame + PREV_ROTATE];
        var translate : Float = frames[frame + PREV_TRANSLATE];
        var frameTime : Float = frames[frame];
        var percent : Float = getCurvePercent(frame / ENTRIES - 1, 1 - (time - frameTime) / (frames[frame + PREV_TIME] - frameTime));
        
        constraint.rotateMix += (rotate + (frames[frame + ROTATE] - rotate) * percent - constraint.rotateMix) * alpha;
        constraint.translateMix += (translate + (frames[frame + TRANSLATE] - translate) * percent - constraint.translateMix)
        * alpha;
    }
}
