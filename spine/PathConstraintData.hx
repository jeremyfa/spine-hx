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

import spine.support.utils.Array;

/** Stores the setup pose for a {@link PathConstraint}.
 * <p>
 * See <a href="http://esotericsoftware.com/spine-path-constraints">Path constraints</a> in the Spine User Guide. */
class PathConstraintData {
    public var name:String;
    public var order:Int = 0;
    public var bones:Array<BoneData> = new Array();
    public var target:SlotData;
    public var positionMode:PositionMode;
    public var spacingMode:SpacingMode;
    public var rotateMode:RotateMode;
    public var offsetRotation:Float = 0;
    public var position:Float = 0; public var spacing:Float = 0; public var rotateMix:Float = 0; public var translateMix:Float = 0;

    public function new(name:String) {
        if (name == null) throw new IllegalArgumentException("name cannot be null.");
        this.name = name;
    }

    /** The path constraint's name, which is unique within the skeleton. */
    #if !spine_no_inline inline #end public function getName():String {
        return name;
    }

    /** See {@link Constraint#getOrder()}. */
    #if !spine_no_inline inline #end public function getOrder():Int {
        return order;
    }

    #if !spine_no_inline inline #end public function setOrder(order:Int):Void {
        this.order = order;
    }

    /** The bones that will be modified by this path constraint. */
    #if !spine_no_inline inline #end public function getBones():Array<BoneData> {
        return bones;
    }

    /** The slot whose path attachment will be used to constrained the bones. */
    #if !spine_no_inline inline #end public function getTarget():SlotData {
        return target;
    }

    #if !spine_no_inline inline #end public function setTarget(target:SlotData):Void {
        this.target = target;
    }

    /** The mode for positioning the first bone on the path. */
    #if !spine_no_inline inline #end public function getPositionMode():PositionMode {
        return positionMode;
    }

    #if !spine_no_inline inline #end public function setPositionMode(positionMode:PositionMode):Void {
        this.positionMode = positionMode;
    }

    /** The mode for positioning the bones after the first bone on the path. */
    #if !spine_no_inline inline #end public function getSpacingMode():SpacingMode {
        return spacingMode;
    }

    #if !spine_no_inline inline #end public function setSpacingMode(spacingMode:SpacingMode):Void {
        this.spacingMode = spacingMode;
    }

    /** The mode for adjusting the rotation of the bones. */
    #if !spine_no_inline inline #end public function getRotateMode():RotateMode {
        return rotateMode;
    }

    #if !spine_no_inline inline #end public function setRotateMode(rotateMode:RotateMode):Void {
        this.rotateMode = rotateMode;
    }

    /** An offset added to the constrained bone rotation. */
    #if !spine_no_inline inline #end public function getOffsetRotation():Float {
        return offsetRotation;
    }

    #if !spine_no_inline inline #end public function setOffsetRotation(offsetRotation:Float):Void {
        this.offsetRotation = offsetRotation;
    }

    /** The position along the path. */
    #if !spine_no_inline inline #end public function getPosition():Float {
        return position;
    }

    #if !spine_no_inline inline #end public function setPosition(position:Float):Void {
        this.position = position;
    }

    /** The spacing between bones. */
    #if !spine_no_inline inline #end public function getSpacing():Float {
        return spacing;
    }

    #if !spine_no_inline inline #end public function setSpacing(spacing:Float):Void {
        this.spacing = spacing;
    }

    /** A percentage (0-1) that controls the mix between the constrained and unconstrained rotations. */
    #if !spine_no_inline inline #end public function getRotateMix():Float {
        return rotateMix;
    }

    #if !spine_no_inline inline #end public function setRotateMix(rotateMix:Float):Void {
        this.rotateMix = rotateMix;
    }

    /** A percentage (0-1) that controls the mix between the constrained and unconstrained translations. */
    #if !spine_no_inline inline #end public function getTranslateMix():Float {
        return translateMix;
    }

    #if !spine_no_inline inline #end public function setTranslateMix(translateMix:Float):Void {
        this.translateMix = translateMix;
    }

    #if !spine_no_inline inline #end public function toString():String {
        return name;
    }
}

/** Controls how the first bone is positioned along the path.
 * <p>
 * See <a href="http://esotericsoftware.com/spine-path-constraints#Position-mode">Position mode</a> in the Spine User Guide. */
@:enum abstract PositionMode(Int) from Int to Int {
    var fixed = 0; var percent = 1;

    //public static var values:PositionMode[] = PositionMode.values();
}

/** Controls how bones after the first bone are positioned along the path.
 * <p>
 * See <a href="http://esotericsoftware.com/spine-path-constraints#Spacing-mode">Spacing mode</a> in the Spine User Guide. */
@:enum abstract SpacingMode(Int) from Int to Int {
    var length = 0; var fixed = 1; var percent = 2;

    //public static var values:SpacingMode[] = SpacingMode.values();
}

/** Controls how bones are rotated, translated, and scaled to match the path.
 * <p>
 * See <a href="http://esotericsoftware.com/spine-path-constraints#Rotate-mode">Rotate mode</a> in the Spine User Guide. */
@:enum abstract RotateMode(Int) from Int to Int {
    var tangent = 0; var chain = 1; var chainScale = 2;

    //public static var values:RotateMode[] = RotateMode.values();
}

class PositionMode_enum {

    public inline static var fixed_value = 0;
    public inline static var percent_value = 1;

    public inline static var fixed_name = "fixed";
    public inline static var percent_name = "percent";

    public inline static function valueOf(value:String):PositionMode {
        return switch (value) {
            case "fixed": PositionMode.fixed;
            case "percent": PositionMode.percent;
            default: PositionMode.fixed;
        };
    }

}

class SpacingMode_enum {

    public inline static var length_value = 0;
    public inline static var fixed_value = 1;
    public inline static var percent_value = 2;

    public inline static var length_name = "length";
    public inline static var fixed_name = "fixed";
    public inline static var percent_name = "percent";

    public inline static function valueOf(value:String):SpacingMode {
        return switch (value) {
            case "length": SpacingMode.length;
            case "fixed": SpacingMode.fixed;
            case "percent": SpacingMode.percent;
            default: SpacingMode.length;
        };
    }

}

class RotateMode_enum {

    public inline static var tangent_value = 0;
    public inline static var chain_value = 1;
    public inline static var chainScale_value = 2;

    public inline static var tangent_name = "tangent";
    public inline static var chain_name = "chain";
    public inline static var chainScale_name = "chainScale";

    public inline static function valueOf(value:String):RotateMode {
        return switch (value) {
            case "tangent": RotateMode.tangent;
            case "chain": RotateMode.chain;
            case "chainScale": RotateMode.chainScale;
            default: RotateMode.tangent;
        };
    }

}
