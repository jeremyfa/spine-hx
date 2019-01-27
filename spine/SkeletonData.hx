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

/** Stores the setup pose and all of the stateless data for a skeleton.
 * <p>
 * See <a href="http://esotericsoftware.com/spine-runtime-architecture#Data-objects">Data objects</a> in the Spine Runtimes
 * Guide. */
class SkeletonData {
    public var name:String;
    public var bones:Array<BoneData> = new Array(); // Ordered parents first.
    public var slots:Array<SlotData> = new Array(); // Setup pose draw order.
    public var skins:Array<Skin> = new Array();
    public var defaultSkin:Skin;
    public var events:Array<EventData> = new Array();
    public var animations:Array<Animation> = new Array();
    public var ikConstraints:Array<IkConstraintData> = new Array();
    public var transformConstraints:Array<TransformConstraintData> = new Array();
    public var pathConstraints:Array<PathConstraintData> = new Array();
    public var width:Float = 0; public var height:Float = 0;
    public var version:String; public var hash:String = null;

    // Nonessential.
    public var fps:Float = 30;
    public var imagesPath:String; public var audioPath:String = null;

    // --- Bones.

    /** The skeleton's bones, sorted parent first. The root bone is always the first bone. */
    public function getBones():Array<BoneData> {
        return bones;
    }

    /** Finds a bone by comparing each bone's name. It is more efficient to cache the results of this method than to call it
     * multiple times.
     * @return May be null. */
    public function findBone(boneName:String):BoneData {
        if (boneName == null) throw new IllegalArgumentException("boneName cannot be null.");
        var bones:Array<BoneData> = this.bones;
        var i:Int = 0; var n:Int = bones.size; while (i < n) {
            var bone:BoneData = bones.get(i);
            if (bone.name.equals(boneName)) return bone;
        i++; }
        return null;
    }

    // --- Slots.

    /** The skeleton's slots. */
    public function getSlots():Array<SlotData> {
        return slots;
    }

    /** Finds a slot by comparing each slot's name. It is more efficient to cache the results of this method than to call it
     * multiple times.
     * @return May be null. */
    public function findSlot(slotName:String):SlotData {
        if (slotName == null) throw new IllegalArgumentException("slotName cannot be null.");
        var slots:Array<SlotData> = this.slots;
        var i:Int = 0; var n:Int = slots.size; while (i < n) {
            var slot:SlotData = slots.get(i);
            if (slot.name.equals(slotName)) return slot;
        i++; }
        return null;
    }

    // --- Skins.

    /** The skeleton's default skin. By default this skin contains all attachments that were not in a skin in Spine.
     * <p>
     * See {@link Skeleton#getAttachment(int, String)}.
     * @return May be null. */
    public function getDefaultSkin():Skin {
        return defaultSkin;
    }

    /** @param defaultSkin May be null. */
    public function setDefaultSkin(defaultSkin:Skin):Void {
        this.defaultSkin = defaultSkin;
    }

    /** Finds a skin by comparing each skin's name. It is more efficient to cache the results of this method than to call it
     * multiple times.
     * @return May be null. */
    public function findSkin(skinName:String):Skin {
        if (skinName == null) throw new IllegalArgumentException("skinName cannot be null.");
        for (skin in skins) {
            if (skin.name.equals(skinName)) return skin; }
        return null;
    }

    /** All skins, including the default skin. */
    public function getSkins():Array<Skin> {
        return skins;
    }

    // --- Events.

    /** Finds an event by comparing each events's name. It is more efficient to cache the results of this method than to call it
     * multiple times.
     * @return May be null. */
    public function findEvent(eventDataName:String):EventData {
        if (eventDataName == null) throw new IllegalArgumentException("eventDataName cannot be null.");
        for (eventData in events) {
            if (eventData.name.equals(eventDataName)) return eventData; }
        return null;
    }

    /** The skeleton's events. */
    public function getEvents():Array<EventData> {
        return events;
    }

    // --- Animations.

    /** The skeleton's animations. */
    public function getAnimations():Array<Animation> {
        return animations;
    }

    /** Finds an animation by comparing each animation's name. It is more efficient to cache the results of this method than to
     * call it multiple times.
     * @return May be null. */
    public function findAnimation(animationName:String):Animation {
        if (animationName == null) throw new IllegalArgumentException("animationName cannot be null.");
        var animations:Array<Animation> = this.animations;
        var i:Int = 0; var n:Int = animations.size; while (i < n) {
            var animation:Animation = animations.get(i);
            if (animation.name.equals(animationName)) return animation;
        i++; }
        return null;
    }

    // --- IK constraints

    /** The skeleton's IK constraints. */
    #if !spine_no_inline inline #end public function getIkConstraints():Array<IkConstraintData> {
        return ikConstraints;
    }

    /** Finds an IK constraint by comparing each IK constraint's name. It is more efficient to cache the results of this method
     * than to call it multiple times.
     * @return May be null. */
    public function findIkConstraint(constraintName:String):IkConstraintData {
        if (constraintName == null) throw new IllegalArgumentException("constraintName cannot be null.");
        var ikConstraints:Array<IkConstraintData> = this.ikConstraints;
        var i:Int = 0; var n:Int = ikConstraints.size; while (i < n) {
            var constraint:IkConstraintData = ikConstraints.get(i);
            if (constraint.name.equals(constraintName)) return constraint;
        i++; }
        return null;
    }

    // --- Transform constraints

    /** The skeleton's transform constraints. */
    #if !spine_no_inline inline #end public function getTransformConstraints():Array<TransformConstraintData> {
        return transformConstraints;
    }

    /** Finds a transform constraint by comparing each transform constraint's name. It is more efficient to cache the results of
     * this method than to call it multiple times.
     * @return May be null. */
    public function findTransformConstraint(constraintName:String):TransformConstraintData {
        if (constraintName == null) throw new IllegalArgumentException("constraintName cannot be null.");
        var transformConstraints:Array<TransformConstraintData> = this.transformConstraints;
        var i:Int = 0; var n:Int = transformConstraints.size; while (i < n) {
            var constraint:TransformConstraintData = transformConstraints.get(i);
            if (constraint.name.equals(constraintName)) return constraint;
        i++; }
        return null;
    }

    // --- Path constraints

    /** The skeleton's path constraints. */
    #if !spine_no_inline inline #end public function getPathConstraints():Array<PathConstraintData> {
        return pathConstraints;
    }

    /** Finds a path constraint by comparing each path constraint's name. It is more efficient to cache the results of this method
     * than to call it multiple times.
     * @return May be null. */
    public function findPathConstraint(constraintName:String):PathConstraintData {
        if (constraintName == null) throw new IllegalArgumentException("constraintName cannot be null.");
        var pathConstraints:Array<PathConstraintData> = this.pathConstraints;
        var i:Int = 0; var n:Int = pathConstraints.size; while (i < n) {
            var constraint:PathConstraintData = pathConstraints.get(i);
            if (constraint.name.equals(constraintName)) return constraint;
        i++; }
        return null;
    }

    // ---

    /** The skeleton's name, which by default is the name of the skeleton data file, if possible.
     * @return May be null. */
    #if !spine_no_inline inline #end public function getName():String {
        return name;
    }

    /** @param name May be null. */
    #if !spine_no_inline inline #end public function setName(name:String):Void {
        this.name = name;
    }

    /** The width of the skeleton's axis aligned bounding box in the setup pose. */
    #if !spine_no_inline inline #end public function getWidth():Float {
        return width;
    }

    #if !spine_no_inline inline #end public function setWidth(width:Float):Void {
        this.width = width;
    }

    /** The height of the skeleton's axis aligned bounding box in the setup pose. */
    #if !spine_no_inline inline #end public function getHeight():Float {
        return height;
    }

    #if !spine_no_inline inline #end public function setHeight(height:Float):Void {
        this.height = height;
    }

    /** The Spine version used to export the skeleton data, or null. */
    #if !spine_no_inline inline #end public function getVersion():String {
        return version;
    }

    /** @param version May be null. */
    #if !spine_no_inline inline #end public function setVersion(version:String):Void {
        this.version = version;
    }

    /** The skeleton data hash. This value will change if any of the skeleton data has changed.
     * @return May be null. */
    #if !spine_no_inline inline #end public function getHash():String {
        return hash;
    }

    /** @param hash May be null. */
    #if !spine_no_inline inline #end public function setHash(hash:String):Void {
        this.hash = hash;
    }

    /** The path to the images directory as defined in Spine. Available only when nonessential data was exported.
     * @return May be null. */
    #if !spine_no_inline inline #end public function getImagesPath():String {
        return imagesPath;
    }

    /** @param imagesPath May be null. */
    #if !spine_no_inline inline #end public function setImagesPath(imagesPath:String):Void {
        this.imagesPath = imagesPath;
    }

    /** The path to the audio directory as defined in Spine. Available only when nonessential data was exported.
     * @return May be null. */
    #if !spine_no_inline inline #end public function getAudioPath():String {
        return audioPath;
    }

    /** @param audioPath May be null. */
    #if !spine_no_inline inline #end public function setAudioPath(audioPath:String):Void {
        this.audioPath = audioPath;
    }

    /** The dopesheet FPS in Spine. Available only when nonessential data was exported. */
    #if !spine_no_inline inline #end public function getFps():Float {
        return fps;
    }

    #if !spine_no_inline inline #end public function setFps(fps:Float):Void {
        this.fps = fps;
    }

    #if !spine_no_inline inline #end public function toString():String {
        return name != null ? name : Type.getClassName(Type.getClass(this));
    }

    public function new() {}
}
