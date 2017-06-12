/******************************************************************************
 * Spine Runtimes Software License
 * Version 2.3
 *
 * Copyright (c) 2013-2015, Esoteric Software
 * All rights reserved.
 *
 * You are granted a perpetual, non-exclusive, non-sublicensable and
 * non-transferable license to use, install, execute and perform the Spine
 * Runtimes Software (the "Software") and derivative works solely for personal
 * or internal use. Without the written permission of Esoteric Software (see
 * Section 2 of the Spine Software License Agreement), you may not (a) modify,
 * translate, adapt or otherwise create derivative works, improvements of the
 * Software or develop new applications using the Software or (b) remove,
 * delete, alter or obscure any trademarks or any copyright, trademark, patent
 * or other intellectual property or proprietary rights notices on or in the
 * Software, including any copy thereof. Redistributions in binary or source
 * form must include this license and terms.
 *
 * THIS SOFTWARE IS PROVIDED BY ESOTERIC SOFTWARE "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL ESOTERIC SOFTWARE BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *****************************************************************************/

package spine;

import spine.compat.ArgumentError;

class Bone implements Updatable
{
    public var data(get, never) : BoneData;
    public var skeleton(get, never) : Skeleton;
    public var parent(get, never) : Bone;
    public var children(get, never) : Array<Bone>;
    public var a(get, never) : Float;
    public var b(get, never) : Float;
    public var c(get, never) : Float;
    public var d(get, never) : Float;
    public var worldX(get, never) : Float;
    public var worldY(get, never) : Float;
    public var worldSignX(get, never) : Float;
    public var worldSignY(get, never) : Float;
    public var worldRotationX(get, never) : Float;
    public var worldRotationY(get, never) : Float;
    public var worldScaleX(get, never) : Float;
    public var worldScaleY(get, never) : Float;

    public static var yDown : Bool = false;

    @:allow(spine)
    private var _data : BoneData;
    @:allow(spine)
    private var _skeleton : Skeleton;
    @:allow(spine)
    private var _parent : Bone;
    @:allow(spine)
    private var _children : Array<Bone> = new Array<Bone>();
    public var x : Float = 0;
    public var y : Float = 0;
    public var rotation : Float = 0;
    public var scaleX : Float = 0;
    public var scaleY : Float = 0;
    public var shearX : Float = 0;
    public var shearY : Float = 0;
    public var appliedRotation : Float = 0;

    @:allow(spine)
    private var _a : Float = 0;
    @:allow(spine)
    private var _b : Float = 0;
    @:allow(spine)
    private var _c : Float = 0;
    @:allow(spine)
    private var _d : Float = 0;
    @:allow(spine)
    private var _worldX : Float = 0;
    @:allow(spine)
    private var _worldY : Float = 0;
    @:allow(spine)
    private var _worldSignX : Float = 0;
    @:allow(spine)
    private var _worldSignY : Float = 0;

    @:allow(spine)
    private var _sorted : Bool = false;

    /** @param parent May be null. */
    public function new(data : BoneData, skeleton : Skeleton, parent : Bone)
    {
        if (data == null)
        {
            throw new ArgumentError("data cannot be null.");
        }
        if (skeleton == null)
        {
            throw new ArgumentError("skeleton cannot be null.");
        }
        _data = data;
        _skeleton = skeleton;
        _parent = parent;
        setToSetupPose();
    }

    /** Same as updateWorldTransform(). This method exists for Bone to implement Updatable. */
    public function update() : Void
    {
        updateWorldTransformWith(x, y, rotation, scaleX, scaleY, shearX, shearY);
    }

    /** Computes the world SRT using the parent bone and this bone's local SRT. */
    public function updateWorldTransform() : Void
    {
        updateWorldTransformWith(x, y, rotation, scaleX, scaleY, shearX, shearY);
    }

    /** Computes the world SRT using the parent bone and the specified local SRT. */
    public function updateWorldTransformWith(x : Float, y : Float, rotation : Float, scaleX : Float, scaleY : Float, shearX : Float, shearY : Float) : Void
    {
        appliedRotation = rotation;

        var rotationY : Float = rotation + 90 + shearY;
        var la : Float = MathUtils.cosDeg(rotation + shearX) * scaleX;
        var lb : Float = MathUtils.cosDeg(rotationY) * scaleY;
        var lc : Float = MathUtils.sinDeg(rotation + shearX) * scaleX;
        var ld : Float = MathUtils.sinDeg(rotationY) * scaleY;

        var parent : Bone = _parent;
        if (parent == null)
        {
            // Root bone.
            var skeleton : Skeleton = _skeleton;
            if (skeleton.flipX)
            {
                x = -x;
                la = -la;
                lb = -lb;
            }
            if (skeleton.flipY != yDown)
            {
                y = -y;
                lc = -lc;
                ld = -ld;
            }
            _a = la;
            _b = lb;
            _c = lc;
            _d = ld;
            _worldX = x;
            _worldY = y;
            _worldSignX = (scaleX < 0) ? -1 : 1;
            _worldSignY = (scaleY < 0) ? -1 : 1;
            return;
        }

        var pa : Float = parent._a;
        var pb : Float = parent._b;
        var pc : Float = parent._c;
        var pd : Float = parent._d;
        _worldX = pa * x + pb * y + parent._worldX;
        _worldY = pc * x + pd * y + parent._worldY;
        _worldSignX = parent._worldSignX * ((scaleX < 0) ? -1 : 1);
        _worldSignY = parent._worldSignY * ((scaleY < 0) ? -1 : 1);

        if (data.inheritRotation && data.inheritScale)
        {
            _a = pa * la + pb * lc;
            _b = pa * lb + pb * ld;
            _c = pc * la + pd * lc;
            _d = pc * lb + pd * ld;
        }
        else
        {
            if (data.inheritRotation)
            {
                // No scale inheritance.
                pa = 1;
                pb = 0;
                pc = 0;
                pd = 1;
                do
                {
                    var cos : Float = MathUtils.cosDeg(parent.appliedRotation);
                    var sin : Float = MathUtils.sinDeg(parent.appliedRotation);
                    var temp : Float = pa * cos + pb * sin;
                    pb = pb * cos - pa * sin;
                    pa = temp;
                    temp = pc * cos + pd * sin;
                    pd = pd * cos - pc * sin;
                    pc = temp;

                    if (!parent.data.inheritRotation)
                    {
                        break;
                    }
                    parent = parent.parent;
                }
                while ((parent != null));
                _a = pa * la + pb * lc;
                _b = pa * lb + pb * ld;
                _c = pc * la + pd * lc;
                _d = pc * lb + pd * ld;
            }
            else
            {
                if (data.inheritScale)
                {
                    // No rotation inheritance.
                    pa = 1;
                    pb = 0;
                    pc = 0;
                    pd = 1;
                    do
                    {
                        var cos = MathUtils.cosDeg(parent.appliedRotation);
                        var sin = MathUtils.sinDeg(parent.appliedRotation);
                        var psx : Float = parent.scaleX;
                        var psy : Float = parent.scaleY;
                        var za : Float = cos * psx;
                        var zb : Float = sin * psy;
                        var zc : Float = sin * psx;
                        var zd : Float = cos * psy;
                        var temp = pa * za + pb * zc;
                        pb = pb * zd - pa * zb;
                        pa = temp;
                        temp = pc * za + pd * zc;
                        pd = pd * zd - pc * zb;
                        pc = temp;

                        if (psx >= 0)
                        {
                            sin = -sin;
                        }
                        temp = pa * cos + pb * sin;
                        pb = pb * cos - pa * sin;
                        pa = temp;
                        temp = pc * cos + pd * sin;
                        pd = pd * cos - pc * sin;
                        pc = temp;

                        if (!parent.data.inheritScale)
                        {
                            break;
                        }
                        parent = parent.parent;
                    }
                    while ((parent != null));
                    _a = pa * la + pb * lc;
                    _b = pa * lb + pb * ld;
                    _c = pc * la + pd * lc;
                    _d = pc * lb + pd * ld;
                }
                else
                {
                    _a = la;
                    _b = lb;
                    _c = lc;
                    _d = ld;
                }
            }
            if (_skeleton.flipX)
            {
                _a = -_a;
                _b = -_b;
            }
            if (_skeleton.flipY != yDown)
            {
                _c = -_c;
                _d = -_d;
            }
        }
    }

    public function setToSetupPose() : Void
    {
        x = _data.x;
        y = _data.y;
        rotation = _data.rotation;
        scaleX = _data.scaleX;
        scaleY = _data.scaleY;
        shearX = _data.shearX;
        shearY = _data.shearY;
    }

    private function get_data() : BoneData
    {
        return _data;
    }

    private function get_skeleton() : Skeleton
    {
        return _skeleton;
    }

    private function get_parent() : Bone
    {
        return _parent;
    }

    private function get_children() : Array<Bone>
    {
        return _children;
    }

    private function get_a() : Float
    {
        return _a;
    }

    private function get_b() : Float
    {
        return _b;
    }

    private function get_c() : Float
    {
        return _c;
    }

    private function get_d() : Float
    {
        return _d;
    }

    private function get_worldX() : Float
    {
        return _worldX;
    }

    private function get_worldY() : Float
    {
        return _worldY;
    }

    private function get_worldSignX() : Float
    {
        return _worldSignX;
    }

    private function get_worldSignY() : Float
    {
        return _worldSignY;
    }

    private function get_worldRotationX() : Float
    {
        return Math.atan2(_c, _a) * MathUtils.radDeg;
    }

    private function get_worldRotationY() : Float
    {
        return Math.atan2(_d, _b) * MathUtils.radDeg;
    }

    private function get_worldScaleX() : Float
    {
        return Math.sqrt(_a * _a + _b * _b) * _worldSignX;
    }

    private function get_worldScaleY() : Float
    {
        return Math.sqrt(_c * _c + _d * _d) * _worldSignY;
    }

    public function worldToLocalRotationX() : Float
    {
        var parent : Bone = _parent;
        if (parent == null)
        {
            return rotation;
        }
        var pa : Float = parent.a;
        var pb : Float = parent.b;
        var pc : Float = parent.c;
        var pd : Float = parent.d;
        var a : Float = this.a;
        var c : Float = this.c;
        return Math.atan2(pa * c - pc * a, pd * a - pb * c) * MathUtils.radDeg;
    }

    public function worldToLocalRotationY() : Float
    {
        var parent : Bone = _parent;
        if (parent == null)
        {
            return rotation;
        }
        var pa : Float = parent.a;
        var pb : Float = parent.b;
        var pc : Float = parent.c;
        var pd : Float = parent.d;
        var b : Float = this.b;
        var d : Float = this.d;
        return Math.atan2(pa * d - pc * b, pd * b - pb * d) * MathUtils.radDeg;
    }

    public function rotateWorld(degrees : Float) : Void
    {
        var a : Float = this.a;
        var b : Float = this.b;
        var c : Float = this.c;
        var d : Float = this.d;
        var cos : Float = MathUtils.cosDeg(degrees);
        var sin : Float = MathUtils.sinDeg(degrees);
        this._a = cos * a - sin * c;
        this._b = cos * b - sin * d;
        this._c = sin * a + cos * c;
        this._d = sin * b + cos * d;
    }

    /** Computes the local transform from the world transform. This can be useful to perform processing on the local transform
	 * after the world transform has been modified directly (eg, by a constraint).
	 * <p>
	 * Some redundant information is lost by the world transform, such as -1,-1 scale versus 180 rotation. The computed local
	 * transform values may differ from the original values but are functionally the same. */
    public function updateLocalTransform() : Void
    {
        var parent : Bone = this.parent;
        if (parent == null)
        {
            x = worldX;
            y = worldY;
            rotation = Math.atan2(c, a) * MathUtils.radDeg;
            scaleX = Math.sqrt(a * a + c * c);
            scaleY = Math.sqrt(b * b + d * d);
            var det : Float = a * d - b * c;
            shearX = 0;
            shearY = Math.atan2(a * b + c * d, det) * MathUtils.radDeg;
            return;
        }
        var pa : Float = parent.a;
        var pb : Float = parent.b;
        var pc : Float = parent.c;
        var pd : Float = parent.d;
        var pid : Float = 1 / (pa * pd - pb * pc);
        var dx : Float = worldX - parent.worldX;
        var dy : Float = worldY - parent.worldY;
        x = (dx * pd * pid - dy * pb * pid);
        y = (dy * pa * pid - dx * pc * pid);
        var ia : Float = pid * pd;
        var id : Float = pid * pa;
        var ib : Float = pid * pb;
        var ic : Float = pid * pc;
        var ra : Float = ia * a - ib * c;
        var rb : Float = ia * b - ib * d;
        var rc : Float = id * c - ic * a;
        var rd : Float = id * d - ic * b;
        shearX = 0;
        scaleX = Math.sqrt(ra * ra + rc * rc);
        if (scaleX > 0.0001)
        {
            var det = ra * rd - rb * rc;
            scaleY = det / scaleX;
            shearY = Math.atan2(ra * rb + rc * rd, det) * MathUtils.radDeg;
            rotation = Math.atan2(rc, ra) * MathUtils.radDeg;
        }
        else
        {
            scaleX = 0;
            scaleY = Math.sqrt(rb * rb + rd * rd);
            shearY = 0;
            rotation = 90 - Math.atan2(rd, rb) * MathUtils.radDeg;
        }
        appliedRotation = rotation;
    }

    public function worldToLocal(world : Array<Float>) : Void
    {
        var a : Float = _a;
        var b : Float = _b;
        var c : Float = _c;
        var d : Float = _d;
        var invDet : Float = 1 / (a * d - b * c);
        var x : Float = world[0] - _worldX;
        var y : Float = world[1] - _worldY;
        world[0] = (x * d * invDet - y * b * invDet);
        world[1] = (y * a * invDet - x * c * invDet);
    }

    public function localToWorld(local : Array<Float>) : Void
    {
        var localX : Float = local[0];
        var localY : Float = local[1];
        local[0] = localX * _a + localY * _b + _worldX;
        local[1] = localX * _c + localY * _d + _worldY;
    }

    public function toString() : String
    {
        return _data._name;
    }
}
