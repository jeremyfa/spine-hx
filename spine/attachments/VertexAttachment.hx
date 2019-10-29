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

import spine.utils.SpineUtils.*;

import spine.support.utils.FloatArray;

import spine.Bone;
import spine.Skeleton;
import spine.Slot;

/** Base class for an attachment with vertices that are transformed by one or more bones and can be deformed by a slot's
 * {@link Slot#getDeform()}. */
class VertexAttachment extends Attachment {
    private static var nextID:Int = 0;

    private var id:Int = (getNextID() & 65535) << 11;
    public var bones:IntArray;
    public var vertices:FloatArray;
    public var worldVerticesLength:Int = 0;
    @:isVar public var deformAttachment(get,set):VertexAttachment = null;
    inline function get_deformAttachment():VertexAttachment { return (deformAttachment != null ? deformAttachment : this); }
    inline function set_deformAttachment(deformAttachment:VertexAttachment):VertexAttachment { return this.deformAttachment = deformAttachment; }

    public function new(name:String) {
        super(name);
    }

    /** Transforms the attachment's local {@link #getVertices()} to world coordinates. If the slot's {@link Slot#getDeform()} is
     * not empty, it is used to deform the vertices.
     * <p>
     * See <a href="http://esotericsoftware.com/spine-runtime-skeletons#World-transforms">World transforms</a> in the Spine
     * Runtimes Guide.
     * @param start The index of the first {@link #getVertices()} value to transform. Each vertex has 2 values, x and y.
     * @param count The number of world vertex values to output. Must be <= {@link #getWorldVerticesLength()} - <code>start</code>.
     * @param worldVertices The output world vertices. Must have a length >= <code>offset</code> + <code>count</code> *
     *           <code>stride</code> / 2.
     * @param offset The <code>worldVertices</code> index to begin writing values.
     * @param stride The number of <code>worldVertices</code> entries between the value pairs written. */
    #if !spine_no_inline inline #end public function computeWorldVertices(slot:Slot, start:Int, count:Int, worldVertices:FloatArray, offset:Int, stride:Int):Void {
        count = offset + (count >> 1) * stride;
        var skeleton:Skeleton = slot.getSkeleton();
        var deformArray:FloatArray = slot.getDeform();
        var vertices:FloatArray = this.vertices;
        var bones:IntArray = this.bones;
        if (bones == null) {
            if (deformArray.size > 0) vertices = deformArray.items;
            var bone:Bone = slot.getBone();
            var x:Float = bone.getWorldX(); var y:Float = bone.getWorldY();
            var a:Float = bone.getA(); var b:Float = bone.getB(); var c:Float = bone.getC(); var d:Float = bone.getD();
            var v:Int = start; var w:Int = offset; while (w < count) {
                var vx:Float = vertices[v]; var vy:Float = vertices[v + 1];
                worldVertices[w] = vx * a + vy * b + x;
                worldVertices[w + 1] = vx * c + vy * d + y;
            v += 2; w += stride; }
            return;
        }
        var v:Int = 0; var skip:Int = 0;
        var i:Int = 0; while (i < start) {
            var n:Int = bones[v];
            v += n + 1;
            skip += n;
        i += 2; }
        var skeletonBones = skeleton.getBones().items;
        if (deformArray.size == 0) {
            var w:Int = offset; var b:Int = skip * 3; while (w < count) {
                var wx:Float = 0; var wy:Float = 0;
                var n:Int = bones[v++];
                n += v;
                while (v < n) {
                    var bone:Bone = fastCast(skeletonBones[bones[v]], Bone);
                    var vx:Float = vertices[b]; var vy:Float = vertices[b + 1]; var weight:Float = vertices[b + 2];
                    wx += (vx * bone.getA() + vy * bone.getB() + bone.getWorldX()) * weight;
                    wy += (vx * bone.getC() + vy * bone.getD() + bone.getWorldY()) * weight;
                v++; b += 3; }
                worldVertices[w] = wx;
                worldVertices[w + 1] = wy;
            w += stride; }
        } else {
            var deform:FloatArray = deformArray.items;
            var w:Int = offset; var b:Int = skip * 3; var f:Int = skip << 1; while (w < count) {
                var wx:Float = 0; var wy:Float = 0;
                var n:Int = bones[v++];
                n += v;
                while (v < n) {
                    var bone:Bone = fastCast(skeletonBones[bones[v]], Bone);
                    var vx:Float = vertices[b] + deform[f]; var vy:Float = vertices[b + 1] + deform[f + 1]; var weight:Float = vertices[b + 2];
                    wx += (vx * bone.getA() + vy * bone.getB() + bone.getWorldX()) * weight;
                    wy += (vx * bone.getC() + vy * bone.getD() + bone.getWorldY()) * weight;
                v++; b += 3; f += 2; }
                worldVertices[w] = wx;
                worldVertices[w + 1] = wy;
            w += stride; }
        }
    }

    /** Deform keys for the deform attachment are also applied to this attachment.
     * @return May be null if no deform keys should be applied. */
    #if !spine_no_inline inline #end public function getDeformAttachment():VertexAttachment {
        return deformAttachment;
    }

    /** @param deformAttachment May be null if no deform keys should be applied. */
    #if !spine_no_inline inline #end public function setDeformAttachment(deformAttachment:VertexAttachment):Void {
        this.deformAttachment = deformAttachment;
    }

    /** The bones which affect the {@link #getVertices()}. The array entries are, for each vertex, the number of bones affecting
     * the vertex followed by that many bone indices, which is the index of the bone in {@link Skeleton#getBones()}. Will be null
     * if this attachment has no weights. */
    #if !spine_no_inline inline #end public function getBones():IntArray {
        return bones;
    }

    /** @param bones May be null if this attachment has no weights. */
    #if !spine_no_inline inline #end public function setBones(bones:IntArray):Void {
        this.bones = bones;
    }

    /** The vertex positions in the bone's coordinate system. For a non-weighted attachment, the values are <code>x,y</code>
     * entries for each vertex. For a weighted attachment, the values are <code>x,y,weight</code> entries for each bone affecting
     * each vertex. */
    #if !spine_no_inline inline #end public function getVertices():FloatArray {
        return vertices;
    }

    #if !spine_no_inline inline #end public function setVertices(vertices:FloatArray):Void {
        this.vertices = vertices;
    }

    /** The maximum number of world vertex values that can be output by
     * {@link #computeWorldVertices(Slot, int, int, float[], int, int)} using the <code>count</code> parameter. */
    #if !spine_no_inline inline #end public function getWorldVerticesLength():Int {
        return worldVerticesLength;
    }

    #if !spine_no_inline inline #end public function setWorldVerticesLength(worldVerticesLength:Int):Void {
        this.worldVerticesLength = worldVerticesLength;
    }

    /** Returns a unique ID for this attachment. */
    #if !spine_no_inline inline #end public function getId():Int {
        return id;
    }

    /** Does not copy id (generated) or name (set on construction). **/
    #if !spine_no_inline inline #end public function copyTo(attachment:VertexAttachment):Void {
        if (bones != null) {
            attachment.bones = IntArray.create(bones.length);
            arraycopy(bones, 0, attachment.bones, 0, bones.length);
        } else
            attachment.bones = null;

        if (vertices != null) {
            attachment.vertices = FloatArray.create(vertices.length);
            arraycopy(vertices, 0, attachment.vertices, 0, vertices.length);
        } else
            attachment.vertices = null;

        attachment.worldVerticesLength = worldVerticesLength;
        attachment.deformAttachment = deformAttachment;
    }

    #if !spine_no_inline inline #end private static function getNextID():Int {
        return nextID++;
    }
}
