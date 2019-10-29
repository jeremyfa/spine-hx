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

import spine.support.graphics.Color;
import spine.support.graphics.TextureAtlas.AtlasRegion;
import spine.support.graphics.TextureRegion;

/** An attachment that displays a textured mesh. A mesh has hull vertices and internal vertices within the hull. Holes are not
 * supported. Each vertex has UVs (texture coordinates) and triangles are used to map an image on to the mesh.
 * <p>
 * See <a href="http://esotericsoftware.com/spine-meshes">Mesh attachments</a> in the Spine User Guide. */
class MeshAttachment extends VertexAttachment {
    private var region:TextureRegion;
    private var path:String;
    private var regionUVs:FloatArray; private var uvs:FloatArray = null;
    private var triangles:ShortArray;
    private var color:Color = new Color(1, 1, 1, 1);
    private var hullLength:Int = 0;
    private var parentMesh:MeshAttachment;

    // Nonessential.
    private var edges:ShortArray;
    private var width:Float = 0; private var height:Float = 0;

    public function new(name:String) {
        super(name);
    }

    public function setRegion(region:TextureRegion):Void {
        if (region == null) throw new IllegalArgumentException("region cannot be null.");
        this.region = region;
    }

    public function getRegion():TextureRegion {
        if (region == null) throw new IllegalStateException("Region has not been set: " + this);
        return region;
    }

    /** Calculates {@link #uvs} using {@link #regionUVs} and the {@link #region}. Must be called after changing the region UVs or
     * region. */
    public function updateUVs():Void {
        var regionUVs:FloatArray = this.regionUVs;
        if (this.uvs == null || this.uvs.length != regionUVs.length) this.uvs = FloatArray.create(regionUVs.length);
        var uvs:FloatArray = this.uvs;
        var n:Int = uvs.length;
        var u:Float = 0; var v:Float = 0; var width:Float = 0; var height:Float = 0;
        if (Std.is(region, AtlasRegion)) {
            u = region.getU();
            v = region.getV();
            var region:AtlasRegion = fastCast(this.region, AtlasRegion);
            var textureWidth:Float = region.getTexture().getWidth(); var textureHeight:Float = region.getTexture().getHeight();
            var _continueAfterSwitch0 = false; while(true) { var _switchCond0 = (region.degrees); {
            if (_switchCond0 == 90) {
                u -= (region.originalHeight - region.offsetY - region.packedWidth) / textureWidth;
                v -= (region.originalWidth - region.offsetX - region.packedHeight) / textureHeight;
                width = region.originalHeight / textureWidth;
                height = region.originalWidth / textureHeight;
                var i:Int = 0; while (i < n) {
                    uvs[i] = u + regionUVs[i + 1] * width;
                    uvs[i + 1] = v + (1 - regionUVs[i]) * height;
                i += 2; }
                return;
            } else if (_switchCond0 == 180) {
                u -= (region.originalWidth - region.offsetX - region.packedWidth) / textureWidth;
                v -= region.offsetY / textureHeight;
                width = region.originalWidth / textureWidth;
                height = region.originalHeight / textureHeight;
                var i:Int = 0; while (i < n) {
                    uvs[i] = u + (1 - regionUVs[i]) * width;
                    uvs[i + 1] = v + (1 - regionUVs[i + 1]) * height;
                i += 2; }
                return;
            } else if (_switchCond0 == 270) {
                u -= region.offsetY / textureWidth;
                v -= region.offsetX / textureHeight;
                width = region.originalHeight / textureWidth;
                height = region.originalWidth / textureHeight;
                var i:Int = 0; while (i < n) {
                    uvs[i] = u + (1 - regionUVs[i + 1]) * width;
                    uvs[i + 1] = v + regionUVs[i] * height;
                i += 2; }
                return;
            } } break; }
            u -= region.offsetX / textureWidth;
            v -= (region.originalHeight - region.offsetY - region.packedHeight) / textureHeight;
            width = region.originalWidth / textureWidth;
            height = region.originalHeight / textureHeight;
        } else if (region == null) {
            u = v = 0;
            width = height = 1;
        } else {
            u = region.getU();
            v = region.getV();
            width = region.getU2() - u;
            height = region.getV2() - v;
        }
        var i:Int = 0; while (i < n) {
            uvs[i] = u + regionUVs[i] * width;
            uvs[i + 1] = v + regionUVs[i + 1] * height;
        i += 2; }
    }

    /** Triplets of vertex indices which describe the mesh's triangulation. */
    #if !spine_no_inline inline #end public function getTriangles():ShortArray {
        return triangles;
    }

    #if !spine_no_inline inline #end public function setTriangles(triangles:ShortArray):Void {
        this.triangles = triangles;
    }

    /** The UV pair for each vertex, normalized within the texture region. */
    #if !spine_no_inline inline #end public function getRegionUVs():FloatArray {
        return regionUVs;
    }

    /** Sets the texture coordinates for the region. The values are u,v pairs for each vertex. */
    #if !spine_no_inline inline #end public function setRegionUVs(regionUVs:FloatArray):Void {
        this.regionUVs = regionUVs;
    }

    /** The UV pair for each vertex, normalized within the entire texture.
     * <p>
     * See {@link #updateUVs}. */
    #if !spine_no_inline inline #end public function getUVs():FloatArray {
        return uvs;
    }

    #if !spine_no_inline inline #end public function setUVs(uvs:FloatArray):Void {
        this.uvs = uvs;
    }

    /** The color to tint the mesh. */
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

    /** The number of entries at the beginning of {@link #vertices} that make up the mesh hull. */
    #if !spine_no_inline inline #end public function getHullLength():Int {
        return hullLength;
    }

    #if !spine_no_inline inline #end public function setHullLength(hullLength:Int):Void {
        this.hullLength = hullLength;
    }

    #if !spine_no_inline inline #end public function setEdges(edges:ShortArray):Void {
        this.edges = edges;
    }

    /** Vertex index pairs describing edges for controling triangulation. Mesh triangles will never cross edges. Only available if
     * nonessential data was exported. Triangulation is not performed at runtime. */
    #if !spine_no_inline inline #end public function getEdges():ShortArray {
        return edges;
    }

    /** The width of the mesh's image. Available only when nonessential data was exported. */
    #if !spine_no_inline inline #end public function getWidth():Float {
        return width;
    }

    #if !spine_no_inline inline #end public function setWidth(width:Float):Void {
        this.width = width;
    }

    /** The height of the mesh's image. Available only when nonessential data was exported. */
    #if !spine_no_inline inline #end public function getHeight():Float {
        return height;
    }

    #if !spine_no_inline inline #end public function setHeight(height:Float):Void {
        this.height = height;
    }

    /** The parent mesh if this is a linked mesh, else null. A linked mesh shares the {@link #bones}, {@link #vertices},
     * {@link #regionUVs}, {@link #triangles}, {@link #hullLength}, {@link #edges}, {@link #width}, and {@link #height} with the
     * parent mesh, but may have a different {@link #name} or {@link #path} (and therefore a different texture). */
    #if !spine_no_inline inline #end public function getParentMesh():MeshAttachment {
        return parentMesh;
    }

    /** @param parentMesh May be null. */
    #if !spine_no_inline inline #end public function setParentMesh(parentMesh:MeshAttachment):Void {
        this.parentMesh = parentMesh;
        if (parentMesh != null) {
            bones = parentMesh.bones;
            vertices = parentMesh.vertices;
            regionUVs = parentMesh.regionUVs;
            triangles = parentMesh.triangles;
            hullLength = parentMesh.hullLength;
            worldVerticesLength = parentMesh.worldVerticesLength;
            edges = parentMesh.edges;
            width = parentMesh.width;
            height = parentMesh.height;
        }
    }

    override #if !spine_no_inline inline #end public function copy():Attachment {
        if (parentMesh != null) return newLinkedMesh();

        var copy:MeshAttachment = new MeshAttachment(name);
        copy.region = region;
        copy.path = path;
        copy.color.setColor(color);

        copyTo(copy);
        copy.regionUVs = FloatArray.create(regionUVs.length);
        arraycopy(regionUVs, 0, copy.regionUVs, 0, regionUVs.length);
        copy.uvs = FloatArray.create(uvs.length);
        arraycopy(uvs, 0, copy.uvs, 0, uvs.length);
        copy.triangles = ShortArray.create(triangles.length);
        arraycopy(triangles, 0, copy.triangles, 0, triangles.length);
        copy.hullLength = hullLength;

        // Nonessential.
        if (edges != null) {
            copy.edges = ShortArray.create(edges.length);
            arraycopy(edges, 0, copy.edges, 0, edges.length);
        }
        copy.width = width;
        copy.height = height;
        return copy;
    }

    /** Returns a new mesh with the {@link #parentMesh} set to this mesh's parent mesh, if any, else to this mesh. **/
    #if !spine_no_inline inline #end public function newLinkedMesh():MeshAttachment {
        var mesh:MeshAttachment = new MeshAttachment(name);
        mesh.region = region;
        mesh.path = path;
        mesh.color.setColor(color);
        mesh.deformAttachment = deformAttachment;
        mesh.setParentMesh(parentMesh != null ? parentMesh : this);
        mesh.updateUVs();
        return mesh;
    }
}
