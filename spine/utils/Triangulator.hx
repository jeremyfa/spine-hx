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

package spine.utils;

import spine.support.utils.Array;
import spine.support.utils.BooleanArray;
import spine.support.utils.FloatArray;
import spine.support.utils.Pool;
import spine.support.utils.ShortArray;

class Triangulator {
    private var convexPolygons:FloatArray2D = new Array();
    private var convexPolygonsIndices:ShortArray2D = new Array();

    private var indicesArray:ShortArray = new ShortArray();
    private var isConcaveArray:BooleanArray = new BooleanArray();
    private var triangles:ShortArray = new ShortArray();

    private var polygonPool:Pool<FloatArray> = new PolygonPool();

    private var polygonIndicesPool:Pool<ShortArray> = new IndicesPool();

    #if !spine_no_inline inline #end public function triangulate(verticesArray:FloatArray):ShortArray {
        var vertices:FloatArray = verticesArray.items;
        var vertexCount:Int = verticesArray.size >> 1;

        var indicesArray:ShortArray = this.indicesArray;
        indicesArray.clear();
        var indices:ShortArray = indicesArray.setSize(vertexCount);
        var i:Short = 0; while (i < vertexCount) {
            indices[i] = i; i++; }

        var isConcaveArray:BooleanArray = this.isConcaveArray;
        var isConcave:BooleanArray = isConcaveArray.setSize(vertexCount);
        var i:Int = 0; var n:Int = vertexCount; while (i < n) {
            isConcave[i] = isGeometryConcave(i, vertexCount, vertices, indices); ++i; }

        var triangles:ShortArray = this.triangles;
        triangles.clear();
        triangles.ensureCapacity(MathUtils.max(0, vertexCount - 2) << 2);

        while (vertexCount > 3) {
            // Find ear tip.
            var previous:Int = vertexCount - 1; var i:Int = 0; var next:Int = 1;
            while (true) {
                var _gotoLabel_outer:Int; while (true) { _gotoLabel_outer = 0; 
                if (!isConcave[i]) {
                    var p1:Int = indices[previous] << 1; var p2:Int = indices[i] << 1; var p3:Int = indices[next] << 1;
                    var p1x:Float = vertices[p1]; var p1y:Float = vertices[p1 + 1];
                    var p2x:Float = vertices[p2]; var p2y:Float = vertices[p2 + 1];
                    var p3x:Float = vertices[p3]; var p3y:Float = vertices[p3 + 1];
                    var ii:Int = (next + 1) % vertexCount; while (ii != previous) {
                        if (!isConcave[ii]) { ii = (ii + 1) % vertexCount; continue; }
                        var v:Int = indices[ii] << 1;
                        var vx:Float = vertices[v]; var vy:Float = vertices[v + 1];
                        if (positiveArea(p3x, p3y, p1x, p1y, vx, vy)) {
                            if (positiveArea(p1x, p1y, p2x, p2y, vx, vy)) {
                                if (positiveArea(p2x, p2y, p3x, p3y, vx, vy)) { _gotoLabel_outer = 1; break; }
                            }
                        }
                    ii = (ii + 1) % vertexCount; } if (_gotoLabel_outer == 2) continue; if (_gotoLabel_outer >= 1) break;
                    break;
                } if (_gotoLabel_outer == 0) break; }

                if (next == 0) {
                    do {
                        if (!isConcave[i]) break;
                        i--;
                    } while (i > 0);
                    break;
                }

                previous = i;
                i = next;
                next = (next + 1) % vertexCount;
            }

            // Cut ear tip.
            triangles.add(indices[(vertexCount + i - 1) % vertexCount]);
            triangles.add(indices[i]);
            triangles.add(indices[(i + 1) % vertexCount]);
            indicesArray.removeIndex(i);
            isConcaveArray.removeIndex(i);
            vertexCount--;

            var previousIndex:Int = (vertexCount + i - 1) % vertexCount;
            var nextIndex:Int = i == vertexCount ? 0 : i;
            isConcave[previousIndex] = isGeometryConcave(previousIndex, vertexCount, vertices, indices);
            isConcave[nextIndex] = isGeometryConcave(nextIndex, vertexCount, vertices, indices);
        }

        if (vertexCount == 3) {
            triangles.add(indices[2]);
            triangles.add(indices[0]);
            triangles.add(indices[1]);
        }

        return triangles;
    }

    #if !spine_no_inline inline #end public function decompose(verticesArray:FloatArray, triangles:ShortArray):FloatArray2D {
        var vertices:FloatArray = verticesArray.items;

        var convexPolygons:FloatArray2D = this.convexPolygons;
        polygonPool.freeAll(convexPolygons);
        convexPolygons.clear();

        var convexPolygonsIndices:ShortArray2D = this.convexPolygonsIndices;
        polygonIndicesPool.freeAll(convexPolygonsIndices);
        convexPolygonsIndices.clear();

        var polygonIndices:ShortArray = polygonIndicesPool.obtain();
        polygonIndices.clear();

        var polygon:FloatArray = polygonPool.obtain();
        polygon.clear();

        // Merge subsequent triangles if they form a triangle fan.
        var fanBaseIndex:Int = -1; var lastWinding:Int = 0;
        var trianglesItems:ShortArray = triangles.items;
        var i:Int = 0; var n:Int = triangles.size; while (i < n) {
            var t1:Int = trianglesItems[i] << 1; var t2:Int = trianglesItems[i + 1] << 1; var t3:Int = trianglesItems[i + 2] << 1;
            var x1:Float = vertices[t1]; var y1:Float = vertices[t1 + 1];
            var x2:Float = vertices[t2]; var y2:Float = vertices[t2 + 1];
            var x3:Float = vertices[t3]; var y3:Float = vertices[t3 + 1];

            // If the base of the last triangle is the same as this triangle, check if they form a convex polygon (triangle fan).
            var merged:Bool = false;
            if (fanBaseIndex == t1) {
                var o:Int = polygon.size - 4;
                var p:FloatArray = polygon.items;
                var winding1:Int = computeWinding(p[o], p[o + 1], p[o + 2], p[o + 3], x3, y3);
                var winding2:Int = computeWinding(x3, y3, p[0], p[1], p[2], p[3]);
                if (winding1 == lastWinding && winding2 == lastWinding) {
                    polygon.add(x3);
                    polygon.add(y3);
                    polygonIndices.add(t3);
                    merged = true;
                }
            }

            // Otherwise make this triangle the new base.
            if (!merged) {
                if (polygon.size > 0) {
                    convexPolygons.add(polygon);
                    convexPolygonsIndices.add(polygonIndices);
                } else {
                    polygonPool.free(polygon);
                    polygonIndicesPool.free(polygonIndices);                    
                }
                polygon = polygonPool.obtain();
                polygon.clear();
                polygon.add(x1);
                polygon.add(y1);
                polygon.add(x2);
                polygon.add(y2);
                polygon.add(x3);
                polygon.add(y3);
                polygonIndices = polygonIndicesPool.obtain();
                polygonIndices.clear();
                polygonIndices.add(t1);
                polygonIndices.add(t2);
                polygonIndices.add(t3);
                lastWinding = computeWinding(x1, y1, x2, y2, x3, y3);
                fanBaseIndex = t1;
            }
        i += 3; }

        if (polygon.size > 0) {
            convexPolygons.add(polygon);
            convexPolygonsIndices.add(polygonIndices);
        }

        // Go through the list of polygons and try to merge the remaining triangles with the found triangle fans.
        var i:Int = 0; var n:Int = convexPolygons.size; while (i < n) {
            polygonIndices = convexPolygonsIndices.get(i);
            if (polygonIndices.size == 0) { i++; continue; }
            var firstIndex:Int = polygonIndices.get(0);
            var lastIndex:Int = polygonIndices.get(polygonIndices.size - 1);

            polygon = convexPolygons.get(i);
            var o:Int = polygon.size - 4;
            var p:FloatArray = polygon.items;
            var prevPrevX:Float = p[o]; var prevPrevY:Float = p[o + 1];
            var prevX:Float = p[o + 2]; var prevY:Float = p[o + 3];
            var firstX:Float = p[0]; var firstY:Float = p[1];
            var secondX:Float = p[2]; var secondY:Float = p[3];
            var winding:Int = computeWinding(prevPrevX, prevPrevY, prevX, prevY, firstX, firstY);

            var ii:Int = 0; while (ii < n) {
                if (ii == i) { ii++; continue; }
                var otherIndices:ShortArray = convexPolygonsIndices.get(ii);
                if (otherIndices.size != 3) { ii++; continue; }
                var otherFirstIndex:Int = otherIndices.get(0);
                var otherSecondIndex:Int = otherIndices.get(1);
                var otherLastIndex:Int = otherIndices.get(2);

                var otherPoly:FloatArray = convexPolygons.get(ii);
                var x3:Float = otherPoly.get(otherPoly.size - 2); var y3:Float = otherPoly.get(otherPoly.size - 1);

                if (otherFirstIndex != firstIndex || otherSecondIndex != lastIndex) { ii++; continue; }
                var winding1:Int = computeWinding(prevPrevX, prevPrevY, prevX, prevY, x3, y3);
                var winding2:Int = computeWinding(x3, y3, firstX, firstY, secondX, secondY);
                if (winding1 == winding && winding2 == winding) {
                    otherPoly.clear();
                    otherIndices.clear();
                    polygon.add(x3);
                    polygon.add(y3);
                    polygonIndices.add(otherLastIndex);
                    prevPrevX = prevX;
                    prevPrevY = prevY;
                    prevX = x3;
                    prevY = y3;
                    ii = 0;
                }
            ii++; }
        i++; }

        // Remove empty polygons that resulted from the merge step above.
        var i:Int = convexPolygons.size - 1; while (i >= 0) {
            polygon = convexPolygons.get(i);
            if (polygon.size == 0) {
                convexPolygons.removeIndex(i);
                polygonPool.free(polygon);
                polygonIndices = convexPolygonsIndices.removeIndex(i);            
                polygonIndicesPool.free(polygonIndices);
            }
        i--; }

        return convexPolygons;
    }

    #if !spine_no_inline inline #end private static function isGeometryConcave(index:Int, vertexCount:Int, vertices:FloatArray, indices:ShortArray):Bool {
        var previous:Int = indices[(vertexCount + index - 1) % vertexCount] << 1;
        var current:Int = indices[index] << 1;
        var next:Int = indices[(index + 1) % vertexCount] << 1;
        return !positiveArea(vertices[previous], vertices[previous + 1], vertices[current], vertices[current + 1], vertices[next],
            vertices[next + 1]);
    }

    #if !spine_no_inline inline #end private static function positiveArea(p1x:Float, p1y:Float, p2x:Float, p2y:Float, p3x:Float, p3y:Float):Bool {
        return p1x * (p3y - p2y) + p2x * (p1y - p3y) + p3x * (p2y - p1y) >= 0;
    }

    #if !spine_no_inline inline #end private static function computeWinding(p1x:Float, p1y:Float, p2x:Float, p2y:Float, p3x:Float, p3y:Float):Int {
        var px:Float = p2x - p1x; var py:Float = p2y - p1y;
        return p3x * py - p3y * px + px * p1y - p1x * py >= 0 ? 1 : -1;
    }

    public function new() {}
}


private class PolygonPool extends Pool<FloatArray> {
    override function newObject() {
        return new FloatArray(16);
    }
}



private class IndicesPool extends Pool<ShortArray> {
    override function newObject() {
        return new ShortArray(16);
    }
}

