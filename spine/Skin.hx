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
import spine.support.utils.AttachmentMap;
import spine.support.utils.AttachmentMap.Entry;
import spine.support.utils.Pool;

import spine.attachments.Attachment;

/** Stores attachments by slot index and attachment name.
 * <p>
 * See SkeletonData {@link SkeletonData#defaultSkin}, Skeleton {@link Skeleton#skin}, and
 * <a href="http://esotericsoftware.com/spine-runtime-skins">Runtime skins</a> in the Spine Runtimes Guide. */
class Skin {
    public var name:String;
    public var attachments:AttachmentMap = new AttachmentMap();
    private var lookup:Key = new Key();
    public var keyPool:Pool<Key> = new KeyPool(64);

    public function new(name:String) {
        if (name == null) throw new IllegalArgumentException("name cannot be null.");
        this.name = name;
    }

    /** Adds an attachment to the skin for the specified slot index and name. */
    #if !spine_no_inline inline #end public function addAttachment(slotIndex:Int, name:String, attachment:Attachment):Void {
        if (attachment == null) throw new IllegalArgumentException("attachment cannot be null.");
        if (slotIndex < 0) throw new IllegalArgumentException("slotIndex must be >= 0.");
        var key:Key = keyPool.obtain();
        key.set(slotIndex, name);
        attachments.put(key, attachment);
    }

    /** Adds all attachments from the specified skin to this skin. */
    #if !spine_no_inline inline #end public function addAttachments(skin:Skin):Void {
        for (entry in skin.attachments.entries()) {
            addAttachment(entry.key.slotIndex, entry.key.name, entry.value); }
    }

    /** Returns the attachment for the specified slot index and name, or null. */
    #if !spine_no_inline inline #end public function getAttachment(slotIndex:Int, name:String):Attachment {
        if (slotIndex < 0) throw new IllegalArgumentException("slotIndex must be >= 0.");
        lookup.set(slotIndex, name);
        return attachments.get(lookup);
    }

    /** Removes the attachment in the skin for the specified slot index and name, if any. */
    #if !spine_no_inline inline #end public function removeAttachment(slotIndex:Int, name:String):Void {
        if (slotIndex < 0) throw new IllegalArgumentException("slotIndex must be >= 0.");
        var key:Key = keyPool.obtain();
        key.set(slotIndex, name);
        attachments.remove(key);
        keyPool.free(key);
    }

    #if !spine_no_inline inline #end public function findNamesForSlot(slotIndex:Int, names:Array<String>):Void {
        if (names == null) throw new IllegalArgumentException("names cannot be null.");
        if (slotIndex < 0) throw new IllegalArgumentException("slotIndex must be >= 0.");
        for (key in attachments.keys()) {
            if (key.slotIndex == slotIndex) names.add(key.name); }
    }

    #if !spine_no_inline inline #end public function findAttachmentsForSlot(slotIndex:Int, attachments:Array<Attachment>):Void {
        if (attachments == null) throw new IllegalArgumentException("attachments cannot be null.");
        if (slotIndex < 0) throw new IllegalArgumentException("slotIndex must be >= 0.");
        for (entry in this.attachments.entries()) {
            if (entry.key.slotIndex == slotIndex) attachments.add(entry.value); }
    }

    #if !spine_no_inline inline #end public function clear():Void {
        for (key in attachments.keys()) {
            keyPool.free(key); }
        attachments.clear();
    }

    #if !spine_no_inline inline #end public function size():Int {
        return attachments.size;
    }

    /** The skin's name, which is unique within the skeleton. */
    #if !spine_no_inline inline #end public function getName():String {
        return name;
    }

    #if !spine_no_inline inline #end public function toString():String {
        return name;
    }

    /** Attach each attachment in this skin if the corresponding attachment in the old skin is currently attached. */
    #if !spine_no_inline inline #end public function attachAll(skeleton:Skeleton, oldSkin:Skin):Void {
        for (entry in oldSkin.attachments.entries()) {
            var slotIndex:Int = entry.key.slotIndex;
            var slot:Slot = skeleton.slots.get(slotIndex);
            if (slot.attachment == entry.value) {
                var attachment:Attachment = getAttachment(slotIndex, entry.key.name);
                if (attachment != null) slot.setAttachment(attachment);
            }
        }
    }
}

class Key {
    public var slotIndex:Int = 0;
    public var name:String;
    public var hashCode:Int = 0;

    #if !spine_no_inline inline #end public function set(slotIndex:Int, name:String):Void {
        if (name == null) throw new IllegalArgumentException("name cannot be null.");
        this.slotIndex = slotIndex;
        this.name = name;
        hashCode = name.getHashCode() + slotIndex * 37;
    }

    #if !spine_no_inline inline #end public function getHashCode():Int {
        return hashCode;
    }

    #if !spine_no_inline inline #end public function equals(object:Dynamic):Bool {
        if (object == null) return false;
        var other:Key = cast(object, Key);
        if (slotIndex != other.slotIndex) return false;
        if (!name.equals(other.name)) return false;
        return true;
    }

    #if !spine_no_inline inline #end public function toString():String {
        return slotIndex + ":" + name;
    }

    public function new() {}
}

private class KeyPool extends Pool<Key> {
    override public function new(initialCapacity:Int) {
        super(initialCapacity, 999999999);
    }
    override function newObject() {
        return new Key();
    }
}

