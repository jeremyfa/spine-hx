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

class BoneData
{
    public var index(get, never) : Int;
    public var name(get, never) : String;
    public var parent(get, never) : BoneData;

    @:allow(spine)
    private var _index : Int;
    @:allow(spine)
    private var _name : String;
    @:allow(spine)
    private var _parent : BoneData;
    public var length : Float;
    public var x : Float;
    public var y : Float;
    public var rotation : Float;
    public var scaleX : Float = 1;
    public var scaleY : Float = 1;
    public var shearX : Float;
    public var shearY : Float;
    public var inheritRotation : Bool = true;
    public var inheritScale : Bool = true;
    
    /** @param parent May be null. */
    public function new(index : Int, name : String, parent : BoneData)
    {
        if (index < 0)
        {
            throw new ArgumentError("index must be >= 0");
        }
        if (name == null)
        {
            throw new ArgumentError("name cannot be null.");
        }
        _index = index;
        _name = name;
        _parent = parent;
    }
    
    private function get_index() : Int
    {
        return _index;
    }
    
    private function get_name() : String
    {
        return _name;
    }
    
    /** @return May be null. */
    private function get_parent() : BoneData
    {
        return _parent;
    }
    
    public function toString() : String
    {
        return _name;
    }
}


