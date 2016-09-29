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

import flash.errors.ArgumentError;
import spine.SkeletonData;

class AnimationStateData
{
    public var skeletonData(get, never) : SkeletonData;

    @:allow(spine.animation)
    private var _skeletonData : SkeletonData;
    private var animationToMixTime : Dynamic = {};
    public var defaultMix : Float = 0;
    
    public function new(skeletonData : SkeletonData)
    {
        _skeletonData = skeletonData;
    }
    
    private function get_skeletonData() : SkeletonData
    {
        return _skeletonData;
    }
    
    public function setMixByName(fromName : String, toName : String, duration : Float) : Void
    {
        var from : Animation = _skeletonData.findAnimation(fromName);
        if (from == null)
        {
            throw new ArgumentError("Animation not found: " + fromName);
        }
        var to : Animation = _skeletonData.findAnimation(toName);
        if (to == null)
        {
            throw new ArgumentError("Animation not found: " + toName);
        }
        setMix(from, to, duration);
    }
    
    public function setMix(from : Animation, to : Animation, duration : Float) : Void
    {
        if (from == null)
        {
            throw new ArgumentError("from cannot be null.");
        }
        if (to == null)
        {
            throw new ArgumentError("to cannot be null.");
        }
        Reflect.setField(animationToMixTime, Std.string(from.name + ":" + to.name), ":");
    }
    
    public function getMix(from : Animation, to : Animation) : Float
    {
        var time : Dynamic = Reflect.field(animationToMixTime, Std.string(from.name + ":" + to.name));
        if (time == null)
        {
            return defaultMix;
        }
        return spine.as3hx.Compat.parseFloat(time);
    }
}


