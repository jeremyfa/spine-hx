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

import spine.support.utils.Array;
import spine.support.utils.AttachmentMap;
import spine.attachments.Attachment;
import spine.attachments.MeshAttachment;

/** Stores attachments by slot index and attachment name.
 * <p>
 * See SkeletonData {@link SkeletonData#defaultSkin}, Skeleton {@link Skeleton#skin}, and
 * <a href="http://esotericsoftware.com/spine-runtime-skins">Runtime skins</a> in the Spine Runtimes Guide. */
class Skin {
    public var name:String;
    public var attachments:AttachmentMap = new AttachmentMap();
    public var bones:Array<BoneData> = new Array();
    public var constraints:Array<ConstraintData> = new Array();
    private var lookup:SkinEntry = @:privateAccess new SkinEntry(0, "", null);

    public function new(name:String) {
        if (name == null) throw new IllegalArgumentException("name cannot be null.");
        this.name = name;
        //this.attachments.orderedKeys().ordered = false;
    }

    /** Adds an attachment to the skin for the specified slot index and name. */
    #if !spine_no_inline inline #end public function setAttachment(slotIndex:Int, name:String, attachment:Attachment):Void {
        if (slotIndex < 0) throw new IllegalArgumentException("slotIndex must be >= 0.");
        if (attachment == null) throw new IllegalArgumentException("attachment cannot be null.");
        var newEntry:SkinEntry = @:privateAccess new SkinEntry(slotIndex, name, attachment);
        var oldEntry:SkinEntry = attachments.put(newEntry, newEntry);
        if (oldEntry != null) {
            oldEntry.attachment = attachment;
        }
    }

    /** Adds all attachments, bones, and constraints from the specified skin to this skin. */
    #if !spine_no_inline inline #end public function addSkin(skin:Skin):Void {
        if (skin == null) throw new IllegalArgumentException("skin cannot be null.");

        for (data in skin.bones) {
            if (!bones.contains(data, true)) bones.add(data); }

        for (data in skin.constraints) {
            if (!constraints.contains(data, true)) constraints.add(data); }

        for (entry in skin.attachments.keys()) {
            setAttachment(entry.slotIndex, entry.name, entry.attachment); }
    }

    /** Adds all bones and constraints and copies of all attachments from the specified skin to this skin. Mesh attachments are not
     * copied, instead a new linked mesh is created. The attachment copies can be modified without affecting the originals. */
    #if !spine_no_inline inline #end public function copySkin(skin:Skin):Void {
        if (skin == null) throw new IllegalArgumentException("skin cannot be null.");

        for (data in skin.bones) {
            if (!bones.contains(data, true)) bones.add(data); }

        for (data in skin.constraints) {
            if (!constraints.contains(data, true)) constraints.add(data); }

        for (entry in skin.attachments.keys()) {
            if (Std.is(entry.attachment, MeshAttachment))
                setAttachment(entry.slotIndex, entry.name, (fastCast(entry.attachment, MeshAttachment)).newLinkedMesh());
            else
                setAttachment(entry.slotIndex, entry.name, entry.attachment != null ? entry.attachment.copy() : null);
        }
    }

    /** Returns the attachment for the specified slot index and name, or null. */
    #if !spine_no_inline inline #end public function getAttachment(slotIndex:Int, name:String):Attachment {
        if (slotIndex < 0) throw new IllegalArgumentException("slotIndex must be >= 0.");
        lookup.set(slotIndex, name);
        var entry:SkinEntry = attachments.get(lookup);
        return entry != null ? entry.attachment : null;
    }

    /** Removes the attachment in the skin for the specified slot index and name, if any. */
    #if !spine_no_inline inline #end public function removeAttachment(slotIndex:Int, name:String):Void {
        if (slotIndex < 0) throw new IllegalArgumentException("slotIndex must be >= 0.");
        lookup.set(slotIndex, name);
        attachments.remove(lookup);
    }

    /** Returns all attachments in this skin. */
    #if !spine_no_inline inline #end public function getAttachments():Array<SkinEntry> {
        return attachments.orderedKeys();
    }

    /** Returns all attachments in this skin for the specified slot index. */
    #if !spine_no_inline inline #end public function getAttachmentsInSkinForSlot(slotIndex:Int, attachments:Array<SkinEntry>):Void {
        if (slotIndex < 0) throw new IllegalArgumentException("slotIndex must be >= 0.");
        if (attachments == null) throw new IllegalArgumentException("attachments cannot be null.");
        for (entry in this.attachments.keys()) {
            if (entry.slotIndex == slotIndex) attachments.add(entry); }
    }

    /** Clears all attachments, bones, and constraints. */
    #if !spine_no_inline inline #end public function clear():Void {
        attachments.clear();
        bones.clear();
        constraints.clear();
    }

    #if !spine_no_inline inline #end public function getBones():Array<BoneData> {
        return bones;
    }

    #if !spine_no_inline inline #end public function getConstraints():Array<ConstraintData> {
        return constraints;
    }

    /** The skin's name, which is unique across all skins in the skeleton. */
    #if !spine_no_inline inline #end public function getName():String {
        return name;
    }

    #if !spine_no_inline inline #end public function toString():String {
        return name;
    }

    /** Attach each attachment in this skin if the corresponding attachment in the old skin is currently attached. */
    #if !spine_no_inline inline #end public function attachAll(skeleton:Skeleton, oldSkin:Skin):Void {
        for (entry in oldSkin.attachments.keys()) {
            var slotIndex:Int = entry.slotIndex;
            var slot:Slot = skeleton.slots.get(slotIndex);
            if (slot.attachment == entry.attachment) {
                var attachment:Attachment = getAttachment(slotIndex, entry.name);
                if (attachment != null) slot.setAttachment(attachment);
            }
        }
    }
}

/** Stores an entry in the skin consisting of the slot index, name, and attachment **/
class SkinEntry {
    public var slotIndex:Int = 0;
    public var name:String;
    public var attachment:Attachment;
    private var hashCode:Int = 0;

    /*function new() {
        set(0, "");
    }*/

    function new(slotIndex:Int, name:String, attachment:Attachment) {
        set(slotIndex, name);
        this.attachment = attachment;
    }

    #if !spine_no_inline inline #end public function set(slotIndex:Int, name:String):Void {
        if (name == null) throw new IllegalArgumentException("name cannot be null.");
        this.slotIndex = slotIndex;
        this.name = name;
        this.hashCode = Std.int(name.getHashCode() + slotIndex * 37);
    }

    #if !spine_no_inline inline #end public function getSlotIndex():Int {
        return slotIndex;
    }

    /** The name the attachment is associated with, equivalent to the skin placeholder name in the Spine editor. */
    #if !spine_no_inline inline #end public function getName():String {
        return name;
    }

    #if !spine_no_inline inline #end public function getAttachment():Attachment {
        return attachment;
    }

    #if !spine_no_inline inline #end public function getHashCode():Int {
        return hashCode;
    }

    #if !spine_no_inline inline #end public function equals(object:Dynamic):Bool {
        if (object == null) return false;
        var other:SkinEntry = fastCast(object, SkinEntry);
        if (slotIndex != other.slotIndex) return false;
        if (!name.equals(other.name)) return false;
        return true;
    }

    #if !spine_no_inline inline #end public function toString():String {
        return slotIndex + ":" + name;
    }
}