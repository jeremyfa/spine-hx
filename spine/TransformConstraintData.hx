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

/** Stores the setup pose for a {@link TransformConstraint}.
 * <p>
 * See <a href="http://esotericsoftware.com/spine-transform-constraints">Transform constraints</a> in the Spine User Guide. */
class TransformConstraintData {
    public var name:String;
    public var order:Int = 0;
    public var bones:Array<BoneData> = new Array();
    public var target:BoneData;
    public var rotateMix:Float = 0; public var translateMix:Float = 0; public var scaleMix:Float = 0; public var shearMix:Float = 0;
    public var offsetRotation:Float = 0; public var offsetX:Float = 0; public var offsetY:Float = 0; public var offsetScaleX:Float = 0; public var offsetScaleY:Float = 0; public var offsetShearY:Float = 0;
    public var relative:Bool = false; public var local:Bool = false;

    public function new(name:String) {
        if (name == null) throw new IllegalArgumentException("name cannot be null.");
        this.name = name;
    }

    /** The transform constraint's name, which is unique within the skeleton. */
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

    /** The bones that will be modified by this transform constraint. */
    #if !spine_no_inline inline #end public function getBones():Array<BoneData> {
        return bones;
    }

    /** The target bone whose world transform will be copied to the constrained bones. */
    #if !spine_no_inline inline #end public function getTarget():BoneData {
        return target;
    }

    #if !spine_no_inline inline #end public function setTarget(target:BoneData):Void {
        if (target == null) throw new IllegalArgumentException("target cannot be null.");
        this.target = target;
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

    /** A percentage (0-1) that controls the mix between the constrained and unconstrained scales. */
    #if !spine_no_inline inline #end public function getScaleMix():Float {
        return scaleMix;
    }

    #if !spine_no_inline inline #end public function setScaleMix(scaleMix:Float):Void {
        this.scaleMix = scaleMix;
    }

    /** A percentage (0-1) that controls the mix between the constrained and unconstrained shears. */
    #if !spine_no_inline inline #end public function getShearMix():Float {
        return shearMix;
    }

    #if !spine_no_inline inline #end public function setShearMix(shearMix:Float):Void {
        this.shearMix = shearMix;
    }

    /** An offset added to the constrained bone rotation. */
    #if !spine_no_inline inline #end public function getOffsetRotation():Float {
        return offsetRotation;
    }

    #if !spine_no_inline inline #end public function setOffsetRotation(offsetRotation:Float):Void {
        this.offsetRotation = offsetRotation;
    }

    /** An offset added to the constrained bone X translation. */
    #if !spine_no_inline inline #end public function getOffsetX():Float {
        return offsetX;
    }

    #if !spine_no_inline inline #end public function setOffsetX(offsetX:Float):Void {
        this.offsetX = offsetX;
    }

    /** An offset added to the constrained bone Y translation. */
    #if !spine_no_inline inline #end public function getOffsetY():Float {
        return offsetY;
    }

    #if !spine_no_inline inline #end public function setOffsetY(offsetY:Float):Void {
        this.offsetY = offsetY;
    }

    /** An offset added to the constrained bone scaleX. */
    #if !spine_no_inline inline #end public function getOffsetScaleX():Float {
        return offsetScaleX;
    }

    #if !spine_no_inline inline #end public function setOffsetScaleX(offsetScaleX:Float):Void {
        this.offsetScaleX = offsetScaleX;
    }

    /** An offset added to the constrained bone scaleY. */
    #if !spine_no_inline inline #end public function getOffsetScaleY():Float {
        return offsetScaleY;
    }

    #if !spine_no_inline inline #end public function setOffsetScaleY(offsetScaleY:Float):Void {
        this.offsetScaleY = offsetScaleY;
    }

    /** An offset added to the constrained bone shearY. */
    #if !spine_no_inline inline #end public function getOffsetShearY():Float {
        return offsetShearY;
    }

    #if !spine_no_inline inline #end public function setOffsetShearY(offsetShearY:Float):Void {
        this.offsetShearY = offsetShearY;
    }

    #if !spine_no_inline inline #end public function getRelative():Bool {
        return relative;
    }

    #if !spine_no_inline inline #end public function setRelative(relative:Bool):Void {
        this.relative = relative;
    }

    #if !spine_no_inline inline #end public function getLocal():Bool {
        return local;
    }

    #if !spine_no_inline inline #end public function setLocal(local:Bool):Void {
        this.local = local;
    }

    #if !spine_no_inline inline #end public function toString():String {
        return name;
    }
}
