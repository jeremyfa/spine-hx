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

package spine;

import spine.support.utils.Array;
import spine.support.utils.FloatArray;
import spine.support.utils.Pool;
import spine.attachments.Attachment;
import spine.attachments.BoundingBoxAttachment;

/** Collects each visible {@link BoundingBoxAttachment} and computes the world vertices for its polygon. The polygon vertices are
 * provided along with convenience methods for doing hit detection. */
class SkeletonBounds {
    private var minX:Float = 0; private var minY:Float = 0; private var maxX:Float = 0; private var maxY:Float = 0;
    private var boundingBoxes:Array<BoundingBoxAttachment> = new Array();
    private var polygons:FloatArray2D = new Array();
    private var polygonPool:Pool<FloatArray> = new PolygonPool();

    /** Clears any previous polygons, finds all visible bounding box attachments, and computes the world vertices for each bounding
     * box's polygon.
     * @param updateAabb If true, the axis aligned bounding box containing all the polygons is computed. If false, the
     *           SkeletonBounds AABB methods will always return true. */
    #if !spine_no_inline inline #end public function update(skeleton:Skeleton, updateAabb:Bool):Void {
        if (skeleton == null) throw new IllegalArgumentException("skeleton cannot be null.");
        var boundingBoxes:Array<BoundingBoxAttachment> = this.boundingBoxes;
        var polygons:FloatArray2D = this.polygons;
        var slots:Array<Slot> = skeleton.slots;
        var slotCount:Int = slots.size;

        boundingBoxes.clear();
        polygonPool.freeAll(polygons);
        polygons.clear();

        var i:Int = 0; while (i < slotCount) {
            var slot:Slot = slots.get(i);
            if (!slot.bone.active) { i++; continue; }
            var attachment:Attachment = slot.attachment;
            if (Std.is(attachment, BoundingBoxAttachment)) {
                var boundingBox:BoundingBoxAttachment = fastCast(attachment, BoundingBoxAttachment);
                boundingBoxes.add(boundingBox);

                var polygon:FloatArray = polygonPool.obtain();
                polygons.add(polygon);
                boundingBox.computeWorldVertices(slot, 0, boundingBox.getWorldVerticesLength(),
                    polygon.setSize(boundingBox.getWorldVerticesLength()), 0, 2);
            }
        i++; }

        if (updateAabb)
            aabbCompute();
        else {
            minX = -999999999;
            minY = -999999999;
            maxX = 999999999;
            maxY = 999999999;
        }
    }

    #if !spine_no_inline inline #end private function aabbCompute():Void {
        var minX:Float = 999999999; var minY:Float = 999999999; var maxX:Float = -999999999; var maxY:Float = -999999999;
        var polygons:FloatArray2D = this.polygons;
        var i:Int = 0; var n:Int = polygons.size; while (i < n) {
            var polygon:FloatArray = polygons.get(i);
            var vertices:FloatArray = polygon.items;
            var ii:Int = 0; var nn:Int = polygon.size; while (ii < nn) {
                var x:Float = vertices[ii];
                var y:Float = vertices[ii + 1];
                minX = MathUtils.min(minX, x);
                minY = MathUtils.min(minY, y);
                maxX = MathUtils.max(maxX, x);
                maxY = MathUtils.max(maxY, y);
            ii += 2; }
        i++; }
        this.minX = minX;
        this.minY = minY;
        this.maxX = maxX;
        this.maxY = maxY;
    }

    /** Returns true if the axis aligned bounding box contains the point. */
    #if !spine_no_inline inline #end public function aabbContainsPoint(x:Float, y:Float):Bool {
        return x >= minX && x <= maxX && y >= minY && y <= maxY;
    }

    /** Returns true if the axis aligned bounding box intersects the line segment. */
    #if !spine_no_inline inline #end public function aabbIntersectsSegment(x1:Float, y1:Float, x2:Float, y2:Float):Bool {
        var minX:Float = this.minX;
        var minY:Float = this.minY;
        var maxX:Float = this.maxX;
        var maxY:Float = this.maxY;
        if ((x1 <= minX && x2 <= minX) || (y1 <= minY && y2 <= minY) || (x1 >= maxX && x2 >= maxX) || (y1 >= maxY && y2 >= maxY))
            return false;
        var m:Float = (y2 - y1) / (x2 - x1);
        var y:Float = m * (minX - x1) + y1;
        if (y > minY && y < maxY) return true;
        y = m * (maxX - x1) + y1;
        if (y > minY && y < maxY) return true;
        var x:Float = (minY - y1) / m + x1;
        if (x > minX && x < maxX) return true;
        x = (maxY - y1) / m + x1;
        if (x > minX && x < maxX) return true;
        return false;
    }

    /** Returns true if the axis aligned bounding box intersects the axis aligned bounding box of the specified bounds. */
    #if !spine_no_inline inline #end public function aabbIntersectsSkeleton(bounds:SkeletonBounds):Bool {
        if (bounds == null) throw new IllegalArgumentException("bounds cannot be null.");
        return minX < bounds.maxX && maxX > bounds.minX && minY < bounds.maxY && maxY > bounds.minY;
    }

    /** Returns the first bounding box attachment that contains the point, or null. When doing many checks, it is usually more
     * efficient to only call this method if {@link #aabbContainsPoint(float, float)} returns true. */
    #if !spine_no_inline inline #end public function containsPoint(x:Float, y:Float):BoundingBoxAttachment {
        var polygons:FloatArray2D = this.polygons;
        var i:Int = 0; var n:Int = polygons.size; while (i < n) {
            if (polygonContainsPoint(polygons.get(i), x, y)) return boundingBoxes.get(i); i++; }
        return null;
    }

    /** Returns true if the polygon contains the point. */
    #if !spine_no_inline inline #end public function polygonContainsPoint(polygon:FloatArray, x:Float, y:Float):Bool {
        if (polygon == null) throw new IllegalArgumentException("polygon cannot be null.");
        var vertices:FloatArray = polygon.items;
        var nn:Int = polygon.size;

        var prevIndex:Int = nn - 2;
        var inside:Bool = false;
        var ii:Int = 0; while (ii < nn) {
            var vertexY:Float = vertices[ii + 1];
            var prevY:Float = vertices[prevIndex + 1];
            if ((vertexY < y && prevY >= y) || (prevY < y && vertexY >= y)) {
                var vertexX:Float = vertices[ii];
                if (vertexX + (y - vertexY) / (prevY - vertexY) * (vertices[prevIndex] - vertexX) < x) inside = !inside;
            }
            prevIndex = ii;
        ii += 2; }
        return inside;
    }

    /** Returns the first bounding box attachment that contains any part of the line segment, or null. When doing many checks, it
     * is usually more efficient to only call this method if {@link #aabbIntersectsSegment(float, float, float, float)} returns
     * true. */
    #if !spine_no_inline inline #end public function intersectsSegment(x1:Float, y1:Float, x2:Float, y2:Float):BoundingBoxAttachment {
        var polygons:FloatArray2D = this.polygons;
        var i:Int = 0; var n:Int = polygons.size; while (i < n) {
            if (polygonIntersectsSegment(polygons.get(i), x1, y1, x2, y2)) return boundingBoxes.get(i); i++; }
        return null;
    }

    /** Returns true if the polygon contains any part of the line segment. */
    public function polygonIntersectsSegment(polygon:FloatArray, x1:Float, y1:Float, x2:Float, y2:Float):Bool {
        if (polygon == null) throw new IllegalArgumentException("polygon cannot be null.");
        var vertices:FloatArray = polygon.items;
        var nn:Int = polygon.size;

        var width12:Float = x1 - x2; var height12:Float = y1 - y2;
        var det1:Float = x1 * y2 - y1 * x2;
        var x3:Float = vertices[nn - 2]; var y3:Float = vertices[nn - 1];
        var ii:Int = 0; while (ii < nn) {
            var x4:Float = vertices[ii]; var y4:Float = vertices[ii + 1];
            var det2:Float = x3 * y4 - y3 * x4;
            var width34:Float = x3 - x4; var height34:Float = y3 - y4;
            var det3:Float = width12 * height34 - height12 * width34;
            var x:Float = (det1 * width34 - width12 * det2) / det3;
            if (((x >= x3 && x <= x4) || (x >= x4 && x <= x3)) && ((x >= x1 && x <= x2) || (x >= x2 && x <= x1))) {
                var y:Float = (det1 * height34 - height12 * det2) / det3;
                if (((y >= y3 && y <= y4) || (y >= y4 && y <= y3)) && ((y >= y1 && y <= y2) || (y >= y2 && y <= y1))) return true;
            }
            x3 = x4;
            y3 = y4;
        ii += 2; }
        return false;
    }

    /** The left edge of the axis aligned bounding box. */
    #if !spine_no_inline inline #end public function getMinX():Float {
        return minX;
    }

    /** The bottom edge of the axis aligned bounding box. */
    #if !spine_no_inline inline #end public function getMinY():Float {
        return minY;
    }

    /** The right edge of the axis aligned bounding box. */
    #if !spine_no_inline inline #end public function getMaxX():Float {
        return maxX;
    }

    /** The top edge of the axis aligned bounding box. */
    #if !spine_no_inline inline #end public function getMaxY():Float {
        return maxY;
    }

    /** The width of the axis aligned bounding box. */
    #if !spine_no_inline inline #end public function getWidth():Float {
        return maxX - minX;
    }

    /** The height of the axis aligned bounding box. */
    #if !spine_no_inline inline #end public function getHeight():Float {
        return maxY - minY;
    }

    /** The visible bounding boxes. */
    #if !spine_no_inline inline #end public function getBoundingBoxes():Array<BoundingBoxAttachment> {
        return boundingBoxes;
    }

    /** The world vertices for the bounding box polygons. */
    #if !spine_no_inline inline #end public function getPolygons():FloatArray2D {
        return polygons;
    }

    /** Returns the polygon for the specified bounding box, or null. */
    #if !spine_no_inline inline #end public function getPolygon(boundingBox:BoundingBoxAttachment):FloatArray {
        if (boundingBox == null) throw new IllegalArgumentException("boundingBox cannot be null.");
        var index:Int = boundingBoxes.indexOf(boundingBox, true);
        return index == -1 ? null : polygons.get(index);
    }

    public function new() {}
}


private class PolygonPool extends Pool<FloatArray> {
    override function newObject() {
        return new FloatArray();
    }
}

