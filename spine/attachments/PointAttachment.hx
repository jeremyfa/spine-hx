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

package spine.attachments;

import spine.support.math.MathUtils.*;

import spine.support.graphics.Color;
import spine.support.math.Vector2;
import spine.Bone;

/** An attachment which is a single point and a rotation. This can be used to spawn projectiles, particles, etc. A bone can be
 * used in similar ways, but a PointAttachment is slightly less expensive to compute and can be hidden, shown, and placed in a
 * skin.
 * <p>
 * See <a href="http://esotericsoftware.com/spine-point-attachments">Point Attachments</a> in the Spine User Guide. */
class PointAttachment extends Attachment {
    public var x:Float = 0; public var y:Float = 0; public var rotation:Float = 0;

    // Nonessential.
    public var color:Color = new Color(0.9451, 0.9451, 0, 1); // f1f100ff

    public function new(name:String) {
        super(name);
    }

    #if !spine_no_inline inline #end public function getX():Float {
        return x;
    }

    #if !spine_no_inline inline #end public function setX(x:Float):Void {
        this.x = x;
    }

    #if !spine_no_inline inline #end public function getY():Float {
        return y;
    }

    #if !spine_no_inline inline #end public function setY(y:Float):Void {
        this.y = y;
    }

    #if !spine_no_inline inline #end public function getRotation():Float {
        return rotation;
    }

    #if !spine_no_inline inline #end public function setRotation(rotation:Float):Void {
        this.rotation = rotation;
    }

    /** The color of the point attachment as it was in Spine. Available only when nonessential data was exported. Point attachments
     * are not usually rendered at runtime. */
    #if !spine_no_inline inline #end public function getColor():Color {
        return color;
    }

    #if !spine_no_inline inline #end public function computeWorldPosition(bone:Bone, point:Vector2):Vector2 {
        point.x = x * bone.getA() + y * bone.getB() + bone.getWorldX();
        point.y = x * bone.getC() + y * bone.getD() + bone.getWorldY();
        return point;
    }

    #if !spine_no_inline inline #end public function computeWorldRotation(bone:Bone):Float {
        var cos:Float = cosDeg(rotation); var sin:Float = sinDeg(rotation);
        var x:Float = cos * bone.getA() + sin * bone.getB();
        var y:Float = cos * bone.getC() + sin * bone.getD();
        return cast(Math.atan2(y, x) * radDeg, Float);
    }
}
