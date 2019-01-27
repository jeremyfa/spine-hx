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

/** Stores the setup pose values for an {@link Event}.
 * <p>
 * See <a href="http://esotericsoftware.com/spine-events">Events</a> in the Spine User Guide. */
class EventData {
    public var name:String;
    public var intValue:Int = 0;
    public var floatValue:Float = 0;
    public var stringValue:String; public var audioPath:String = null;
    public var volume:Float = 0; public var balance:Float = 0;

    public function new(name:String) {
        if (name == null) throw new IllegalArgumentException("name cannot be null.");
        this.name = name;
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
        this.stringValue = stringValue;
    }

    #if !spine_no_inline inline #end public function getAudioPath():String {
        return audioPath;
    }

    #if !spine_no_inline inline #end public function setAudioPath(audioPath:String):Void {
        this.audioPath = audioPath;
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

    /** The name of the event, which is unique within the skeleton. */
    #if !spine_no_inline inline #end public function getName():String {
        return name;
    }

    #if !spine_no_inline inline #end public function toString():String {
        return name;
    }
}
