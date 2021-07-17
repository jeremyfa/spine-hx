/******************************************************************************
 * Spine Runtimes License Agreement
 * Last updated January 1, 2020. Replaces all prior versions.
 *
 * Copyright (c) 2013-2020, Esoteric Software LLC
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
 * THE SPINE RUNTIMES ARE PROVIDED BY ESOTERIC SOFTWARE LLC "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL ESOTERIC SOFTWARE LLC BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES,
 * BUSINESS INTERRUPTION, OR LOSS OF USE, DATA, OR PROFITS) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THE SPINE RUNTIMES, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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
