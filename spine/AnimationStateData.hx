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

import spine.support.utils.AnimationStateMap;

import spine.AnimationState.TrackEntry;

/** Stores mix (crossfade) durations to be applied when {@link AnimationState} animations are changed. */
class AnimationStateData {
    public var skeletonData:SkeletonData;
    public var animationToMixTime:AnimationStateMap = new AnimationStateMap(51, 0.8);
    public var tempAnimationStateDataKey:AnimationStateDataKey = new AnimationStateDataKey();
    public var defaultMix:Float = 0;

    public function new(skeletonData:SkeletonData) {
        if (skeletonData == null) throw new IllegalArgumentException("skeletonData cannot be null.");
        this.skeletonData = skeletonData;
    }

    /** The SkeletonData to look up animations when they are specified by name. */
    #if !spine_no_inline inline #end public function getSkeletonData():SkeletonData {
        return skeletonData;
    }

    /** Sets a mix duration by animation name.
     * <p>
     * See {@link #setMix(Animation, Animation, float)}. */
    #if !spine_no_inline inline #end public function setMixByName(fromName:String, toName:String, duration:Float):Void {
        var from:Animation = skeletonData.findAnimation(fromName);
        if (from == null) throw new IllegalArgumentException("Animation not found: " + fromName);
        var to:Animation = skeletonData.findAnimation(toName);
        if (to == null) throw new IllegalArgumentException("Animation not found: " + toName);
        setMix(from, to, duration);
    }

    /** Sets the mix duration when changing from the specified animation to the other.
     * <p>
     * See {@link TrackEntry#mixDuration}. */
    #if !spine_no_inline inline #end public function setMix(from:Animation, to:Animation, duration:Float):Void {
        if (from == null) throw new IllegalArgumentException("from cannot be null.");
        if (to == null) throw new IllegalArgumentException("to cannot be null.");
        var key:AnimationStateDataKey = new AnimationStateDataKey();
        key.a1 = from;
        key.a2 = to;
        animationToMixTime.put(key, duration);
    }

    /** Returns the mix duration to use when changing from the specified animation to the other, or the {@link #getDefaultMix()} if
     * no mix duration has been set. */
    #if !spine_no_inline inline #end public function getMix(from:Animation, to:Animation):Float {
        if (from == null) throw new IllegalArgumentException("from cannot be null.");
        if (to == null) throw new IllegalArgumentException("to cannot be null.");
        tempAnimationStateDataKey.a1 = from;
        tempAnimationStateDataKey.a2 = to;
        return animationToMixTime.get(tempAnimationStateDataKey, defaultMix);
    }

    /** The mix duration to use when no mix duration has been defined between two animations. */
    #if !spine_no_inline inline #end public function getDefaultMix():Float {
        return defaultMix;
    }

    #if !spine_no_inline inline #end public function setDefaultMix(defaultMix:Float):Void {
        this.defaultMix = defaultMix;
    }
}

class AnimationStateDataKey {
    public var a1:Animation; public var a2:Animation = null;

    public function getHashCode():Int {
        return 31 * (31 + a1.getHashCode()) + a2.getHashCode();
    }

    public function equals(obj:Dynamic):Bool {
        if (this == obj) return true;
        if (obj == null) return false;
        var other:AnimationStateDataKey = fastCast(obj, AnimationStateDataKey);
        if (a1 == null) {
            if (other.a1 != null) return false;
        } else if (!a1.equals(other.a1)) return false;
        if (a2 == null) {
            if (other.a2 != null) return false;
        } else if (!a2.equals(other.a2)) return false;
        return true;
    }

    #if !spine_no_inline inline #end public function toString():String {
        return a1.name + "->" + a2.name;
    }

    public function new() {}
}