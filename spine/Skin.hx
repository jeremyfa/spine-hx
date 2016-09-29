/******************************************************************************
 * Spine Runtimes Software License
 * Version 2.3
 * 
 * Copyright (c) 2013-2015, Esoteric Software
 * All rights reserved.
 * 
 * You are granted a perpetual, non-exclusive, non-sublicensable and
 * non-transferable license to use, install, execute and perform the Spine
 * Runtimes Software (the "Software") and derivative works solely for personal
 * or internal use. Without the written permission of Esoteric Software (see
 * Section 2 of the Spine Software License Agreement), you may not (a) modify,
 * translate, adapt or otherwise create derivative works, improvements of the
 * Software or develop new applications using the Software or (b) remove,
 * delete, alter or obscure any trademarks or any copyright, trademark, patent
 * or other intellectual property or proprietary rights notices on or in the
 * Software, including any copy thereof. Redistributions in binary or source
 * form must include this license and terms.
 * 
 * THIS SOFTWARE IS PROVIDED BY ESOTERIC SOFTWARE "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL ESOTERIC SOFTWARE BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *****************************************************************************/

package spine;

import flash.errors.ArgumentError;
import flash.utils.Dictionary;
import spine.attachments.Attachment;

/** Stores attachments by slot index and attachment name. */
class Skin
{
    public var attachments(get, never) : Array<Dictionary>;
    public var name(get, never) : String;

    @:allow(spine)
    private var _name : String;
    private var _attachments : Array<Dictionary> = new Array<Dictionary>();
    
    public function new(name : String)
    {
        if (name == null)
        {
            throw new ArgumentError("name cannot be null.");
        }
        _name = name;
    }
    
    public function addAttachment(slotIndex : Int, name : String, attachment : Attachment) : Void
    {
        if (attachment == null)
        {
            throw new ArgumentError("attachment cannot be null.");
        }
        if (slotIndex >= attachments.length)
        {
            spine.as3hx.Compat.setArrayLength(attachments, slotIndex + 1);
        }
        if (attachments[slotIndex] == null)
        {
            attachments[slotIndex] = new Dictionary();
        }
        Reflect.setField(attachments[slotIndex], name, attachment);
    }
    
    /** @return May be null. */
    public function getAttachment(slotIndex : Int, name : String) : Attachment
    {
        if (slotIndex >= attachments.length)
        {
            return null;
        }
        var dictionary : Dictionary = attachments[slotIndex];
        return (dictionary != null) ? dictionary[name] : null;
    }
    
    private function get_attachments() : Array<Dictionary>
    {
        return _attachments;
    }
    
    private function get_name() : String
    {
        return _name;
    }
    
    public function toString() : String
    {
        return _name;
    }
    
    /** Attach each attachment in this skin if the corresponding attachment in the old skin is currently attached. */
    public function attachAll(skeleton : Skeleton, oldSkin : Skin) : Void
    {
        var slotIndex : Int = 0;
        for (slot/* AS3HX WARNING could not determine type for var: slot exp: EField(EIdent(skeleton),slots) type: null */ in skeleton.slots)
        {
            var slotAttachment : Attachment = slot.attachment;
            if (slotAttachment != null && slotIndex < oldSkin.attachments.length)
            {
                var dictionary : Dictionary = oldSkin.attachments[slotIndex];
                for (name in Reflect.fields(dictionary))
                {
                    var skinAttachment : Attachment = dictionary[name];
                    if (slotAttachment == skinAttachment)
                    {
                        var attachment : Attachment = getAttachment(slotIndex, name);
                        if (attachment != null)
                        {
                            slot.attachment = attachment;
                        }
                        break;
                    }
                }
            }
            slotIndex++;
        }
    }
}


