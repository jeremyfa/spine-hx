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

@:enum abstract AttachmentType(Int) from Int to Int {
    var region = 0; var boundingbox = 1; var mesh = 2; var linkedmesh = 3; var path = 4; var point = 5; var clipping = 6;

    //public static var values:AttachmentType[] = values();
}


class AttachmentType_enum {

    public inline static var region_value = 0;
    public inline static var boundingbox_value = 1;
    public inline static var mesh_value = 2;
    public inline static var linkedmesh_value = 3;
    public inline static var path_value = 4;
    public inline static var point_value = 5;
    public inline static var clipping_value = 6;

    public inline static var region_name = "region";
    public inline static var boundingbox_name = "boundingbox";
    public inline static var mesh_name = "mesh";
    public inline static var linkedmesh_name = "linkedmesh";
    public inline static var path_name = "path";
    public inline static var point_name = "point";
    public inline static var clipping_name = "clipping";

    public inline static function valueOf(value:String):AttachmentType {
        return switch (value) {
            case "region": AttachmentType.region;
            case "boundingbox": AttachmentType.boundingbox;
            case "mesh": AttachmentType.mesh;
            case "linkedmesh": AttachmentType.linkedmesh;
            case "path": AttachmentType.path;
            case "point": AttachmentType.point;
            case "clipping": AttachmentType.clipping;
            default: AttachmentType.region;
        };
    }

}
