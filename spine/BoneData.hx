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

import spine.support.graphics.Color;

/** Stores the setup pose for a {@link Bone}. */
class BoneData {
    public var index:Int = 0;
    public var name:String;
    public var parent:BoneData;
    public var length:Float = 0;
    public var x:Float = 0; public var y:Float = 0; public var rotation:Float = 0; public var scaleX:Float = 1; public var scaleY:Float = 1; public var shearX:Float = 0; public var shearY:Float = 0;
    public var transformMode:TransformMode = TransformMode.normal;

    // Nonessential.
    public var color:Color = new Color(0.61, 0.61, 0.61, 1); // 9b9b9bff

    /** @param parent May be null. */
    public function new(index:Int, name:String, parent:BoneData) {
        if (index < 0) throw new IllegalArgumentException("index must be >= 0.");
        if (name == null) throw new IllegalArgumentException("name cannot be null.");
        this.index = index;
        this.name = name;
        this.parent = parent;
    }

    /** Copy constructor.
     * @param parent May be null. */
    /*public function new(bone:BoneData, parent:BoneData) {
        if (bone == null) throw new IllegalArgumentException("bone cannot be null.");
        index = bone.index;
        name = bone.name;
        this.parent = parent;
        length = bone.length;
        x = bone.x;
        y = bone.y;
        rotation = bone.rotation;
        scaleX = bone.scaleX;
        scaleY = bone.scaleY;
        shearX = bone.shearX;
        shearY = bone.shearY;
    }*/

    /** The index of the bone in {@link Skeleton#getBones()}. */
    #if !spine_no_inline inline #end public function getIndex():Int {
        return index;
    }

    /** The name of the bone, which is unique within the skeleton. */
    #if !spine_no_inline inline #end public function getName():String {
        return name;
    }

    /** @return May be null. */
    #if !spine_no_inline inline #end public function getParent():BoneData {
        return parent;
    }

    /** The bone's length. */
    #if !spine_no_inline inline #end public function getLength():Float {
        return length;
    }

    #if !spine_no_inline inline #end public function setLength(length:Float):Void {
        this.length = length;
    }

    /** The local x translation. */
    #if !spine_no_inline inline #end public function getX():Float {
        return x;
    }

    #if !spine_no_inline inline #end public function setX(x:Float):Void {
        this.x = x;
    }

    /** The local y translation. */
    #if !spine_no_inline inline #end public function getY():Float {
        return y;
    }

    #if !spine_no_inline inline #end public function setY(y:Float):Void {
        this.y = y;
    }

    #if !spine_no_inline inline #end public function setPosition(x:Float, y:Float):Void {
        this.x = x;
        this.y = y;
    }

    /** The local rotation. */
    #if !spine_no_inline inline #end public function getRotation():Float {
        return rotation;
    }

    #if !spine_no_inline inline #end public function setRotation(rotation:Float):Void {
        this.rotation = rotation;
    }

    /** The local scaleX. */
    #if !spine_no_inline inline #end public function getScaleX():Float {
        return scaleX;
    }

    #if !spine_no_inline inline #end public function setScaleX(scaleX:Float):Void {
        this.scaleX = scaleX;
    }

    /** The local scaleY. */
    #if !spine_no_inline inline #end public function getScaleY():Float {
        return scaleY;
    }

    #if !spine_no_inline inline #end public function setScaleY(scaleY:Float):Void {
        this.scaleY = scaleY;
    }

    #if !spine_no_inline inline #end public function setScale(scaleX:Float, scaleY:Float):Void {
        this.scaleX = scaleX;
        this.scaleY = scaleY;
    }

    /** The local shearX. */
    #if !spine_no_inline inline #end public function getShearX():Float {
        return shearX;
    }

    #if !spine_no_inline inline #end public function setShearX(shearX:Float):Void {
        this.shearX = shearX;
    }

    /** The local shearX. */
    #if !spine_no_inline inline #end public function getShearY():Float {
        return shearY;
    }

    #if !spine_no_inline inline #end public function setShearY(shearY:Float):Void {
        this.shearY = shearY;
    }

    /** The transform mode for how parent world transforms affect this bone. */
    #if !spine_no_inline inline #end public function getTransformMode():TransformMode {
        return transformMode;
    }

    #if !spine_no_inline inline #end public function setTransformMode(transformMode:TransformMode):Void {
        this.transformMode = transformMode;
    }

    /** The color of the bone as it was in Spine. Available only when nonessential data was exported. Bones are not usually
     * rendered at runtime. */
    #if !spine_no_inline inline #end public function getColor():Color {
        return color;
    }

    #if !spine_no_inline inline #end public function toString():String {
        return name;
    }
}

/** Determines how a bone inherits world transforms from parent bones. */
@:enum abstract TransformMode(Int) from Int to Int {
    var normal = 0; var onlyTranslation = 1; var noRotationOrReflection = 2; var noScale = 3; var noScaleOrReflection = 4;

    //public static var values:TransformMode[] = TransformMode.values();
}

class TransformMode_enum {

    public inline static var normal_value = 0;
    public inline static var onlyTranslation_value = 1;
    public inline static var noRotationOrReflection_value = 2;
    public inline static var noScale_value = 3;
    public inline static var noScaleOrReflection_value = 4;

    public inline static var normal_name = "normal";
    public inline static var onlyTranslation_name = "onlyTranslation";
    public inline static var noRotationOrReflection_name = "noRotationOrReflection";
    public inline static var noScale_name = "noScale";
    public inline static var noScaleOrReflection_name = "noScaleOrReflection";

    public inline static function valueOf(value:String):TransformMode {
        return switch (value) {
            case "normal": TransformMode.normal;
            case "onlyTranslation": TransformMode.onlyTranslation;
            case "noRotationOrReflection": TransformMode.noRotationOrReflection;
            case "noScale": TransformMode.noScale;
            case "noScaleOrReflection": TransformMode.noScaleOrReflection;
            default: TransformMode.normal;
        };
    }

}
