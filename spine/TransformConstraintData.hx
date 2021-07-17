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

import spine.support.utils.Array;

/** Stores the setup pose for a {@link TransformConstraint}.
 * <p>
 * See <a href="http://esotericsoftware.com/spine-transform-constraints">Transform constraints</a> in the Spine User Guide. */
class TransformConstraintData extends ConstraintData {
    public var bones:Array<BoneData> = new Array();
    public var target:BoneData;
    public var mixRotate:Float = 0; public var mixX:Float = 0; public var mixY:Float = 0; public var mixScaleX:Float = 0; public var mixScaleY:Float = 0; public var mixShearY:Float = 0;
    public var offsetRotation:Float = 0; public var offsetX:Float = 0; public var offsetY:Float = 0; public var offsetScaleX:Float = 0; public var offsetScaleY:Float = 0; public var offsetShearY:Float = 0;
    public var relative:Bool = false; public var local:Bool = false;

    public function new(name:String) {
        super(name);
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

    /** A percentage (0-1) that controls the mix between the constrained and unconstrained rotation. */
    #if !spine_no_inline inline #end public function getMixRotate():Float {
        return mixRotate;
    }

    #if !spine_no_inline inline #end public function setMixRotate(mixRotate:Float):Void {
        this.mixRotate = mixRotate;
    }

    /** A percentage (0-1) that controls the mix between the constrained and unconstrained translation X. */
    #if !spine_no_inline inline #end public function getMixX():Float {
        return mixX;
    }

    #if !spine_no_inline inline #end public function setMixX(mixX:Float):Void {
        this.mixX = mixX;
    }

    /** A percentage (0-1) that controls the mix between the constrained and unconstrained translation Y. */
    #if !spine_no_inline inline #end public function getMixY():Float {
        return mixY;
    }

    #if !spine_no_inline inline #end public function setMixY(mixY:Float):Void {
        this.mixY = mixY;
    }

    /** A percentage (0-1) that controls the mix between the constrained and unconstrained scale X. */
    #if !spine_no_inline inline #end public function getMixScaleX():Float {
        return mixScaleX;
    }

    #if !spine_no_inline inline #end public function setMixScaleX(mixScaleX:Float):Void {
        this.mixScaleX = mixScaleX;
    }

    /** A percentage (0-1) that controls the mix between the constrained and unconstrained scale Y. */
    #if !spine_no_inline inline #end public function getMixScaleY():Float {
        return mixScaleY;
    }

    #if !spine_no_inline inline #end public function setMixScaleY(mixScaleY:Float):Void {
        this.mixScaleY = mixScaleY;
    }

    /** A percentage (0-1) that controls the mix between the constrained and unconstrained shear Y. */
    #if !spine_no_inline inline #end public function getMixShearY():Float {
        return mixShearY;
    }

    #if !spine_no_inline inline #end public function setMixShearY(mixShearY:Float):Void {
        this.mixShearY = mixShearY;
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
}
