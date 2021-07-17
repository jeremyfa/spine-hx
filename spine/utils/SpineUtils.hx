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

package spine.utils;

class SpineUtils {
    inline public static var PI:Float = 3.1415927;
    inline public static var PI2:Float = PI * 2;
    public static var radiansToDegrees:Float = 180 / PI;
    public static var radDeg:Float = radiansToDegrees;
    public static var degreesToRadians:Float = PI / 180;
    public static var degRad:Float = degreesToRadians;

    #if !spine_no_inline inline #end public static function cosDeg(degrees:Float):Float {
        return Math.cos(degrees * degRad);
    }

    #if !spine_no_inline inline #end public static function sinDeg(degrees:Float):Float {
        return Math.sin(degrees * degRad);
    }

    #if !spine_no_inline inline #end public static function cos(radians:Float):Float {
        return Math.cos(radians);
    }

    #if !spine_no_inline inline #end public static function sin(radians:Float):Float {
        return Math.sin(radians);
    }

    #if !spine_no_inline inline #end public static function atan2(y:Float, x:Float):Float {
        return Math.atan2(y, x);
    }

    #if !spine_no_inline inline #end public static function arraycopy(src:Dynamic, srcPos:Int, dest:Dynamic, destPos:Int, length:Int):Void {
        if (src == null) throw new IllegalArgumentException("src cannot be null.");
        if (dest == null) throw new IllegalArgumentException("dest cannot be null.");
        try {
            spine.support.utils.Array.copy(src, srcPos, dest, destPos, length);
        } catch (ex:Dynamic) {
            throw new ArrayIndexOutOfBoundsException( //
                "Src: " + spine.support.utils.Array.getLengthOf(src) + ", " + srcPos //
                    + ", dest: " + spine.support.utils.Array.getLengthOf(dest) + ", " + destPos //
                    + ", count: " + length);
        }
    }

    public function new() {}
}
