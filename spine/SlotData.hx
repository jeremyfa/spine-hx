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

import spine.support.graphics.Color;

/** Stores the setup pose for a {@link Slot}. */
class SlotData {
    public var index:Int = 0;
    public var name:String;
    public var boneData:BoneData;
    public var color:Color = new Color(1, 1, 1, 1);
    public var darkColor:Color;
    public var attachmentName:String;
    public var blendMode:BlendMode;

    public function new(index:Int, name:String, boneData:BoneData) {
        if (index < 0) throw new IllegalArgumentException("index must be >= 0.");
        if (name == null) throw new IllegalArgumentException("name cannot be null.");
        if (boneData == null) throw new IllegalArgumentException("boneData cannot be null.");
        this.index = index;
        this.name = name;
        this.boneData = boneData;
    }

    /** The index of the slot in {@link Skeleton#getSlots()}. */
    #if !spine_no_inline inline #end public function getIndex():Int {
        return index;
    }

    /** The name of the slot, which is unique within the skeleton. */
    #if !spine_no_inline inline #end public function getName():String {
        return name;
    }

    /** The bone this slot belongs to. */
    #if !spine_no_inline inline #end public function getBoneData():BoneData {
        return boneData;
    }

    /** The color used to tint the slot's attachment. If {@link #getDarkColor()} is set, this is used as the light color for two
     * color tinting. */
    #if !spine_no_inline inline #end public function getColor():Color {
        return color;
    }

    /** The dark color used to tint the slot's attachment for two color tinting, or null if two color tinting is not used. The dark
     * color's alpha is not used. */
    #if !spine_no_inline inline #end public function getDarkColor():Color {
        return darkColor;
    }

    #if !spine_no_inline inline #end public function setDarkColor(darkColor:Color):Void {
        this.darkColor = darkColor;
    }

    /** @param attachmentName May be null. */
    #if !spine_no_inline inline #end public function setAttachmentName(attachmentName:String):Void {
        this.attachmentName = attachmentName;
    }

    /** The name of the attachment that is visible for this slot in the setup pose, or null if no attachment is visible. */
    #if !spine_no_inline inline #end public function getAttachmentName():String {
        return attachmentName;
    }

    /** The blend mode for drawing the slot's attachment. */
    #if !spine_no_inline inline #end public function getBlendMode():BlendMode {
        return blendMode;
    }

    #if !spine_no_inline inline #end public function setBlendMode(blendMode:BlendMode):Void {
        this.blendMode = blendMode;
    }

    #if !spine_no_inline inline #end public function toString():String {
        return name;
    }
}
