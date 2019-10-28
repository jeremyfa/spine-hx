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



/** Determines how images are blended with existing pixels when drawn. */
@:enum abstract BlendMode(Int) from Int to Int {
    var normal = 0; //
    var additive = 1; //
    var multiply = 2; //
    var screen = 3;

    //public var source:Int = 0; public var sourcePMA:Int = 0; public var dest:Int = 0;

    /*function new(source:Int, sourcePremultipledAlpha:Int, dest:Int) {
        this.source = source;
        this.sourcePMA = sourcePremultipledAlpha;
        this.dest = dest;
    }*/

    /*#if !spine_no_inline inline #end public function getSource(premultipliedAlpha:Bool):Int {
        return premultipliedAlpha ? sourcePMA : source;
    }*/

    /*#if !spine_no_inline inline #end public function getDest():Int {
        return dest;
    }*/

    //public static var values:BlendMode[] = values();
}


class BlendMode_enum {

    public inline static var normal_value = 0;
    public inline static var additive_value = 1;
    public inline static var multiply_value = 2;
    public inline static var screen_value = 3;

    public inline static var normal_name = "normal";
    public inline static var additive_name = "additive";
    public inline static var multiply_name = "multiply";
    public inline static var screen_name = "screen";

    public inline static function valueOf(value:String):BlendMode {
        return switch (value) {
            case "normal": BlendMode.normal;
            case "additive": BlendMode.additive;
            case "multiply": BlendMode.multiply;
            case "screen": BlendMode.screen;
            default: BlendMode.normal;
        };
    }

}
