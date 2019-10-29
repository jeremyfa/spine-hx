/******************************************************************************
 * Spine Runtimes License Agreement
 * Last updated May 1, 2019. Replaces all prior versions.
 *
 * Copyright (c) 2013-2019, Esoteric Software LLC
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
 * THIS SOFTWARE IS PROVIDED BY ESOTERIC SOFTWARE LLC "AS IS" AND ANY EXPRESS
 * OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN
 * NO EVENT SHALL ESOTERIC SOFTWARE LLC BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES, BUSINESS
 * INTERRUPTION, OR LOSS OF USE, DATA, OR PROFITS) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *****************************************************************************/

package spine;

import spine.Animation.Timeline;
import spine.AnimationState.AnimationStateListener;

/** Stores the current pose values for an {@link Event}.
 * <p>
 * See Timeline
 * {@link Timeline#apply(Skeleton, float, float, com.badlogic.gdx.utils.Array, float, com.esotericsoftware.spine.Animation.MixBlend, com.esotericsoftware.spine.Animation.MixDirection)},
 * AnimationStateListener {@link AnimationStateListener#event(com.esotericsoftware.spine.AnimationState.TrackEntry, Event)}, and
 * <a href="http://esotericsoftware.com/spine-events">Events</a> in the Spine User Guide. */
class Event {
    private var data:EventData;
    public var intValue:Int = 0;
    public var floatValue:Float = 0;
    public var stringValue:String;
    public var volume:Float = 0; public var balance:Float = 0;
    public var time:Float = 0;

    public function new(time:Float, data:EventData) {
        if (data == null) throw new IllegalArgumentException("data cannot be null.");
        this.time = time;
        this.data = data;
    }

    #if !spine_no_inline inline #end public function getInt():Int {
        return intValue;
    }

    #if !spine_no_inline inline #end public function setInt(intValue:Int):Void {
        this.intValue = intValue;
    }

    #if !spine_no_inline inline #end public function getFloat():Float {
        return floatValue;
    }

    #if !spine_no_inline inline #end public function setFloat(floatValue:Float):Void {
        this.floatValue = floatValue;
    }

    #if !spine_no_inline inline #end public function getString():String {
        return stringValue;
    }

    #if !spine_no_inline inline #end public function setString(stringValue:String):Void {
        if (stringValue == null) throw new IllegalArgumentException("stringValue cannot be null.");
        this.stringValue = stringValue;
    }

    #if !spine_no_inline inline #end public function getVolume():Float {
        return volume;
    }

    #if !spine_no_inline inline #end public function setVolume(volume:Float):Void {
        this.volume = volume;
    }

    #if !spine_no_inline inline #end public function getBalance():Float {
        return balance;
    }

    #if !spine_no_inline inline #end public function setBalance(balance:Float):Void {
        this.balance = balance;
    }

    /** The animation time this event was keyed. */
    #if !spine_no_inline inline #end public function getTime():Float {
        return time;
    }

    /** The events's setup pose data. */
    #if !spine_no_inline inline #end public function getData():EventData {
        return data;
    }

    #if !spine_no_inline inline #end public function toString():String {
        return data.name;
    }
}
