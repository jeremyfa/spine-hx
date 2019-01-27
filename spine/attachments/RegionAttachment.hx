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

package spine.attachments;

import spine.support.graphics.Color;
import spine.support.graphics.TextureAtlas.AtlasRegion;
import spine.support.graphics.TextureRegion;
import spine.support.math.MathUtils;
import spine.Bone;

/** An attachment that displays a textured quadrilateral.
 * <p>
 * See <a href="http://esotericsoftware.com/spine-regions">Region attachments</a> in the Spine User Guide. */
class RegionAttachment extends Attachment {
    inline public static var BLX:Int = 0;
    inline public static var BLY:Int = 1;
    inline public static var ULX:Int = 2;
    inline public static var ULY:Int = 3;
    inline public static var URX:Int = 4;
    inline public static var URY:Int = 5;
    inline public static var BRX:Int = 6;
    inline public static var BRY:Int = 7;

    private var region:TextureRegion;
    private var path:String;
    private var x:Float = 0; private var y:Float = 0; private var scaleX:Float = 1; private var scaleY:Float = 1; private var rotation:Float = 0; private var width:Float = 0; private var height:Float = 0;
    private var uvs:FloatArray = FloatArray.create(8);
    private var offset:FloatArray = FloatArray.create(8);
    private var color:Color = new Color(1, 1, 1, 1);

    public function new(name:String) {
        super(name);
    }

    /** Calculates the {@link #offset} using the region settings. Must be called after changing region settings. */
    #if !spine_no_inline inline #end public function updateOffset():Void {
        var width:Float = getWidth();
        var height:Float = getHeight();
        var localX2:Float = width / 2;
        var localY2:Float = height / 2;
        var localX:Float = -localX2;
        var localY:Float = -localY2;
        if (Std.is(region, AtlasRegion)) {
            var region:AtlasRegion = cast(this.region, AtlasRegion);
            localX += region.offsetX / region.originalWidth * width;
            localY += region.offsetY / region.originalHeight * height;
            if (region.rotate) {
                localX2 -= (region.originalWidth - region.offsetX - region.packedHeight) / region.originalWidth * width;
                localY2 -= (region.originalHeight - region.offsetY - region.packedWidth) / region.originalHeight * height;
            } else {
                localX2 -= (region.originalWidth - region.offsetX - region.packedWidth) / region.originalWidth * width;
                localY2 -= (region.originalHeight - region.offsetY - region.packedHeight) / region.originalHeight * height;
            }
        }
        var scaleX:Float = getScaleX();
        var scaleY:Float = getScaleY();
        localX *= scaleX;
        localY *= scaleY;
        localX2 *= scaleX;
        localY2 *= scaleY;
        var rotation:Float = getRotation();
        var cos:Float = cast(Math.cos(MathUtils.degRad * rotation), Float);
        var sin:Float = cast(Math.sin(MathUtils.degRad * rotation), Float);
        var x:Float = getX();
        var y:Float = getY();
        var localXCos:Float = localX * cos + x;
        var localXSin:Float = localX * sin;
        var localYCos:Float = localY * cos + y;
        var localYSin:Float = localY * sin;
        var localX2Cos:Float = localX2 * cos + x;
        var localX2Sin:Float = localX2 * sin;
        var localY2Cos:Float = localY2 * cos + y;
        var localY2Sin:Float = localY2 * sin;
        var offset:FloatArray = this.offset;
        offset[BLX] = localXCos - localYSin;
        offset[BLY] = localYCos + localXSin;
        offset[ULX] = localXCos - localY2Sin;
        offset[ULY] = localY2Cos + localXSin;
        offset[URX] = localX2Cos - localY2Sin;
        offset[URY] = localY2Cos + localX2Sin;
        offset[BRX] = localX2Cos - localYSin;
        offset[BRY] = localYCos + localX2Sin;
    }

    #if !spine_no_inline inline #end public function setRegion(region:TextureRegion):Void {
        if (region == null) throw new IllegalArgumentException("region cannot be null.");
        this.region = region;
        var uvs:FloatArray = this.uvs;
        if (Std.is(region, AtlasRegion) && (cast(region, AtlasRegion)).rotate) {
            uvs[URX] = region.getU();
            uvs[URY] = region.getV2();
            uvs[BRX] = region.getU();
            uvs[BRY] = region.getV();
            uvs[BLX] = region.getU2();
            uvs[BLY] = region.getV();
            uvs[ULX] = region.getU2();
            uvs[ULY] = region.getV2();
        } else {
            uvs[ULX] = region.getU();
            uvs[ULY] = region.getV2();
            uvs[URX] = region.getU();
            uvs[URY] = region.getV();
            uvs[BRX] = region.getU2();
            uvs[BRY] = region.getV();
            uvs[BLX] = region.getU2();
            uvs[BLY] = region.getV2();
        }
    }

    #if !spine_no_inline inline #end public function getRegion():TextureRegion {
        if (region == null) throw new IllegalStateException("Region has not been set: " + this);
        return region;
    }

    /** Transforms the attachment's four vertices to world coordinates.
     * <p>
     * See <a href="http://esotericsoftware.com/spine-runtime-skeletons#World-transforms">World transforms</a> in the Spine
     * Runtimes Guide.
     * @param worldVertices The output world vertices. Must have a length >= <code>offset</code> + 8.
     * @param offset The <code>worldVertices</code> index to begin writing values.
     * @param stride The number of <code>worldVertices</code> entries between the value pairs written. */
    #if !spine_no_inline inline #end public function computeWorldVertices(bone:Bone, worldVertices:FloatArray, offset:Int, stride:Int):Void {
        var vertexOffset:FloatArray = this.offset;
        var x:Float = bone.getWorldX(); var y:Float = bone.getWorldY();
        var a:Float = bone.getA(); var b:Float = bone.getB(); var c:Float = bone.getC(); var d:Float = bone.getD();
        var offsetX:Float = 0; var offsetY:Float = 0;

        offsetX = vertexOffset[BRX];
        offsetY = vertexOffset[BRY];
        worldVertices[offset] = offsetX * a + offsetY * b + x; // br
        worldVertices[offset + 1] = offsetX * c + offsetY * d + y;
        offset += stride;

        offsetX = vertexOffset[BLX];
        offsetY = vertexOffset[BLY];
        worldVertices[offset] = offsetX * a + offsetY * b + x; // bl
        worldVertices[offset + 1] = offsetX * c + offsetY * d + y;
        offset += stride;

        offsetX = vertexOffset[ULX];
        offsetY = vertexOffset[ULY];
        worldVertices[offset] = offsetX * a + offsetY * b + x; // ul
        worldVertices[offset + 1] = offsetX * c + offsetY * d + y;
        offset += stride;

        offsetX = vertexOffset[URX];
        offsetY = vertexOffset[URY];
        worldVertices[offset] = offsetX * a + offsetY * b + x; // ur
        worldVertices[offset + 1] = offsetX * c + offsetY * d + y;
    }

    /** For each of the 4 vertices, a pair of <code>x,y</code> values that is the local position of the vertex.
     * <p>
     * See {@link #updateOffset()}. */
    #if !spine_no_inline inline #end public function getOffset():FloatArray {
        return offset;
    }

    #if !spine_no_inline inline #end public function getUVs():FloatArray {
        return uvs;
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

    /** The local rotation. */
    #if !spine_no_inline inline #end public function getRotation():Float {
        return rotation;
    }

    #if !spine_no_inline inline #end public function setRotation(rotation:Float):Void {
        this.rotation = rotation;
    }

    /** The width of the region attachment in Spine. */
    #if !spine_no_inline inline #end public function getWidth():Float {
        return width;
    }

    #if !spine_no_inline inline #end public function setWidth(width:Float):Void {
        this.width = width;
    }

    /** The height of the region attachment in Spine. */
    #if !spine_no_inline inline #end public function getHeight():Float {
        return height;
    }

    #if !spine_no_inline inline #end public function setHeight(height:Float):Void {
        this.height = height;
    }

    /** The color to tint the region attachment. */
    #if !spine_no_inline inline #end public function getColor():Color {
        return color;
    }

    /** The name of the texture region for this attachment. */
    #if !spine_no_inline inline #end public function getPath():String {
        return path;
    }

    #if !spine_no_inline inline #end public function setPath(path:String):Void {
        this.path = path;
    }
}
