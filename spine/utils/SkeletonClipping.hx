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
import spine.support.utils.FloatArray;
import spine.support.utils.ShortArray;
import spine.Slot;
import spine.attachments.ClippingAttachment;

class SkeletonClipping {
    private var triangulator:Triangulator = new Triangulator();
    private var clippingPolygon:FloatArray = new FloatArray();
    private var clipOutput:FloatArray = new FloatArray(128);
    private var clippedVertices:FloatArray = new FloatArray(128);
    private var clippedTriangles:ShortArray = new ShortArray(128);
    private var scratch:FloatArray = new FloatArray();

    private var clipAttachment:ClippingAttachment;
    private var clippingPolygons:FloatArray2D;

    #if !spine_no_inline inline #end public function clipStart(slot:Slot, clip:ClippingAttachment):Int {
        if (clipAttachment != null) return 0;
        var n:Int = clip.getWorldVerticesLength();
        if (n < 6) return 0;
        clipAttachment = clip;

        var vertices:FloatArray = clippingPolygon.setSize(n);
        clip.computeWorldVertices(slot, 0, n, vertices, 0, 2);
        makeClockwise(clippingPolygon);
        var triangles:ShortArray = triangulator.triangulate(clippingPolygon);
        clippingPolygons = triangulator.decompose(clippingPolygon, triangles);
        for (polygon in clippingPolygons) {
            makeClockwise(polygon);
            polygon.add(polygon.items[0]);
            polygon.add(polygon.items[1]);
        }
        return clippingPolygons.size;
    }

    #if !spine_no_inline inline #end public function clipEndWithSlot(slot:Slot):Void {
        if (clipAttachment != null && clipAttachment.getEndSlot() == slot.getData()) clipEnd();
    }

    #if !spine_no_inline inline #end public function clipEnd():Void {
        if (clipAttachment == null) return;
        clipAttachment = null;
        clippingPolygons = null;
        clippedVertices.clear();
        clippedTriangles.clear();
        clippingPolygon.clear();
    }

    #if !spine_no_inline inline #end public function isClipping():Bool {
        return clipAttachment != null;
    }

    #if !spine_no_inline inline #end public function clipTriangles(vertices:FloatArray, verticesLength:Int, triangles:ShortArray, trianglesLength:Int, uvs:FloatArray, light:Float, dark:Float, twoColor:Bool):Void {

        var clipOutput:FloatArray = this.clipOutput; var clippedVertices:FloatArray = this.clippedVertices;
        var clippedTriangles:ShortArray = this.clippedTriangles;
        var polygons = clippingPolygons.items;
        var polygonsCount:Int = clippingPolygons.size;
        var vertexSize:Int = twoColor ? 6 : 5;

        var index:Short = 0;
        clippedVertices.clear();
        clippedTriangles.clear();
        var _gotoLabel_outer:Int; while (true) { _gotoLabel_outer = 0; 
        var i:Int = 0; while (i < trianglesLength) {
            var vertexOffset:Int = triangles[i] << 1;
            var x1:Float = vertices[vertexOffset]; var y1:Float = vertices[vertexOffset + 1];
            var u1:Float = uvs[vertexOffset]; var v1:Float = uvs[vertexOffset + 1];

            vertexOffset = triangles[i + 1] << 1;
            var x2:Float = vertices[vertexOffset]; var y2:Float = vertices[vertexOffset + 1];
            var u2:Float = uvs[vertexOffset]; var v2:Float = uvs[vertexOffset + 1];

            vertexOffset = triangles[i + 2] << 1;
            var x3:Float = vertices[vertexOffset]; var y3:Float = vertices[vertexOffset + 1];
            var u3:Float = uvs[vertexOffset]; var v3:Float = uvs[vertexOffset + 1];

            var p:Int = 0; while (p < polygonsCount) {
                var s:Int = clippedVertices.size;
                if (clip(x1, y1, x2, y2, x3, y3, polygons[p], clipOutput)) {
                    var clipOutputLength:Int = clipOutput.size;
                    if (clipOutputLength == 0) { p++; continue; }
                    var d0:Float = y2 - y3; var d1:Float = x3 - x2; var d2:Float = x1 - x3; var d4:Float = y3 - y1;
                    var d:Float = 1 / (d0 * d2 + d1 * (y1 - y3));

                    var clipOutputCount:Int = clipOutputLength >> 1;
                    var clipOutputItems:FloatArray = clipOutput.items;
                    var clippedVerticesItems:FloatArray = clippedVertices.setSize(s + clipOutputCount * vertexSize);
                    var ii:Int = 0; while (ii < clipOutputLength) {
                        var x:Float = clipOutputItems[ii]; var y:Float = clipOutputItems[ii + 1];
                        clippedVerticesItems[s] = x;
                        clippedVerticesItems[s + 1] = y;
                        clippedVerticesItems[s + 2] = light;
                        if (twoColor) {
                            clippedVerticesItems[s + 3] = dark;
                            s += 4;
                        } else
                            s += 3;
                        var c0:Float = x - x3; var c1:Float = y - y3;
                        var a:Float = (d0 * c0 + d1 * c1) * d;
                        var b:Float = (d4 * c0 + d2 * c1) * d;
                        var c:Float = 1 - a - b;
                        clippedVerticesItems[s] = u1 * a + u2 * b + u3 * c;
                        clippedVerticesItems[s + 1] = v1 * a + v2 * b + v3 * c;
                        s += 2;
                    ii += 2; } if (_gotoLabel_outer == 2) break; if (_gotoLabel_outer >= 1) break;

                    s = clippedTriangles.size;
                    var clippedTrianglesItems:ShortArray = clippedTriangles.setSize(s + 3 * (clipOutputCount - 2));
                    clipOutputCount--;
                    var ii:Int = 1; while (ii < clipOutputCount) {
                        clippedTrianglesItems[s] = index;
                        clippedTrianglesItems[s + 1] = cast((index + ii), Short);
                        clippedTrianglesItems[s + 2] = cast((index + ii + 1), Short);
                        s += 3;
                    ii++; } if (_gotoLabel_outer == 2) break; if (_gotoLabel_outer >= 1) break;
                    index += clipOutputCount + 1;

                } else {
                    var clippedVerticesItems:FloatArray = clippedVertices.setSize(s + 3 * vertexSize);
                    clippedVerticesItems[s] = x1;
                    clippedVerticesItems[s + 1] = y1;
                    clippedVerticesItems[s + 2] = light;
                    if (!twoColor) {
                        clippedVerticesItems[s + 3] = u1;
                        clippedVerticesItems[s + 4] = v1;

                        clippedVerticesItems[s + 5] = x2;
                        clippedVerticesItems[s + 6] = y2;
                        clippedVerticesItems[s + 7] = light;
                        clippedVerticesItems[s + 8] = u2;
                        clippedVerticesItems[s + 9] = v2;

                        clippedVerticesItems[s + 10] = x3;
                        clippedVerticesItems[s + 11] = y3;
                        clippedVerticesItems[s + 12] = light;
                        clippedVerticesItems[s + 13] = u3;
                        clippedVerticesItems[s + 14] = v3;
                    } else {
                        clippedVerticesItems[s + 3] = dark;
                        clippedVerticesItems[s + 4] = u1;
                        clippedVerticesItems[s + 5] = v1;

                        clippedVerticesItems[s + 6] = x2;
                        clippedVerticesItems[s + 7] = y2;
                        clippedVerticesItems[s + 8] = light;
                        clippedVerticesItems[s + 9] = dark;
                        clippedVerticesItems[s + 10] = u2;
                        clippedVerticesItems[s + 11] = v2;

                        clippedVerticesItems[s + 12] = x3;
                        clippedVerticesItems[s + 13] = y3;
                        clippedVerticesItems[s + 14] = light;
                        clippedVerticesItems[s + 15] = dark;
                        clippedVerticesItems[s + 16] = u3;
                        clippedVerticesItems[s + 17] = v3;
                    }

                    s = clippedTriangles.size;
                    var clippedTrianglesItems:ShortArray = clippedTriangles.setSize(s + 3);
                    clippedTrianglesItems[s] = index;
                    clippedTrianglesItems[s + 1] = cast((index + 1), Short);
                    clippedTrianglesItems[s + 2] = cast((index + 2), Short);
                    index += 3;
                    { p++; _gotoLabel_outer = 2; break; }
                }
            p++; } if (_gotoLabel_outer == 2) { _gotoLabel_outer = 0; { i += 3; continue; } } if (_gotoLabel_outer >= 1) break;
        i += 3; } if (_gotoLabel_outer == 0) break; }
    }

    /** Clips the input triangle against the convex, clockwise clipping area. If the triangle lies entirely within the clipping
     * area, false is returned. The clipping area must duplicate the first vertex at the end of the vertices list. */
    public function clip(x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float, clippingArea:FloatArray, output:FloatArray):Bool {
        var originalOutput:FloatArray = output;
        var clipped:Bool = false;

        // Avoid copy at the end.
        var input:FloatArray = null;
        if (clippingArea.size % 4 >= 2) {
            input = output;
            output = scratch;
        } else
            input = scratch;

        input.clear();
        input.add(x1);
        input.add(y1);
        input.add(x2);
        input.add(y2);
        input.add(x3);
        input.add(y3);
        input.add(x1);
        input.add(y1);
        output.clear();

        var clippingVertices:FloatArray = clippingArea.items;
        var clippingVerticesLast:Int = clippingArea.size - 4;
        var i:Int = 0; while (true) {
            var edgeX:Float = clippingVertices[i]; var edgeY:Float = clippingVertices[i + 1];
            var edgeX2:Float = clippingVertices[i + 2]; var edgeY2:Float = clippingVertices[i + 3];
            var deltaX:Float = edgeX - edgeX2; var deltaY:Float = edgeY - edgeY2;

            var inputVertices:FloatArray = input.items;
            var inputVerticesLength:Int = input.size - 2; var outputStart:Int = output.size;
            var ii:Int = 0; while (ii < inputVerticesLength) {
                var inputX:Float = inputVertices[ii]; var inputY:Float = inputVertices[ii + 1];
                var inputX2:Float = inputVertices[ii + 2]; var inputY2:Float = inputVertices[ii + 3];
                var side2:Bool = deltaX * (inputY2 - edgeY2) - deltaY * (inputX2 - edgeX2) > 0;
                if (deltaX * (inputY - edgeY2) - deltaY * (inputX - edgeX2) > 0) {
                    if (side2) { // v1 inside, v2 inside
                        output.add(inputX2);
                        output.add(inputY2);
                        { ii += 2; continue; }
                    }
                    // v1 inside, v2 outside
                    var c0:Float = inputY2 - inputY; var c2:Float = inputX2 - inputX;
                    var s:Float = c0 * (edgeX2 - edgeX) - c2 * (edgeY2 - edgeY);
                    if (Math.abs(s) > 0.000001) {
                        var ua:Float = (c2 * (edgeY - inputY) - c0 * (edgeX - inputX)) / s;
                        output.add(edgeX + (edgeX2 - edgeX) * ua);
                        output.add(edgeY + (edgeY2 - edgeY) * ua);
                    } else {
                        output.add(edgeX);
                        output.add(edgeY);
                    }
                } else if (side2) { // v1 outside, v2 inside
                    var c0:Float = inputY2 - inputY; var c2:Float = inputX2 - inputX;
                    var s:Float = c0 * (edgeX2 - edgeX) - c2 * (edgeY2 - edgeY);
                    if (Math.abs(s) > 0.000001) {
                        var ua:Float = (c2 * (edgeY - inputY) - c0 * (edgeX - inputX)) / s;
                        output.add(edgeX + (edgeX2 - edgeX) * ua);
                        output.add(edgeY + (edgeY2 - edgeY) * ua);
                    } else {
                        output.add(edgeX);
                        output.add(edgeY);
                    }
                    output.add(inputX2);
                    output.add(inputY2);
                }
                clipped = true;
            ii += 2; }

            if (outputStart == output.size) { // All edges outside.
                originalOutput.clear();
                return true;
            }

            output.add(output.items[0]);
            output.add(output.items[1]);

            if (i == clippingVerticesLast) break;
            var temp:FloatArray = output;
            output = input;
            output.clear();
            input = temp;
        i += 2; }

        if (originalOutput != output) {
            originalOutput.clear();
            originalOutput.addAll(output.items, 0, output.size - 2);
        } else
            originalOutput.setSize(originalOutput.size - 2);

        return clipped;
    }

    #if !spine_no_inline inline #end public function getClippedVertices():FloatArray {
        return clippedVertices;
    }

    #if !spine_no_inline inline #end public function getClippedTriangles():ShortArray {
        return clippedTriangles;
    }

    #if !spine_no_inline inline #end static public function makeClockwise(polygon:FloatArray):Void {
        var vertices:FloatArray = polygon.items;
        var verticeslength:Int = polygon.size;

        var area:Float = vertices[verticeslength - 2] * vertices[1] - vertices[0] * vertices[verticeslength - 1]; var p1x:Float = 0; var p1y:Float = 0; var p2x:Float = 0; var p2y:Float = 0;
        var i:Int = 0; var n:Int = verticeslength - 3; while (i < n) {
            p1x = vertices[i];
            p1y = vertices[i + 1];
            p2x = vertices[i + 2];
            p2y = vertices[i + 3];
            area += p1x * p2y - p2x * p1y;
        i += 2; }
        if (area < 0) return;

        var i:Int = 0; var lastX:Int = verticeslength - 2; var n:Int = verticeslength >> 1; while (i < n) {
            var x:Float = vertices[i]; var y:Float = vertices[i + 1];
            var other:Int = lastX - i;
            vertices[i] = vertices[other];
            vertices[i + 1] = vertices[other + 1];
            vertices[other] = x;
            vertices[other + 1] = y;
        i += 2; }
    }

    public function new() {}
}
