
package spine;



import spine.support.files.FileHandle;
import spine.support.graphics.TextureAtlas;
import spine.support.utils.Array;

import spine.SkeletonJson.LinkedMesh;
import spine.attachments.AtlasAttachmentLoader;
import spine.attachments.AttachmentLoader;

/** Base class for loading skeleton data from a file.
 * <p>
 * See <a href="http://esotericsoftware.com/spine-loading-skeleton-data#JSON-and-binary-data">JSON and binary data</a> in the
 * Spine Runtimes Guide. */
class SkeletonLoader {
    public var attachmentLoader:AttachmentLoader;
    public var scale:Float = 1;
    public var linkedMeshes:Array<LinkedMesh> = new Array();

    /** Creates a skeleton loader that loads attachments using an {@link AtlasAttachmentLoader} with the specified atlas. */
    /*public function new(atlas:TextureAtlas) {
        attachmentLoader = new AtlasAttachmentLoader(atlas);
    }*/

    /** Creates a skeleton loader that loads attachments using the specified attachment loader.
     * <p>
     * See <a href='http://esotericsoftware.com/spine-loading-skeleton-data#JSON-and-binary-data'>Loading skeleton data</a> in the
     * Spine Runtimes Guide. */
    public function new(attachmentLoader:AttachmentLoader) {
        if (attachmentLoader == null) throw new IllegalArgumentException("attachmentLoader cannot be null.");
        this.attachmentLoader = attachmentLoader;
    }

    /** Scales bone positions, image sizes, and translations as they are loaded. This allows different size images to be used at
     * runtime than were used in Spine.
     * <p>
     * See <a href="http://esotericsoftware.com/spine-loading-skeleton-data#Scaling">Scaling</a> in the Spine Runtimes Guide. */
    #if !spine_no_inline inline #end public function getScale():Float {
        return scale;
    }

    #if !spine_no_inline inline #end public function setScale(scale:Float):Void {
        if (scale == 0) throw new IllegalArgumentException("scale cannot be 0.");
        this.scale = scale;
    }

    

    
}
