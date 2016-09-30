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

import spine.attachments.VertexAttachment;
import spine.Event;
import spine.Skeleton;
import spine.Slot;

class DeformTimeline extends CurveTimeline
{
    public var slotIndex : Int;
    public var frames : Array<Float>;
    public var frameVertices : Array<Array<Float>>;
    public var attachment : VertexAttachment;

    public function new(frameCount : Int)
    {
        super(frameCount);
        frames = new Array<Float>();
        frameVertices = new Array<Array<Float>>();
        for (i in 0...frameCount) {
            frames.push(0);
            frameVertices.push(null);
        }
    }

    /** Sets the time and value of the specified keyframe. */
    public function setFrame(frameIndex : Int, time : Float, vertices : Array<Float>) : Void
    {
        frames[frameIndex] = time;
        frameVertices[frameIndex] = vertices;
    }

    override public function apply(skeleton : Skeleton, lastTime : Float, time : Float, firedEvents : Array<Event>, alpha : Float) : Void
    {
        var slot : Slot = skeleton.slots[slotIndex];
        var slotAttachment : VertexAttachment = try cast(slot.attachment, VertexAttachment) catch(e:Dynamic) null;
        if (slotAttachment == null || !slotAttachment.applyDeform(attachment))
        {
            return;
        }

        var frames : Array<Float> = this.frames;
        if (time < frames[0])
        {
            return;
        }  // Time is before first frame.

        var frameVertices : Array<Array<Float>> = this.frameVertices;
        var vertexCount : Int = frameVertices[0].length;

        var vertices : Array<Float> = slot.attachmentVertices;
        if (vertices.length != vertexCount)
        {
            alpha = 1;
        }  // Don't mix from uninitialized slot vertices.
        spine.compat.Compat.setArrayLength(vertices, vertexCount);

        var i : Int;
        if (time >= frames[frames.length - 1])
        {
            // Time is after last frame.
            var lastVertices : Array<Float> = frameVertices[spine.compat.Compat.parseInt(frames.length - 1)];
            if (alpha < 1)
            {
                for (i in 0...vertexCount)
                {
                    vertices[i] += (lastVertices[i] - vertices[i]) * alpha;
                }
            }
            else
            {
                for (i in 0...vertexCount)
                {
                    vertices[i] = lastVertices[i];
                }
            }
            return;
        }

        // Interpolate between the previous frame and the current frame.
        var frame : Int = Animation.binarySearch1(frames, time);
        var prevVertices : Array<Float> = frameVertices[spine.compat.Compat.parseInt(frame - 1)];
        var nextVertices : Array<Float> = frameVertices[frame];
        var frameTime : Float = frames[frame];
        var percent : Float = getCurvePercent(frame - 1, 1 - (time - frameTime) / (frames[frame - 1] - frameTime));

        var prev : Float;
        if (alpha < 1)
        {
            for (i in 0...vertexCount)
            {
                prev = prevVertices[i];
                vertices[i] += (prev + (nextVertices[i] - prev) * percent - vertices[i]) * alpha;
            }
        }
        else
        {
            for (i in 0...vertexCount)
            {
                prev = prevVertices[i];
                vertices[i] = prev + (nextVertices[i] - prev) * percent;
            }
        }
    }
}
