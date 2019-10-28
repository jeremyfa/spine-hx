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

import spine.Skin;

import spine.support.graphics.TextureAtlas;
import spine.support.graphics.TextureAtlas.AtlasRegion;

/** An {@link AttachmentLoader} that configures attachments using texture regions from an {@link Atlas}.
 * <p>
 * See <a href='http://esotericsoftware.com/spine-loading-skeleton-data#JSON-and-binary-data'>Loading skeleton data</a> in the
 * Spine Runtimes Guide. */
@SuppressWarnings("javadoc")
class AtlasAttachmentLoader implements AttachmentLoader {
    private var atlas:TextureAtlas;

    public function new(atlas:TextureAtlas) {
        if (atlas == null) throw new IllegalArgumentException("atlas cannot be null.");
        this.atlas = atlas;
    }

    #if !spine_no_inline inline #end public function newRegionAttachment(skin:Skin, name:String, path:String):RegionAttachment {
        var region:AtlasRegion = atlas.findRegion(path);
        if (region == null) throw new RuntimeException("Region not found in atlas: " + path + " (region attachment: " + name + ")");
        var attachment:RegionAttachment = new RegionAttachment(name);
        attachment.setRegion(region);
        return attachment;
    }

    #if !spine_no_inline inline #end public function newMeshAttachment(skin:Skin, name:String, path:String):MeshAttachment {
        var region:AtlasRegion = atlas.findRegion(path);
        if (region == null) throw new RuntimeException("Region not found in atlas: " + path + " (mesh attachment: " + name + ")");
        var attachment:MeshAttachment = new MeshAttachment(name);
        attachment.setRegion(region);
        return attachment;
    }

    #if !spine_no_inline inline #end public function newBoundingBoxAttachment(skin:Skin, name:String):BoundingBoxAttachment {
        return new BoundingBoxAttachment(name);
    }

    #if !spine_no_inline inline #end public function newClippingAttachment(skin:Skin, name:String):ClippingAttachment {
        return new ClippingAttachment(name);
    }

    #if !spine_no_inline inline #end public function newPathAttachment(skin:Skin, name:String):PathAttachment {
        return new PathAttachment(name);
    }

    #if !spine_no_inline inline #end public function newPointAttachment(skin:Skin, name:String):PointAttachment {
        return new PointAttachment(name);
    }
}
