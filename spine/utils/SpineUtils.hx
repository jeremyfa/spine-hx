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

package spine.utils;

class SpineUtils {
    inline public static var PI:Float = 3.1415927;
    inline public static var PI2:Float = PI * 2;
    public static var radiansToDegrees:Float = 180 / PI;
    public static var radDeg:Float = radiansToDegrees;
    public static var degreesToRadians:Float = PI / 180;
    public static var degRad:Float = degreesToRadians;

    #if !spine_no_inline inline #end public static function cosDeg(angle:Float):Float {
        return cast(Math.cos(angle * degRad), Float);
    }

    #if !spine_no_inline inline #end public static function sinDeg(angle:Float):Float {
        return cast(Math.sin(angle * degRad), Float);
    }

    #if !spine_no_inline inline #end public static function cos(angle:Float):Float {
        return cast(Math.cos(angle), Float);
    }

    #if !spine_no_inline inline #end public static function sin(angle:Float):Float {
        return cast(Math.sin(angle), Float);
    }

    #if !spine_no_inline inline #end public static function atan2(y:Float, x:Float):Float {
        return cast(Math.atan2(y, x), Float);
    }

    public function new() {}
}
