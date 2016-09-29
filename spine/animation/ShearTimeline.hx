package spine.animation;

import spine.Event;
import spine.Skeleton;
import spine.Bone;

class ShearTimeline extends TranslateTimeline
{
    public function new(frameCount : Int)
    {
        super(frameCount);
    }

    override public function apply(skeleton : Skeleton, lastTime : Float, time : Float, firedEvents : Array<Event>, alpha : Float) : Void
    {
        var frames : Array<Float> = this.frames;
        if (time < frames[0])
        {
            return;
        }  // Time is before first frame.

        var bone : Bone = skeleton.bones[boneIndex];
        if (time >= frames[frames.length - TranslateTimeline.ENTRIES])
        {
            // Time is after last frame.
            bone.shearX += (bone.data.shearX + frames[frames.length + TranslateTimeline.PREV_X] - bone.shearX) * alpha;
            bone.shearY += (bone.data.shearY + frames[frames.length + TranslateTimeline.PREV_Y] - bone.shearY) * alpha;
            return;
        }

        // Interpolate between the previous frame and the current frame.
        var frame : Int = Animation.binarySearch(frames, time, TranslateTimeline.ENTRIES);
        var prevX : Float = frames[frame + TranslateTimeline.PREV_X];
        var prevY : Float = frames[frame + TranslateTimeline.PREV_Y];
        var frameTime : Float = frames[frame];
        var percent : Float = getCurvePercent(cast frame / TranslateTimeline.ENTRIES - 1, 1 - (time - frameTime) / (frames[frame + TranslateTimeline.PREV_TIME] - frameTime));

        bone.shearX += (bone.data.shearX + (prevX + (frames[frame + TranslateTimeline.X] - prevX) * percent) - bone.shearX) * alpha;
        bone.shearY += (bone.data.shearY + (prevY + (frames[frame + TranslateTimeline.Y] - prevY) * percent) - bone.shearY) * alpha;
    }
}
